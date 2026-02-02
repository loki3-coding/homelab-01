# Moving Immich Thumbnails to SSD

---

## 📚 Documentation Navigation

- **[← Back to Immich README](README.md)**
- **[💾 Backup Guide](../../scripts/IMMICH_BACKUP_README.md)** - Backup before migration
- **[📜 Scripts README](../../scripts/README.md)** - All automation scripts
- **[📖 CLAUDE.md](../../CLAUDE.md)** - Quick reference

---

## Document Status
- **Last Updated:** 2026-02-02
- **Current State:** ⚠️ NOT YET APPLIED - Configuration ready, waiting for backup to complete
- **Purpose:** Implementation guide for moving thumbnails to SSD

⚠️ **IMPORTANT: All commands in this document must be run on the homelab server (`ssh loki3@homelab-01`), not locally.**

## Why This Is Needed

Your HDD (/dev/sdb) has **64 reallocated sectors** (bad sectors), which is causing thumbnail corruption. Moving thumbnails to the SSD will:
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

⚠️ RECOMMENDATION: Plan to replace this HDD soon
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

### 3. Move existing thumbnails to SSD (optional but recommended)

**Should you do this?**
- ✅ **YES** (recommended): Preserves existing thumbnails, no regeneration needed
- ❌ **NO**: You'll regenerate all thumbnails (Step 6), which may take hours

**If you choose YES:**
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

**If you choose NO:** Skip to step 4.

### 4. Apply configuration changes

**Option A: Pull from git (if you're following this guide after changes were committed)**
```bash
cd ~/github/homelab/apps/immich
git pull origin main

# Verify docker-compose.yml has SSD mounts
grep -A 2 "immich-thumbs" docker-compose.yml
```

**Expected output:**
```yaml
- /home/loki3/immich-thumbs:/usr/src/app/upload/thumbs
- /home/loki3/immich-thumbs:/usr/src/app/upload/encoded-video
```

**Option B: Manually verify if configuration is already present**
```bash
cd ~/github/homelab-01/apps/immich
cat docker-compose.yml | grep "immich-thumbs"
```

If you don't see the SSD mounts, the configuration needs to be added manually or pulled from git.

### 5. Restart Immich

```bash
cd ~/github/homelab/apps/immich
docker compose up -d

# Wait 10 seconds, then verify services started
sleep 10
docker ps | grep immich
# Should show: immich-server, immich-machine-learning, immich-redis
```

### 6. Regenerate thumbnails (if needed)

**Access Immich Admin Panel:**
- URL: `http://homelab-01:2283` or `http://localhost:2283` (if using SSH port forward)
- Login with your admin account

**Regeneration Options:**
- **"Generate Missing"** (recommended if you copied thumbnails in step 3) - Only creates missing (~5-30 min)
- **"Generate All"** (if you skipped step 3) - Recreates ALL thumbnails (~2-4 hours for 163GB library)

**Steps:**
1. Log into Immich as admin
2. Navigate to **Administration → Jobs**
3. Find "**Generate Thumbnails**" job
4. Click:
   - **"Generate Missing"** if you copied thumbnails
   - **"Generate All"** if you skipped the copy
5. Monitor progress in the Jobs page

**Monitor progress from command line:**
```bash
# Watch thumbnail directory size grow
watch -n 5 "du -sh /home/loki3/immich-thumbs"

# Check Immich logs for errors
docker compose logs -f immich-server | grep -i thumb
```

### 6. Verify SSD usage

```bash
# Check that thumbnails are being written to SSD
watch -n 2 "du -sh /home/loki3/immich-thumbs"

# Check container logs
docker compose logs -f immich-server
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

## Rollback (if needed)

**If thumbnails are corrupted or something went wrong:**

### Quick Rollback (keeps thumbnails on SSD, just reverts mount points)

```bash
# On server
ssh loki3@homelab-01
cd ~/github/homelab/apps/immich

# Find commit before SSD changes
git log --oneline docker-compose.yml | head -5

# Checkout specific commit (replace COMMIT_HASH with actual hash)
git checkout COMMIT_HASH docker-compose.yml

# Restart
docker compose down && docker compose up -d
```

### Full Rollback (restore thumbnails to HDD)

```bash
# On server
ssh loki3@homelab-01

# 1. Stop Immich
cd ~/github/homelab-01/apps/immich
docker compose down

# 2. Move thumbnails back to HDD (if you moved them in step 3)
sudo mkdir -p /home/loki3/immich/thumbs
sudo mkdir -p /home/loki3/immich/encoded-video

sudo rsync -av /home/loki3/immich-thumbs/ /home/loki3/immich/thumbs/ 2>/dev/null || true
sudo rsync -av /home/loki3/immich-thumbs/encoded-video/ /home/loki3/immich/encoded-video/ 2>/dev/null || true

# Fix permissions
sudo chown -R 1000:1000 /home/loki3/immich

# 3. Revert docker-compose.yml
git log --oneline docker-compose.yml | head -5  # Find commit before SSD
git checkout COMMIT_HASH docker-compose.yml  # Replace COMMIT_HASH

# 4. Restart
docker compose up -d
```

### Ultimate Fallback (restore from backup)

**If rollback fails or data is corrupted:**
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
