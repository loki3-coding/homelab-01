# Caddy Reverse Proxy - Quick Start Guide

**Get HTTPS working in 5 minutes!**

## Prerequisites Checklist

- [ ] Pi-hole Local DNS configured with `*.homelab.com` → `100.x.y.z` (Tailscale IP)
- [ ] Pi-hole set as Tailscale DNS
- [ ] MacBook connected to Tailscale network
- [ ] SSH access to homelab server: `ssh username@homelab-01`

## Quick Setup (SSH to Server)

```bash
# 1. SSH to your homelab server
ssh username@homelab-01

# 2. Navigate to the homelab directory
cd ~/github/homelab-01

# 3. Create required Docker networks
docker network create proxy 2>/dev/null || echo "proxy network already exists"
docker network create db-net 2>/dev/null || echo "db-net already exists"

# 4. Start Caddy
cd platform/caddy
docker compose up -d

# 5. Check Caddy is running
docker ps | grep caddy
docker compose logs -f
```

## Update Backend Services

Services need to join the `proxy` network to be accessible via Caddy.

### Automated Method (Recommended)

```bash
cd ~/github/homelab-01
./scripts/integrate-caddy.sh
```

This script will:
- Backup existing configurations
- Add `proxy` network to Gitea, Immich, and Monitoring services
- Show you what changes were made

### Manual Method

Edit each service's `docker-compose.yml`:

**Gitea** (`platform/gitea/docker-compose.yml`):
```yaml
networks:
  - gitea-net
  - db-net
  - proxy  # ADD THIS

networks:
  proxy:  # ADD THIS BLOCK
    external: true
```

**Immich** (`apps/immich/docker-compose.yml`):
```yaml
services:
  immich-server:
    networks:
      - db-net
      - immich-net
      - proxy  # ADD THIS

networks:
  proxy:  # ADD THIS BLOCK
    external: true
```

**Monitoring** (`system/monitoring/docker-compose.yml`):
```yaml
services:
  prometheus:
    networks:
      - monitoring-net
      - proxy  # ADD THIS

  loki:
    networks:
      - monitoring-net
      - proxy  # ADD THIS
```

## Restart Updated Services

```bash
# Restart each service after updating
cd ~/github/homelab-01/platform/gitea
docker compose down && docker compose up -d

cd ~/github/homelab-01/apps/immich
docker compose down && docker compose up -d

cd ~/github/homelab-01/system/monitoring
docker compose down && docker compose up -d
```

## Test HTTPS Access

**From your MacBook** (connected to Tailscale):

```bash
# Test each service
curl -k https://immich.homelab.com
curl -k https://gitea.homelab.com
curl -k https://grafana.homelab.com

# Or open in browser
open https://grafana.homelab.com
```

**Note**: `-k` flag ignores certificate warnings (expected with self-signed certs)

## Trust Caddy's Certificate (Remove Browser Warnings)

### Extract Root CA from Caddy

```bash
# On server
ssh username@homelab-01
docker exec caddy cat /data/caddy/pki/authorities/local/root.crt > /tmp/caddy-root.crt

# Copy to MacBook (from MacBook)
scp username@homelab-01:/tmp/caddy-root.crt ~/Downloads/
```

### Trust Certificate on MacBook

**GUI Method**:
1. Open `caddy-root.crt` from Downloads (double-click)
2. Keychain Access will open
3. Find "Caddy Local Authority" in System keychain
4. Double-click → Trust section → "Always Trust" for SSL

**Command Line**:
```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/Downloads/caddy-root.crt
```

### Restart Browser

Close and reopen your browser. Certificate warnings should be gone!

## All-in-One Startup

Use the updated startup script to start everything including Caddy:

```bash
ssh username@homelab-01
cd ~/github/homelab-01
./scripts/start-all-services.sh
```

This will start services in the correct order:
1. Tailscale & SSH
2. PostgreSQL
3. Gitea & Immich
4. Homepage & Pi-hole
5. Monitoring stack
6. **Caddy reverse proxy** ← New!

## Troubleshooting

### "Connection refused" or "Service unavailable"

1. **Check Caddy is running**:
   ```bash
   docker ps | grep caddy
   ```

2. **Check backend service is running**:
   ```bash
   docker ps | grep immich-server
   ```

3. **Verify service is on proxy network**:
   ```bash
   docker network inspect proxy | grep immich
   ```

4. **Check Caddy logs**:
   ```bash
   cd ~/github/homelab-01/platform/caddy
   docker compose logs -f
   ```

### DNS not resolving

```bash
# From MacBook
nslookup immich.homelab.com

# Should return your Tailscale IP (100.x.y.z)
# If not, check Pi-hole Local DNS configuration
```

### Certificate warnings persist

- Wait 1-2 minutes after importing certificate
- Restart browser completely
- Check certificate is in System keychain, not Login keychain
- Verify "Always Trust" is set for SSL

### Caddy won't start

**Port conflict check**:
```bash
sudo lsof -i :443
sudo lsof -i :80
```

**Network issue**:
```bash
# Ensure networks exist
docker network ls | grep -E "proxy|db-net|monitoring-net|immich-net|gitea-net"

# Create missing networks
docker network create <network-name>
```

## Next Steps

1. **Bookmark HTTPS URLs** (see [README.md](README.md#service-urls) for full list)
2. **Configure Let's Encrypt** (optional) - See [README.md](README.md#certificate-options)
3. **Add more services** - See [README.md](README.md#adding-new-services)

## Support

- **Full Documentation**: [README.md](README.md)
- **Caddy Docs**: https://caddyserver.com/docs/
