# homelab-01

A compact, Docker Compose–driven personal homelab repository for local/home server services and configuration.

**Documentation:**
- [CLAUDE.md](docs/CLAUDE.md) - Project context for AI and developers
- [SERVER-SETUP.md](docs/SERVER-SETUP.md) - Complete server setup guide from scratch
- [STARTUP.md](docs/STARTUP.md) - Automated service startup documentation
- [HARDWARE.md](docs/HARDWARE.md) - Hardware specifications and performance notes
- [ARCHITECTURE-REVIEW.md](docs/ARCHITECTURE-REVIEW.md) - Architectural analysis and recommendations

---

## 🚀 Overview

This repository collects docker-compose stacks and configuration for the services I run at home. It groups each service in its own directory so you can run, update, and manage them independently.

My local homepage is available at: [http://homelab-01/](http://homelab-01/)

**Included services:** Gitea (self-hosted Git), a static homepage, Immich (photo & video management), Nginx reverse proxy (with TLS certs), Pi-hole, and a Postgres instance for service data.

**Note:** This repo is actively expanded — more services will be added over time (for example: monitoring, backups, home automation, metrics, etc.). Check the repository issues or the (planned) `ROADMAP.md` for planned additions, or open an issue to suggest a service.

---

## Repository structure

### Platform Services
| Service | Description | Directory |
| --- | --- | --- |
| [Gitea](https://about.gitea.com/) | Self-hosted Git service (repositories, issues, web UI) | [`platform/gitea/`](platform/gitea/) |

### Applications
| Service | Description | Directory |
| --- | --- | --- |
| [Homepage](https://gethomepage.dev/) | Dashboard and service links | [`apps/homepage/`](apps/homepage/) |
| [Immich](https://immich.app/) | Self-hosted photo & video backup solution | [`apps/immich/`](apps/immich/) |
| [Pi-hole](https://pi-hole.net/) | Network-level ad and tracker blocking | [`apps/pi-hole/`](apps/pi-hole/) |

### System Services
| Service | Description | Directory |
| --- | --- | --- |
| [Nginx](https://nginx.org/) | Reverse proxy, TLS termination and vhost configs | [`system/nginx/`](system/nginx/) |
| [Postgres](https://www.postgresql.org/) | Dedicated PostgreSQL instance for service data | [`platform/postgres/`](platform/postgres/) |
| [Monitoring](https://grafana.com/) | Prometheus, Grafana, Loki monitoring stack | [`system/monitoring/`](system/monitoring/) |

### Planned / Future
Backups, home automation, etc. (tracked in `ROADMAP.md`)

---

## Quick start

Requirements: Docker Engine and Docker Compose (v2) installed on your macOS host.

Start a single service:

```bash
cd system/nginx && docker compose up -d
```

Start multiple services at once (example combining files):

```bash
docker compose -f system/nginx/docker-compose.yml -f platform/gitea/docker-compose.yml -f apps/homepage/docker-compose.yml -f apps/immich/docker-compose.yml -f apps/pi-hole/docker-compose.yml -f platform/postgres/docker-compose.yml up -d
```

**Important:** Start `postgres` before `gitea` and `immich`. Both require a reachable Postgres database at startup; if Postgres isn't available, they may fail to initialize and exit.

Recommended ways to start in order:

```bash
# start Postgres first, then Gitea and Immich
docker compose -f platform/postgres/docker-compose.yml up -d && docker compose -f platform/gitea/docker-compose.yml -f apps/immich/docker-compose.yml up -d

# or start Postgres first followed by the rest
docker compose -f platform/postgres/docker-compose.yml up -d && docker compose -f system/nginx/docker-compose.yml -f platform/gitea/docker-compose.yml -f apps/homepage/docker-compose.yml -f apps/immich/docker-compose.yml -f apps/pi-hole/docker-compose.yml up -d
```

Notes:
- Each service is self-contained; you can `cd` into the service folder and use `docker compose` there to manage it.
- Check service-specific directories for additional README or config instructions.

### Automated Startup (Recommended)

For easier management and automatic startup on server boot, use the provided scripts:

```bash
# Start all services in correct order
./scripts/start-all-services.sh

# Stop all services
./scripts/stop-all-services.sh
```

The startup script handles:
- Docker availability check
- Network creation
- Dependency ordering (Postgres → Gitea/Immich → Others)
- Health checks and error handling

**Auto-start on boot**: See [STARTUP.md](docs/STARTUP.md) for systemd service installation to automatically start services when the server reboots.

---

## Local machine vs homeserver

I use a MacBook Pro (Apple M1) with **16GB RAM** for development. To avoid overloading the laptop, all services run on a separate dedicated **homeserver**.

**Homeserver Hardware:**
- Acer Aspire V3-572G
- 8GB RAM, 128GB SSD + 500GB HDD
- Ubuntu Server 24.04 LTS
- Static IP: 192.168.100.200

**Setup:** MacBook is reserved for editor / AI / browser; all long-running services and Docker containers run on the homeserver.


---

## 🔧 Common tasks

- View logs: `docker compose logs -f` (run from the service folder)
- Update images: `docker compose pull && docker compose up -d`
- Stop service: `docker compose down`

---

## Configuration & data

Service configuration files can be found inside each service folder (e.g., `homepage/config/`). Docker volumes are used to persist data (database files, service configs). If you need to migrate data, inspect the `volumes:` section of the service's `docker-compose.yml`.

---

## License & contact

No license file is included in this repository.

For questions or help, open an issue in this repository.

---
