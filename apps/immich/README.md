# Immich - Self-hosted Photo & Video Management

This Docker Compose setup runs Immich connected to the shared PostgreSQL database.

## Prerequisites

1. **PostgreSQL with pgvecto.rs extension**: The postgres container must use `tensorchord/pgvecto-rs:pg16-v0.2.1` image (already updated in `../postgres/docker-compose.yml`)

2. **Create Immich database and user**: Connect to PostgreSQL and run the init script:
   ```bash
   docker exec -i postgres psql -U $POSTGRES_ADMIN_USER < init-db.sql
   ```
   Or manually copy/paste the contents of `init-db.sql` into psql.

3. **Create upload directory on HDD**:
   ```bash
   sudo mkdir -p /home/loki3/immich
   sudo chown -R 1000:1000 /home/loki3/immich
   ```

## Configuration

Create a `.env` file in this directory:

```bash
# Immich Database Configuration
IMMICH_DB_NAME=immich
IMMICH_DB_USER=immich
IMMICH_DB_PASSWORD=your_secure_password_here
```

## Starting the Services

1. First, ensure PostgreSQL is running:
   ```bash
   cd ../../platform/postgres
   docker compose up -d
   ```

2. Start Immich:
   ```bash
   cd ../../apps/immich
   docker compose up -d
   ```

## Access

- **Web Interface**: http://localhost:2283
- First-time setup will prompt you to create an admin account

## Storage

- **Upload directory**: `/home/loki3/immich` (HDD mount)
- **ML model cache**: Docker volume `immich-model-cache`
- **Redis data**: Docker volume `immich-redis-data`

## Network Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  immich-server  │────▶│    postgres     │
│   (db-net)      │     │   (db-net)      │
└────────┬────────┘     └─────────────────┘
         │
    ┌────▼────┐
    │  redis  │
    │(immich) │
    └────┬────┘
         │
┌────────▼────────┐
│ machine-learning│
│   (immich-net)  │
└─────────────────┘
```

## Troubleshooting

### Database connection issues
- Ensure the `db-net` network exists: `docker network ls | grep db-net`
- Verify postgres container is running: `docker ps | grep postgres`

### Permission issues with uploads
- Check ownership: `ls -la /home/loki3/immich`
- Fix permissions: `sudo chown -R 1000:1000 /home/loki3/immich`

