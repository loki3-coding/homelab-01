# Known Issues and Limitations

## Current Known Issues

### Hardware: Failing HDD ⚠️ MONITORING

**Issue:** Main storage HDD (500GB Seagate ST500LT012) has 64 reallocated sectors (bad sectors).

**Status:** Under monitoring - thumbnails moved to SSD as mitigation

**Drive Details:**
- Model: Seagate 500GB (ST500LT012-1DG142)
- Status: FAILING - 64 bad sectors reallocated
- Power-On: 19,004 hours (~2.2 years)
- Usage: Stores Immich photo uploads (163GB of 500GB)

**Monitor command:**
```bash
ssh loki3@homelab-01
# Note: Device name changed to /dev/sdc - verify with `lsblk` or `sudo blkid`
sudo smartctl -a /dev/sdb | grep -E "(Reallocated|Pending|Uncorrectable)"
```

**Action needed:** Replace HDD when reallocated sectors exceed 100, or immediately if uncorrectable sectors appear.

**See also:** [apps/immich/SSD_THUMBNAILS_SETUP.md](../apps/immich/SSD_THUMBNAILS_SETUP.md) for mitigation strategy

---

## Resolved Issues

### Pi-hole HTTPS Access Through Caddy ✅ SOLVED

**Problem:** Pi-hole (running in host network mode) could not be accessed via HTTPS through Caddy reverse proxy.

**Status:** Resolved on 2026-02-04

**Solution:** UFW firewall rule + Docker bridge gateway configuration

**See full documentation:** [system/caddy/PIHOLE_HTTPS_SOLUTION.md](../system/caddy/PIHOLE_HTTPS_SOLUTION.md)

**Quick reference:**
```bash
# UFW rule (required)
sudo ufw allow from 172.18.0.0/16 to any port 8080 proto tcp

# Caddyfile configuration
pihole.homelab.com {
    reverse_proxy 172.18.0.1:8080
}
```

**Access:** https://pihole.homelab.com/admin

---

### Immich Thumbnail Corruption on Failing HDD ✅ SOLVED

**Problem:** Immich thumbnails were corrupting due to HDD with 64 bad sectors (reallocated sectors).

**Status:** Resolved on 2026-02-02

**Solution:** Move thumbnails to SSD while keeping original uploads on HDD

**See full documentation:** [apps/immich/SSD_THUMBNAILS_SETUP.md](../apps/immich/SSD_THUMBNAILS_SETUP.md)

**Quick reference:**
```bash
# Create SSD directory for thumbnails
sudo mkdir -p /home/loki3/immich-thumbs/encoded-video
sudo chown -R 1000:1000 /home/loki3/immich-thumbs

# Update docker-compose.yml to mount SSD paths
# Then restart Immich
cd ~/github/homelab/apps/immich
docker compose down
docker compose up -d
```

**Results:**
- ✅ No more thumbnail corruption
- ✅ Faster thumbnail loading (SSD vs HDD)
- ✅ Reduced wear on failing HDD
- ⚠️ HDD still needs replacement (monitor reallocated sectors)


