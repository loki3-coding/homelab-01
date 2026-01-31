#!/bin/bash

################################################################################
# Homelab Server Initial Setup Script
#
# This script automates the initial setup of a Ubuntu Server for homelab use.
# It installs and configures:
# - System updates and essential packages
# - Docker and Docker Compose
# - Tailscale VPN
# - SSH hardening
# - Firewall (UFW)
# - System monitoring tools (Cockpit, lm-sensors)
# - Portainer for Docker management
#
# Usage: sudo ./server-setup.sh
#
# IMPORTANT: Review and customize variables before running!
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables - CUSTOMIZE THESE!
HOMELAB_USER="loki3"
HOMELAB_HOSTNAME="homelab-01"
LAN_INTERFACE="enp1s0f1"  # Your LAN network interface
TAILSCALE_INTERFACE="tailscale0"
MACBOOK_LAN_IP="192.168.100.100"
TAILSCALE_SUBNET="100.64.0.0/10"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
    log_success "Running as root"
}

# Phase 1: System Updates and Essential Packages
phase1_system_updates() {
    log "========================================"
    log "Phase 1: System Updates"
    log "========================================"
    echo ""

    log "Updating package lists..."
    apt update

    log "Upgrading installed packages..."
    apt upgrade -y

    log "Installing essential packages..."
    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        wget \
        git \
        vim \
        htop \
        net-tools \
        unattended-upgrades \
        update-notifier-common \
        lm-sensors

    log_success "System updates completed"
    echo ""
}

# Phase 2: Disable Sleep/Suspend
phase2_disable_sleep() {
    log "========================================"
    log "Phase 2: Disable Sleep/Suspend"
    log "========================================"
    echo ""

    log "Disabling sleep, suspend, hibernate..."
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

    log_success "Sleep/suspend disabled"
    echo ""
}

# Phase 3: Install Docker
phase3_install_docker() {
    log "========================================"
    log "Phase 3: Docker Installation"
    log "========================================"
    echo ""

    # Remove old Docker installations
    log "Removing old Docker installations..."
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Add Docker's official GPG key
    log "Adding Docker GPG key..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    log "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    log "Installing Docker..."
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker
    log "Enabling Docker service..."
    systemctl enable --now docker

    # Add user to docker group
    log "Adding ${HOMELAB_USER} to docker group..."
    usermod -aG docker ${HOMELAB_USER}

    # Test Docker
    log "Testing Docker installation..."
    docker run --rm hello-world > /dev/null 2>&1

    log_success "Docker installed successfully"
    echo ""
}

# Phase 4: Install Portainer
phase4_install_portainer() {
    log "========================================"
    log "Phase 4: Portainer Installation"
    log "========================================"
    echo ""

    log "Creating Portainer volume..."
    docker volume create portainer_data

    log "Starting Portainer container..."
    docker run -d \
        --name portainer \
        -p 9000:9000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        --restart=always \
        portainer/portainer-ce

    log_success "Portainer installed at http://${HOMELAB_HOSTNAME}:9000"
    echo ""
}

# Phase 5: Install Tailscale
phase5_install_tailscale() {
    log "========================================"
    log "Phase 5: Tailscale Installation"
    log "========================================"
    echo ""

    log "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh

    log "Starting Tailscale with SSH and exit node..."
    tailscale up --ssh --advertise-exit-node

    # Enable IP forwarding for exit node
    log "Enabling IP forwarding..."
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p
    fi

    log_success "Tailscale installed and configured"
    log_warning "Remember to approve exit node in Tailscale admin console!"
    echo ""
}

# Phase 6: Install Cockpit
phase6_install_cockpit() {
    log "========================================"
    log "Phase 6: Cockpit Installation"
    log "========================================"
    echo ""

    log "Installing Cockpit..."
    apt install -y cockpit cockpit-pcp

    log "Enabling Cockpit..."
    systemctl enable --now cockpit.socket

    log_success "Cockpit installed at https://${HOMELAB_HOSTNAME}:9090"
    echo ""
}

# Phase 7: Create Docker Networks
phase7_create_networks() {
    log "========================================"
    log "Phase 7: Docker Networks"
    log "========================================"
    echo ""

    log "Creating db-net network..."
    docker network create db-net 2>/dev/null || log_warning "db-net already exists"

    log "Creating proxy network..."
    docker network create proxy 2>/dev/null || log_warning "proxy already exists"

    log_success "Docker networks created"
    echo ""
}

