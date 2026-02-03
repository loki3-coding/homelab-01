#!/bin/bash

# Homelab Services Startup Script
# Starts all Docker Compose services in the correct dependency order
# Usage: ./start-all-services.sh

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

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if Docker is running
check_docker() {
    log "Checking Docker availability..."
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    log_success "Docker is running"
}

# Start a service and verify it started
start_service() {
    local service_name=$1
    local service_dir=$2

    log "Starting ${service_name}..."

    if [ ! -d "${PROJECT_ROOT}/${service_dir}" ]; then
        log_error "Directory ${service_dir} not found"
        return 1
    fi

    cd "${PROJECT_ROOT}/${service_dir}"

    if docker compose up -d; then
        log_success "${service_name} started successfully"
        return 0
    else
        log_error "Failed to start ${service_name}"
        return 1
    fi
}

# Wait for Postgres to be ready
wait_for_postgres() {
    log "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec postgres pg_isready -U postgres > /dev/null 2>&1; then
            log_success "PostgreSQL is ready"
            return 0
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "PostgreSQL failed to become ready after ${max_attempts} attempts"
    return 1
}

# Start Tailscale
start_tailscale() {
    log "Starting Tailscale..."

    # Check if Tailscale is already running
    if sudo tailscale status > /dev/null 2>&1; then
        log_success "Tailscale is already running"
        return 0
    fi

    # Start Tailscale with SSH and exit node advertising
    if sudo tailscale up --ssh --advertise-exit-node; then
        log_success "Tailscale started successfully"

        # Show Tailscale status
        log "Tailscale status:"
        sudo tailscale status | head -5
        return 0
    else
        log_error "Failed to start Tailscale"
        log_warning "Continuing without Tailscale..."
        return 1
    fi
}

# Create networks if they don't exist
create_networks() {
    log "Ensuring Docker networks exist..."

    if ! docker network inspect db-net > /dev/null 2>&1; then
        log "Creating db-net network..."
        docker network create db-net
        log_success "db-net network created"
    else
        log_success "db-net network already exists"
    fi

    if ! docker network inspect proxy > /dev/null 2>&1; then
        log "Creating proxy network..."
        docker network create proxy
        log_success "proxy network created"
    else
        log_success "proxy network already exists"
    fi
}

# Main startup sequence
main() {
    log "========================================"
    log "Homelab Services Startup"
    log "========================================"
    echo ""

    # Phase 0: Start Tailscale VPN and SSH
    log "Phase 0: Starting Tailscale VPN and SSH..."
    start_tailscale

    log "Starting SSH service..."
    if sudo systemctl start ssh 2>/dev/null; then
        log_success "SSH service started"
    else
        log_warning "SSH service may already be running or not installed"
    fi
    echo ""

    # Check prerequisites
    check_docker
    create_networks

    echo ""
    log "========================================"
    log "Starting services in dependency order"
    log "========================================"
    echo ""

    # Phase 1: Start PostgreSQL (required by Gitea and Immich)
    log "Phase 1: Starting database services..."
    log "Starting PostgreSQL (pgAdmin excluded - start manually if needed)..."

    cd "${PROJECT_ROOT}/platform/postgres"
    if docker compose up -d postgres; then
        log_success "PostgreSQL started successfully"
    else
        log_error "Failed to start PostgreSQL"
        exit 1
    fi

    wait_for_postgres || exit 1
    echo ""

    # Phase 2: Start services that depend on PostgreSQL
    log "Phase 2: Starting database-dependent services..."
    start_service "Gitea" "platform/gitea" || log_warning "Gitea failed to start, continuing..."
    start_service "Immich" "apps/immich" || log_warning "Immich failed to start, continuing..."
    echo ""

    # Phase 3: Start independent services
    log "Phase 3: Starting independent services..."
    start_service "Homepage" "apps/homepage" || log_warning "Homepage failed to start, continuing..."
    start_service "Pi-hole" "apps/pi-hole" || log_warning "Pi-hole failed to start, continuing..."
    echo ""

    # Phase 4: Start monitoring stack
    log "Phase 4: Starting monitoring services..."
    start_service "Monitoring (Prometheus, Grafana, Loki)" "system/monitoring" || log_warning "Monitoring failed to start, continuing..."
    echo ""

    # Summary
    log "========================================"
    log "Startup Complete"
    log "========================================"
    echo ""
    log "Checking running containers..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    log_success "All services startup sequence completed!"
    echo ""
    log "Access points:"
    log "  - Homepage:    http://homelab-01/"
    log "  - Immich:      http://localhost:2283"
    log "  - Pi-hole:     http://localhost:8080/admin"
    log "  - Grafana:     http://localhost:3002"
    log "  - Prometheus:  http://localhost:9091"
    echo ""
    log "To start pgAdmin manually:"
    log "  cd platform/postgres && docker compose up -d pgadmin"
    echo ""
}

# Run main function
main "$@"
