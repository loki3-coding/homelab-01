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

### Git Security: Prevent Committing Secrets 🔒 IMPORTANT

**Issue:** Risk of accidentally committing sensitive files (private keys, .env files, passwords) to git history.

**Status:** Protection available via git hooks

**Background:**
- A private key (`nginx/certs/cockpit.homelab-key.pem`) was previously committed to git history
- Even though the file was later deleted, it remained in git history
- GitGuardian detected the exposed key and sent security alert
- Required complete git history rewrite to remove the key

**Solution:** Pre-commit hook that blocks dangerous commits

**Installation:**
```bash
# Install git hooks (one-time setup after cloning repo)
cd ~/github/homelab-01
./scripts/git-hooks/install-hooks.sh
```

**What the hook prevents:**
- ❌ Private key files (`.pem`, `.key`, `.p12`, `.pfx`, `.keystore`)
- ❌ Private key content (`BEGIN PRIVATE KEY`, `BEGIN RSA PRIVATE KEY`)
- ❌ Environment files (`.env` - secrets should never be committed)
- ⚠️  API keys and tokens (warns but doesn't block)

**How it works:**
```bash
# Normal workflow - no changes
git add README.md
git commit -m "Update docs"
🔍 Scanning for secrets...
✅ No secrets detected - commit allowed

# Trying to commit a secret - BLOCKED
git add server.key
git commit -m "Add key"
🔍 Scanning for secrets...
❌ ERROR: Attempting to commit private key file!
❌ COMMIT BLOCKED
```

**Benefits:**
- ✅ Prevents accidents before they reach git history
- ✅ No workflow changes (runs automatically)
- ✅ Protects against security breaches
- ✅ Avoids costly git history rewrites

**See also:**
- [scripts/git-hooks/README.md](../scripts/git-hooks/README.md) - Full documentation
- [scripts/git-hooks/pre-commit](../scripts/git-hooks/pre-commit) - Hook source code

**Important:**
- Hooks are LOCAL only (not synced via git for security)
- Must be installed manually after cloning repository
- Can be bypassed with `--no-verify` (use with extreme caution!)

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


