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
- ✓ Tailscale VPN startup (with SSH and exit node advertising)
- ✓ Docker availability check
- ✓ Automatic network creation (db-net, proxy)
- ✓ Correct dependency ordering (Postgres first)
- ✓ PostgreSQL health check before starting dependent services
- ✓ Colored output with timestamps
- ✓ Error handling and status reporting
- ✓ Summary of running containers
- ✓ Access point URLs

The shutdown script includes:
- ✓ Reverse dependency ordering (database last)
- ✓ Graceful container shutdown
- ✓ Status verification

## Startup Order

The scripts follow this order:

### Start Sequence
1. **Phase 0**: Tailscale VPN (with --ssh --advertise-exit-node flags)
2. **Phase 1**: PostgreSQL + PgAdmin (wait for ready)
3. **Phase 2**: Gitea, Immich (depend on Postgres)
4. **Phase 3**: Nginx, Homepage, Pi-hole (independent)

### Stop Sequence
1. **Phase 1**: Pi-hole, Homepage, Nginx (independent)
2. **Phase 2**: Immich, Gitea (database-dependent)
3. **Phase 3**: PostgreSQL + PgAdmin (database)
4. **Phase 4**: Tailscale VPN (optional - disabled by default)

## Automatic Startup on Boot (Systemd)

To make services start automatically when the server boots:

### 1. Edit the systemd service file

Edit `scripts/homelab.service` and update these lines to match your system:

```ini
User=loki3
WorkingDirectory=/home/loki3/homelab-01
ExecStart=/home/loki3/homelab-01/start-all-services.sh
ExecStop=/home/loki3/homelab-01/stop-all-services.sh
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

## Troubleshooting

### Tailscale fails to start

Check if Tailscale is installed:
```bash
which tailscale
tailscale version
```

Check Tailscale status:
```bash
sudo tailscale status
```

Manually start Tailscale:
```bash
sudo tailscale up --ssh --advertise-exit-node
```

### Script fails with "Docker is not running"

Ensure Docker is started:
```bash
sudo systemctl start docker
# or on macOS:
open -a Docker
```

### PostgreSQL fails to start

Check if the data directory has correct permissions:
```bash
ls -la postgres/data/
# Should be owned by user/group with appropriate permissions
```

### Service fails to start

Check individual service logs:
```bash
cd <service-directory>
docker compose logs -f
```

### Networks don't exist

The script automatically creates networks, but you can create them manually:
```bash
docker network create db-net
docker network create proxy
```

### Port conflicts

Check if ports are already in use:
```bash
# Check specific port
sudo lsof -i :5432  # Postgres
sudo lsof -i :80    # Nginx
sudo lsof -i :53    # Pi-hole DNS

# List all listening ports
sudo lsof -i -P | grep LISTEN
```

### Systemd service fails

Check the service logs:
```bash
sudo journalctl -u homelab -n 50 --no-pager
```

Verify the paths in scripts/homelab.service are correct:
```bash
# Test the script manually
sudo -u loki3 /home/loki3/homelab-01/start-all-services.sh
```

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

## Customization

### Adding a new service

1. Edit `start-all-services.sh`
2. Add the service to the appropriate phase:
   - Phase 1: If it requires Postgres
   - Phase 2: If it's independent

Example:
```bash
# In Phase 3 (independent services)
start_service "NewService" "newservice" || log_warning "NewService failed to start, continuing..."
```

3. Edit `stop-all-services.sh`
4. Add the service to Phase 1 (stop independent services first)

### Changing startup delay

To add delay between service starts, modify the script:
```bash
start_service "ServiceName" "service-dir"
sleep 5  # Wait 5 seconds
```

### Modifying PostgreSQL wait timeout

Edit `wait_for_postgres()` function in `start-all-services.sh`:
```bash
local max_attempts=30  # Change this value (30 attempts × 2 seconds = 60 seconds)
```

## Best Practices

1. **Test scripts after changes**: Always test manually before enabling systemd
2. **Check logs**: Use `journalctl` to monitor service startup
3. **Backup before updates**: Backup Docker volumes before major changes
4. **Monitor resources**: Keep an eye on RAM/CPU usage during startup
5. **Staged rollout**: Test new services individually before adding to startup script

## Access Points After Startup

Once all services are running:

- Homepage: http://homelab-01/
- Immich: http://localhost:2283
- PgAdmin: http://localhost:5050
- Pi-hole Admin: http://localhost:8080/admin
- Gitea: Via Nginx reverse proxy

## Recovery After Power Failure

If the server experiences a power failure:

1. **With systemd enabled**: Services auto-start after boot (recommended)
2. **Without systemd**: SSH into server and run `./scripts/start-all-services.sh`

## Environment Variables

Ensure all `.env` files are present in their respective service directories:
- `postgres/.env` - Database credentials
- `gitea/.env` - Gitea configuration
- `immich/.env` - Immich database credentials
- `pi-hole/.env` - Pi-hole admin password

The scripts do not manage `.env` files - they must exist before running.

---

**Last Updated**: 2026-01-30
**Related**: See CLAUDE.md for full project documentation
