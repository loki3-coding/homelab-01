# Speedtest - Network Speed Test

A self-hosted HTML5 speedtest application for testing your homelab network performance.

## Overview

**Image**: `ghcr.io/librespeed/speedtest:latest`
**Container Name**: `speedtest`
**Internal Port**: 80
**Host Port**: 8765
**HTTPS Access**: https://speedtest.homelab.com

## Features

- Download/Upload speed testing
- Ping and jitter measurements
- No external dependencies
- Privacy-focused (no telemetry)
- Works on all devices

## Quick Start

### Start the Service

```bash
cd apps/speedtest
docker compose up -d
```

### View Logs

```bash
docker compose logs -f speedtest
```

### Stop the Service

```bash
docker compose down
```

## Access

- **Direct**: http://localhost:8765
- **HTTPS (via Caddy)**: https://speedtest.homelab.com (requires Pi-hole DNS)

## Configuration

Edit the environment variables in `docker-compose.yml`:

- `TITLE`: Custom title for the speedtest page
- `TELEMETRY`: Set to `true` to enable anonymous statistics
- `DISTANCE`: Unit for distance (km or mi)

## Pi-hole DNS Setup

Add this entry to Pi-hole's Local DNS Records:

```
Domain: speedtest.homelab.com
IP Address: 100.x.y.z (your Tailscale IP)
```

**See**: [Pi-hole DNS Update Guide](../../docs/PIHOLE-DNS-UPDATE.md)

## Troubleshooting

**Service won't start:**
```bash
docker ps | grep speedtest
docker compose logs speedtest
```

**Can't access via HTTPS:**
1. Verify Caddy is running: `cd ../../system/caddy && docker compose ps`
2. Check DNS is configured in Pi-hole
3. Ensure you're connected to Tailscale network
