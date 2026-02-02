# Immich Backup & Restore Guide

⚠️ **IMPORTANT: All commands in this document must be run on the homelab server, not your local machine.**

## Quick Start

```bash
# 1. SSH to the server
ssh loki3@homelab-01

# 2. Mount backup drive
sudo mount /dev/sdc1 /mnt/backup

# 3. Run backup
cd ~/github/homelab-01-01/scripts
./backup-immich.sh
```

## Overview

These scripts provide a complete backup and restore solution for your Immich photo management system.

**Critical Information:**
- Immich will be **INACCESSIBLE** during backup (2-4 hours first time, 10-30 min incremental)
- All commands run on **homelab server** (`ssh loki3@homelab-01`), not locally
- Postgres must be running before backup/restore

### What Gets Backed Up

1. **Upload Directory** (`/home/loki3/immich`)
   - All your photos, videos, and assets
   - Approximately 500GB on old HDD

2. **Postgres Database** (`immich` database)
   - User accounts, albums, metadata
   - Sharing settings, tags, and search data

3. **Docker Volumes**
   - Machine learning model cache
   - Redis data

## Prerequisites

**Before running backup or restore, verify these on the server:**

```bash
# SSH to server
ssh loki3@homelab-01

# 1. Check Postgres is running (REQUIRED for backup/restore)
docker ps | grep postgres
# Should show: postgres container running

# 2. Check Immich status
docker ps | grep immich
# Shows if Immich is running (will be stopped during backup)

# 3. Check/mount backup drive
mountpoint /mnt/backup
# If NOT mounted, mount it:
sudo mount /dev/sdc1 /mnt/backup

# 4. Verify backup drive space
df -h /mnt/backup
# Should show: 916G total with sufficient free space

# 5. Make scripts executable (one-time setup)
chmod +x ~/github/homelab-01/scripts/backup-immich.sh
chmod +x ~/github/homelab-01/scripts/restore-immich.sh
```

**If Postgres is NOT running:**
```bash
cd ~/github/homelab-01
./scripts/start-all-services.sh
# Wait 30 seconds for Postgres to start
docker ps | grep postgres
```

## Backup Process

### Run Backup (on server)

```bash
# Make sure you're on the server
ssh loki3@homelab-01

cd ~/github/homelab-01/scripts
./backup-immich.sh
```

### What Happens During Backup

1. ✓ Checks if backup drive is mounted
2. ✓ Creates timestamped backup directory
3. ⚠️ **Stops Immich services** (Immich becomes INACCESSIBLE)
4. ✓ Backs up uploads directory using rsync (THIS IS THE SLOW STEP)
5. ✓ Exports and compresses database
6. ✓ Backs up Docker volumes
7. ✓ **Restarts Immich services** (Immich becomes accessible again)
8. ✓ Creates backup manifest with checksums
9. ✓ Keeps only last 3 backups (auto-cleanup)

### Backup Duration

**Current data size: ~163GB**

| Backup Type | Duration | Notes |
|-------------|----------|-------|
| **First backup** | 2-4 hours | Copies all 163GB |
| **Incremental** | 10-30 minutes | Only changed files |
| **Database only** | 1-2 minutes | ~few hundred MB |

⚠️ **Immich is DOWN during the entire backup process**

### Monitor Progress

```bash
# In another terminal, watch the backup
ssh loki3@homelab-01

# Watch log file
tail -f /mnt/backup/immich-backup/backup.log

# Watch backup size grow
watch -n 5 "du -sh /mnt/backup/immich-backup/$(ls -t /mnt/backup/immich-backup/ | head -1)"
```

### Backup Structure

```
/mnt/backup/immich-backup/
├── 20260202_143000/              # Timestamped backup
│   ├── uploads/                  # All photos/videos
│   ├── database/
│   │   └── immich_backup.sql.gz  # Compressed database
│   ├── volumes/
│   │   ├── immich-model-cache.tar.gz
│   │   └── immich-redis-data.tar.gz
│   └── backup-manifest.txt       # Backup details & checksums
└── backup.log                    # All backup operations log
```

### Automated Backups (Optional - NOT YET CONFIGURED)

**⚠️ WARNINGS before automating:**
- Immich will be DOWN during backup (10-30 min for incremental, 2-4 hours if full)
- Choose a time when photo uploads are unlikely
- Backup drive must be auto-mounted (not currently configured)
- Script does not check if previous backup is running

**To schedule weekly backups:**

```bash
# On the server
ssh loki3@homelab-01
crontab -e
```

Add this line for Sunday 2 AM backups:
```cron
0 2 * * 0 /home/loki3/github/homelab-01/scripts/backup-immich.sh
```

