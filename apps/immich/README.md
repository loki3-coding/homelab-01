# Immich - Photo & Video Management

Self-hosted photo and video backup solution with automatic organization, facial recognition, and mobile apps.

**📱 Access:** [http://homelab-01:2283](http://homelab-01:2283) or [http://localhost:2283](http://localhost:2283)

---

## 📚 Documentation Navigation

- **[← Back to Main README](../../README.md)**
- **[📖 Quick Reference (CLAUDE.md)](../../CLAUDE.md#immich-backup--restore)** - Common Immich commands
- **[💾 Backup Guide](../../scripts/IMMICH_BACKUP_README.md)** - Complete backup/restore procedures
- **[🚀 SSD Setup Guide](SSD_THUMBNAILS_SETUP.md)** - Move thumbnails to SSD (performance fix)

---

## 📁 Immich Folder Structure

### Current Storage Layout

```
Server: loki3@homelab-01

📦 Immich Data (500GB HDD /dev/sdb - ⚠️ 64 bad sectors!)
/home/loki3/immich/                     [163GB total]
├── library/                            # User uploads
│   └── [user-id]/
│       ├── 2024/                       # Organized by year
│       │   ├── 01/                     # Then by month
│       │   │   └── IMG_1234.jpg        # Original photos
│       │   └── 02/
│       └── 2025/
├── upload/                             # Temporary upload staging
├── profile/                            # User profile pictures
└── thumbs/                             # ⚠️ Will be moved to SSD
    ├── [asset-id]/
    │   ├── preview.webp                # Preview thumbnails
    │   └── thumbnail.webp              # Small thumbnails
    └── encoded-video/                  # Transcoded videos

💾 Immich Thumbnails (SSD /dev/sda - FAST, NO BAD SECTORS)
/home/loki3/immich-thumbs/              [~20-30GB estimated]
├── [asset-id]/                         # Thumbnail cache
│   ├── preview.webp                    # Fast loading previews
│   └── thumbnail.webp                  # Grid view thumbnails
└── encoded-video/                      # Transcoded video cache

🗄️ Docker Volumes (Managed by Docker)
immich-model-cache                      # ML models (face recognition)
immich-redis-data                       # Cache and job queue

🗃️ Database (Postgres)
Database: immich                        # All metadata
├── users, albums, sharing              # User data
├── assets metadata                     # EXIF, dates, locations
├── face recognition data               # ML results
└── search indexes                      # Smart search
```

### Why This Layout?

| Location | Storage | Speed | Purpose | Notes |
|----------|---------|-------|---------|-------|
| `/home/loki3/immich` | 500GB HDD | Slow | Original uploads | ⚠️ **64 bad sectors** causing corruption |
| `/home/loki3/immich-thumbs` | 128GB SSD | **Fast** | Thumbnails & videos | 🚀 Eliminates thumbnail bugs |
| Docker volumes | SSD | Fast | ML models, cache | Managed automatically |
| Postgres DB | SSD | Fast | Metadata | Lives with other DBs |

**Current Status:**
- ✅ Uploads on HDD (163GB used)
- ⚠️ Thumbnails still on HDD (configured to move to SSD, not yet applied)
- ⚠️ HDD has bad sectors causing thumbnail corruption

---

## 🚀 Quick Start

### Start Immich

```bash
# SSH to server
ssh loki3@homelab-01

# Start Immich (Postgres must be running first)
cd ~/github/homelab-01/apps/immich
docker compose up -d

# Check status
docker ps | grep immich
```

### View Logs

```bash
cd ~/github/homelab-01/apps/immich
docker compose logs -f
```

### Restart Immich

```bash
cd ~/github/homelab-01/apps/immich
docker compose restart
```

---

## 💾 Backup & Restore

**⚠️ IMPORTANT: Always backup before major changes!**

### Run Backup

```bash
# SSH to server
ssh loki3@homelab-01

# Mount backup drive
sudo mount /dev/sdc1 /mnt/backup

# Run backup (Immich will be DOWN for 10-30 min)
cd ~/github/homelab-01/scripts
./backup-immich.sh
```

**What gets backed up:**
- All photos and videos (163GB)
- Database with metadata, albums, users
- Docker volumes (ML models, cache)

**Duration:** First backup 2-4 hours, incremental 10-30 minutes

📖 **[Complete Backup Guide →](../../scripts/IMMICH_BACKUP_README.md)**

---

## 🔧 Common Issues & Solutions

### Thumbnail Corruption / Missing Thumbnails

**Problem:** Thumbnails show errors, need regeneration frequently
**Cause:** HDD has 64 bad sectors causing file corruption
**Solution:** Move thumbnails to SSD

```bash
# Check HDD health
ssh loki3@homelab-01
sudo smartctl -a /dev/sdb | grep -E "(Reallocated|Pending|Uncorrectable)"
```

🚀 **[SSD Thumbnail Setup Guide →](SSD_THUMBNAILS_SETUP.md)**

### Permission Errors

**Problem:** Can't upload photos, permission denied errors in logs
**Fix:**

```bash
ssh loki3@homelab-01
sudo chown -R 1000:1000 /home/loki3/immich
sudo chown -R 1000:1000 /home/loki3/immich-thumbs
```

### Immich Won't Start

```bash
# 1. Check Postgres is running (required!)
docker ps | grep postgres

# 2. If not running, start it
cd ~/github/homelab-01
./scripts/start-all-services.sh

# 3. Check Immich logs
cd ~/github/homelab-01/apps/immich
docker compose logs -f
```

### Out of Space

```bash
# Check HDD space
df -h /home/loki3/immich

# Check SSD space
df -h /

# Check backup drive
df -h /mnt/backup
```

---

## ⚙️ Configuration

### Environment Variables

Edit `.env` file:
```bash
IMMICH_DB_NAME=immich
IMMICH_DB_USER=postgres
IMMICH_DB_PASSWORD=changeit
```

### Docker Compose

**Services:**
- `immich-server` - Main application (port 2283)
- `immich-machine-learning` - Face recognition, object detection
- `immich-redis` - Cache and job queue

**Memory Limits:**
- Server: 2GB limit, 1GB reserved
- ML container: 4GB limit, 2GB reserved

### Storage Paths

| Container Path | Host Path | Purpose |
|----------------|-----------|---------|
| `/usr/src/app/upload` | `/home/loki3/immich` | Original uploads |
| `/usr/src/app/upload/thumbs` | `/home/loki3/immich-thumbs` | Thumbnails (SSD) |
| `/usr/src/app/upload/encoded-video` | `/home/loki3/immich-thumbs/encoded-video` | Videos (SSD) |

---

## 🔍 Monitoring

### Check Storage Usage

```bash
# Immich uploads (HDD)
du -sh /home/loki3/immich

# Immich thumbnails (SSD)
du -sh /home/loki3/immich-thumbs

# Breakdown by folder
du -h --max-depth=1 /home/loki3/immich | sort -h
```

### Check Container Health

```bash
docker ps | grep immich
docker stats --no-stream | grep immich
```

### Check HDD Health

```bash
sudo smartctl -H /dev/sdb              # Quick health check
sudo smartctl -a /dev/sdb | grep -E "(Reallocated|Pending)"  # Bad sectors
```

---

## 📖 Related Documentation

- **[Main README](../../README.md)** - Project overview
- **[CLAUDE.md](../../CLAUDE.md)** - Quick reference for all services
- **[Backup Guide](../../scripts/IMMICH_BACKUP_README.md)** - Detailed backup procedures
- **[SSD Setup](SSD_THUMBNAILS_SETUP.md)** - Move thumbnails to SSD
- **[Scripts README](../../scripts/README.md)** - All automation scripts

---

## 🆘 Need Help?

1. Check logs: `docker compose logs -f`
2. See [CLAUDE.md](../../CLAUDE.md) troubleshooting section
3. Review [Immich documentation](https://immich.app/docs)
4. Check [backup guide](../../scripts/IMMICH_BACKUP_README.md) for restore procedures

**Emergency:** Restore from backup using `~/github/homelab-01/scripts/restore-immich.sh`
