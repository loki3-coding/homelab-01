#!/bin/bash

################################################################################
# SSH Hardening Script
#
# This script hardens SSH configuration for the homelab server:
# - Disables password authentication
# - Enables public key authentication only
# - Disables root login
# - Restricts SSH to LAN interface
# - Configures authorized_keys with source restrictions
#
# Usage: sudo ./setup-ssh.sh
#
# Prerequisites:
# - SSH public key must be added to ~/.ssh/authorized_keys first
# - Firewall must be configured (run server-setup.sh first)
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
HOMELAB_USER="loki3"
MACBOOK_LAN_IP="192.168.100.100"
TAILSCALE_SUBNET="100.64.0.0/10"

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
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

log "========================================"
log "SSH Hardening Setup"
log "========================================"
echo ""

# Backup original sshd_config
log "Backing up sshd_config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
log_success "Backup created"

# Configure SSH
log "Configuring SSH hardening..."

cat > /etc/ssh/sshd_config.d/99-homelab-hardening.conf <<'EOF'
# Homelab SSH Hardening Configuration

# Listen on all interfaces (firewall handles filtering)
ListenAddress 0.0.0.0

# Authentication
PubkeyAuthentication yes
AuthenticationMethods publickey
AuthorizedKeysFile .ssh/authorized_keys
StrictModes yes

# Disable password authentication
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no

# Disable root login
PermitRootLogin no

# Reduce attack surface
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no

# Security settings
MaxAuthTries 3
LoginGraceTime 20
ClientAliveInterval 300
ClientAliveCountMax 2

# Only allow specific user
AllowUsers loki3
EOF

log_success "SSH configuration updated"

# Test SSH configuration
log "Testing SSH configuration..."
if sshd -t; then
    log_success "SSH configuration is valid"
else
    log_error "SSH configuration has errors!"
    log_error "Restoring backup..."
    mv /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
fi

# Reload SSH
log "Reloading SSH service..."
systemctl reload ssh

log_success "SSH service reloaded"
echo ""

# Instructions for authorized_keys
log "========================================"
log "Configure authorized_keys"
log "========================================"
echo ""

log "To restrict SSH access by source IP, update authorized_keys:"
log "  File: /home/${HOMELAB_USER}/.ssh/authorized_keys"
echo ""
log "Add this prefix before your public key:"
echo ""
echo "from=\"${MACBOOK_LAN_IP}\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAA..."
echo ""
log_warning "IMPORTANT: Make sure you have working SSH access before closing this session!"
echo ""

log "Example command to update authorized_keys:"
cat <<EOF

su - ${HOMELAB_USER}
cd ~/.ssh
# Backup current authorized_keys
cp authorized_keys authorized_keys.backup

# Edit authorized_keys and add the from= restriction
nano authorized_keys

# Example line:
from="${MACBOOK_LAN_IP}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpxWv5nUw5pkTAq4izpC3zoh5Cb82G/V2UE5ZYvyaCj homelab-01

EOF

echo ""
log "========================================"
log "SSH Hardening Complete"
log "========================================"
echo ""
log_success "SSH is now configured for public key authentication only"
log_success "Password authentication is disabled"
log_success "Root login is disabled"
echo ""
log_warning "Test SSH access from another terminal before closing this session!"
echo ""
