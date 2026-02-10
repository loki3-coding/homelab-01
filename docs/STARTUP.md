# Homelab Startup Scripts Documentation

This directory contains scripts and configuration for managing the homelab services startup and shutdown.

## Files

- `start-all-services.sh` - Start all services in correct dependency order
- `stop-all-services.sh` - Stop all services in reverse order
- `scripts/homelab.service` - Systemd service for automatic startup on boot

## Quick Start

### Manual Service Management

Start all services:
```bash
./scripts/start-all-services.sh
```

Stop all services:
```bash
./scripts/stop-all-services.sh
```

### Features

The startup script includes:
- Tailscale VPN startup (with SSH and exit node advertising)
- Docker availability check
- Automatic network creation (db-net, proxy)
- Correct dependency ordering (Postgres first)
- PostgreSQL health check before starting dependent services
- Colored output with timestamps
- Error handling and status reporting
- Summary of running containers
- Access point URLs

The shutdown script includes:
- Reverse dependency ordering (database last)
- Graceful container shutdown
- Status verification

## Startup Order

The scripts follow this order:

### Start Sequence
1.**Phase 0**: Tailscale VPN (with --ssh --advertise-exit-node flags)
2.**Phase 1**: PostgreSQL + PgAdmin (wait for ready)
3.**Phase 2**: Gitea, Immich (depend on Postgres)
4.**Phase 3**: Homepage, Pi-hole (independent)
5.**Phase 4**: Monitoring (Prometheus, Grafana, Loki) + Caddy (HTTPS reverse proxy)

### Stop Sequence
1.**Phase 1**: Caddy (reverse proxy - stop first)
2.**Phase 2**: Monitoring, Pi-hole, Homepage (independent)
3.**Phase 3**: Immich, Gitea (database-dependent)
4.**Phase 4**: PostgreSQL + PgAdmin (database)
5.**Phase 5**: Tailscale VPN (optional - disabled by default)

## Automatic Startup on Boot (Systemd)

To make services start automatically when the server boots:

### 1. Edit the systemd service file

Edit `scripts/homelab.service` and update these lines to match your system:

```ini
User=username
WorkingDirectory=/home/username/homelab
ExecStart=/home/username/homelab/start-all-services.sh
ExecStop=/home/username/homelab/stop-all-services.sh
```

Change `loki3` to your username and update paths accordingly.

### 2. Install the service

```bash
# Copy the service file to systemd directory
sudo cp scripts/homelab.service /etc/systemd/system/

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable scripts/homelab.service
```

### 3. Manage the service

```bash
# Start services now
sudo systemctl start homelab

# Check status
sudo systemctl status homelab

# View logs
sudo journalctl -u homelab -f

# Restart all services
sudo systemctl restart homelab

# Stop services
sudo systemctl stop homelab

# Disable automatic startup
sudo systemctl disable homelab
```

## Prerequisites

### Tailscale

The startup script requires Tailscale to be installed on the system. The script will:
- Start Tailscale with SSH access enabled
- Advertise the node as an exit node
- Continue even if Tailscale fails (non-blocking)

Install Tailscale if not already installed:
```bash
# On Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh

# On other systems, see: https://tailscale.com/download
```

Note: The script requires sudo access to run `tailscale` commands.

### Sudo Access

The startup script requires passwordless sudo for the `tailscale` command. Add this to your sudoers file:

```bash
# Edit sudoers file
sudo visudo

# Add this line (replace 'username' with your actual username):
username ALL=(ALL) NOPASSWD: /usr/bin/tailscale
```

Or for the systemd service to work properly, ensure the service user has appropriate sudo privileges.

## Testing

### Test startup script
```bash
# Stop all services first
./scripts/stop-all-services.sh

# Run startup script
./scripts/start-all-services.sh

# Verify all containers are running
docker ps
```

### Test systemd service
```bash
# Stop services
sudo systemctl stop homelab

# Start via systemd
sudo systemctl start homelab

# Check status
sudo systemctl status homelab

# View startup logs
sudo journalctl -u homelab -n 100 --no-pager
```

## Access Points After Startup

Once all services are running:

**HTTPS Access (via Caddy - Recommended):**
- Homepage: https://home.homelab.com
- Immich: https://immich.homelab.com
- Gitea: https://gitea.homelab.com
- Grafana: https://grafana.homelab.com
- Prometheus: https://prometheus.homelab.com
- Loki: https://loki.homelab.com
- Pi-hole: https://pihole.homelab.com/admin
- Portainer: https://portainer.homelab.com

**Direct HTTP Access (Fallback):**
- Homepage: http://homelab-01:3000
- Immich: http://homelab-01:2283
- PgAdmin: http://homelab-01:5050 (manual start only)
- Pi-hole Admin: http://homelab-01:8080/admin
- Gitea: http://homelab-01:3000
- Grafana: http://homelab-01:3002
- Portainer: http://homelab-01:9000

**Note:** HTTPS URLs require:
- Pi-hole configured as Tailscale DNS
- Local DNS entries for `*.homelab.com`
- Trust Caddy's self-signed certificate (see [system/caddy/QUICKSTART.md](../system/caddy/QUICKSTART.md))

## Recovery After Power Failure

If the server experiences a power failure:

1.**With systemd enabled**: Services auto-start after boot (recommended)
2.**Without systemd**: SSH into server and run `./scripts/start-all-services.sh`

## Environment Variables

The scripts do not manage `.env` files - they must exist before running.

Copy the example files and set your own secure passwords:
```bash
# Platform services
cp core/postgres/.env.example core/postgres/.env
cp core/gitea/.env.example core/gitea/.env

# Applications
cp apps/immich/.env.example apps/immich/.env
cp system/pi-hole/.env.example system/pi-hole/.env

# Monitoring
cp system/monitoring/.env.example system/monitoring/.env
```

**Edit each `.env` file:**
```bash
# Replace all instances of "your-secure-password-here" with strong passwords
nano core/postgres/.env
nano core/gitea/.env
nano apps/immich/.env
nano system/pi-hole/.env
nano system/monitoring/.env
```
