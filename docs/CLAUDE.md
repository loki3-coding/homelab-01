# CLAUDE.md - Homelab-01 Project Documentation

This document provides context for Claude AI (and other developers) about the homelab-01 project structure, architecture, and operations.

## Project Overview

**homelab-01** is a Docker Compose-driven personal homelab running on a dedicated homeserver. The project separates various self-hosted services into modular directories, allowing independent management and updates of each service.

### Key Goals
- Self-host essential services (Git, photo management, DNS blocking, etc.)
- Keep services isolated and independently manageable
- Reduce load on development machine (MacBook Pro M1, 16GB RAM)
- Use Docker Compose for reproducible deployments
- Maintain clear documentation and configuration

### Development Environment
- **Primary Machine**: MacBook Pro (Apple M1, 16GB RAM) - Used for development, IDE, browser
- **Homeserver**: Acer Aspire V3-572G
  - CPU: Intel Core (5th gen)
  - RAM: 8GB DDR3
  - Storage: 128GB SSD (OS, Docker images) + 500GB HDD (data storage)
  - OS: Ubuntu Server 24.04 LTS
  - Hostname: homelab-01
  - User: loki3
- **Container Runtime**: Docker Engine with Docker Compose v2
- **VPN**: Tailscale (for remote access with SSH and exit node)
- **Local Domain**: Services accessible via http://homelab-01/

## Repository Structure

```
homelab-01/
├── README.md              # User-facing documentation
├── .gitignore
│
├── docs/                  # Documentation
│   ├── CLAUDE.md         # This file - AI/developer context
│   ├── SERVER-SETUP.md   # Server setup guide
│   └── STARTUP.md        # Startup automation docs
│
├── scripts/               # Automation scripts
│   ├── start-all-services.sh      # Start all services
│   ├── stop-all-services.sh       # Stop all services
│   ├── server-setup.sh            # Server installation
│   ├── setup-ssh.sh               # SSH hardening
│   ├── setup-dns.sh               # DNS configuration
│   ├── setup-firewall-services.sh # Firewall rules
│   └── homelab.service            # Systemd service
│
├── platform/              # Platform services
│   ├── gitea/            # Self-hosted Git service
│   │   ├── docker-compose.yml
│   │   └── .env          # Gitea DB credentials
│   └── postgres/         # Shared PostgreSQL database
│       ├── docker-compose.yml
│       ├── .env          # Database credentials
│       └── data/         # Postgres data (gitignored)
│
├── apps/                  # Application services
│   ├── homepage/         # Dashboard homepage
│   │   ├── docker-compose.yml
│   │   └── config/       # Homepage configuration
│   ├── immich/           # Photo & video management
│   │   ├── docker-compose.yml
│   │   ├── .env          # Immich DB credentials
│   │   ├── init-db.sql   # Database initialization
│   │   └── README.md     # Immich-specific docs
│   └── pi-hole/          # Network-level ad blocking
│       ├── docker-compose.yml
│       └── .env          # Pi-hole admin password
│
├── system/                # System services
│   ├── nginx/            # Reverse proxy and TLS termination
│   │   ├── docker-compose.yml
│   │   ├── conf.d/       # Nginx vhost configs
│   │   └── certs/        # TLS certificates
│   └── monitoring/       # Prometheus + Grafana + Loki stack
│       ├── docker-compose.yml
│       ├── .env          # Grafana admin password
│       ├── prometheus/   # Prometheus scrape config
│       ├── loki/         # Loki log storage config
│       ├── promtail/     # Log shipping config
│       └── grafana/      # Grafana provisioning
│
```

## Services Architecture

### Service Dependencies

