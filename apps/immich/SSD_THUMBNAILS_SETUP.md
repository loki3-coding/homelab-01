# Moving Immich Thumbnails to SSD

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

## Setup Steps (Run AFTER backup completes)

### 1. Create SSD directory

```bash
sudo mkdir -p /home/loki3/immich-thumbs
sudo chown -R 1000:1000 /home/loki3/immich-thumbs
sudo chmod -R 755 /home/loki3/immich-thumbs
```

### 2. Stop Immich services

```bash
cd ~/github/homelab/apps/immich
docker compose down
```

### 3. Move existing thumbnails to SSD (optional)

```bash
# If you want to preserve existing thumbnails
if [ -d "/home/loki3/immich/thumbs" ]; then
    sudo mv /home/loki3/immich/thumbs/* /home/loki3/immich-thumbs/
fi

if [ -d "/home/loki3/immich/encoded-video" ]; then
    sudo mv /home/loki3/immich/encoded-video/* /home/loki3/immich-thumbs/encoded-video/
fi
```

### 4. Pull latest changes and restart

```bash
cd ~/github/homelab/apps/immich
git pull
docker compose up -d
```

### 5. Regenerate thumbnails

Go to Immich web UI:
1. Navigate to Administration → Jobs
2. Find "Generate Thumbnails" job
3. Click "Generate All" or "Generate Missing"
4. Monitor progress

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

If something goes wrong:

```bash
cd ~/github/homelab/apps/immich
git checkout HEAD~1 docker-compose.yml
docker compose down
docker compose up -d
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
