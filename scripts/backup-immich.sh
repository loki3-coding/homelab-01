#!/bin/bash
# Immich Backup Script
# Backs up Immich data (uploads, database, and Docker volumes) to external HDD

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/mnt/backup/immich-backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
LOG_FILE="${BACKUP_ROOT}/backup.log"

# Immich paths
IMMICH_UPLOAD_DIR="/home/loki3/immich"
IMMICH_COMPOSE_DIR="$HOME/github/homelab/apps/immich"

# Database configuration (from .env file)
DB_NAME="immich"
DB_USER="postgres"
DB_PASSWORD="changeit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${YELLOW}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Check if backup drive is mounted
check_backup_drive() {
    if ! mountpoint -q /mnt/backup; then
        log_error "Backup drive is not mounted at /mnt/backup"
        log_info "Please mount the drive first: sudo mount /dev/sdc1 /mnt/backup"
        exit 1
    fi
    log_success "Backup drive is mounted"
}

# Create backup directory structure
create_backup_dirs() {
    mkdir -p "${BACKUP_DIR}"/{uploads,database,volumes}
    log_success "Created backup directory: ${BACKUP_DIR}"
}

# Stop Immich services
stop_immich() {
    log_info "Stopping Immich services..."
    cd "${IMMICH_COMPOSE_DIR}"
    docker compose stop
    log_success "Immich services stopped"
}

# Start Immich services
start_immich() {
    log_info "Starting Immich services..."
    cd "${IMMICH_COMPOSE_DIR}"
    docker compose up -d
    log_success "Immich services started"
}

# Backup upload directory
backup_uploads() {
    log_info "Backing up Immich uploads directory..."
    log_info "Source: ${IMMICH_UPLOAD_DIR}"
    log_info "Destination: ${BACKUP_DIR}/uploads/"

    # Find most recent backup for incremental backup with hard links
    # Exclude the current backup directory being created
    CURRENT_DIR=$(basename "${BACKUP_DIR}")
    LATEST_BACKUP=$(ls -t "${BACKUP_ROOT}" 2>/dev/null | grep -E '^[0-9]{8}_[0-9]{6}$' | grep -v "^${CURRENT_DIR}$" | head -1)

    if [ -n "$LATEST_BACKUP" ] && [ -d "${BACKUP_ROOT}/${LATEST_BACKUP}/uploads" ]; then
        log_info "Found previous backup: ${LATEST_BACKUP}"
        log_info "Using incremental backup with hard links..."
        # Incremental: only changed files take new space, unchanged files are hard-linked
        rsync -av --info=progress2 --link-dest="${BACKUP_ROOT}/${LATEST_BACKUP}/uploads" \
            "${IMMICH_UPLOAD_DIR}/" "${BACKUP_DIR}/uploads/"
    else
        log_info "No previous backup found. Performing full backup..."
        # First backup: full copy
        rsync -av --info=progress2 "${IMMICH_UPLOAD_DIR}/" "${BACKUP_DIR}/uploads/"
    fi

    UPLOAD_SIZE=$(du -sh "${BACKUP_DIR}/uploads" | cut -f1)
    log_success "Upload directory backup complete (${UPLOAD_SIZE})"
}

# Backup Postgres database
backup_database() {
    log_info "Backing up Immich database..."

    # Export database to SQL file
    docker exec postgres pg_dump -U "${DB_USER}" "${DB_NAME}" > "${BACKUP_DIR}/database/immich_backup.sql"

    # Compress the SQL file
    gzip "${BACKUP_DIR}/database/immich_backup.sql"

    DB_SIZE=$(du -sh "${BACKUP_DIR}/database/immich_backup.sql.gz" | cut -f1)
    log_success "Database backup complete (${DB_SIZE})"
}

# Backup Docker volumes
backup_volumes() {
    log_info "Backing up Docker volumes..."

    # Backup model cache volume
    log_info "Backing up immich-model-cache volume..."
    docker run --rm \
        -v immich-model-cache:/data \
        -v "${BACKUP_DIR}/volumes":/backup \
        alpine tar czf /backup/immich-model-cache.tar.gz -C /data .

    # Backup redis data volume
    log_info "Backing up immich-redis-data volume..."
    docker run --rm \
        -v immich-redis-data:/data \
        -v "${BACKUP_DIR}/volumes":/backup \
        alpine tar czf /backup/immich-redis-data.tar.gz -C /data .

    log_success "Docker volumes backup complete"
}

# Create backup manifest
create_manifest() {
    log_info "Creating backup manifest..."

    MANIFEST_FILE="${BACKUP_DIR}/backup-manifest.txt"

    cat > "${MANIFEST_FILE}" <<EOF
Immich Backup Manifest
=====================
Backup Date: $(date)
Backup Directory: ${BACKUP_DIR}

Contents:
---------
1. Uploads Directory: ${IMMICH_UPLOAD_DIR}
   - Location: ${BACKUP_DIR}/uploads/
   - Size: $(du -sh "${BACKUP_DIR}/uploads" | cut -f1)

2. Database: ${DB_NAME}
   - Location: ${BACKUP_DIR}/database/immich_backup.sql.gz
   - Size: $(du -sh "${BACKUP_DIR}/database/immich_backup.sql.gz" | cut -f1)

3. Docker Volumes:
   - Model Cache: ${BACKUP_DIR}/volumes/immich-model-cache.tar.gz
     Size: $(du -sh "${BACKUP_DIR}/volumes/immich-model-cache.tar.gz" | cut -f1)
   - Redis Data: ${BACKUP_DIR}/volumes/immich-redis-data.tar.gz
     Size: $(du -sh "${BACKUP_DIR}/volumes/immich-redis-data.tar.gz" | cut -f1)

Total Backup Size: $(du -sh "${BACKUP_DIR}" | cut -f1)

File Count:
-----------
$(find "${BACKUP_DIR}/uploads" -type f | wc -l) files in uploads directory

Checksums:
----------
$(cd "${BACKUP_DIR}" && find . -type f -exec sha256sum {} \; | sort)
EOF

    log_success "Backup manifest created"
}

# Cleanup old backups (keep last 3)
cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last 3)..."

    cd "${BACKUP_ROOT}"
    ls -t | tail -n +4 | xargs -I {} rm -rf {}

    log_success "Cleanup complete"
}

# Main backup process
main() {
    # Create backup root directory first (needed for logging)
    mkdir -p "${BACKUP_ROOT}"

    log "========================================="
    log "Starting Immich Backup Process"
    log "========================================="

    # Check prerequisites
    check_backup_drive

    # Create backup directories
    create_backup_dirs

    # Stop services for consistent backup
    stop_immich

    # Perform backups
    backup_uploads
    backup_database
    backup_volumes

    # Start services
    start_immich

    # Create manifest
    create_manifest

    # Cleanup old backups
    cleanup_old_backups

    log "========================================="
    log_success "Backup completed successfully!"
    log "Backup location: ${BACKUP_DIR}"
    log "Total size: $(du -sh "${BACKUP_DIR}" | cut -f1)"
    log "========================================="

    # Display disk usage
    log_info "Backup drive usage:"
    df -h /mnt/backup | tee -a "$LOG_FILE"
}

# Run main function
main
