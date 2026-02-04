# Pi-hole HTTPS Access Through Caddy - Complete Solution

**Status:** ✅ RESOLVED (2026-02-04)

## Problem Summary

Pi-hole could not be accessed via HTTPS through Caddy reverse proxy. Attempts to proxy `pihole.homelab.com` resulted in connection timeouts and TLS handshake errors.

## Root Cause

Pi-hole uses **host network mode** (`network_mode: host`), which means it listens directly on the host's network interfaces. Caddy runs in **bridge network mode** with Docker networks (proxy, db-net, etc.).

**The challenge:** Docker's default firewall rules (via iptables/UFW) prevent containers in bridge networks from accessing services on the host's ports, creating a container-to-host communication barrier.

## Solution Overview

The solution requires **two components**:

1. **UFW firewall rule** - Allow Caddy's proxy network to access Pi-hole's port
2. **Caddyfile configuration** - Use Docker bridge gateway IP to reach the host

## Step-by-Step Implementation

### 1. Add UFW Firewall Rule

Allow traffic from Caddy's proxy network (172.18.0.0/16) to reach Pi-hole on port 8080:

```bash
ssh loki3@homelab-01
sudo ufw allow from 172.18.0.0/16 to any port 8080 proto tcp comment 'Caddy proxy to Pi-hole'
sudo ufw status numbered
```

**Expected output:**
```
[ 7] 8080/tcp                   ALLOW IN    172.18.0.0/16
```

**Why this is needed:**
- UFW's default INPUT policy blocks container-to-host traffic
- This rule explicitly allows only the proxy network (where Caddy runs)
- More secure than opening port 8080 to all Docker networks

### 2. Configure Caddyfile

Add Pi-hole reverse proxy configuration using the Docker bridge gateway IP:

```caddyfile
# Pi-hole - DNS & Ad Blocking
pihole.homelab.com {
	reverse_proxy 172.18.0.1:8080

	log {
		output file /data/logs/pihole.log
		format json
	}
}
```

