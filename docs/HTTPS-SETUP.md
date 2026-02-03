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
│           Client(s)            │              │   - Let's Encrypt DNS-01       │
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
                                                │  Pi-hole  → 127.0.0.1:80       │
                                                └───────────────────────────────┘

```

## Pi Hole Local DNS
gitea.homelab.com	100.126.93.59	
grafana.homelab.com	100.126.93.59	
immich.homelab.com	100.126.93.59	
loki.homelab.com	100.126.93.59	
portainer.homelab.com	100.126.93.59	
prometheus.homelab.com	100.126.93.59