# homelab-01

A compact, Docker Compose-driven personal homelab for local/home server services.

**🏠 Homepage:** [http://homelab-01/](http://homelab-01/)

---

## 📚 Documentation

**Start here:**

1. **[CLAUDE.md](CLAUDE.md)** - Quick reference for Claude AI sessions and daily operations

2. **[Immich Guide](apps/immich/README.md)** - Photo management setup

3. **[Scripts Reference](scripts/README.md)** - Automation scripts

**Detailed Guides:**
- [SERVER-SETUP.md](docs/SERVER-SETUP.md) - Initial server setup from scratch
- [STARTUP.md](docs/STARTUP.md) - Auto-start configuration

---

## 🚀 Quick Start

### Prerequisites
- Docker Engine and Docker Compose (v2)
- Ubuntu Server on homelab-01

### Start All Services

```bash
# SSH to server
ssh loki3@homelab-01

# Start everything
cd ~/github/homelab-01
./scripts/start-all-services.sh
```

---

## 📦 Services

### Platform
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
| **Postgres** | Internal | Database for Gitea, Immich | [`platform/postgres/`](platform/postgres/) |
| **Gitea** | 3000, 2222 | Self-hosted Git service | [`platform/gitea/`](platform/gitea/) |

### Applications
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
| **Homepage** | 3000 | Dashboard | [`apps/homepage/`](apps/homepage/) |
| **Immich** | 2283 | Photo & video management | [`apps/immich/`](apps/immich/) |
| **Pi-hole** | 53, 8080 | Network ad blocker | [`apps/pi-hole/`](apps/pi-hole/) |

### System
| Service | Port | Description | Directory |
|---------|------|-------------|-----------|
| **Nginx** | 80 | Reverse proxy | [`system/nginx/`](system/nginx/) |
| **Prometheus** | 9091 | Metrics collection | [`system/monitoring/`](system/monitoring/) |
| **Grafana** | 3002 | Monitoring dashboards | [`system/monitoring/`](system/monitoring/) |

---

## 🖥️ Infrastructure

**Local Machine:**
- MacBook Pro M1, 16GB RAM
- Used for: editing, AI, browser

**Homelab Server:**
- Acer Aspire V3-572G
- 8GB RAM, 128GB SSD + 500GB HDD
- Ubuntu Server 24.04 LTS
- Static IP: 192.168.100.200
- Repository: `/home/loki3/github/homelab`
- All Docker containers run here

**SSH Access:**
```bash
# From anywhere (Tailscale)
ssh loki3@homelab-01

# From local network
ssh loki3@homeLAN-01
```

---


## 📁 Repository Structure

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
- Immich uploads: `/home/loki3/immich` (163GB on 500GB HDD)
- Immich thumbnails: `/home/loki3/immich-thumbs` (SSD)
- Backups: `/mnt/backup` (916GB external HDD)

---