#!/bin/bash
# Immich Restore Script
# Restores Immich data from backup

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/mnt/backup/immich-backup"
IMMICH_UPLOAD_DIR="/home/loki3/immich"
IMMICH_COMPOSE_DIR="$HOME/github/homelab/apps/immich"

# Database configuration
DB_NAME="immich"
DB_USER="postgres"
DB_PASSWORD="changeit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

# List available backups
list_backups() {
    log_info "Available backups:"
    echo ""
    ls -lt "${BACKUP_ROOT}" | grep "^d" | awk '{print $9}' | nl
    echo ""
}

# Select backup to restore
select_backup() {
    list_backups

    read -p "Enter backup number to restore (or 'q' to quit): " backup_num

    if [[ "$backup_num" == "q" ]]; then
        log_info "Restore cancelled"
        exit 0
    fi

    BACKUP_DIR=$(ls -t "${BACKUP_ROOT}" | sed -n "${backup_num}p")

    if [[ -z "$BACKUP_DIR" ]]; then
        log_error "Invalid backup number"
        exit 1
    fi

    BACKUP_PATH="${BACKUP_ROOT}/${BACKUP_DIR}"
    log_info "Selected backup: ${BACKUP_DIR}"

    # Show manifest if available
    if [[ -f "${BACKUP_PATH}/backup-manifest.txt" ]]; then
        echo ""
        cat "${BACKUP_PATH}/backup-manifest.txt"
        echo ""
    fi
}

# Confirm restore
confirm_restore() {
    log_error "WARNING: This will OVERWRITE existing Immich data!"
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
}

# Stop Immich services
stop_immich() {
    log_info "Stopping Immich services..."
    cd "${IMMICH_COMPOSE_DIR}"
    docker compose down
    log_success "Immich services stopped"
}

# Start Immich services
start_immich() {
    log_info "Starting Immich services..."
    cd "${IMMICH_COMPOSE_DIR}"
    docker compose up -d
    log_success "Immich services started"
}

# Restore uploads directory
restore_uploads() {
    log_info "Restoring uploads directory..."

    # Backup existing data
    if [[ -d "${IMMICH_UPLOAD_DIR}" ]]; then
        log_info "Backing up existing uploads to ${IMMICH_UPLOAD_DIR}.old"
        mv "${IMMICH_UPLOAD_DIR}" "${IMMICH_UPLOAD_DIR}.old"
    fi

    # Restore from backup
    mkdir -p "${IMMICH_UPLOAD_DIR}"
    rsync -av --info=progress2 "${BACKUP_PATH}/uploads/" "${IMMICH_UPLOAD_DIR}/"

    # Set correct permissions
    sudo chown -R 1000:1000 "${IMMICH_UPLOAD_DIR}"

    log_success "Uploads directory restored"
}

# Restore database
restore_database() {
    log_info "Restoring database..."

    # Drop and recreate database
    docker exec postgres psql -U "${DB_USER}" -c "DROP DATABASE IF EXISTS ${DB_NAME};"
    docker exec postgres psql -U "${DB_USER}" -c "CREATE DATABASE ${DB_NAME};"

    # Restore from backup
    gunzip -c "${BACKUP_PATH}/database/immich_backup.sql.gz" | \
        docker exec -i postgres psql -U "${DB_USER}" -d "${DB_NAME}"

    log_success "Database restored"
}

# Restore Docker volumes
restore_volumes() {
    log_info "Restoring Docker volumes..."

    # Remove existing volumes
    docker volume rm -f immich-model-cache immich-redis-data 2>/dev/null || true

    # Restore model cache volume
    log_info "Restoring immich-model-cache volume..."
    docker volume create immich-model-cache
    docker run --rm \
        -v immich-model-cache:/data \
        -v "${BACKUP_PATH}/volumes":/backup \
        alpine tar xzf /backup/immich-model-cache.tar.gz -C /data

    # Restore redis data volume
    log_info "Restoring immich-redis-data volume..."
    docker volume create immich-redis-data
    docker run --rm \
        -v immich-redis-data:/data \
        -v "${BACKUP_PATH}/volumes":/backup \
        alpine tar xzf /backup/immich-redis-data.tar.gz -C /data

    log_success "Docker volumes restored"
}

# Main restore process
main() {
    echo "========================================="
    echo "Immich Restore Process"
    echo "========================================="

    # Check if backup drive is mounted
    if ! mountpoint -q /mnt/backup; then
        log_error "Backup drive is not mounted at /mnt/backup"
        log_info "Please mount the drive first: sudo mount /dev/sdc1 /mnt/backup"
        exit 1
    fi

    # Select backup
    select_backup

    # Confirm restore
    confirm_restore

    # Stop services
    stop_immich

    # Perform restore
    restore_uploads
    restore_database
    restore_volumes

    # Start services
    start_immich

    echo "========================================="
    log_success "Restore completed successfully!"
    log_info "Immich should now be running with restored data"
    log_info "Access it at: http://localhost:2283"
    echo "========================================="
}

# Run main function
main
