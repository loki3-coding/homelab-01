# CLAUDE.md - Homelab-01 Quick Reference

**This is the main operational reference for Claude AI sessions and daily tasks**

---

## Documentation Navigation

- **[Main README](README.md)** - Project overview and getting started
- **[Immich Guide](apps/immich/README.md)** - Photo management operations
- **[Scripts](scripts/README.md)** - Automation and backup scripts
- **[Backup Guide](scripts/IMMICH_BACKUP_README.md)** - Detailed backup procedures
- **[Caddy Setup](system/caddy/QUICKSTART.md)** - HTTPS reverse proxy quick start
- **[HTTPS Architecture](docs/HTTPS-SETUP.md)** - Network architecture and TLS setup

---

## Server Access

**Important Context:**
- **Claude Code** runs on the LOCAL machine (`/Users/standard-xvy/Github/homelab-01`)
- **Docker containers** run on the REMOTE homelab server
- Most operations require SSH to the server

**SSH to Homelab Server:**
```bash
# From anywhere (Tailscale VPN - recommended for Claude sessions)
ssh username@homelab-01

# From local network only
ssh username@homeLAN-01
```

**For Claude Code Sessions:**
- Use: `ssh username@homelab-01` (works locally and remotely via Tailscale)
- SSH keys configured for passwordless authentication
- Execute remote commands: `ssh username@homelab-01 "cd ~/github/homelab-01 && docker ps"`
- Git operations work over SSH

## Project Structure

**Local Repository** (`/Users/standard-xvy/Github/homelab-01`):
```
homelab-01/
├── core/    # Foundation services
│   └── postgres/      # Database + pgAdmin
├── apps/              # User-facing applications
│   ├── gitea/         # Git service
│   ├── homepage/      # Dashboard
│   └── immich/        # Photo management (includes SSD_THUMBNAILS_SETUP.md)
├── system/            # System services
│   ├── caddy/         # HTTPS reverse proxy
│   ├── monitoring/    # Prometheus/Grafana/Loki + scripts
│   └── pi-hole/       # DNS & ad blocking
├── scripts/           # Automation (backup, startup, integration)
└── CLAUDE.md          # This file (main reference)
```

**Server Data Paths** (`username@homelab-01`):
- Repository clone: `~/github/homelab-01/`
- Immich uploads: `/home/username/immich` (163GB on 500GB HDD - **has 64 bad sectors!**)
- Immich thumbnails: `/home/username/immich-thumbs` (SSD - configured but not yet applied)
- Backup drive: `/mnt/backup` (916GB external HDD - manually mounted)

## Service Architecture

**Critical Dependencies:**
- Postgres MUST start before Gitea and Immich
- Services use `db-net` network for database connections
- Caddy provides HTTPS access via `proxy` network

| Service | Container | Ports | Dependencies | Direct Access | HTTPS Access (via Caddy) |
|---------|-----------|-------|--------------|---------------|--------------------------|
| Caddy | caddy | 80, 443 | None (last to start) | N/A | Reverse proxy for all services |
| Postgres | postgres | Internal | None | Auto-start | N/A |
| PgAdmin | pgadmin | 5050 | postgres | http://localhost:5050 | N/A (manual start) |
| Gitea | gitea | 3000, 2222 | postgres | http://localhost:3000 | https://gitea.homelab.com |
| Immich | immich-server | 2283 | postgres, redis | http://localhost:2283 | https://immich.homelab.com |
| Homepage | homepage | 3000 | None | http://homelab-01/ | N/A |
| Pi-hole | pihole | 53, 8080 | None | http://localhost:8080/admin | https://pihole.homelab.com |
| Prometheus | prometheus | 9091 | None | http://localhost:9091 | https://prometheus.homelab.com |
| Grafana | grafana | 3002 | prometheus, loki | http://localhost:3002 | https://grafana.homelab.com |
| Loki | loki | 3100 | None | http://localhost:3100 | https://loki.homelab.com |