**To auto-mount backup drive on boot, add to `/etc/fstab`:**
```
/dev/sdc1  /mnt/backup  ext4  defaults  0  2
```

## Restore Process

### Prerequisites for Restore

**Before running restore, verify these on the server:**

```bash
# SSH to server
ssh loki3@homelab-01

# 1. Check Postgres is running (REQUIRED)
docker ps | grep postgres
# If not running: cd ~/github/homelab-01 && ./scripts/start-all-services.sh

# 2. Verify backup drive is mounted
mountpoint /mnt/backup
# If not: sudo mount /dev/sdc1 /mnt/backup

# 3. List available backups
ls -lh /mnt/backup/immich-backup/
```

### Run Restore (Interactive - on server)

```bash
# Make sure you're on the server
ssh loki3@homelab-01

cd ~/github/homelab-01/scripts
./restore-immich.sh
# This is INTERACTIVE - you'll be prompted to select a backup
```

### What Happens During Restore

1. Lists available backups with timestamps
2. **You select which backup to restore** (interactive prompt)
3. Shows backup manifest for review
4. **Asks for confirmation - type 'yes'** (destructive operation!)
5. Stops Immich services
6. Backs up current data to `/home/loki3/immich.old`
7. Restores uploads, database, and volumes
8. Restarts Immich services

⏱️ **Duration:** 30 minutes to 2 hours depending on backup size

### Restore Warning

⚠️ **CRITICAL**: Restore will **OVERWRITE** all current Immich data!

- Your existing data is backed up to `/home/loki3/immich.old` before restore
- The restore process cannot be undone (except by restoring another backup)
- Database will be dropped and recreated
- All current photos/albums/users will be replaced with backup data

## Maintenance

**All maintenance commands run on the server:**

### Check Backup Drive Space

```bash
ssh loki3@homelab-01 "df -h /mnt/backup"
```

### View Backup Log

```bash
ssh loki3@homelab-01 "tail -f /mnt/backup/immich-backup/backup.log"
```

### List All Backups

```bash
ssh loki3@homelab-01 "ls -lh /mnt/backup/immich-backup/"
```

### Verify Backup Integrity

Check the manifest file:
```bash
cat /mnt/backup/immich-backup/[timestamp]/backup-manifest.txt
```

### Manual Cleanup

To remove specific old backups:
```bash
rm -rf /mnt/backup/immich-backup/[timestamp]
```

## Troubleshooting

### Backup Drive Not Mounted

**Error**: "Backup drive is not mounted at /mnt/backup"

**Solution**:
```bash
sudo mount /dev/sdc1 /mnt/backup
```

### Permission Errors

If you get permission errors on restore or Immich can't read uploaded files:

```bash
# On the server
ssh loki3@homelab-01

# Fix permissions (1000:1000 is the Immich container user)
sudo chown -R 1000:1000 /home/loki3/immich
sudo chown -R 1000:1000 /home/loki3/immich-thumbs  # If using SSD thumbnails
```

**When to use:**
- After restore completes
- If Immich logs show "permission denied" errors
- After manually copying files to the upload directory
- After moving files between drives

### Immich Won't Start After Restore

1. Check logs:
   ```bash
   cd ~/github/homelab-01/apps/immich
   docker compose logs -f
   ```

2. Verify Postgres is running:
   ```bash
   docker ps | grep postgres
   ```

3. Restart services:
   ```bash
   cd ~/github/homelab-01/apps/immich
   docker compose restart
   ```

### Backup Takes Too Long

The first backup copies everything and may take hours. Subsequent backups use rsync and only copy changed files, which is much faster.

### Out of Space on Backup Drive

1. Check space: `df -h /mnt/backup`
2. Manually remove old backups (script keeps last 3 automatically)
3. Consider getting a larger backup drive

## Best Practices

1. **Regular Backups**: Run weekly or before major changes
2. **Test Restores**: Periodically test restore process to ensure backups work
3. **Multiple Locations**: Consider backing up to cloud storage as well
4. **Monitor Space**: Keep an eye on both source and backup drive space
5. **Verify Backups**: Check the manifest file after each backup

## Quick Reference

### Essential Commands

```bash
# Mount backup drive
sudo mount /dev/sdc1 /mnt/backup

# Run backup
~/github/homelab-01/scripts/backup-immich.sh

# Run restore
~/github/homelab-01/scripts/restore-immich.sh

# Check backup size
du -sh /mnt/backup/immich-backup/*

# Unmount backup drive (when done)
sudo umount /mnt/backup
```

## Need Help?

- Check logs: `/mnt/backup/immich-backup/backup.log`
- Immich logs: `docker compose logs -f` (from apps/immich directory)
- See main homelab docs: `~/github/homelab-01/CLAUDE.md`
