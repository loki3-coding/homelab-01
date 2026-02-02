# Server Setup Documentation

Complete guide for setting up a new Ubuntu Server for the homelab from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Installation](#initial-server-installation)
3. [Network Configuration](#network-configuration)
4. [Automated Setup Scripts](#automated-setup-scripts)
5. [Manual Configuration Steps](#manual-configuration-steps)
6. [Service Deployment](#service-deployment)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware

**Current Homelab Machine:**
- **Model**: Acer Aspire V3-572G
- **CPU**: Intel Core (5th generation)
- **RAM**: 8GB DDR3
- **Storage**:
  - 128GB SSD - OS, Docker images, and container volumes
  - 500GB HDD - Large data storage (Immich media, backups)
- **Network**: Gigabit Ethernet (wired connection)

### Network Information

Collect this information before starting:

- Server static IP: `192.168.100.200` (example)
- Gateway: `192.168.100.1`
- Subnet: `192.168.100.0/24`
- DNS: `1.1.1.1, 8.8.8.8`
- Management machine IP: `192.168.100.100`

## Initial Server Installation

### 1. Install Ubuntu Server

1. Download Ubuntu Server ISO from ubuntu.com
2. Create bootable USB drive (use Rufus, Etcher, or dd)
3. Boot server from USB drive
4. Follow installation wizard:
   - **Server name**: `homelab-01`
   - **Username**: `loki3`
   - **Password**: (use strong password from Bitwarden)
   - Install OpenSSH server
   - No additional snaps needed initially

### 2. First Boot

After installation completes and server reboots:

```bash
# Login to server console
# Username: loki3
# Password: <your-password>

# Check network connectivity
ip addr show
ping -c 4 1.1.1.1

# Update system
sudo apt update
sudo apt upgrade -y
```

## Network Configuration

### Static IP Configuration

Configure static IP using netplan:

```bash
# Edit netplan configuration
sudo nano /etc/netplan/00-installer-config.yaml
```

Example configuration:

```yaml
network:
  version: 2
  ethernets:
    enp1s0f1:  # Your interface name (use 'ip link' to find it)
      addresses:
        - 192.168.100.200/24
      routes:
        - to: default
          via: 192.168.100.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
      dhcp4: false
```

Apply configuration:

```bash
sudo netplan try
# If successful:
sudo netplan apply
```

### Verify Network

```bash
# Check IP address
ip addr show

# Check routing
ip route show

# Test connectivity
ping -c 4 1.1.1.1
ping -c 4 google.com
```

## Automated Setup Scripts

The repository includes automated setup scripts to configure the server.

### 1. Clone Repository

First, set up Git and clone the homelab repository:

```bash
# Install git if not already installed
sudo apt update
sudo apt install -y git

# Create directory for repositories
mkdir -p ~/github
cd ~/github

# Clone repository (use HTTPS initially)
git clone https://github.com/loki3-coding/homelab-01.git
cd homelab-01
```

### 2. Run Main Setup Script

The main setup script installs and configures:
- System updates
- Docker and Docker Compose
- Tailscale VPN
- Portainer (Docker GUI)
- UFW firewall
- Docker networks

**IMPORTANT**: Review and customize variables in the script before running!

```bash
cd ~/github/homelab-01

# Edit configuration variables
nano scripts/server-setup.sh

# Variables to customize:
# - HOMELAB_USER (default: loki3)
# - HOMELAB_HOSTNAME (default: homelab-01)
# - LAN_INTERFACE (find with 'ip link')
# - MACBOOK_LAN_IP (your management machine IP)

# Run the setup script
sudo ./scripts/server-setup.sh
```

The script will:
1. Update system packages
2. Disable sleep/suspend
3. Install Docker
4. Install Portainer
5. Install and configure Tailscale
6. Install Cockpit
7. Create Docker networks (db-net, proxy)
8. Configure UFW firewall

**Estimated time**: 10-15 minutes

### 3. SSH Hardening (Optional but Recommended)

After verifying SSH access works with your key:

```bash
# Generate SSH key on your Mac (if not already done)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_homelab-01 -C "homelab-01"

# Copy SSH key to server
ssh-copy-id -i ~/.ssh/id_ed25519_homelab-01.pub loki3@192.168.100.200

# Test SSH access
ssh -i ~/.ssh/id_ed25519_homelab-01 loki3@192.168.100.200

# On server, run SSH hardening script
sudo ./scripts/setup-ssh.sh

# Update authorized_keys with IP restrictions
nano ~/.ssh/authorized_keys

# Add before your public key:
from="192.168.100.100",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAA...
```

### 4. DNS Configuration

Run before starting Pi-hole:

```bash
sudo ./scripts/setup-dns.sh
```

This will:
- Disable systemd-resolved
- Configure temporary DNS (1.1.1.1)
- Prepare for Pi-hole DNS

### 5. Service Firewall Rules

After starting services (Pi-hole, etc.), run:

```bash
sudo ./scripts/setup-firewall-services.sh
```

This adds firewall rules for:
- Pi-hole admin interface (port 8080)
- Docker bridge forwarding

### 6. Reboot

After running all setup scripts:

```bash
sudo reboot
```

## Manual Configuration Steps

### Tailscale Configuration

1. **Approve Exit Node** (if using Tailscale as VPN):
   - Go to Tailscale admin console
   - Find your homelab-01 device
   - Approve as exit node

2. **Configure ACLs** (optional):
   - Set up access controls
   - Tag devices (tag:server, tag:macbook)
   - Configure SSH permissions

### SSH Client Configuration (MacBook)

Add to `~/.ssh/config`:

```ssh
# OpenSSH via LAN
Host homeLAN-01
    HostName 192.168.100.200
    User loki3
    IdentityFile ~/.ssh/id_ed25519_homelab-01
    IdentitiesOnly yes

# Tailscale SSH
Host homelab-01
    HostName 100.126.93.59  # Your Tailscale IP
    User loki3
    IdentitiesOnly yes
```

Test connections:

```bash
# LAN SSH
ssh homeLAN-01

# Tailscale SSH
ssh homelab-01
```

## Service Deployment

After server setup is complete, deploy services:

### 1. Start Core Services

```bash
cd ~/github/homelab-01

# Start all services in correct order
./scripts/start-all-services.sh
```

This will start:
- Tailscale (Phase 0)
- PostgreSQL + PgAdmin (Phase 1)
- Gitea + Immich (Phase 2)
- Nginx + Homepage + Pi-hole (Phase 3)

### 2. Update DNS After Pi-hole Starts

```bash
# After Pi-hole is running
sudo nano /etc/resolv.conf

# Change to:
nameserver 127.0.0.1
options edns0 trust-ad
```

### 3. Configure Pi-hole

1. Access Pi-hole admin: http://homelab-01:8080/admin
2. Login with password from `.env` file
3. Configure blocklists
4. Set up local DNS records

### 4. Configure Services

Each service needs initial configuration:

- **Gitea**: http://homelab-01:3000 - Create admin account
- **Immich**: http://homelab-01:2283 - Create admin account
- **PgAdmin**: http://homelab-01:5050 - Add server connections
- **Portainer**: http://homelab-01:9000 - Set admin password
- **Grafana**: http://homelab-01:3002 - Login with admin credentials

## Security Checklist

After setup is complete, verify:

- [x] UFW firewall is enabled and configured
- [x] SSH password authentication is disabled
- [x] SSH root login is disabled
- [x] SSH is restricted to LAN interface
- [x] Tailscale is configured with ACLs
- [x] All service default passwords are changed
- [x] Unattended upgrades are enabled
- [ ] Fail2ban is installed (optional)
- [x] Services are not exposed to public internet

## Maintenance

### Regular Updates

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Update Docker images
cd ~/github/homelab-01
docker compose pull
docker compose up -d
```

## Reference

### Network Interfaces

Find your network interface name:

```bash
ip link show
# or
ip addr show
```

Common names:
- `enp1s0f1` - Physical ethernet
- `docker0` - Docker bridge
- `tailscale0` - Tailscale VPN
- `br-<hash>` - Docker custom bridges

### Firewall Rules Template

Current configuration from notes:

```
[ 1] Anywhere on tailscale0     ALLOW IN    Anywhere
[ 2] Anywhere                   ALLOW IN    192.168.100.100
[ 3] Anywhere on enp1s0f1       ALLOW FWD   Anywhere on tailscale0
[ 4] 53 on enp1s0f1             ALLOW IN    Anywhere
[ 5] 53 on tailscale0           DENY IN     Anywhere
[ 6] 22 on enp1s0f1             ALLOW IN    Anywhere
[ 7] 22                         DENY IN     Anywhere
[ 8] 22 on tailscale0           DENY IN     Anywhere
[ 9] 8080/tcp                   ALLOW IN    172.18.0.0/16
[10] Anywhere on enp1s0f1       ALLOW FWD   Anywhere on br-<proxy>
```

### Service Ports

| Port | Service | Access |
|------|---------|--------|
| 22 | SSH | LAN only |
| 53 | DNS (Pi-hole) | LAN only |
| 80 | Nginx | LAN + Tailscale |
| 2222 | Gitea SSH | LAN + Tailscale |
| 2283 | Immich | LAN + Tailscale |
| 3000 | Gitea Web | LAN + Tailscale |
| 3002 | Grafana | LAN + Tailscale |
| 5050 | PgAdmin | LAN + Tailscale |
| 8080 | Pi-hole Admin | LAN + Docker |
| 9000 | Portainer | LAN + Tailscale |
| 9091 | Prometheus | LAN + Tailscale |

---