```
┌─────────────┐
│   Postgres  │  (Must start first)
│  (db-net)   │
└──────┬──────┘
       │
       ├────────────┐
       │            │
   ┌───▼───┐   ┌───▼────┐
   │ Gitea │   │ Immich │
   │(db-net│   │(db-net)│
   │proxy) │   │ redis  │
   └───────┘   └────────┘
       │
   ┌───▼────┐
   │  Nginx │  (Reverse proxy)
   │ (proxy)│
   └────────┘

 ┌──────────┐   ┌──────────┐
 │ Homepage │   │ Pi-hole  │  (Independent services)
 └──────────┘   └──────────┘

 ┌─────────────────────────────────────────────────────┐
 │              Monitoring Stack                        │
 │                                                      │
 │  ┌─────────────┐   ┌──────────┐   ┌──────────────┐ │
 │  │ Prometheus  │◄──│ cAdvisor │   │ Node Exporter│ │
 │  │   :9091     │   │  :8081   │   │    :9100     │ │
 │  └──────┬──────┘   └──────────┘   └──────────────┘ │
 │         │         ┌──────────┐                      │
 │         │         │   Loki   │◄──┐                  │
 │         │         │  :3100   │   │                  │
 │         ▼         └────┬─────┘   │                  │
 │  ┌─────────────┐       │    ┌────┴─────┐           │
 │  │   Grafana   │◄──────┘    │ Promtail │           │
 │  │   :3001     │            │ (logs)   │           │
 │  └─────────────┘            └──────────┘           │
 └─────────────────────────────────────────────────────┘
```

### Network Architecture

**db-net**: Bridge network for database-dependent services
- postgres (container)
- gitea (depends on postgres)
- immich-server (depends on postgres)
- pgadmin (database management UI)

**proxy**: External network for reverse proxy
- nginx-proxy
- gitea (exposed via proxy)

**immich-net**: Internal network for Immich services
- immich-server
- immich-redis
- immich-machine-learning

### Service Details

| Service | Container Name | Ports | Dependencies | Purpose |
|---------|---------------|-------|--------------|---------|
| Postgres | postgres | Internal (5432) | None | Shared database for Gitea and Immich |
| PgAdmin | pgadmin | 5050:80 | postgres | Database management UI |
| Gitea | gitea | 3000, 2222 | postgres | Self-hosted Git repositories |
| Immich | immich-server | 2283:3001 | postgres, redis | Photo/video backup and management |
| Nginx | nginx-proxy | 80:80 | None | Reverse proxy and TLS termination |
| Homepage | homepage | 3000:3000 | None | Dashboard and service links |
| Pi-hole | pihole | 53, 8080:80 | None | DNS-based ad blocking |
| Prometheus | prometheus | 9091:9090 | None | Metrics collection and storage |
| Grafana | grafana | 3001:3000 | prometheus, loki | Visualization dashboards |
| Loki | loki | Internal (3100) | None | Log aggregation |
| Promtail | promtail | None | loki | Log shipping agent |
| Node Exporter | node-exporter | Internal (9100) | None | Host system metrics |
| cAdvisor | cadvisor | 8081:8080 | None | Container metrics |

### Important Configuration Notes

1. **Postgres Image**: Uses `tensorchord/pgvecto-rs:pg16-v0.2.1` for Immich compatibility (includes vector extension for ML features)

2. **Environment Files**: Each service with credentials has a `.env` file (gitignored)
   - `postgres/.env`: POSTGRES_ADMIN_USER, POSTGRES_ADMIN_PASSWORD, PGADMIN_PASSWORD
   - `gitea/.env`: Database credentials for Gitea
   - `immich/.env`: IMMICH_DB_NAME, IMMICH_DB_USER, IMMICH_DB_PASSWORD
   - `pi-hole/.env`: WEBPASSWORD (admin interface)
   - `monitoring/.env`: GRAFANA_ADMIN_PASSWORD

3. **Data Persistence**:
   - Postgres: `./platform/postgres/data` volume (stored on 128GB SSD)
   - Immich uploads: `/home/loki3/immich` on homeserver (500GB HDD mount for large media files)
   - Gitea: Docker volumes for repos and data (128GB SSD)
   - PgAdmin: Named volume `pgadmin-data` (128GB SSD)

4. **Startup Order**:
   - Postgres MUST start before Gitea and Immich
   - Other services can start in any order

## Common Operations

### Starting Services

**Recommended**: Use the automated startup script (includes Tailscale):
```bash
./scripts/start-all-services.sh
```

Manual startup in correct order:
```bash
# Start Tailscale first
sudo tailscale up --ssh --advertise-exit-node

# Start Postgres
docker compose -f platform/postgres/docker-compose.yml up -d

# Then start dependent services
docker compose -f platform/gitea/docker-compose.yml -f apps/immich/docker-compose.yml up -d

# Start remaining services
docker compose -f system/nginx/docker-compose.yml -f apps/homepage/docker-compose.yml -f apps/pi-hole/docker-compose.yml up -d
```

