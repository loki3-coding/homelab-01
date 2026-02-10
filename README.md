# homelab-01

Personal home server. Reduce paying for Cloud Services.

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

> **Detailed network flow:** See [NETWORKING.md](docs/NETWORKING.md) for DNS, HTTPS, and Tailscale architecture

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

## Homepage Dashboard

**Homelab Service Overview:**
![Homepage Dashboard](img/homepage.png)

---

## Grafana Dashboards

**Server Metrics Dashboard:**
![Grafana Server Metrics](img/grafana-server-metrics.png)

**Container Metrics Dashboard:**
![Grafana Container Metrics](img/grafana-container-metrics.png)

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

## Developer Setup (Local Machine)

### Install Git Hooks (Prevent Committing Secrets)

**⚠️ IMPORTANT:** Install git hooks on your **local development machine** (MacBook, laptop, etc.) where you commit code.

Git hooks prevent accidentally committing sensitive files like private keys, `.env` files, and passwords to the repository.

**One-time setup after cloning:**
```bash
# On your local machine (NOT the server)
cd ~/path/to/homelab-01
./scripts/git-hooks/install-hooks.sh
```

**What it protects against:**
- ❌ Private keys (`.pem`, `.key`, `.p12`, `.pfx`)
- ❌ Environment files (`.env`)
- ❌ API keys and tokens

**How it works:**
The hook runs automatically before every `git commit` and blocks dangerous commits. Your normal workflow stays the same - no extra steps needed!

**See full documentation:** [Git Hooks README](scripts/git-hooks/README.md)

---