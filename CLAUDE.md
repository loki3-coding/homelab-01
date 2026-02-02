# CLAUDE.md - Homelab-01 Quick Reference

## Server Access

**Important Context:**
- **Claude Code** runs on the LOCAL machine (`/Users/standard-xvy/Github/homelab-01`)
- **Docker containers** run on the REMOTE homelab server
- Most operations require SSH to the server

**SSH to Homelab Server:**
```bash
# From anywhere (Tailscale VPN - recommended for Claude sessions)
ssh loki3@homelab-01

# From local network only
ssh loki3@homeLAN-01
```

**For Claude Code Sessions:**
- Use: `ssh loki3@homelab-01` (works locally and remotely via Tailscale)
- SSH keys configured for passwordless authentication
- Execute remote commands: `ssh loki3@homelab-01 "cd ~/github/homelab-01 && docker ps"`
- Git operations work over SSH

## Project Structure

**Local Repository** (`/Users/standard-xvy/Github/homelab-01`):
```
homelab-01/
├── platform/          # Postgres, Gitea + their .env files
├── apps/              # Homepage, Immich, Pi-hole + their .env files
│   └── immich/        # Includes SSD_THUMBNAILS_SETUP.md
├── system/            # Nginx, Monitoring (Prometheus/Grafana/Loki)
│   └── monitoring/scripts/  # Container name export script
├── scripts/           # Automation scripts + IMMICH_BACKUP_README.md
└── CLAUDE.md          # This file (main reference)
```

**Server Data Paths** (`loki3@homelab-01`):
- Repository clone: `~/github/homelab-01/`
- Immich uploads: `/home/loki3/immich` (163GB on 500GB HDD - **has 64 bad sectors!**)
- Immich thumbnails: `/home/loki3/immich-thumbs` (SSD - configured but not yet applied)
- Backup drive: `/mnt/backup` (916GB external HDD - manually mounted)

## Service Architecture

**Critical Dependencies:**
- Postgres MUST start before Gitea and Immich
- Services use `db-net` network for database connections
- Nginx uses `proxy` network for reverse proxy

| Service | Container | Ports | Dependencies | Access |
|---------|-----------|-------|--------------|--------|
| Postgres | postgres | Internal | None | Auto-start |
| PgAdmin | pgadmin | 5050 | postgres | Manual start - http://localhost:5050 |
| Gitea | gitea | 3000, 2222 | postgres | Via nginx proxy |
| Immich | immich-server | 2283 | postgres, redis | http://localhost:2283 |
| Homepage | homepage | 3000 | None | http://homelab-01/ |
| Pi-hole | pihole | 53, 8080 | None | http://localhost:8080/admin |
| Nginx | nginx-proxy | 80 | None | - |
| Prometheus | prometheus | 9091 | None | http://localhost:9091 |
| Grafana | grafana | 3002 | prometheus, loki | http://localhost:3002 |

## Common Commands

**Start all services:**
```bash
./scripts/start-all-services.sh
```

**Note:** pgAdmin is excluded from automatic startup. Start manually when needed:
```bash
cd platform/postgres && docker compose up -d pgadmin
```

**Stop pgAdmin:**
```bash
cd platform/postgres && docker compose stop pgadmin
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

⚠️ **CRITICAL: All backup/restore commands run ON THE SERVER, not locally**

**Quick Reference:**
```bash
# 1. SSH to server
ssh loki3@homelab-01

# 2. Verify prerequisites
docker ps | grep postgres  # Postgres MUST be running
mountpoint /mnt/backup     # If not mounted: sudo mount /dev/sdc1 /mnt/backup

# 3. Run backup
cd ~/github/homelab-01/scripts
./backup-immich.sh  # ⚠️ Immich DOWN for 10-30 min (2-4 hours first time)
```

**Current Data Size:** 163GB actual (not 500GB as originally estimated)

**What Gets Backed Up:**
- Upload directory: `/home/loki3/immich` (163GB photos/videos on failing HDD)
- Postgres database: `immich` database with all metadata
- Docker volumes: ML model cache and Redis data
- Auto-cleanup: Keeps last 3 backups only

**Backup Duration:**
- **First backup:** 2-4 hours (copies all 163GB)
- **Incremental:** 10-30 minutes (only changed files)
- ⚠️ **Immich is INACCESSIBLE during entire backup**

**Restore:**
```bash
ssh loki3@homelab-01
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

**Automation Status:** ❌ NOT configured (manual backups only)

**Detailed Guide:** `scripts/IMMICH_BACKUP_README.md`

## Key Configuration

**Environment Files (.env):**
- `postgres/.env`: POSTGRES_ADMIN_USER, POSTGRES_ADMIN_PASSWORD
- `gitea/.env`: Database credentials
- `immich/.env`: IMMICH_DB_NAME, IMMICH_DB_USER, IMMICH_DB_PASSWORD
- `pi-hole/.env`: WEBPASSWORD
- `monitoring/.env`: GRAFANA_ADMIN_PASSWORD

**Data Storage (on homelab server):**
- Postgres: `/home/loki3/github/homelab-01/platform/postgres/data`
- Immich uploads: `/home/loki3/immich` (163GB on 500GB HDD - ⚠️ **64 bad sectors!**)
- Immich thumbnails: `/home/loki3/immich-thumbs` (SSD - configured, not yet applied)
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
ssh loki3@homelab-01

# Fix permissions (1000:1000 is the Immich container user)
sudo chown -R 1000:1000 /home/loki3/immich
sudo chown -R 1000:1000 /home/loki3/immich-thumbs  # If using SSD thumbnails
```
**When to use:** After restore, manual file operations, or permission denied errors

**Container names showing as hashes in Grafana:**
```bash
# Check if export script is running
cat /tmp/export-container-names.log
# Manually run the export script
cd ~/github/homelab-01/system/monitoring/scripts && ./export-container-names.sh
```