Start a single service:
```bash
cd <service-directory>
docker compose up -d
```

### Managing Services

View logs:
```bash
cd <service-directory>
docker compose logs -f
```

Update images:
```bash
cd <service-directory>
docker compose pull
docker compose up -d
```

Stop service:
```bash
cd <service-directory>
docker compose down
```

Restart service:
```bash
cd <service-directory>
docker compose restart
```

### Database Operations

Initialize Immich database:
```bash
docker exec -i postgres psql -U $POSTGRES_ADMIN_USER < immich/init-db.sql
```

Access PostgreSQL CLI:
```bash
docker exec -it postgres psql -U <admin-user>
```

Access PgAdmin UI:
```
http://localhost:5050
```

## Development Guidelines

### When Adding New Services

1. Create a new directory for the service
2. Add `docker-compose.yml` with service definition
3. If using shared Postgres, connect to `db-net` network
4. If exposed via web, consider adding to `proxy` network
5. Create `.env.example` file (without secrets)
6. Add `.env` to `.gitignore`
7. Document setup in service directory README.md
8. Update main README.md service table
9. Update this CLAUDE.md with architecture details

### When Modifying Services

1. Always read existing configuration before making changes
2. Test changes in isolated environment first
3. Document any breaking changes
4. Update `.env.example` if environment variables change
5. Consider impact on dependent services
6. Update relevant documentation

### Best Practices

- Keep services modular and self-contained
- Use environment variables for all credentials
- Never commit `.env` files with secrets
- Document service-specific setup in service README
- Use Docker networks for service isolation
- Prefer named volumes over bind mounts (except for config/certs)
- Always specify restart policies for production services

## Troubleshooting

### Service Won't Start

1. Check if dependencies are running (especially Postgres)
   ```bash
   docker ps | grep postgres
   ```

2. Check logs for error messages
   ```bash
   docker compose logs
   ```

3. Verify network exists
   ```bash
   docker network ls | grep -E "db-net|proxy"
   ```

4. Create missing networks manually if needed
   ```bash
   docker network create db-net
   docker network create proxy
   ```

### Database Connection Issues

1. Verify Postgres is running and healthy
   ```bash
   docker exec postgres pg_isready -U <admin-user>
   ```

2. Check database exists
   ```bash
   docker exec -it postgres psql -U <admin-user> -l
   ```

3. Verify credentials in `.env` files match database users

### Permission Issues (Immich Uploads)

```bash
# Check ownership
ls -la /home/loki3/immich

# Fix permissions
sudo chown -R 1000:1000 /home/loki3/immich
```

### Port Conflicts

Check if port is already in use:
```bash
lsof -i :<port-number>
```

## Future Roadmap

Planned additions (check repository issues for details):
- Backup automation
- Home automation integration
- Additional services as needed

## Git Workflow

- **Main Branch**: `main` (default)
- **Remote**: ssh://gitea.homelab/vynguyen/homelab-01
- **Commit Style**: Descriptive messages with co-author attribution to Claude
- **Current Status**: Clean working tree (as of last check)

### Recent Changes

Recent commits focus on:
- Immich environment configuration
- Homepage updates
- Service integration improvements

## Access Information

- **Homepage**: http://homelab-01/
- **Gitea**: Accessible via Nginx proxy
- **Immich**: http://localhost:2283
- **PgAdmin**: http://localhost:5050
- **Pi-hole**: http://localhost:8080/admin
- **Grafana**: http://localhost:3001
- **Prometheus**: http://localhost:9091

## Notes for Claude AI

When working with this repository:

1. **Always read files before editing** - Understand current configuration first
2. **Respect the modular structure** - Each service is independent
3. **Consider dependencies** - Some services require Postgres
4. **Don't commit secrets** - All `.env` files are gitignored
5. **Test changes** - Suggest testing approach before implementing
6. **Document changes** - Update relevant README files
7. **Follow Docker Compose best practices** - Use networks, volumes, and restart policies appropriately
8. **Consider the homeserver context** - Services run on a separate machine from the development environment

## Questions or Issues

For questions about this project:
- Check service-specific README files in each directory
- Review docker-compose.yml for configuration details
- Check logs for runtime issues
- Open an issue in the repository for persistent problems

---

**Last Updated**: 2026-01-30
**Maintained By**: vynguyen
**Purpose**: Self-hosted homelab infrastructure
