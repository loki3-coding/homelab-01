## Diagram
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         HOMELAB ARCHITECTURE                                │
│               (DNS FLOW vs TRAFFIC FLOW – L3 vs L7)                         │
└─────────────────────────────────────────────────────────────────────────────┘

    DNS FLOW (Name Resolution)                            TRAFFIC FLOW (Data)
        L7 DNS                                                L7 HTTPS over L3

┌───────────────────────────────────────────────────────────────────────────────┐
│                                    Client(s)                                  │
│                                MacBook / iPhone                               │
└───────────────┬───────────────────────────────────────────────┬───────────────┘
                │ DNS query (immich.example.com)                │ HTTPS request
                ▼                                               ▼
┌───────────────────────────────┐              ┌───────────────────────────────┐
│     Tailscale DNS / MagicDNS  │              │   Tailscale WireGuard Tunnel  │
│        (DNS override)         │              │        (L3 encryption)        │
└───────────────┬───────────────┘              └───────────────┬───────────────┘
                │ forwards DNS query                           │ encrypted packets
                ▼                                              ▼
┌───────────────────────────────┐              ┌───────────────────────────────┐
│          Pi-hole DNS           │              │        Homelab Server          │
│   (Authoritative internal DNS) │              │        Tailscale IP            │
│                                │              │          100.x.y.z             │
│  immich.example.com → 100.x.y.z│              └───────────────┬───────────────┘
│  gitea.example.com  → 100.x.y.z│                              │ HTTPS (TLS)
│  grafana.example.com→ 100.x.y.z│                              ▼
└───────────────┬───────────────┘               ┌───────────────────────────────┐
                │ DNS response returned         │     Caddy Reverse Proxy        │
                ▼                               │   (TLS terminate – L7)         │
┌───────────────────────────────┐               │   - Listens on :443            │
│           Client(s)            │              │   - Caddy Local CA.            │
│  DNS resolved: 100.x.y.z       │              │   - Host-based routing         │
└───────────────────────────────┘               └───────────────┬───────────────┘
                                                                │
                                                                │ L7 HTTP (internal)
                                                                ▼
                                                ┌───────────────────────────────┐
                                                │     Backend Services           │
                                                │  Immich   → 127.0.0.1:2283     │
                                                │  Gitea    → 127.0.0.1:3000     │
                                                │  Grafana  → 127.0.0.1:3001     │
                                                │  PiHole   → 127.0.0.1:8080     │
                                                │  Portainer→ 127.0.0.1:9000     │
                                                |  ...                           |
                                                └───────────────────────────────┘

```

**Security:**
- All services behind Caddy reverse proxy (HTTPS)
- Tailscale VPN for remote access
- UFW firewall with restrictive rules
- Self-signed TLS certificates via Caddy

## Pi Hole Local DNS

- actualbudget.homelab.com	100.x.y.z
- gitea.homelab.com	100.x.y.z
- grafana.homelab.com	100.x.y.z
- home.homelab.com	100.x.y.z
- immich.homelab.com	100.x.y.z
- loki.homelab.com	100.x.y.z
- pihole.homelab.com	100.x.y.z
- portainer.homelab.com   100.x.y.z
- prometheus.homelab.com	100.x.y.z
- speedtest.homelab.com	100.x.y.z