**Key detail:** Use `172.18.0.1` (Docker bridge gateway from proxy network's perspective), NOT:
- ❌ `127.0.0.1` or `localhost` - Connection refused
- ❌ `192.168.x.x` (LAN IP) - Blocked by firewall
- ❌ `100.x.x.x` (Tailscale IP) - Blocked by firewall
- ✅ `172.18.0.1` - Docker bridge gateway, allowed by UFW rule

### 3. Deploy Configuration

```bash
# On local machine (commit changes)
git add platform/caddy/Caddyfile
git commit -m "Add Pi-hole HTTPS reverse proxy"
git push

# On server (pull and apply)
ssh loki3@homelab-01
cd ~/github/homelab
git pull

# IMPORTANT: Restart Caddy (reload is not enough for new sites)
cd platform/caddy
docker compose restart caddy

# Verify configuration loaded
docker compose exec caddy caddy adapt --config /etc/caddy/Caddyfile | grep -o 'pihole' | wc -l
# Should output: 3 (or more)
```

**Critical note:** `caddy reload` may NOT properly load new site configurations. Use `docker compose restart caddy` when adding new domains.

### 4. Verify Solution

```bash
# Test HTTP access from Caddy to Pi-hole
docker exec caddy wget -q -O- 'http://172.18.0.1:8080/admin' | head -5
# Should return: <!doctype html>...

# Test HTTPS from server
curl -k -I https://pihole.homelab.com/admin/
# Should return: HTTP/2 302 (redirect to login)

# Test from any Tailscale device
curl -k https://pihole.homelab.com/admin/
# Should return: HTTP/2 302

# Open in browser (accept self-signed cert warning)
open https://pihole.homelab.com/admin/
```

## Access Methods

| Method | URL | Notes |
|--------|-----|-------|
| **HTTPS via Caddy** (Preferred) | https://pihole.homelab.com/admin/ | Self-signed cert warning (safe to accept) |
| Direct HTTP (Backup) | http://homelab-01:8080/admin | No encryption, use for troubleshooting |
| Via Tailscale IP | http://100.126.93.59:8080/admin | Direct host access |

## Technical Details

### Network Architecture

```
Client (Mac/Phone)
    |
    | HTTPS (443)
    v
Caddy Container (172.18.0.5 on proxy network)
    |
    | HTTP to 172.18.0.1:8080 (Docker bridge gateway)
    | [UFW Rule allows this traffic]
    v
Host Network (where Pi-hole runs)
    |
    | Pi-hole listens on 0.0.0.0:8080
    v
Pi-hole Container (host network mode)
```

### Why Docker Bridge Gateway Works

- Each Docker network has a gateway IP (typically .0.1 of the subnet)
- From containers on the `proxy` network (172.18.0.0/16), the host is reachable at `172.18.0.1`
- This IP is specifically allowed by the UFW rule
- Pi-hole listens on all interfaces (0.0.0.0:8080), so accepts connections from any source IP

### Security Considerations

**Why this is secure:**
- ✅ Only Caddy's proxy network (172.18.0.0/16) can access port 8080
- ✅ Other Docker networks are blocked
- ✅ External access requires going through Caddy's HTTPS
- ✅ Caddy provides TLS encryption for all external traffic
- ✅ Pi-hole admin interface protected by its own authentication

**Not allowed:**
- ❌ Direct access to port 8080 from external networks (blocked by UFW)
- ❌ Access from other Docker networks (not in the 172.18.0.0/16 range)
- ❌ Bypass of Caddy reverse proxy from outside the host

## What We Tried (Failed Approaches)

### Attempt 1: localhost (127.0.0.1)
```caddyfile
reverse_proxy 127.0.0.1:8080  # ❌ Connection refused
```
**Why it failed:** Containers have their own network namespace; localhost refers to the container, not the host.

### Attempt 2: LAN IP (192.168.x.x)
```caddyfile
reverse_proxy 192.168.100.200:8080  # ❌ Connection timeout
```
**Why it failed:** UFW blocks traffic from Docker networks to LAN IPs by default.

### Attempt 3: Tailscale IP (100.x.x.x)
```caddyfile
reverse_proxy 100.126.93.59:8080  # ❌ Connection timeout
```
**Why it failed:** Tailscale interface traffic also blocked by UFW.

### Attempt 4: Docker default bridge (172.17.0.1)
```caddyfile
reverse_proxy 172.17.0.1:8080  # ❌ Connection timeout
```
**Why it failed:** Caddy is on proxy network (172.18.x.x), not default bridge (172.17.x.x).

### ✅ Working Solution: Proxy network gateway (172.18.0.1)
```caddyfile
reverse_proxy 172.18.0.1:8080  # ✅ Works with UFW rule
```
**Why it works:** Matches the proxy network's gateway + UFW rule allows this specific network.

## Lessons Learned

1. **Host network mode requires special handling** - Services using `network_mode: host` need explicit firewall rules for container-to-host access
2. **UFW is more restrictive than raw Docker** - When UFW is enabled, container-to-host traffic needs explicit rules
3. **Use network-specific gateway IPs** - Each Docker network has its own gateway IP (e.g., 172.18.0.1 for proxy network)
4. **Caddy reload may not be enough** - New site configurations often require a full restart
5. **Bridge gateway IP is the key** - Not localhost, not LAN IP, but the Docker network's gateway IP

## References

- Docker Networking: https://docs.docker.com/network/
- Pi-hole Network Mode: https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
- Caddy Reverse Proxy: https://caddyserver.com/docs/quick-starts/reverse-proxy
- UFW with Docker: https://github.com/chaifeng/ufw-docker

## Final Result

✅ **All 7 services now accessible via HTTPS through Caddy:**

| Service | HTTPS URL | Status |
|---------|-----------|--------|
| Homepage | https://home.homelab.com | ✅ Working |
| Immich | https://immich.homelab.com | ✅ Working |
| Gitea | https://gitea.homelab.com | ✅ Working |
| Grafana | https://grafana.homelab.com | ✅ Working |
| Prometheus | https://prometheus.homelab.com | ✅ Working |
| Loki | https://loki.homelab.com | ✅ Working |
| **Pi-hole** | **https://pihole.homelab.com/admin** | ✅ **Working** |
