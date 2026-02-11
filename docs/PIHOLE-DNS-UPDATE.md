# Pi-hole DNS Configuration Guide

This guide explains how to add Local DNS records in Pi-hole for homelab services.

## Overview

Pi-hole acts as your DNS server on the Tailscale network, resolving *.homelab.com domains to your homelab server's Tailscale IP address.

**Current Setup:**
- Pi-hole is configured as Tailscale's DNS server
- All devices on Tailscale use Pi-hole for DNS resolution
- Caddy reverse proxy handles HTTPS/TLS for all services

---

## Quick Reference: Current DNS Records

All domains point to your homelab server's Tailscale IP: `100.x.y.z`

| Domain | Service |
|--------|---------|
| actualbudget.homelab.com | Actual Budget (Personal Finance) |
| gitea.homelab.com | Gitea (Git Service) |
| grafana.homelab.com | Grafana (Monitoring Dashboard) |
| home.homelab.com | Homepage (Dashboard) |
| immich.homelab.com | Immich (Photo Management) |
| loki.homelab.com | Loki (Log Aggregation) |
| pihole.homelab.com | Pi-hole (DNS & Ad Blocking) |
| portainer.homelab.com | Portainer (Docker Management) |
| prometheus.homelab.com | Prometheus (Metrics) |
| speedtest.homelab.com | Speedtest (Network Speed Test) |

---

## Adding New DNS Records

### Method 1: Via Web Interface (Recommended)

1. **Access Pi-hole Admin:**
   - Direct: http://homelab-01:8080/admin
   - HTTPS: https://pihole.homelab.com/admin

2. **Login:**
   - Use your Pi-hole admin password (from `system/pi-hole/.env`)

3. **Navigate to Local DNS:**
   - Click **"Local DNS"** in the left sidebar
   - Click **"DNS Records"** tab

4. **Add New Record:**
   - **Domain**: Enter the subdomain (e.g., `speedtest.homelab.com`)
   - **IP Address**: Enter your Tailscale IP (e.g., `100.x.y.z`)
   - Click **"Add"**

5. **Verify:**
   ```bash
   # On any device connected to Tailscale
   nslookup speedtest.homelab.com
   ```

### Method 2: Via SSH (Advanced)

```bash
# SSH to homelab server
ssh username@homelab-01

# Add DNS record
docker exec pihole pihole -a addcustomdns speedtest.homelab.com 100.x.y.z

# Verify
docker exec pihole pihole -a listcustomdns

# Restart DNS service (if needed)
docker exec pihole pihole restartdns
```

---

## Finding Your Tailscale IP

```bash
# On the homelab server
tailscale ip -4
```

Example output: `100.101.102.103`

---

## After Adding DNS Records

### 1. Update Caddyfile

Ensure Caddy has a reverse proxy entry for the new service:

```caddyfile
# In system/caddy/Caddyfile
speedtest.homelab.com {
    reverse_proxy speedtest:80

    log {
        output file /data/logs/speedtest.log
        format json
    }
}
```

### 2. Reload Caddy Configuration

```bash
# On homelab server
ssh username@homelab-01
cd ~/github/homelab-01/system/caddy
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### 3. Start the Service

```bash
# On homelab server
cd ~/github/homelab-01/apps/speedtest
docker compose up -d
```

### 4. Test Access

```bash
# From any device on Tailscale
curl -k https://speedtest.homelab.com

# Or open in browser
open https://speedtest.homelab.com
```

---

## Troubleshooting

### DNS Not Resolving

**Check Pi-hole is running:**
```bash
ssh username@homelab-01
docker ps | grep pihole
```

**Verify DNS record exists:**
```bash
# Via Pi-hole web interface
https://pihole.homelab.com/admin → Local DNS → DNS Records

# Via command line
docker exec pihole pihole -a listcustomdns | grep speedtest
```

**Test DNS resolution:**
```bash
# From your local machine
nslookup speedtest.homelab.com

# Should return 100.x.y.z
```

### HTTPS Not Working

**Check Caddy is running:**
```bash
cd ~/github/homelab-01/system/caddy
docker compose ps
```

**Verify Caddyfile configuration:**
```bash
cat ~/github/homelab-01/system/caddy/Caddyfile | grep speedtest
```

**Check Caddy logs:**
```bash
docker compose logs -f caddy
```

**Reload Caddy configuration:**
```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Service Not Accessible

**Check service is running:**
```bash
docker ps | grep speedtest
```

**Check service is on proxy network:**
```bash
docker inspect speedtest | grep proxy
```

**Verify port mapping:**
```bash
docker ps | grep speedtest
# Should show: 0.0.0.0:8765->80/tcp
```

---

## DNS Cache Issues

If changes don't take effect immediately:

**Clear local DNS cache:**

**macOS:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux:**
```bash
sudo systemd-resolve --flush-caches
```

**Windows:**
```cmd
ipconfig /flushdns
```

**Restart Pi-hole DNS:**
```bash
ssh username@homelab-01
docker exec pihole pihole restartdns
```

---

## Best Practices

1. **Naming Convention**: Use descriptive subdomains (e.g., `speedtest.homelab.com`, not `st.homelab.com`)

2. **Document Changes**: Update relevant documentation when adding new services:
   - `docs/NETWORKING.md` - Add to DNS records list
   - `CLAUDE.md` - Add to service table
   - Service README - Document HTTPS access

3. **Test Before Committing**: Always verify DNS and HTTPS work before committing changes

4. **Backup Pi-hole Configuration**:
   ```bash
   # Via web interface: Settings → Teleporter → Backup
   ```

5. **Security**: All services should go through Caddy (HTTPS only), never expose services directly

---

## Related Documentation

- **[NETWORKING.md](NETWORKING.md)** - Complete network architecture
- **[Caddy QUICKSTART](../system/caddy/QUICKSTART.md)** - Caddy setup guide
- **[CLAUDE.md](../CLAUDE.md)** - Service reference table
