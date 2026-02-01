# CLAUDE.md - Homelab-01 Quick Reference

## Server Access
All Docker containers run on the homelab server.

**SSH Access:**
- Local LAN: `ssh loki3@homeLAN-01`
- Remote (Tailscale): `ssh loki3@homelab-01`

## Project Structure
```
homelab-01/
├── platform/          # Postgres, Gitea
├── apps/              # Homepage, Immich, Pi-hole
├── system/            # Nginx, Monitoring (Prometheus/Grafana/Loki)
├── scripts/           # Automation scripts
└── docs/              # Documentation
```

## Service Architecture

**Critical Dependencies:**
- Postgres MUST start before Gitea and Immich
- Services use `db-net` network for database connections
- Nginx uses `proxy` network for reverse proxy

| Service | Container | Ports | Dependencies | Access |
|---------|-----------|-------|--------------|--------|
| Postgres | postgres | Internal | None | - |
| PgAdmin | pgadmin | 5050 | postgres | http://localhost:5050 |
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

## Key Configuration

**Environment Files (.env):**
- `postgres/.env`: POSTGRES_ADMIN_USER, POSTGRES_ADMIN_PASSWORD
- `gitea/.env`: Database credentials
- `immich/.env`: IMMICH_DB_NAME, IMMICH_DB_USER, IMMICH_DB_PASSWORD
- `pi-hole/.env`: WEBPASSWORD
- `monitoring/.env`: GRAFANA_ADMIN_PASSWORD

**Data Storage:**
- Postgres: `./platform/postgres/data`
- Immich uploads: `/home/loki3/immich` (500GB HDD)
- Gitea: Docker volumes

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

**Verify it's working:**
```bash
curl http://localhost:9100/metrics | grep container_name_info
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

**Fix Immich permissions:**
```bash
sudo chown -R 1000:1000 /home/loki3/immich
```

**Container names showing as hashes in Grafana:**
```bash
# Check if export script is running
cat /tmp/export-container-names.log
# Manually run the export script
cd ~/github/homelab/system/monitoring/scripts && ./export-container-names.sh
```
