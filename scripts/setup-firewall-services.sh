#!/bin/bash

################################################################################
# Service-Specific Firewall Rules
#
# This script adds firewall rules for homelab services:
# - Pi-hole (port 8080 from Docker network)
# - Docker bridge routing
# - Additional service ports as needed
#
# Usage: sudo ./setup-firewall-services.sh
#
# Prerequisites:
# - UFW must be installed and basic rules configured
# - Docker networks must be created
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
log "Service Firewall Configuration"
log "========================================"
echo ""

# Configuration
LAN_INTERFACE="enp1s0f1"

# Find Docker bridge networks
log "Detecting Docker bridge networks..."
DOCKER0_BRIDGE=$(ip addr show docker0 2>/dev/null | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+' || echo "")
PROXY_BRIDGE=$(docker network inspect proxy -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "")

if [ -n "$DOCKER0_BRIDGE" ]; then
    log "Found docker0: $DOCKER0_BRIDGE"
fi

if [ -n "$PROXY_BRIDGE" ]; then
    log "Found proxy network: $PROXY_BRIDGE"
fi

echo ""

# Allow Pi-hole admin interface from Docker networks
if [ -n "$PROXY_BRIDGE" ]; then
    log "Allowing Pi-hole admin (8080) from proxy network..."
    ufw allow in from $PROXY_BRIDGE to any port 8080 proto tcp
    log_success "Pi-hole admin access allowed from Docker"
fi

# Allow Docker bridge forwarding
log "Configuring Docker bridge forwarding..."

# Get bridge interface for proxy network
PROXY_BRIDGE_IFACE=$(docker network inspect proxy -f '{{.Id}}' 2>/dev/null | cut -c 1-12)
if [ -n "$PROXY_BRIDGE_IFACE" ]; then
    PROXY_BRIDGE_NAME="br-${PROXY_BRIDGE_IFACE}"
    log "Found proxy bridge interface: ${PROXY_BRIDGE_NAME}"

    # Allow forwarding from proxy bridge to LAN
    ufw route allow in on ${PROXY_BRIDGE_NAME} out on ${LAN_INTERFACE}
    log_success "Forwarding allowed for proxy bridge"
fi

# Allow forwarding from docker0 to LAN
if [ -n "$DOCKER0_BRIDGE" ]; then
    ufw route allow in on docker0 out on ${LAN_INTERFACE}
    log_success "Forwarding allowed for docker0"
fi

echo ""

# Reload firewall
log "Reloading firewall..."
ufw reload

log_success "Firewall rules updated"
echo ""

# Show current rules
log "Current firewall rules:"
ufw status numbered
echo ""

log "========================================"
log "Service Firewall Complete"
log "========================================"
echo ""

log "Configured rules:"
log "  ✓ Pi-hole admin (8080) from Docker networks"
log "  ✓ Docker bridge forwarding to LAN"
echo ""

log_warning "If you add more services, you may need to add additional rules"
echo ""
