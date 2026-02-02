# Moving Immich Thumbnails to SSD

---

## 📚 Documentation Navigation

- **[← Back to Immich README](README.md)**
- **[💾 Backup Guide](IMMICH_BACKUP_README.md)** - Backup before migration
- **[📜 Scripts README](../../scripts/README.md)** - All automation scripts
- **[📖 CLAUDE.md](../../CLAUDE.md)** - Quick reference

---

## Document Status
- **Last Updated:** 2026-02-02
- **Purpose:** Implementation guide for moving thumbnails to SSD

**IMPORTANT: All commands in this document must be run on the homelab server (`ssh loki3@homelab-01`), not locally.**

## Why This Is Needed

Main HDD (/dev/sdb) has **64 reallocated sectors** (bad sectors), which is causing thumbnail corruption. Moving thumbnails to the SSD will:
- Eliminate thumbnail corruption errors
- Significantly speed up thumbnail loading
- Reduce wear on the failing HDD

## HDD Health Summary

```
Drive: Seagate 500GB (ST500LT012-1DG142)
Status: FAILING - 64 bad sectors reallocated
Power-On: 19,004 hours (~2.2 years)
Temperature: 48°C
CRC Errors: 29

RECOMMENDATION: Plan to replace this HDD soon
```

## What Changed in docker-compose.yml

1. **Added SSD volume mounts:**
   - Thumbnails: `/home/loki3/immich-thumbs` (on SSD)
   - Encoded videos: `/home/loki3/immich-thumbs/encoded-video` (on SSD)
   - Original uploads: Still on HDD `/home/loki3/immich`

2. **Increased memory limits:**
   - Immich server: 2GB limit, 1GB reserved
   - ML container: 4GB limit, 2GB reserved

## Setup Steps

### Prerequisites (COMPLETE THESE FIRST)

**1. Run a full backup (this is your safety net):**
```bash
ssh loki3@homelab-01
sudo mount /dev/sdc1 /mnt/backup
cd ~/github/homelab/scripts
./backup-immich.sh
```

**2. Verify backup completed successfully:**
```bash
ssh loki3@homelab-01 "ls -lh /mnt/backup/immich-backup/"
# Check latest backup has uploads/, database/, volumes/
ssh loki3@homelab-01 "cat /mnt/backup/immich-backup/\$(ls -t /mnt/backup/immich-backup/ | head -1)/backup-manifest.txt"
```

### Implementation Steps (Run on server)

**All commands below run on the server. SSH in first:**
```bash
ssh loki3@homelab-01
```

---

### 1. Create SSD directory

```bash
sudo mkdir -p /home/loki3/immich-thumbs/encoded-video
sudo chown -R 1000:1000 /home/loki3/immich-thumbs
sudo chmod -R 755 /home/loki3/immich-thumbs

# Verify
ls -ld /home/loki3/immich-thumbs
# Should show: drwxr-xr-x ... 1000 1000 ... /home/loki3/immich-thumbs
```

### 2. Stop Immich services

```bash
cd ~/github/homelab/apps/immich
docker compose down

# Verify stopped
docker ps | grep immich
# Should show nothing
```

### 3. Move existing thumbnails to SSD

```bash
# Check if source thumbnails exist
ls -lh /home/loki3/immich/thumbs 2>/dev/null
ls -lh /home/loki3/immich/encoded-video 2>/dev/null

# Copy (not move) to preserve originals during migration
if [ -d "/home/loki3/immich/thumbs" ]; then
    sudo rsync -av /home/loki3/immich/thumbs/ /home/loki3/immich-thumbs/
    echo "Thumbnails copied"
fi

if [ -d "/home/loki3/immich/encoded-video" ]; then
    sudo rsync -av /home/loki3/immich/encoded-video/ /home/loki3/immich-thumbs/encoded-video/
    echo "Encoded videos copied"
fi

# Verify copy succeeded
du -sh /home/loki3/immich-thumbs
```

### 4. Restart Immich

```bash
cd ~/github/homelab/apps/immich
docker compose up -d

# Wait 10 seconds, then verify services started
sleep 10
docker ps | grep immich
# Should show: immich-server, immich-machine-learning, immich-redis
```


## Expected Results

- **Faster thumbnail loading** - SSD is much faster than HDD
- **No more corruption** - No bad sectors on SSD
- **Better performance** - ML container has more memory
- **Cooler HDD** - Less read/write activity reduces temperature

## Space Usage Estimates

Thumbnails typically use 10-20% of original photo size:
- Your photos: 163GB
- Expected thumbnails: ~16-32GB
- Available on SSD: 58GB

✅ You have plenty of SSD space!

## Monitoring

After setup, monitor for issues:

```bash
# Check disk usage
df -h /home/loki3/immich-thumbs

# Check for errors
docker compose logs immich-server --tail 100 | grep -i error

# Check container memory
docker stats --no-stream
```

## Restore from backup

```bash
ssh loki3@homelab-01
cd ~/github/homelab/scripts
./restore-immich.sh
# Select the backup from before the SSD migration
```

## Future Recommendation

Your HDD is showing signs of failure (64 bad sectors). Consider:
1. **Short term:** Current setup (thumbnails on SSD) ✅
2. **Medium term:** Monitor HDD health weekly
3. **Long term:** Replace HDD and move all Immich data to new drive or SSD

Check HDD health regularly:
```bash
sudo smartctl -a /dev/sdb | grep -E "(Reallocated|Pending|Uncorrectable)"
```

If reallocated sectors increase beyond 100, replace the drive immediately.
