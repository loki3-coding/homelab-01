# Immich - Photo & Video Management

Self-hosted photo and video backup solution with automatic organization, facial recognition, and mobile apps.

** Access:** [http://homelab-01:2283](http://homelab-01:2283) or [http://localhost:2283](http://localhost:2283)

---

##  Documentation Navigation

- **[← Back to Main README](../../README.md)**
- **[ Quick Reference (CLAUDE.md)](../../CLAUDE.md#immich-backup--restore)** - Common Immich commands
- **[ Backup Guide](IMMICH_BACKUP_README.md)** - Complete backup/restore procedures
- **[ SSD Setup Guide](SSD_THUMBNAILS_SETUP.md)** - Move thumbnails to SSD (performance fix)

---

##  Immich Folder Structure

### Current Storage Layout

```
Server: username@homelab-01

 Immich Data (500GB HDD /dev/sdb -  64 bad sectors!)
/home/username/immich/                     [163GB total]
├── library/                            # User uploads
│   └── [user-id]/
│       ├── 2024/                       # Organized by year
│       │   ├── 01/                     # Then by month
│       │   │   └── IMG_1234.jpg        # Original photos
│       │   └── 02/
│       └── 2025/
├── upload/                             # Temporary upload staging
├── profile/                            # User profile pictures
└── thumbs/                             #  Will be moved to SSD
    ├── [asset-id]/
    │   ├── preview.webp                # Preview thumbnails
    │   └── thumbnail.webp              # Small thumbnails
    └── encoded-video/                  # Transcoded videos

 Immich Thumbnails (SSD /dev/sda - FAST, NO BAD SECTORS)
/home/username/immich-thumbs/              [~20-30GB estimated]
├── [asset-id]/                         # Thumbnail cache
│   ├── preview.webp                    # Fast loading previews
│   └── thumbnail.webp                  # Grid view thumbnails
└── encoded-video/                      # Transcoded video cache

🗄 Docker Volumes (Managed by Docker)
immich-model-cache                      # ML models (face recognition)
immich-redis-data                       # Cache and job queue

🗃 Database (Postgres)
Database: immich                        # All metadata
├── users, albums, sharing              # User data
├── assets metadata                     # EXIF, dates, locations
├── face recognition data               # ML results
└── search indexes                      # Smart search
```

### Why This Layout?

| Location | Storage | Speed | Purpose | Notes |
|----------|---------|-------|---------|-------|
| `/home/username/immich` | 500GB HDD | Slow | Original uploads | **64 bad sectors** causing corruption |
| `/home/username/immich-thumbs` | 128GB SSD |**Fast** | Thumbnails & videos |  Eliminates thumbnail bugs |
| Docker volumes | SSD | Fast | ML models, cache | Managed automatically |
| Postgres DB | SSD | Fast | Metadata | Lives with other DBs |

**Current Status:**
- Uploads on HDD (163GB used)
- Thumbnails still on HDD (configured to move to SSD, not yet applied)
- HDD has bad sectors causing thumbnail corruption

---

##  Quick Start

### Start Immich

```bash
# SSH to server
ssh username@homelab-01

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

##  Configuration

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
| `/usr/src/app/upload` | `/home/username/immich` | Original uploads |
| `/usr/src/app/upload/thumbs` | `/home/username/immich-thumbs` | Thumbnails (SSD) |
| `/usr/src/app/upload/encoded-video` | `/home/username/immich-thumbs/encoded-video` | Videos (SSD) |

---

##  Monitoring

### Check Storage Usage

```bash
# Immich uploads (HDD)
du -sh /home/username/immich

# Immich thumbnails (SSD)
du -sh /home/username/immich-thumbs

# Breakdown by folder
du -h --max-depth=1 /home/username/immich | sort -h
```

### Check HDD Health

```bash
sudo smartctl -H /dev/sdb              # Quick health check (use /dev/sdc if device name changed)
sudo smartctl -a /dev/sdb | grep -E "(Reallocated|Pending)"  # Bad sectors
```

---

## ⚠️ Troubleshooting

### Images Not Loading / "Failed to Download" Errors

**Symptoms:**
- Immich web interface shows images but they won't open
- "Failed to download original image" errors
- Thumbnails work but full images don't load
- Mobile app can't download photos

**Cause:**
The Immich data drive is not mounted at `/home/loki3/immich`. This can happen when:
- Server reboots and automount fails
- USB drive is unplugged/replugged
- Device names change (the HDD device name changed from `/dev/sdb` to `/dev/sdc`)

**Quick Fix:**

1. **Check if drive is mounted:**
   ```bash
   df -h | grep immich
   mountpoint /home/loki3/immich
   ```
   If you see "is not a mountpoint", the drive isn't mounted.

2. **Mount the drive:**
   ```bash
   sudo mount /home/loki3/immich
   ```
   This uses the `/etc/fstab` entry which is already configured with the UUID.

3. **Verify data is accessible:**
   ```bash
   ls /home/loki3/immich
   ```
   You should see: `library/`, `upload/`, `profile/`, `thumbs/`

4. **Restart Immich:**
   ```bash
   cd ~/github/homelab-01/apps/immich
   docker compose restart
   ```

5. **Check logs for errors:**
   ```bash
   docker compose logs -f immich-server
   ```

**Prevention:**
The drive is configured in `/etc/fstab` with UUID (not device name) and `x-systemd.automount`, so it should automount on boot. If this issue persists, check systemd mount status:
```bash
systemctl status home-loki3-immich.automount
```

**Note:** The data drive is labeled `IMMICH_DATA` with UUID `66bb0d49-4ffa-4dbe-9ddc-a25cdb9e3b7d`. Device names like `/dev/sdb` or `/dev/sdc` can change, but the UUID stays constant.

---

##  Related Documentation

- **[Main README](../../README.md)** - Project overview
- **[CLAUDE.md](../../CLAUDE.md)** - Quick reference for all services
- **[Backup Guide](IMMICH_BACKUP_README.md)** - Detailed backup procedures
- **[SSD Setup](SSD_THUMBNAILS_SETUP.md)** - Move thumbnails to SSD
- **[Scripts README](../../scripts/README.md)** - All automation scripts
