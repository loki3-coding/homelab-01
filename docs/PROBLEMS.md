# Known Issues and Limitations

## Resolved Issues

### Pi-hole HTTPS Access Through Caddy ✅ SOLVED

**Problem:** Pi-hole (running in host network mode) could not be accessed via HTTPS through Caddy reverse proxy.

**Status:** Resolved on 2026-02-04

**Solution:** UFW firewall rule + Docker bridge gateway configuration

**See full documentation:** [platform/caddy/PIHOLE_HTTPS_SOLUTION.md](../platform/caddy/PIHOLE_HTTPS_SOLUTION.md)

**Quick reference:**
```bash
# UFW rule (required)
sudo ufw allow from 172.18.0.0/16 to any port 8080 proto tcp

# Caddyfile configuration
pihole.homelab.com {
    reverse_proxy 172.18.0.1:8080
}
```

**Access:** https://pihole.homelab.com/admin

---

## Current Known Issues

*No unresolved issues at this time.*

---

## All Services Status

| Service | HTTPS via Caddy | Access Method |
|---------|----------------|---------------|
| Homepage | ✅ Working | https://home.homelab.com |
| Immich | ✅ Working | https://immich.homelab.com |
| Gitea | ✅ Working | https://gitea.homelab.com |
| Grafana | ✅ Working | https://grafana.homelab.com |
| Prometheus | ✅ Working | https://prometheus.homelab.com |
| Loki | ✅ Working | https://loki.homelab.com |
| Pi-hole | ✅ Working | https://pihole.homelab.com/admin |

**Result:** 🎉 All 7 services successfully accessible via HTTPS through Caddy!

---

## Useful References

- Docker Networking: https://docs.docker.com/network/
- Caddy Documentation: https://caddyserver.com/docs/
- UFW with Docker: https://github.com/chaifeng/ufw-docker
