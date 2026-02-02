# Scripts - Automation & Management

Collection of automation scripts for backup, service management, and system maintenance.

---

## 📚 Documentation Navigation

- **[← Back to Main README](../README.md)**
- **[📖 CLAUDE.md](../CLAUDE.md)** - Quick reference
- **[📦 Immich Guide](../apps/immich/README.md)** - Immich documentation

---

## 📜 Available Scripts

### Service Management

#### `start-all-services.sh`
Starts all homelab services in correct dependency order.

**Usage:**
```bash
ssh loki3@homelab-01
cd ~/github/homelab-01
./scripts/start-all-services.sh
```

**What it does:**
1. Checks Docker is running
2. Creates required networks
3. Starts Postgres first
4. Waits for Postgres health check
5. Starts dependent services (Gitea, Immich)
6. Starts remaining services

**Note:** pgAdmin is excluded from automatic startup. Start manually when needed.

#### `stop-all-services.sh`
Stops all homelab services gracefully.

**Usage:**
```bash
ssh loki3@homelab-01
cd ~/github/homelab-01
./scripts/stop-all-services.sh
```

---

### Immich Backup & Restore

#### `backup-immich.sh`
Creates complete backup of Immich data to external HDD.

**Usage:**
```bash
ssh loki3@homelab-01
sudo mount /dev/sdc1 /mnt/backup
cd ~/github/homelab-01/scripts
./backup-immich.sh
```

**What gets backed up:**
- All photos and videos (163GB)
- Postgres database with metadata
- Docker volumes (ML models, Redis)

**Duration:** 2-4 hours first time, 10-30 min incremental

⚠️ **Immich is DOWN during backup**

📖 **[Complete Backup Guide](IMMICH_BACKUP_README.md)**

#### `restore-immich.sh`
Restores Immich from backup (interactive).

**Usage:**
```bash
ssh loki3@homelab-01
cd ~/github/homelab-01/scripts
./restore-immich.sh
```

**Interactive process:**
1. Lists available backups
2. Shows backup manifest
3. Confirms destructive operation
4. Restores all data
5. Restarts services

⚠️ **This OVERWRITES all current Immich data!**

📖 **[Complete Backup Guide](IMMICH_BACKUP_README.md)**

---

## 🔧 Script Details

### Backup System

**Storage:**
- Backup location: `/mnt/backup/immich-backup/`
- Drive: 916GB external HDD (`/dev/sdc1`)
- Retention: Keeps last 3 backups automatically

**Backup Contents:**
```
/mnt/backup/immich-backup/
├── 20260202_143000/          # Timestamped backup
│   ├── uploads/              # 163GB photos/videos
│   ├── database/
│   │   └── immich_backup.sql.gz
│   ├── volumes/
│   │   ├── immich-model-cache.tar.gz
│   │   └── immich-redis-data.tar.gz
│   └── backup-manifest.txt   # Checksums and metadata
└── backup.log                # All operations
```

**Prerequisites:**
- Postgres must be running
- Backup drive must be mounted
- Sufficient disk space (170GB+ for full backup)

### Service Startup

**Dependency Order:**
1. Docker networks (db-net, proxy)
2. Postgres (wait for health check)
3. Dependent services (Gitea, Immich)
4. Independent services (Nginx, Pi-hole, Homepage, Monitoring)

**Excluded from Auto-start:**
- pgAdmin (manual start when needed)

**Health Checks:**
- Postgres: Waits for ready state
- Other services: Best effort start

---

## 📖 Related Documentation

### Backup & Restore
- **[IMMICH_BACKUP_README.md](IMMICH_BACKUP_README.md)** - Complete backup/restore guide
  - Prerequisites
  - Step-by-step procedures
  - Monitoring and troubleshooting
  - Automated backups setup

### Immich
- **[apps/immich/README.md](../apps/immich/README.md)** - Immich operations
- **[apps/immich/SSD_THUMBNAILS_SETUP.md](../apps/immich/SSD_THUMBNAILS_SETUP.md)** - SSD migration

### System
- **[CLAUDE.md](../CLAUDE.md)** - Quick reference for all operations
- **[README.md](../README.md)** - Main project overview

---

## 🆘 Troubleshooting

### Backup Issues

**Backup drive not mounted:**
```bash
ssh loki3@homelab-01
sudo mount /dev/sdc1 /mnt/backup
df -h /mnt/backup  # Verify
```

**Postgres not running:**
```bash
docker ps | grep postgres
# If not running:
cd ~/github/homelab-01
./scripts/start-all-services.sh
```

**Permission errors:**
```bash
sudo chown -R loki3:loki3 /mnt/backup/immich-backup
```

### Service Startup Issues

**Docker not running:**
```bash
sudo systemctl status docker
sudo systemctl start docker
```

**Network creation fails:**
```bash
docker network ls
docker network create db-net
docker network create proxy
```

**Service fails to start:**
```bash
cd ~/github/homelab-01/apps/[service]
docker compose logs
```

---

## 💡 Tips

### Monitoring Backups

```bash
# Watch backup progress
ssh loki3@homelab-01
tail -f /mnt/backup/immich-backup/backup.log

# Check backup sizes
du -sh /mnt/backup/immich-backup/*

# Verify latest backup
cat /mnt/backup/immich-backup/$(ls -t /mnt/backup/immich-backup/ | head -1)/backup-manifest.txt
```

### Running Scripts Remotely

```bash
# From local machine, run backup remotely
ssh loki3@homelab-01 "cd ~/github/homelab-01/scripts && ./backup-immich.sh"

# Start all services remotely
ssh loki3@homelab-01 "cd ~/github/homelab-01 && ./scripts/start-all-services.sh"
```

### Automated Backups

Not yet configured. See [IMMICH_BACKUP_README.md](IMMICH_BACKUP_README.md#automated-backups-optional---not-yet-configured) for setup instructions.

---

## 📝 Adding New Scripts

When adding new scripts:

1. Make executable: `chmod +x script-name.sh`
2. Add shebang: `#!/bin/bash`
3. Include error handling: `set -e`
4. Add logging for important operations
5. Document in this README
6. Test on homelab server first

Example template:
```bash
#!/bin/bash
set -e  # Exit on error

# Script description
# Usage: ./script-name.sh

# Add your script logic here
echo "Script starting..."
```

---

**Questions?** See [CLAUDE.md](../CLAUDE.md) or open an issue.
