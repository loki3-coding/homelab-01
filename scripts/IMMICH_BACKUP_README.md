# Immich Backup & Restore Guide

## Overview

These scripts provide a complete backup and restore solution for your Immich photo management system.

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

### Mount the Backup Drive

Before running any backup/restore operations, mount your backup HDD:

```bash
sudo mount /dev/sdc1 /mnt/backup
```

To verify it's mounted:
```bash
mountpoint /mnt/backup
```

### Make Scripts Executable

```bash
chmod +x ~/github/homelab/scripts/backup-immich.sh
chmod +x ~/github/homelab/scripts/restore-immich.sh
```

## Backup Process

### Run Backup

```bash
cd ~/github/homelab/scripts
./backup-immich.sh
```

### What Happens During Backup

1. ✓ Checks if backup drive is mounted
2. ✓ Creates timestamped backup directory
3. ✓ Stops Immich services (for data consistency)
4. ✓ Backs up uploads directory using rsync
5. ✓ Exports and compresses database
6. ✓ Backs up Docker volumes
7. ✓ Restarts Immich services
8. ✓ Creates backup manifest with checksums
9. ✓ Keeps only last 3 backups (auto-cleanup)

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

### Backup Timing

**Initial backup**: May take several hours depending on data size
**Incremental backups**: Faster as rsync only copies changed files

### Automated Backups (Optional)

To schedule weekly backups, add to crontab:

```bash
crontab -e
```

Add this line for Sunday 2 AM backups:
```cron
0 2 * * 0 /home/loki3/github/homelab/scripts/backup-immich.sh
```

## Restore Process

### Run Restore

```bash
cd ~/github/homelab/scripts
./restore-immich.sh
```

### What Happens During Restore

1. Lists available backups with timestamps
2. You select which backup to restore
3. Shows backup manifest for review
4. Asks for confirmation (type 'yes')
5. Stops Immich services
6. Backs up current data to `.old` directory
7. Restores uploads, database, and volumes
8. Restarts Immich services

### Restore Warning

⚠️ **IMPORTANT**: Restore will OVERWRITE all current Immich data!

- Your existing data is backed up to `/home/loki3/immich.old`
- The restore process cannot be undone (except by restoring another backup)

## Maintenance

### Check Backup Drive Space

```bash
df -h /mnt/backup
```

### View Backup Log

```bash
tail -f /mnt/backup/immich-backup/backup.log
```

### List All Backups

```bash
ls -lh /mnt/backup/immich-backup/
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

If you get permission errors on restore:

```bash
sudo chown -R 1000:1000 /home/loki3/immich
```

### Immich Won't Start After Restore

1. Check logs:
   ```bash
   cd ~/github/homelab/apps/immich
   docker compose logs -f
   ```

2. Verify Postgres is running:
   ```bash
   docker ps | grep postgres
   ```

3. Restart services:
   ```bash
   cd ~/github/homelab/apps/immich
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
~/github/homelab/scripts/backup-immich.sh

# Run restore
~/github/homelab/scripts/restore-immich.sh

# Check backup size
du -sh /mnt/backup/immich-backup/*

# Unmount backup drive (when done)
sudo umount /mnt/backup
```

## Need Help?

- Check logs: `/mnt/backup/immich-backup/backup.log`
- Immich logs: `docker compose logs -f` (from apps/immich directory)
- See main homelab docs: `~/github/homelab/CLAUDE.md`
