# homelab-01

A compact, Docker Compose-driven personal homelab for local/home server services.

**Homepage:** [https://home.homelab.com/](https://home.homelab.com/)

---

## Architecture

### Three-Tier Service Model

```
┌─────────────────────────────────────────────────────────────────┐
│                     Homelab (Ubuntu Server)                     │
│                  Docker Compose-based Services                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Phase 4: System Services (Networking & Monitoring)     │    │
│  ├────────────────────────────────────────────────────────┤    │
│  │ • Caddy      - HTTPS reverse proxy (TLS termination)   │    │
│  │ • Pi-hole    - DNS & ad blocking                       │    │
│  │ • Monitoring - Prometheus, Grafana, Loki               │    │
│  └─────────────┬──────────────────────────────────────────┘    │
│                │ (provides networking & observability)          │
│                ▼                                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Phase 2-3: Applications (User-Facing Services)         │    │
│  ├────────────────────────────────────────────────────────┤    │
│  │ • Gitea      - Git repository hosting                  │    │
│  │ • Immich     - Photo & video management                │    │
│  │ • Homepage   - Homelab dashboard                       │    │
│  └─────────────┬──────────────────────────────────────────┘    │
│                │ (depends on database)                          │
│                ▼                                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Phase 1: Core Services (Foundation)                    │    │
│  ├────────────────────────────────────────────────────────┤    │
│  │ • Postgres   - Database (Gitea, Immich, Grafana)       │    │
│  │ • PgAdmin    - Database management UI                  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

**Dependency Order:**
- Core services (database) start first
- Applications depend on core services
- System services start last (proxy to applications)

**Security:**
- All services behind Caddy reverse proxy (HTTPS)
- Tailscale VPN for remote access
- UFW firewall with restrictive rules
- Self-signed TLS certificates via Caddy

**Modularity:**
- Each service in its own docker-compose.yml
- Shared networks (proxy, db-net) for inter-service communication
- Environment-based configuration (.env files)

**Data Storage:**
- Database: PostgreSQL (shared foundation)
- Photos: HDD storage (163GB) + SSD thumbnails
- Backups: External HDD (916GB)

> **Detailed network flow:** See [NETWORKING.md](docs/NETWORKING.md) for DNS, HTTPS, and Tailscale architecture

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

### 1. Architecture & Problem Solving

**Network & HTTPS:**
- **[NETWORKING.md](docs/NETWORKING.md)** - HTTPS architecture and DNS flow diagram
- **[Caddy README](system/caddy/README.md)** - Detailed Caddy configuration

**Issues & Solutions:**
- **[PROBLEMS.md](docs/PROBLEMS.md)** - Known issues and resolved problems

### 2. AI Assistant Guide

**For Claude Code / AI Sessions:**
- **[CLAUDE.md](CLAUDE.md)** - Start here for AI-assisted homelab operations

### 3. Setup & Operations

**Initial Setup:**
- **[SERVER-SETUP.md](docs/SERVER-SETUP.md)** - Complete server setup from scratch

**Daily Operations:**
- **[STARTUP.md](docs/STARTUP.md)** - Service startup/shutdown and auto-start
- **[Scripts Reference](scripts/README.md)** - Automation scripts overview
- **[Immich Guide](apps/immich/README.md)** - Photo management operations
- **[Immich Backup Guide](apps/immich/IMMICH_BACKUP_README.md)** - Backup and restore procedures

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