# Phase 8: Configure Firewall
phase8_configure_firewall() {
    log "========================================"
    log "Phase 8: Firewall Configuration"
    log "========================================"
    echo ""

    log "Configuring UFW firewall..."

    # Reset UFW to default
    log "Resetting UFW to defaults..."
    ufw --force reset

    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow all traffic on Tailscale interface
    log "Allowing traffic on ${TAILSCALE_INTERFACE}..."
    ufw allow in on ${TAILSCALE_INTERFACE}

    # Allow traffic from MacBook on LAN
    log "Allowing traffic from MacBook (${MACBOOK_LAN_IP})..."
    ufw allow in from ${MACBOOK_LAN_IP}

    # Allow forwarding from Tailscale to LAN
    log "Allowing forwarding from Tailscale to LAN..."
    ufw route allow in on ${TAILSCALE_INTERFACE} out on ${LAN_INTERFACE}

    # Allow DNS (port 53) on LAN interface
    log "Allowing DNS (port 53) on ${LAN_INTERFACE}..."
    ufw allow in on ${LAN_INTERFACE} to any port 53

    # Deny DNS on Tailscale (optional - use LAN DNS only)
    log "Denying DNS on ${TAILSCALE_INTERFACE}..."
    ufw deny in on ${TAILSCALE_INTERFACE} to any port 53

    # Enable SSH service
    log "Enabling SSH service..."
    systemctl enable ssh
    systemctl start ssh
    log_success "SSH service enabled and started"

    # Allow SSH on LAN interface only
    log "Allowing SSH (port 22) on ${LAN_INTERFACE}..."
    ufw allow in on ${LAN_INTERFACE} to any port 22

    # Deny SSH on other interfaces
    log "Denying SSH on non-LAN interfaces..."
    ufw deny 22
    ufw deny in on ${TAILSCALE_INTERFACE} to any port 22

    # Enable UFW
    log "Enabling UFW..."
    ufw --force enable

    log_success "Firewall configured"
    echo ""
    log "Current firewall rules:"
    ufw status numbered
    echo ""
}

# Phase 9: Summary and Next Steps
phase9_summary() {
    log "========================================"
    log "Setup Complete!"
    log "========================================"
    echo ""

    log "Installed services:"
    log "  ✓ Docker and Docker Compose"
    log "  ✓ Portainer (http://${HOMELAB_HOSTNAME}:9000)"
    log "  ✓ Tailscale VPN (with SSH and exit node)"
    log "  ✓ Cockpit (https://${HOMELAB_HOSTNAME}:9090)"
    log "  ✓ UFW Firewall"
    log "  ✓ System monitoring tools"
    echo ""

    log "Docker networks created:"
    log "  ✓ db-net (for database connections)"
    log "  ✓ proxy (for nginx reverse proxy)"
    echo ""

    log "Next steps:"
    log "  1. Approve Tailscale exit node in admin console"
    log "  2. Configure SSH hardening (run setup-ssh.sh)"
    log "  3. Set up DNS resolution (disable systemd-resolved)"
    log "  4. Clone homelab repository and start services"
    log "  5. Configure Pi-hole DNS"
    log "  6. Set up PostgreSQL and Gitea"
    echo ""

    log_warning "IMPORTANT: Reboot is recommended to apply all changes"
    log_warning "After reboot, re-login as ${HOMELAB_USER} (not root)"
    echo ""
}

# Main execution
main() {
    log "========================================"
    log "Homelab Server Setup"
    log "========================================"
    echo ""

    check_root

    log "Configuration:"
    log "  User: ${HOMELAB_USER}"
    log "  Hostname: ${HOMELAB_HOSTNAME}"
    log "  LAN Interface: ${LAN_INTERFACE}"
    log "  MacBook IP: ${MACBOOK_LAN_IP}"
    echo ""

    read -p "Continue with installation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Installation cancelled"
        exit 1
    fi

    echo ""

    phase1_system_updates
    phase2_disable_sleep
    phase3_install_docker
    phase4_install_portainer
    phase5_install_tailscale
    phase6_install_cockpit
    phase7_create_networks
    phase8_configure_firewall
    phase9_summary
}

# Run main function
main "$@"
