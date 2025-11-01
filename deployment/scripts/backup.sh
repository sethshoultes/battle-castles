#!/bin/bash
#
# Battle Castles Backup Script
# Automated backup for database and configuration files
#
# Usage: ./backup.sh [options]
#   options:
#     --type <full|db|config>  Type of backup (default: full)
#     --output <path>          Output directory (default: ./backups)
#     --retention <days>       Days to retain backups (default: 7)
#     --s3                     Upload backup to S3
#     --restore <backup-file>  Restore from backup
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BACKUP_TYPE="full"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups"
RETENTION_DAYS=7
UPLOAD_S3=false
RESTORE_FILE=""

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --output)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --s3)
            UPLOAD_S3=true
            shift
            ;;
        --restore)
            RESTORE_FILE="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate backup type
if [[ ! "$BACKUP_TYPE" =~ ^(full|db|config)$ ]]; then
    log_error "Invalid backup type: $BACKUP_TYPE. Must be full, db, or config."
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Load environment variables
load_environment() {
    local env_file="${PROJECT_ROOT}/deployment/docker/.env"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
    fi
}

# Database backup
backup_database() {
    log_info "Backing up PostgreSQL database..."

    local db_backup_file="${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql.gz"

    # Check if postgres container is running
    if ! docker ps | grep -q battle-castles-postgres; then
        log_error "PostgreSQL container is not running"
        return 1
    fi

    # Create database dump
    if docker exec battle-castles-postgres pg_dump \
        -U "${POSTGRES_USER:-battlecastles}" \
        -d "${POSTGRES_DB:-battlecastles}" \
        --clean --if-exists \
        | gzip > "$db_backup_file"; then

        local size=$(du -h "$db_backup_file" | cut -f1)
        log_success "Database backup created: $db_backup_file ($size)"
        echo "$db_backup_file"
    else
        log_error "Failed to create database backup"
        return 1
    fi
}

# Redis backup
backup_redis() {
    log_info "Backing up Redis data..."

    local redis_backup_file="${BACKUP_DIR}/redis_backup_${TIMESTAMP}.rdb"

    # Check if redis container is running
    if ! docker ps | grep -q battle-castles-redis; then
        log_error "Redis container is not running"
        return 1
    fi

    # Trigger Redis save
    docker exec battle-castles-redis redis-cli SAVE

    # Copy RDB file
    if docker cp battle-castles-redis:/data/dump.rdb "$redis_backup_file"; then
        local size=$(du -h "$redis_backup_file" | cut -f1)
        log_success "Redis backup created: $redis_backup_file ($size)"
        echo "$redis_backup_file"
    else
        log_error "Failed to create Redis backup"
        return 1
    fi
}

# Configuration backup
backup_configuration() {
    log_info "Backing up configuration files..."

    local config_backup_file="${BACKUP_DIR}/config_backup_${TIMESTAMP}.tar.gz"

    # Create tar archive of configuration files
    tar -czf "$config_backup_file" \
        -C "${PROJECT_ROOT}" \
        deployment/docker/.env* \
        deployment/nginx/nginx.conf \
        deployment/nginx/conf.d \
        docker-compose.yml \
        2>/dev/null || true

    if [ -f "$config_backup_file" ]; then
        local size=$(du -h "$config_backup_file" | cut -f1)
        log_success "Configuration backup created: $config_backup_file ($size)"
        echo "$config_backup_file"
    else
        log_error "Failed to create configuration backup"
        return 1
    fi
}

# Logs backup
backup_logs() {
    log_info "Backing up application logs..."

    local logs_backup_file="${BACKUP_DIR}/logs_backup_${TIMESTAMP}.tar.gz"

    # Check if log volumes exist
    if docker volume ls | grep -q game_server.*logs; then
        # Create temporary directory for logs
        local temp_logs_dir="${BACKUP_DIR}/temp_logs_${TIMESTAMP}"
        mkdir -p "$temp_logs_dir"

        # Copy logs from Docker volumes
        for volume in $(docker volume ls -q | grep game_server.*logs); do
            local container_name=$(echo "$volume" | sed 's/_logs$//')
            if docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
                docker cp "${container_name}:/app/logs" "${temp_logs_dir}/${container_name}_logs" 2>/dev/null || true
            fi
        done

        # Also get nginx logs
        if docker ps | grep -q battle-castles-nginx; then
            docker cp battle-castles-nginx:/var/log/nginx "${temp_logs_dir}/nginx_logs" 2>/dev/null || true
        fi

        # Create tar archive
        tar -czf "$logs_backup_file" -C "$temp_logs_dir" . 2>/dev/null

        # Cleanup temp directory
        rm -rf "$temp_logs_dir"

        if [ -f "$logs_backup_file" ]; then
            local size=$(du -h "$logs_backup_file" | cut -f1)
            log_success "Logs backup created: $logs_backup_file ($size)"
            echo "$logs_backup_file"
        fi
    else
        log_warning "No log volumes found, skipping logs backup"
    fi
}

