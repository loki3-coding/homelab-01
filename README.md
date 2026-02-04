# homelab-01

A compact, Docker Compose-driven personal homelab for local/home server services.

**Homepage:** [http://homelab-01/](http://homelab-01/)

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                              Clients                                   │
│                          MacBook / iPhone                              │
└──────────────────┬─────────────────────────────┬───────────────────────┘
                   │                             │
           DNS Query (L7)                  HTTPS Request (L7)
                   │                             │
                   ▼                             ▼
         ┌──────────────────┐         ┌──────────────────────┐
         │ Tailscale MagicDNS│         │  Tailscale WireGuard │
         │  (DNS override)   │         │   (L3 encryption)    │
         └─────────┬─────────┘         └──────────┬───────────┘
                   │                              │
                   │                              │
┌──────────────────┼──────────────────────────────┼──────────────────────┐
│                  │       Homelab Server         │                      │
│                  │  Tailscale IP: 100.x.y.z.    │                      │
│                  │   LAN IP: 192.168.x.200      │                      │
│                  ▼                              ▼                      │
│  ┌──────────────────────────────────┐  ┌──────────────────────────┐   │
│  │      Pi-hole DNS (:53)           │  │  Caddy Reverse Proxy     │   │
│  │  *.homelab.com → 100.x.y.z       │  │       (:443)             │   │
│  └──────────────────────────────────┘  │  TLS Termination +       │   │
│                                        │  Host Routing            │   │
│                                        │  immich.homelab.com      │   │
│                                        │  → :2283                 │   │
│                                        │  gitea.homelab.com       │   │
│                                        │  → :3000                 │   │
│                                        │  grafana.homelab.com     │   │
│                                        │  → :3002                 │   │
│                                         └────────┬─────────────────┘   │
│                                                  │ HTTP (internal)     │
│               ┌──────────────────────────────────┼─────────────┐       │
│               ▼          ▼                       ▼             ▼       │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────┐    │
│  │Infrastructure│  │Applications │  │   System    │  │          │    │
│  ├──────────────┤  ├─────────────┤  ├─────────────┤  │          │    │
│  │ Postgres     │  │ Gitea       │  │ Caddy       │  │          │    │
│  │  Internal    │  │  :3000      │  │  :80, :443  │  │          │    │
│  └──────────────┘  │  :2222      │  │             │  │          │    │
│                    │             │  │ Pi-hole     │  │          │    │
│                    │ Immich      │  │  :53, :8080 │  │          │    │
│                    │  :2283      │  │             │  │          │    │
│                    │             │  │ Monitoring  │  │          │    │
│                    │ Homepage    │  │ Prometheus  │  │          │    │
│                    │  :3000      │  │ Grafana     │  │          │    │
│                    │             │  │ Loki        │  │          │    │
│                    └─────────────┘  └─────────────┘  └──────────┘    │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Quick Setup

### Prerequisites
- Docker Engine and Docker Compose v2
- Ubuntu Server (or similar Linux distribution)
- Tailscale account (for VPN access)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/homelab-01.git
   cd homelab-01
   ```

2. **Configure environment files:**

   Copy the example files and set your own secure passwords:
   ```bash
   # Platform services
   cp core/postgres/.env.example core/postgres/.env
   cp core/gitea/.env.example core/gitea/.env

   # Applications
   cp apps/immich/.env.example apps/immich/.env
   cp system/pi-hole/.env.example system/pi-hole/.env

   # Monitoring
   cp system/monitoring/.env.example system/monitoring/.env
   ```

3. **Edit each `.env` file:**
   ```bash
   # Replace all instances of "your-secure-password-here" with strong passwords
   nano core/postgres/.env
   nano core/gitea/.env
   nano apps/immich/.env
   nano system/pi-hole/.env
   nano system/monitoring/.env
   ```

4. **Start all services:**
   ```bash
   # SSH to your homelab server
   ssh username@homelab-01

   # Navigate to repository
   cd ~/github/homelab-01

   # Start everything
   ./scripts/start-all-services.sh
   ```

**For detailed setup instructions, see [SERVER-SETUP.md](docs/SERVER-SETUP.md)**

---

## Documentation

**Start here:**

1. **[CLAUDE.md](CLAUDE.md)** - Quick reference for Claude AI sessions and daily operations

2. **[Immich Guide](apps/immich/README.md)** - Photo management setup

3. **[Scripts Reference](scripts/README.md)** - Automation scripts

**Detailed Guides:**
- [SERVER-SETUP.md](docs/SERVER-SETUP.md) - Initial server setup from scratch
- [STARTUP.md](docs/STARTUP.md) - Auto-start configuration
- [NETWORKING.md](docs/NETWORKING.md) - HTTPS architecture and DNS flow diagram
- [PROBLEMS.md](docs/PROBLEMS.md) - Open and Resolved Issues

## Services

### Core Services
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
|**Postgres** | Internal | Database for Gitea, Immich, Grafana | [`core/postgres/`](core/postgres/) |
|**PgAdmin** | 5050 | Database management UI | [`core/postgres/`](core/postgres/) |

### Applications
| Service | Port | Description | HTTPS Access | Directory |
|---------|------|-------------|--------------|-----------|
|**Gitea** | 3000, 2222 | Self-hosted Git service | https://gitea.homelab.com | [`apps/gitea/`](apps/gitea/) |
|**Immich** | 2283 | Photo & video management | https://immich.homelab.com | [`apps/immich/`](apps/immich/) |
|**Homepage** | 3000 | Homelab dashboard | https://home.homelab.com | [`apps/homepage/`](apps/homepage/) |

### System Services
| Service | Port | Description | HTTPS Access | Directory |
|---------|------|-------------|--------------|-----------|
|**Caddy** | 80, 443 | HTTPS reverse proxy & TLS termination | N/A (proxy) | [`system/caddy/`](system/caddy/) |
|**Pi-hole** | 53, 8080 | DNS & network ad blocker | https://pihole.homelab.com/admin | [`system/pi-hole/`](system/pi-hole/) |
|**Prometheus** | 9091 | Metrics collection | https://prometheus.homelab.com | [`system/monitoring/`](system/monitoring/) |
|**Grafana** | 3002 | Monitoring dashboards | https://grafana.homelab.com | [`system/monitoring/`](system/monitoring/) |
|**Loki** | 3100 | Log aggregation | https://loki.homelab.com | [`system/monitoring/`](system/monitoring/) |
|**Portainer** | 9000 | Docker management UI | https://portainer.homelab.com | N/A (external) |

---

## Repository Structure

```
homelab-01/
├── core/    # Foundation services (Phase 1)
│   └── postgres/      # Database + pgAdmin
│
├── apps/              # User-facing applications (Phase 2-3)
│   ├── gitea/         # Git service
│   ├── homepage/      # Dashboard
│   └── immich/        # Photo management
│
├── system/            # System services (Phase 3-4)
│   ├── caddy/         # HTTPS reverse proxy
│   ├── monitoring/    # Prometheus, Grafana, Loki
│   └── pi-hole/       # DNS & ad blocking
│
├── scripts/           # Automation and backup scripts
├── docs/              # Documentation
├── CLAUDE.md          # Main operational reference
└── README.md          # This file
```

**Service Tiers:**
- **core/**: Foundation services that others depend on
- **apps/**: User-facing applications (depend on infrastructure)
- **system/**: Infrastructure services (networking, monitoring, reverse proxy)

**Data Storage on Server:**
- Immich uploads: `/home/username/immich` (163GB on 500GB HDD)
- Immich thumbnails: `/home/username/immich-thumbs` (SSD)
- Backups: `/mnt/backup` (916GB external HDD)

---