# Actual Budget - Personal Finance Manager

A super fast and privacy-focused app for managing your finances with a powerful budgeting system.

## Overview

**Image**: `actualbudget/actual-server:latest`
**Container Name**: `actualbudget`
**Internal Port**: 5006
**Host Port**: 5006
**HTTPS Access**: https://actualbudget.homelab.com

## Features

- Zero-based envelope budgeting
- Bank synchronization (optional)
- End-to-end encryption
- Multi-device sync
- Privacy-focused (self-hosted)
- Mobile apps available

## Quick Start

### Start the Service

```bash
cd apps/actualbudget
docker compose up -d
```

### View Logs

```bash
docker compose logs -f actualbudget
```

### Stop the Service

```bash
docker compose down
```

## Access

- **Direct**: http://localhost:5006
- **HTTPS (via Caddy)**: https://actualbudget.homelab.com (requires Pi-hole DNS)

## Initial Setup

1. Access the web interface via https://actualbudget.homelab.com
2. Create your first budget file
3. Set up your accounts and categories
4. (Optional) Configure bank sync

## Data Storage

Budget data is stored in `./data` directory (Docker volume).

**Backup Location**: `apps/actualbudget/data`

## Configuration

Environment variables in `docker-compose.yml`:

- `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB`: Max file sync size (default: 20MB)
- `ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB`: Max encrypted sync size (default: 50MB)
- `ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB`: Max file upload size (default: 20MB)

## Pi-hole DNS Setup

Add this entry to Pi-hole's Local DNS Records:

```
Domain: actualbudget.homelab.com
IP Address: 100.x.y.z (your Tailscale IP)
```

**See**: [Pi-hole DNS Update Guide](../../docs/PIHOLE-DNS-UPDATE.md)

## Backup

To backup your budget data:

```bash
# On the homelab server
cd ~/github/homelab-01/apps/actualbudget
tar -czf actualbudget-backup-$(date +%Y%m%d).tar.gz data/
```

## Mobile Apps

- **iOS**: Available on App Store
- **Android**: Available on Google Play

Configure the sync URL as: `https://actualbudget.homelab.com`

## Troubleshooting

**Service won't start:**
```bash
docker ps | grep actualbudget
docker compose logs actualbudget
```

**Can't access via HTTPS:**
1. Verify Caddy is running: `cd ../../system/caddy && docker compose ps`
2. Check DNS is configured in Pi-hole
3. Ensure you're connected to Tailscale network

**Data not persisting:**
```bash
# Check data directory permissions
ls -la apps/actualbudget/data
```
