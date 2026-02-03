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
│                  │  Tailscale IP: 100.x.y.z │                      │
│                  │   LAN IP: 192.168.x.200    │                      │
│                  ▼                              ▼                      │
│  ┌──────────────────────────────────┐  ┌──────────────────────────┐   │
│  │      Pi-hole DNS (:53)           │  │  Caddy Reverse Proxy     │   │
│  │  *.homelab.com → 100.x.y.z   │  │       (:443)             │   │
│  └──────────────────────────────────┘  │  TLS Termination +       │   │
│                                         │  Host Routing            │   │
│                                         │  immich.homelab.com      │   │
│                                         │  → :2283                 │   │
│                                         │  gitea.homelab.com       │   │
│                                         │  → :3000                 │   │
│                                         │  grafana.homelab.com     │   │
│                                         │  → :3002                 │   │
│                                         └────────┬─────────────────┘   │
│                                                  │ HTTP (internal)     │
│               ┌──────────────────────────────────┼─────────────┐       │
│               ▼          ▼                       ▼             ▼       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────┐     │
│  │  Platform   │  │Applications │  │ Monitoring  │  │ Database │     │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤  ├──────────┤     │
│  │ Gitea       │  │ Immich      │  │ Prometheus  │  │ Postgres │     │
│  │  :3000      │  │  :2283      │  │  :9091      │  │ Internal │     │
│  │  :2222      │  │             │  │             │  │          │     │
│  │             │  │ Homepage    │  │ Grafana     │  └──────────┘     │
│  │             │  │  :3000      │  │  :3002      │                   │
│  │             │  │             │  │             │                   │
│  │             │  │ Pi-hole     │  │ Loki        │                   │
│  │             │  │  :53, :8080 │  │  :3100      │                   │
│  └─────────────┘  └─────────────┘  └─────────────┘                   │
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
   cp platform/postgres/.env.example platform/postgres/.env
   cp platform/gitea/.env.example platform/gitea/.env

   # Applications
   cp apps/immich/.env.example apps/immich/.env
   cp apps/pi-hole/.env.example apps/pi-hole/.env

   # Monitoring
   cp system/monitoring/.env.example system/monitoring/.env
   ```

3. **Edit each `.env` file:**
   ```bash
   # Replace all instances of "your-secure-password-here" with strong passwords
   nano platform/postgres/.env
   nano platform/gitea/.env
   nano apps/immich/.env
   nano apps/pi-hole/.env
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

5. **Access services:**
   - Homepage: http://homelab-01/
   - Immich: http://homelab-01:2283
   - Gitea: http://homelab-01:3000
   - Pi-hole Admin: http://homelab-01:8080/admin
   - Grafana: http://homelab-01:3002

**For detailed setup instructions, see [SERVER-SETUP.md](docs/SERVER-SETUP.md)**

---

## Documentation

**Start here:**

1.**[CLAUDE.md](CLAUDE.md)** - Quick reference for Claude AI sessions and daily operations

2.**[Immich Guide](apps/immich/README.md)** - Photo management setup

3.**[Scripts Reference](scripts/README.md)** - Automation scripts

**Detailed Guides:**
- [SERVER-SETUP.md](docs/SERVER-SETUP.md) - Initial server setup from scratch
- [STARTUP.md](docs/STARTUP.md) - Auto-start configuration
- [HTTPS-SETUP.md](docs/HTTPS-SETUP.md) - HTTPS architecture and DNS flow diagram

## Services

### Platform
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
|**Postgres** | Internal | Database for Gitea, Immich | [`platform/postgres/`](platform/postgres/) |
|**Gitea** | 3000, 2222 | Self-hosted Git service | [`platform/gitea/`](platform/gitea/) |

### Applications
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
|**Homepage** | 3000 | Dashboard | [`apps/homepage/`](apps/homepage/) |
|**Immich** | 2283 | Photo & video management | [`apps/immich/`](apps/immich/) |
|**Pi-hole** | 53, 8080 | Network ad blocker | [`apps/pi-hole/`](apps/pi-hole/) |

### System
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
|**Prometheus** | 9091 | Metrics collection | [`system/monitoring/`](system/monitoring/) |
|**Grafana** | 3002 | Monitoring dashboards | [`system/monitoring/`](system/monitoring/) |

---

## Repository Structure

```
homelab-01/
├── platform/          # Core services (Postgres, Gitea)
├── apps/              # User applications (Immich, Pi-hole, Homepage)
├── system/            # Infrastructure (Nginx, Monitoring)
├── scripts/           # Automation and backup scripts
├── CLAUDE.md          # Main operational reference
└── README.md          # This file
```

**Data Storage on Server:**
- Immich uploads: `/home/username/immich` (163GB on 500GB HDD)
- Immich thumbnails: `/home/username/immich-thumbs` (SSD)
- Backups: `/mnt/backup` (916GB external HDD)

---