**HTTPS Access Notes:**
- Accessible from any device on Tailscale network
- Requires Pi-hole as Tailscale DNS (already configured)
- Uses self-signed certificates (trust Caddy's CA for no warnings)
- **Pi-hole requires UFW rule**: `sudo ufw allow from 172.18.0.0/16 to any port 8080 proto tcp` (allows Caddy proxy network to access Pi-hole's host port)
- See `system/caddy/QUICKSTART.md` for setup

## Common Commands

**Start all services:**
```bash
./scripts/start-all-services.sh
```

**Note:** pgAdmin is excluded from automatic startup. Start manually when needed:
```bash
cd core/postgres && docker compose up -d pgadmin
```

**Stop pgAdmin:**
```bash
cd core/postgres && docker compose stop pgadmin
```

**Caddy (HTTPS Reverse Proxy):**
```bash
# Start Caddy
cd system/caddy && docker compose up -d

# Stop Caddy
cd system/caddy && docker compose down

# View logs
cd system/caddy && docker compose logs -f

# Reload configuration (without downtime)
cd system/caddy && docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# Integrate existing services with Caddy
./scripts/integrate-caddy.sh
```

**Manual service management:**
```bash
cd <service-directory>
docker compose up -d      # Start
docker compose logs -f    # View logs
docker compose restart    # Restart
docker compose down       # Stop
```

**Debugging:**
```bash
docker ps                                    # Check running containers
docker compose logs <service>                # View specific service logs
docker network ls                            # List networks
docker exec -it postgres psql -U <user>      # Access database
```

## Immich Backup & Restore

**CRITICAL: All backup/restore commands run ON THE SERVER, not locally**

**Quick Reference:**
```bash
# 1. SSH to server
ssh username@homelab-01

# 2. Verify prerequisites
docker ps | grep postgres  # Postgres MUST be running
mountpoint /mnt/backup     # If not mounted: sudo mount /dev/sdc1 /mnt/backup

# 3. Run backup
cd ~/github/homelab-01/scripts
./backup-immich.sh  # Immich DOWN for 10-30 min (2-4 hours first time)
```

**Current Data Size:** 163GB actual (not 500GB as originally estimated)

**What Gets Backed Up:**
- Upload directory: `/home/username/immich` (163GB photos/videos on failing HDD)
- Postgres database: `immich` database with all metadata
- Docker volumes: ML model cache and Redis data
- Auto-cleanup: Keeps last 3 backups only

**Backup Duration:**
- **First backup:** 2-4 hours (copies all 163GB)
- **Incremental:** 10-30 minutes (only changed files)
- **Immich is INACCESSIBLE during entire backup**

**Restore:**
```bash
ssh username@homelab-01
cd ~/github/homelab-01/scripts
./restore-immich.sh  # Interactive - select backup to restore
```

**Backup Location:** `/mnt/backup/immich-backup/` (916GB external HDD, manually mounted)
```
/mnt/backup/immich-backup/
├── 20260202_143000/  # Timestamped backups
│   ├── uploads/ (163GB)
│   ├── database/immich_backup.sql.gz
│   ├── volumes/
│   └── backup-manifest.txt
└── backup.log
```

**Automation Status:** NOT configured (manual backups only)

**Detailed Guide:** `scripts/IMMICH_BACKUP_README.md`

## Key Configuration

**Environment Files (.env):**
- `postgres/.env`: POSTGRES_ADMIN_USER, POSTGRES_ADMIN_PASSWORD
- `gitea/.env`: Database credentials
- `immich/.env`: IMMICH_DB_NAME, IMMICH_DB_USER, IMMICH_DB_PASSWORD
- `pi-hole/.env`: WEBPASSWORD
- `monitoring/.env`: GRAFANA_ADMIN_PASSWORD

**Data Storage (on homelab server):**
- Postgres: `/home/username/github/homelab-01/core/postgres/data`
- Immich uploads: `/home/username/immich` (163GB on 500GB HDD - **64 bad sectors!**)
- Immich thumbnails: `/home/username/immich-thumbs` (SSD - configured, not yet applied)
- Gitea: Docker volumes (managed by Docker)
- Backup drive: `/mnt/backup` (916GB external HDD - manually mounted)

## Development Guidelines

1. Always read existing config before editing
2. Keep services modular in their directories
3. Never commit `.env` files
4. Respect service dependencies (Postgres first)
5. Update relevant README when changing services

## Container Name Mapping (Grafana)

The monitoring stack uses a textfile collector approach for container names:
- Script: `system/monitoring/scripts/export-container-names.sh`
- Runs via cron every minute to update container ID → name mappings
- Exposed as `container_name_info` metric via Node Exporter
- Grafana dashboards join this with container metrics for proper names
- **Important**: Uses cAdvisor v0.47.2 (compatible with Docker API 1.41)

**Verify it's working:**
```bash
curl http://localhost:9100/metrics | grep container_name_info
```

**How the join works:**
```promql
container_memory_usage_bytes{id=~"/system.slice/docker-.*"}
  * on(container_id) group_left(container_name) container_name_info
```

## Quick Troubleshooting

**Service won't start:**
```bash
docker ps | grep postgres              # Check Postgres running
docker compose logs                    # Check error messages
docker network ls | grep db-net        # Verify network exists
```

**Database issues:**
```bash
docker exec postgres pg_isready -U <admin-user>    # Check Postgres health
docker exec -it postgres psql -U <admin-user> -l   # List databases
```

**Fix Immich permissions (on server):**
```bash
# Run on server
ssh username@homelab-01

# Fix permissions (1000:1000 is the Immich container user)
sudo chown -R 1000:1000 /home/username/immich
sudo chown -R 1000:1000 /home/username/immich-thumbs  # If using SSD thumbnails
```
**When to use:** After restore, manual file operations, or permission denied errors

**Container names showing as hashes in Grafana:**
```bash
# Check if export script is running
cat /tmp/export-container-names.log
# Manually run the export script
cd ~/github/homelab-01/system/monitoring/scripts && ./export-container-names.sh
```
