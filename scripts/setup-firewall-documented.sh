#!/bin/bash
# Complete UFW Firewall Setup with Comments
# This script sets up all firewall rules with proper documentation
# Usage: sudo ./setup-firewall-documented.sh

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "Homelab Firewall Setup"
echo "======================================${NC}"
echo ""

# Get network interface names
LAN_INTERFACE="enp1s0f1"  # Change if different
TAILSCALE_INTERFACE="tailscale0"

echo "Network interfaces:"
echo "  LAN: $LAN_INTERFACE"
echo "  Tailscale: $TAILSCALE_INTERFACE"
echo ""

read -p "Are these correct? (y/n): " answer
if [[ ! $answer =~ ^[Yy]$ ]]; then
    echo "Edit the script to set correct interface names."
    exit 1
fi

echo ""
echo -e "${YELLOW}WARNING: This will reset UFW rules!${NC}"
echo "Current rules will be backed up to /tmp/ufw-backup-$(date +%Y%m%d-%H%M%S).txt"
echo ""
read -p "Continue? (y/n): " answer
if [[ ! $answer =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Backup current rules
BACKUP_FILE="/tmp/ufw-backup-$(date +%Y%m%d-%H%M%S).txt"
ufw status numbered > "$BACKUP_FILE"
echo -e "${GREEN}✓ Current rules backed up to: $BACKUP_FILE${NC}"
echo ""

# Reset UFW (optional - comment out if you want to keep existing rules)
echo -e "${YELLOW}Resetting UFW...${NC}"
# ufw --force reset  # Uncomment to reset all rules

echo -e "${BLUE}Adding firewall rules with comments...${NC}"
echo ""

# ============================================
# Phase 1: VPN & Network Forwarding
# ============================================
echo "Phase 1: VPN & Network Forwarding"

# Allow Tailscale to LAN forwarding
ufw route allow in on $TAILSCALE_INTERFACE out on $LAN_INTERFACE comment 'Tailscale VPN to LAN forwarding'
echo "  ✓ Tailscale → LAN forwarding"

# ============================================
# Phase 2: DNS (Pi-hole)
# ============================================
echo ""
echo "Phase 2: DNS Services (Pi-hole)"

# DNS on LAN
ufw allow in on $LAN_INTERFACE to any port 53 comment 'Pi-hole DNS on LAN'
echo "  ✓ DNS on LAN"

# DNS on Tailscale
ufw allow in on $TAILSCALE_INTERFACE to any port 53 comment 'Pi-hole DNS on Tailscale'
echo "  ✓ DNS on Tailscale"

# ============================================
# Phase 3: SSH Access
# ============================================
echo ""
echo "Phase 3: SSH Access"

# SSH on LAN (ALLOW)
ufw allow in on $LAN_INTERFACE to any port 22 comment 'SSH access on LAN only'
echo "  ✓ SSH on LAN (allowed)"

# SSH on Tailscale (DENY for security)
ufw deny in on $TAILSCALE_INTERFACE to any port 22 comment 'Block SSH on Tailscale (security)'
echo "  ✓ SSH on Tailscale (blocked for security)"

# ============================================
# Phase 4: Docker & Container Access
# ============================================
echo ""
echo "Phase 4: Docker & Container Access"

# Caddy proxy network to Pi-hole
ufw allow from 172.18.0.0/16 to any port 8080 proto tcp comment 'Caddy proxy to Pi-hole (host network)'
echo "  ✓ Caddy (proxy network) → Pi-hole"

# ============================================
# Phase 5: HTTPS (Caddy Reverse Proxy)
# ============================================
echo ""
echo "Phase 5: HTTPS Access (Caddy)"

# HTTPS on LAN
ufw allow in on $LAN_INTERFACE to any port 443 proto tcp comment 'Caddy HTTPS on LAN'
echo "  ✓ HTTPS on LAN"

# HTTPS on Tailscale
ufw allow in on $TAILSCALE_INTERFACE to any port 443 proto tcp comment 'Caddy HTTPS on Tailscale'
echo "  ✓ HTTPS on Tailscale"

# ============================================
# Enable UFW
# ============================================
echo ""
echo -e "${BLUE}Enabling UFW...${NC}"
ufw --force enable

# ============================================
# Show final rules
# ============================================
echo ""
echo -e "${GREEN}======================================"
echo "Firewall setup complete!"
echo "======================================${NC}"
echo ""
echo "Final rules:"
ufw status numbered

echo ""
echo -e "${YELLOW}Notes:${NC}"
echo "  • SSH is only allowed on LAN ($LAN_INTERFACE)"
echo "  • All services accessible via HTTPS (port 443) through Caddy"
echo "  • Pi-hole DNS on both LAN and Tailscale"
echo "  • Caddy proxy network can access Pi-hole on port 8080"
echo "  • No direct Docker network forwarding (access via Caddy reverse proxy)"
echo "  • Backup saved to: $BACKUP_FILE"
echo ""
echo "To restore backup:"
echo "  cat $BACKUP_FILE"
echo ""
