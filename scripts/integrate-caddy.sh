#!/bin/bash

# Integrate Caddy with Existing Services
# This script updates docker-compose.yml files to add proxy network connectivity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Backup a file
backup_file() {
    local file=$1
    local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$backup"
    log_success "Backed up: $backup"
}

# Update Gitea docker-compose.yml
update_gitea() {
    log "Updating Gitea configuration..."
    local compose_file="${PROJECT_ROOT}/infrastructure/gitea/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        log_error "Gitea docker-compose.yml not found"
        return 1
    fi

    # Check if already configured
    if grep -q "proxy:" "$compose_file"; then
        log_warning "Gitea already has proxy network configured"
        return 0
    fi

    backup_file "$compose_file"

    # Add proxy to networks section of service
    sed -i.tmp '/networks:/a\      - proxy' "$compose_file"

    # Add proxy network definition if not exists
    if ! grep -q "^  proxy:" "$compose_file"; then
        echo "  proxy:" >> "$compose_file"
        echo "    external: true" >> "$compose_file"
    fi

    rm -f "${compose_file}.tmp"
    log_success "Gitea configuration updated"
}

# Update Immich docker-compose.yml
update_immich() {
    log "Updating Immich configuration..."
    local compose_file="${PROJECT_ROOT}/apps/immich/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        log_error "Immich docker-compose.yml not found"
        return 1
    fi

    if grep -q "proxy:" "$compose_file"; then
        log_warning "Immich already has proxy network configured"
        return 0
    fi

    backup_file "$compose_file"

    # Find the immich-server service networks section and add proxy
    # This is a bit complex because we need to add it to the right service
    awk '
    /^  immich-server:/ { in_server=1 }
    /^  immich-machine-learning:/ { in_server=0 }
    /^    networks:/ && in_server {
        print
        print "      - proxy"
        next
    }
    { print }
    ' "$compose_file" > "${compose_file}.new"

    mv "${compose_file}.new" "$compose_file"

    # Add proxy network definition if not exists
    if ! grep -q "^  proxy:" "$compose_file"; then
        echo "  proxy:" >> "$compose_file"
        echo "    external: true" >> "$compose_file"
    fi

    log_success "Immich configuration updated"
}

# Update Monitoring docker-compose.yml
update_monitoring() {
    log "Updating Monitoring configuration..."
    local compose_file="${PROJECT_ROOT}/system/monitoring/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        log_error "Monitoring docker-compose.yml not found"
        return 1
    fi

    # Grafana already has proxy, so we need to add it to Prometheus and Loki
    backup_file "$compose_file"

    local updated=false

    # Add proxy to Prometheus if not present
    if ! awk '/^  prometheus:/,/^  grafana:/ {if (/proxy/) exit 0} END {exit 1}' "$compose_file"; then
        log_warning "Prometheus already has proxy network"
    else
        # Add proxy to prometheus networks
        sed -i.tmp '/^  prometheus:/,/^  grafana:/ {/networks:/a\      - proxy
}' "$compose_file"
        updated=true
    fi

    # Add proxy to Loki if not present
    if ! awk '/^  loki:/,/^  promtail:/ {if (/proxy/) exit 0} END {exit 1}' "$compose_file"; then
        log_warning "Loki already has proxy network"
    else
        # Add proxy to loki networks
        sed -i.tmp '/^  loki:/,/^  promtail:/ {/networks:/a\      - proxy
}' "$compose_file"
        updated=true
    fi

    rm -f "${compose_file}.tmp"

    if [ "$updated" = true ]; then
        log_success "Monitoring configuration updated"
    else
        log_warning "Monitoring already configured"
    fi
}

# Main function
main() {
    echo "========================================="
    echo "Caddy Integration Script"
    echo "========================================="
    echo
    log "This script will update docker-compose.yml files to add proxy network"
    log "Backups will be created for all modified files"
    echo

    # Confirm before proceeding
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Aborted by user"
        exit 0
    fi

    echo
    log "Starting integration..."
    echo

    # Update services
    update_gitea || log_warning "Failed to update Gitea"
    echo
    update_immich || log_warning "Failed to update Immich"
    echo
    update_monitoring || log_warning "Failed to update Monitoring"
    echo

    echo "========================================="
    log_success "Integration complete!"
    echo "========================================="
    echo
    log "Next steps:"
    log "1. Review the changes in each docker-compose.yml file"
    log "2. Restart services: cd <service-dir> && docker compose down && docker compose up -d"
    log "3. Start Caddy: cd system/caddy && docker compose up -d"
    log "4. Test access: curl -k https://immich.homelab.com"
    echo
    log "Backup files created with .backup-* extension"
    log "To rollback, restore from backups: mv file.backup-* docker-compose.yml"
    echo
}

# Run main function
main "$@"
