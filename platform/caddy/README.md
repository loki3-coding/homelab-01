# Caddy Reverse Proxy

Caddy serves as the HTTPS/TLS reverse proxy for all homelab services, providing:
- Automatic HTTPS with TLS termination
- Host-based routing to backend services
- HTTP to HTTPS redirection
- Certificate management (Let's Encrypt or internal CA)

## Quick Links

- **[QUICKSTART.md](QUICKSTART.md)** - Get HTTPS working in 5 minutes
- **[Caddy Documentation](https://caddyserver.com/docs/)** - Official Caddy docs

## Architecture

```
Internet/Tailscale → Caddy (443) → Internal Services
                      ↓
                   TLS Termination
                      ↓
         ┌───────────────────────────┐
         │   immich.homelab.com      │ → immich-server:2283
         │   gitea.homelab.com       │ → gitea:3000
         │   grafana.homelab.com     │ → grafana:3000
         │   prometheus.homelab.com  │ → prometheus:9090
         │   loki.homelab.com        │ → loki:3100
         │   home.homelab.com        │ → homepage:3000
         └───────────────────────────┘
```

## Service URLs

| Service | Direct Access | HTTPS (via Caddy) |
|---------|---------------|-------------------|
| Immich | http://localhost:2283 | https://immich.homelab.com |
| Gitea | http://localhost:3000 | https://gitea.homelab.com |
| Grafana | http://localhost:3002 | https://grafana.homelab.com |
| Prometheus | http://localhost:9091 | https://prometheus.homelab.com |
| Loki | http://localhost:3100 | https://loki.homelab.com |
| Portainer | http://localhost:9000 | https://portainer.homelab.com |
| Homepage | http://localhost:3001 | https://home.homelab.com |
| Pi-hole | http://100.126.93.59:8080/admin | Direct HTTP only* |

**Note:** Pi-hole uses host network mode and is accessed directly (not through Caddy) due to Docker networking limitations. Access via Tailscale IP or LAN IP.

## First-Time Setup

**See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.**

Quick commands:
```bash
ssh username@homelab-01
cd ~/github/homelab-01
docker network create proxy 2>/dev/null || true
./scripts/integrate-caddy.sh  # Add proxy network to services
cd platform/caddy && docker compose up -d
```

## Certificate Options

**Default: Internal CA (Self-Signed)**
- Uses Caddy's built-in CA, works immediately
- Trust certificate to remove browser warnings: See [QUICKSTART.md](QUICKSTART.md#trust-caddys-certificate-remove-browser-warnings)

**Alternative: Let's Encrypt**
- For public domains with DNS API access
- Edit `Caddyfile`: Remove `local_certs`, add DNS provider config
- See `.env.example` for configuration template
- Docs: https://caddyserver.com/docs/automatic-https#dns-challenge

## Adding New Services

1. **Add to `Caddyfile`**:
   ```caddyfile
   newservice.homelab.com {
       reverse_proxy service-container:port
       log {
           output file /data/logs/newservice.log
           format json
       }
   }
   ```

2. **Add Pi-hole DNS**: Pi-hole Admin → Local DNS → `newservice.homelab.com` → `100.x.y.z`

3. **Add proxy network to service's docker-compose.yml**:
   ```yaml
   services:
     service-name:
       networks:
         - existing-net
         - proxy  # Add this

   networks:
     proxy:
       external: true  # Add this
   ```

4. **Restart service**: `docker compose down && docker compose up -d`

5. **Reload Caddy**: `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`

## Troubleshooting

**Service not accessible:**
```bash
docker ps | grep caddy              # Check Caddy running
docker ps | grep <service-name>     # Check backend running
docker network inspect proxy        # Verify both on proxy network
nslookup immich.homelab.com         # Verify DNS (should return 100.x.y.z)
```

**Caddy won't start:**
```bash
sudo lsof -i :443                   # Check port conflicts
docker network ls | grep proxy      # Verify network exists
docker compose logs caddy           # Check error messages
```

**Certificate warnings:**
- Expected with self-signed certs
- Trust Caddy's CA: See [QUICKSTART.md](QUICKSTART.md#trust-caddys-certificate-remove-browser-warnings)

## View Logs

```bash
docker compose logs -f                                  # Real-time
docker compose exec caddy cat /data/logs/immich.log     # Per-service logs
```

## Common Commands

```bash
docker compose up -d                                     # Start Caddy
docker compose down                                      # Stop Caddy
docker compose restart                                   # Restart
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile  # Reload config
docker compose pull && docker compose up -d              # Update Caddy
docker compose exec caddy caddy list-certificates        # View certs
```

## References

- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Reverse Proxy Guide](https://caddyserver.com/docs/quick-starts/reverse-proxy)
