#!/bin/bash

################################################################################
# DNS Configuration Script
#
# This script configures DNS for Pi-hole:
# - Disables systemd-resolved
# - Configures resolv.conf to use Pi-hole (127.0.0.1)
# - Temporarily uses 1.1.1.1 until Pi-hole is running
#
# Usage: sudo ./setup-dns.sh
#
# Run this BEFORE starting Pi-hole container
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
log "DNS Configuration for Pi-hole"
log "========================================"
echo ""

# Disable systemd-resolved
log "Disabling systemd-resolved..."
systemctl disable --now systemd-resolved

log "Checking systemd-resolved status..."
if systemctl is-active --quiet systemd-resolved; then
    log_error "systemd-resolved is still running"
    exit 1
else
    log_success "systemd-resolved is stopped"
fi

# Remove resolv.conf symlink
log "Removing resolv.conf symlink..."
if [ -L /etc/resolv.conf ]; then
    rm -f /etc/resolv.conf
    log_success "Symlink removed"
else
    log_warning "resolv.conf is not a symlink"
fi

# Create temporary resolv.conf with Cloudflare DNS
log "Creating temporary resolv.conf with Cloudflare DNS..."
cat > /etc/resolv.conf <<EOF
# Temporary DNS configuration
# After Pi-hole is running, change to:
# nameserver 127.0.0.1
# options edns0 trust-ad

nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

log_success "Temporary DNS configured (1.1.1.1)"
echo ""

log "========================================"
log "Next Steps"
log "========================================"
echo ""
log "1. Start Pi-hole container:"
log "   cd ~/homelab-01/pi-hole"
log "   docker compose up -d"
echo ""
log "2. After Pi-hole is running, update /etc/resolv.conf:"
log "   sudo nano /etc/resolv.conf"
echo ""
log "   Change to:"
echo "   ---"
echo "   nameserver 127.0.0.1"
echo "   options edns0 trust-ad"
echo "   ---"
echo ""
log "3. Test DNS resolution:"
log "   nslookup google.com"
log "   dig google.com"
echo ""
log_success "DNS configuration complete"
echo ""
