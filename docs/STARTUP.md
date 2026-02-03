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

### Stop Sequence
1.**Phase 1**: Pi-hole, Homepage (independent)
2.**Phase 2**: Immich, Gitea (database-dependent)
3.**Phase 3**: PostgreSQL + PgAdmin (database)
4.**Phase 4**: Tailscale VPN (optional - disabled by default)

## Automatic Startup on Boot (Systemd)

To make services start automatically when the server boots:

### 1. Edit the systemd service file

Edit `scripts/homelab.service` and update these lines to match your system:

```ini
User=loki3
WorkingDirectory=/home/loki3/homelab
ExecStart=/home/loki3/homelab/start-all-services.sh
ExecStop=/home/loki3/homelab/stop-all-services.sh
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

- Homepage: http://homelab-01/
- Immich: http://localhost:2283
- PgAdmin: http://localhost:5050
- Pi-hole Admin: http://localhost:8080/admin
- Gitea: http://localhost:3000

## Recovery After Power Failure

If the server experiences a power failure:

1.**With systemd enabled**: Services auto-start after boot (recommended)
2.**Without systemd**: SSH into server and run `./scripts/start-all-services.sh`

## Environment Variables

Ensure all `.env` files are present in their respective service directories:
- `postgres/.env` - Database credentials
- `gitea/.env` - Gitea configuration
- `immich/.env` - Immich database credentials
- `pi-hole/.env` - Pi-hole admin password

The scripts do not manage `.env` files - they must exist before running.
