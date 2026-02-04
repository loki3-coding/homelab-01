#!/bin/bash

# Homelab Services Shutdown Script
# Stops all Docker Compose services in reverse dependency order
# Usage: ./stop-all-services.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (scripts/ folder)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root directory (parent of scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

# Stop a service
stop_service() {
    local service_name=$1
    local service_dir=$2

    log "Stopping ${service_name}..."

    if [ ! -d "${PROJECT_ROOT}/${service_dir}" ]; then
        log_error "Directory ${service_dir} not found"
        return 1
    fi

    cd "${PROJECT_ROOT}/${service_dir}"

    if docker compose down; then
        log_success "${service_name} stopped successfully"
        return 0
    else
        log_error "Failed to stop ${service_name}"
        return 1
    fi
}

# Stop Tailscale (optional)
stop_tailscale() {
    log "Stopping Tailscale..."

    # Check if Tailscale is running
    if ! sudo tailscale status > /dev/null 2>&1; then
        log_success "Tailscale is not running"
        return 0
    fi

    # Stop Tailscale
    if sudo tailscale down; then
        log_success "Tailscale stopped successfully"
        return 0
    else
        log_error "Failed to stop Tailscale"
        return 1
    fi
}

# Main shutdown sequence
main() {
    log "========================================"
    log "Homelab Services Shutdown"
    log "========================================"
    echo ""

    # Stop in reverse order (independent services first, database last)
    log "Stopping services in reverse dependency order..."
    echo ""

    # Phase 1: Stop monitoring stack
    log "Phase 1: Stopping monitoring services..."
    stop_service "Monitoring (Prometheus, Grafana, Loki)" "system/monitoring" || log_error "Failed to stop Monitoring"
    echo ""

    # Phase 2: Stop independent services
    log "Phase 2: Stopping independent services..."
    stop_service "Pi-hole" "system/pi-hole" || log_error "Failed to stop Pi-hole"
    stop_service "Homepage" "apps/homepage" || log_error "Failed to stop Homepage"
    echo ""

    # Phase 3: Stop database-dependent services
    log "Phase 3: Stopping database-dependent services..."
    stop_service "Immich" "apps/immich" || log_error "Failed to stop Immich"
    stop_service "Gitea" "apps/gitea" || log_error "Failed to stop Gitea"
    echo ""

    # Phase 4: Stop database (pgAdmin excluded - stop manually if running)
    log "Phase 4: Stopping database services..."
    log "Stopping PostgreSQL (pgAdmin excluded - stop manually if needed)..."

    cd "${PROJECT_ROOT}/infrastructure/postgres"
    if docker compose stop postgres; then
        log_success "PostgreSQL stopped successfully"
    else
        log_error "Failed to stop PostgreSQL"
    fi
    echo ""

    # Phase 5: Stop Tailscale (optional - uncomment if you want to stop Tailscale)
    # log "Phase 5: Stopping Tailscale VPN..."
    # stop_tailscale || log_error "Failed to stop Tailscale"
    # echo ""

    # Summary
    log "========================================"
    log "Shutdown Complete"
    log "========================================"
    echo ""
    log "Checking remaining containers..."
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "postgres|gitea|immich|homepage|pihole|prometheus|grafana|loki|promtail|node-exporter|cadvisor" || log_success "All homelab services stopped"
    echo ""
    log "Note: If pgAdmin is running, stop it manually:"
    log "  cd infrastructure/postgres && docker compose stop pgadmin"
    echo ""
}

# Run main function
main "$@"
