# Known Issues and Limitations

## Pi-hole Cannot Be Proxied Through Caddy

### Problem

Pi-hole cannot be accessed via HTTPS through Caddy reverse proxy. All attempts to proxy `pihole.homelab.com` result in 502 Bad Gateway errors.

### Root Cause

Pi-hole uses **host network mode** (`network_mode: host`), which means it listens directly on the host's network interfaces. However, Caddy runs in **bridge network mode** with Docker networks (proxy, db-net, etc.).

Docker's default firewall rules prevent containers in bridge networks from accessing services on the host's ports, creating a container-to-host communication barrier.

### What Was Attempted

1. **IPv4 localhost (127.0.0.1:8080)** - Connection refused
2. **IPv6 localhost ([::1]:8080)** - Connection refused
3. **Docker bridge gateway (172.17.0.1:8080)** - Timeout
4. **LAN IP (192.168.100.200:8080)** - Timeout
5. **Tailscale IP (100.126.93.59:8080)** - Timeout
6. **extra_hosts mapping** - Ping worked, HTTP timeout
7. **host.docker.internal** - Not available on Linux

All connection attempts from Caddy container to host port 8080 were blocked by firewall/iptables rules.

### Test Results

```bash
# From host - Works ✓
curl http://localhost:8080/admin
# Returns: HTTP/1.1 302 Found

# From Caddy container - Fails ✗
docker exec caddy wget -O- http://192.168.100.200:8080/admin
# Returns: wget: download timed out

# Pi-hole is listening on all interfaces
ss -tlnp | grep 8080
# Shows: 0.0.0.0:8080 and [::]:8080
```

### Solution

**Pi-hole is accessed directly via HTTP (not through Caddy):**

- **Via hostname**: http://homelab-01:8080/admin
- **Via Tailscale IP**: http://100.126.93.59:8080/admin
- **Via LAN IP**: http://192.168.100.200:8080/admin

### Why This Is Acceptable

1. **Internal Use Only**: Pi-hole admin panel is only for homelab management
2. **Already Encrypted at L3**: Tailscale provides WireGuard encryption for all traffic
3. **No External Exposure**: Pi-hole is not exposed to the internet
4. **HTTP is Fine**: For internal admin panels, HTTP is sufficient
5. **All Other Services Work**: 6 out of 7 services successfully use HTTPS via Caddy

### Alternative Solutions (Not Implemented)

If HTTPS for Pi-hole is absolutely required:

#### Option 1: Configure Host Firewall
Allow Docker containers to access host port 8080:
```bash
sudo iptables -I INPUT -i docker0 -p tcp --dport 8080 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Drawback**: Opens host firewall, potential security implications.

#### Option 2: Move Pi-hole to Bridge Network
Change Pi-hole from host network to bridge network mode.

**Drawback**: Would break Pi-hole's DNS functionality since it needs to bind to port 53 on all interfaces.

#### Option 3: Use Tailscale HTTPS
Let Tailscale handle HTTPS for Pi-hole using `*.ts.net` domains.

**Drawback**: Requires Tailscale CLI on server, different certificate management.

## Services Status

| Service | HTTPS via Caddy | Access Method |
|---------|----------------|---------------|
| Homepage | ✅ Working | https://home.homelab.com |
| Immich | ✅ Working | https://immich.homelab.com |
| Gitea | ✅ Working | https://gitea.homelab.com |
| Grafana | ✅ Working | https://grafana.homelab.com |
| Prometheus | ✅ Working | https://prometheus.homelab.com |
| Loki | ✅ Working | https://loki.homelab.com |
| **Pi-hole** | ❌ Not Possible | http://homelab-01:8080/admin |

## Lessons Learned

1. **Host network mode and bridge networks don't mix** - Services using `network_mode: host` cannot be easily proxied by containers in bridge networks
2. **Docker firewall is restrictive by default** - This is by design for security
3. **Not everything needs HTTPS** - For internal admin tools, direct HTTP access is perfectly acceptable
4. **Pick your battles** - 6 out of 7 services working with HTTPS is a great result

## References

- Docker Networking: https://docs.docker.com/network/
- Pi-hole Network Mode: https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
- Caddy Reverse Proxy: https://caddyserver.com/docs/quick-starts/reverse-proxy
