# Firewall Rules Reference

## Current UFW Configuration (15 Rules)

### Network Forwarding
| Rule | Direction | Purpose | Command |
|------|-----------|---------|---------|
| 1, 9 | tailscale0 → enp1s0f1 | VPN to LAN forwarding | `ufw route allow in on tailscale0 out on enp1s0f1 comment 'Tailscale VPN to LAN forwarding'` |

### DNS (Pi-hole)
| Rule | Port | Interface | Purpose | Command |
|------|------|-----------|---------|---------|
| 2, 10 | 53 | enp1s0f1 | DNS on LAN | `ufw allow in on enp1s0f1 to any port 53 comment 'Pi-hole DNS on LAN'` |
| 3, 11 | 53 | tailscale0 | DNS on VPN | `ufw allow in on tailscale0 to any port 53 comment 'Pi-hole DNS on Tailscale'` |

### SSH Access
| Rule | Port | Interface | Action | Purpose | Command |
|------|------|-----------|--------|---------|---------|
| 4, 12 | 22 | enp1s0f1 | ALLOW | SSH on LAN | `ufw allow in on enp1s0f1 to any port 22 comment 'SSH on LAN only'` |
| 5, 13 | 22 | tailscale0 | DENY | Block SSH on VPN | `ufw deny in on tailscale0 to any port 22 comment 'Block SSH on Tailscale (security)'` |

### Docker Container Access
| Rule | Port | Source | Purpose | Command |
|------|------|--------|---------|---------|
| 6 | 8080/tcp | 172.18.0.0/16 | Caddy → Pi-hole | `ufw allow from 172.18.0.0/16 to any port 8080 proto tcp comment 'Caddy proxy to Pi-hole'` |

### HTTPS (Caddy Reverse Proxy)
| Rule | Port | Interface | Purpose | Command |
|------|------|-----------|---------|---------|
| 7, 14 | 443/tcp | enp1s0f1 | HTTPS on LAN | `ufw allow in on enp1s0f1 to any port 443 proto tcp comment 'Caddy HTTPS on LAN'` |
| 8, 15 | 443/tcp | tailscale0 | HTTPS on VPN | `ufw allow in on tailscale0 to any port 443 proto tcp comment 'Caddy HTTPS on Tailscale'` |

## Rule Summary

```
Total Rules: 15 (8 IPv4 + 7 IPv6)

IPv4 Rules (1-8):
[ 1] Tailscale → LAN forwarding
[ 2] DNS on LAN
[ 3] DNS on Tailscale
[ 4] SSH on LAN (allow)
[ 5] SSH on Tailscale (deny)
[ 6] Caddy → Pi-hole (172.18.0.0/16 → port 8080)
[ 7] HTTPS on LAN
[ 8] HTTPS on Tailscale

IPv6 Rules (9-15):
[ 9] Tailscale → LAN forwarding (IPv6)
[10] DNS on LAN (IPv6)
[11] DNS on Tailscale (IPv6)
[12] SSH on LAN (IPv6)
[13] SSH on Tailscale DENY (IPv6)
[14] HTTPS on LAN (IPv6)
[15] HTTPS on Tailscale (IPv6)
```

## Adding Comments to Rules

```bash
# IPv4 Rules
sudo ufw delete 1 && sudo ufw route allow in on tailscale0 out on enp1s0f1 comment 'Tailscale VPN to LAN forwarding'
sudo ufw delete 2 && sudo ufw allow in on enp1s0f1 to any port 53 comment 'Pi-hole DNS on LAN'
sudo ufw delete 3 && sudo ufw allow in on tailscale0 to any port 53 comment 'Pi-hole DNS on Tailscale'
sudo ufw delete 4 && sudo ufw allow in on enp1s0f1 to any port 22 comment 'SSH on LAN only'
sudo ufw delete 5 && sudo ufw deny in on tailscale0 to any port 22 comment 'Block SSH on Tailscale (security)'
# Rule 6 already has comment
sudo ufw delete 7 && sudo ufw allow in on enp1s0f1 to any port 443 proto tcp comment 'Caddy HTTPS on LAN'
sudo ufw delete 8 && sudo ufw allow in on tailscale0 to any port 443 proto tcp comment 'Caddy HTTPS on Tailscale'

# IPv6 Rules (check numbering after IPv4 rules are updated)
sudo ufw delete 9 && sudo ufw route allow in on tailscale0 out on enp1s0f1 comment 'Tailscale to LAN (IPv6)'
sudo ufw delete 10 && sudo ufw allow in on enp1s0f1 to any port 53 comment 'Pi-hole DNS on LAN (IPv6)'
sudo ufw delete 11 && sudo ufw allow in on tailscale0 to any port 53 comment 'Pi-hole DNS on Tailscale (IPv6)'
sudo ufw delete 12 && sudo ufw allow in on enp1s0f1 to any port 22 comment 'SSH on LAN only (IPv6)'
sudo ufw delete 13 && sudo ufw deny in on tailscale0 to any port 22 comment 'Block SSH on Tailscale (IPv6)'
sudo ufw delete 14 && sudo ufw allow in on enp1s0f1 to any port 443 proto tcp comment 'Caddy HTTPS on LAN (IPv6)'
sudo ufw delete 15 && sudo ufw allow in on tailscale0 to any port 443 proto tcp comment 'Caddy HTTPS on Tailscale (IPv6)'
```

## Security Notes

- **SSH**: Only allowed on LAN (enp1s0f1), blocked on Tailscale for security
- **HTTPS**: All services accessible via Caddy on port 443
- **DNS**: Pi-hole serves DNS on both LAN and Tailscale
- **Docker**: Only Caddy proxy network (172.18.0.0/16) can access Pi-hole on port 8080
- **No direct container access**: All services accessed via Caddy reverse proxy

## Removed Rules (Cleanup)

These rules were removed as unnecessary:
- **LAN → proxy network forwarding** - Redundant, access via Caddy ports
- **LAN → docker0 forwarding (IPv6)** - Docker IPv6 not enabled, no containers on docker0

## Interface Names

- **enp1s0f1**: LAN interface (Ethernet)
- **tailscale0**: Tailscale VPN interface
- **docker0**: Default Docker bridge (172.17.0.0/16) - Only Portainer uses this
- **br-3a82f996c3e5**: Caddy proxy network bridge (172.18.0.0/16)

## Related Documentation

- [SERVER-SETUP.md](SERVER-SETUP.md) - Initial server setup including firewall
- [NETWORKING.md](NETWORKING.md) - Network architecture and flow
- [Caddy QUICKSTART](../system/caddy/QUICKSTART.md) - HTTPS reverse proxy setup
- [PROBLEMS.md](PROBLEMS.md) - Known issues and solutions