# Full backup
backup_full() {
    log_info "Performing full backup..."

    local backup_manifest="${BACKUP_DIR}/backup_manifest_${TIMESTAMP}.txt"
    echo "Battle Castles Full Backup - ${TIMESTAMP}" > "$backup_manifest"
    echo "========================================" >> "$backup_manifest"
    echo "" >> "$backup_manifest"

    # Backup database
    local db_file=$(backup_database)
    echo "Database: $(basename $db_file)" >> "$backup_manifest"

    # Backup Redis
    local redis_file=$(backup_redis)
    echo "Redis: $(basename $redis_file)" >> "$backup_manifest"

    # Backup configuration
    local config_file=$(backup_configuration)
    echo "Config: $(basename $config_file)" >> "$backup_manifest"

    # Backup logs
    local logs_file=$(backup_logs)
    if [ -n "$logs_file" ]; then
        echo "Logs: $(basename $logs_file)" >> "$backup_manifest"
    fi

    echo "" >> "$backup_manifest"
    echo "Backup completed at: $(date)" >> "$backup_manifest"

    log_success "Full backup completed. Manifest: $backup_manifest"
}

# Upload to S3
upload_to_s3() {
    if [ "$UPLOAD_S3" = false ]; then
        return 0
    fi

    log_info "Uploading backups to S3..."

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Install it to enable S3 uploads."
        return 1
    fi

    # Check if S3 bucket is configured
    if [ -z "${S3_BUCKET_NAME:-}" ]; then
        log_error "S3_BUCKET_NAME not configured in environment"
        return 1
    fi

    # Upload all files from today's backup
    local files_to_upload=$(find "${BACKUP_DIR}" -type f -name "*${TIMESTAMP}*")

    for file in $files_to_upload; do
        local s3_path="s3://${S3_BUCKET_NAME}/backups/$(basename $file)"

        if aws s3 cp "$file" "$s3_path" --storage-class STANDARD_IA; then
            log_success "Uploaded to S3: $(basename $file)"
        else
            log_error "Failed to upload to S3: $(basename $file)"
        fi
    done
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."

    local deleted_count=0

    # Find and delete old backup files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        deleted_count=$((deleted_count + 1))
    done < <(find "${BACKUP_DIR}" -type f -mtime +${RETENTION_DAYS} -print0)

    if [ $deleted_count -gt 0 ]; then
        log_success "Deleted $deleted_count old backup file(s)"
    else
        log_info "No old backups to clean up"
    fi
}

# Restore database
restore_database() {
    log_info "Restoring database from backup..."

    if [ ! -f "$RESTORE_FILE" ]; then
        log_error "Backup file not found: $RESTORE_FILE"
        return 1
    fi

    # Check if it's a gzipped file
    if [[ "$RESTORE_FILE" == *.gz ]]; then
        gunzip -c "$RESTORE_FILE" | docker exec -i battle-castles-postgres \
            psql -U "${POSTGRES_USER:-battlecastles}" -d "${POSTGRES_DB:-battlecastles}"
    else
        docker exec -i battle-castles-postgres \
            psql -U "${POSTGRES_USER:-battlecastles}" -d "${POSTGRES_DB:-battlecastles}" < "$RESTORE_FILE"
    fi

    if [ $? -eq 0 ]; then
        log_success "Database restored successfully"
    else
        log_error "Failed to restore database"
        return 1
    fi
}

# Restore Redis
restore_redis() {
    log_info "Restoring Redis from backup..."

    if [ ! -f "$RESTORE_FILE" ]; then
        log_error "Backup file not found: $RESTORE_FILE"
        return 1
    fi

    # Stop Redis
    docker stop battle-castles-redis

    # Copy RDB file
    docker cp "$RESTORE_FILE" battle-castles-redis:/data/dump.rdb

    # Start Redis
    docker start battle-castles-redis

    # Wait for Redis to be ready
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec battle-castles-redis redis-cli ping &> /dev/null; then
            log_success "Redis restored and running"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Redis failed to start after restore"
    return 1
}

# Restore configuration
restore_configuration() {
    log_info "Restoring configuration from backup..."

    if [ ! -f "$RESTORE_FILE" ]; then
        log_error "Backup file not found: $RESTORE_FILE"
        return 1
    fi

    # Extract configuration backup
    tar -xzf "$RESTORE_FILE" -C "${PROJECT_ROOT}"

    log_success "Configuration restored successfully"
}

# Main function
main() {
    load_environment

    # Restore mode
    if [ -n "$RESTORE_FILE" ]; then
        log_warning "RESTORE MODE - This will overwrite existing data!"
        read -p "Are you sure you want to continue? (yes/no): " confirm

        if [ "$confirm" != "yes" ]; then
            log_info "Restore cancelled"
            exit 0
        fi

        # Determine restore type from file extension
        if [[ "$RESTORE_FILE" == *db_backup* ]]; then
            restore_database
        elif [[ "$RESTORE_FILE" == *redis_backup* ]]; then
            restore_redis
        elif [[ "$RESTORE_FILE" == *config_backup* ]]; then
            restore_configuration
        else
            log_error "Unknown backup file type"
            exit 1
        fi
        exit 0
    fi

    # Backup mode
    log_info "Starting ${BACKUP_TYPE} backup..."

    case $BACKUP_TYPE in
        db)
            backup_database
            ;;
        config)
            backup_configuration
            ;;
        full)
            backup_full
            ;;
    esac

    upload_to_s3
    cleanup_old_backups

    log_success "========================================="
    log_success "Backup completed successfully!"
    log_success "========================================="
    log_info "Backup location: ${BACKUP_DIR}"
    log_info "Backup timestamp: ${TIMESTAMP}"
}

# Run main function
main
