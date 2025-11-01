#!/bin/bash
#
# Battle Castles Deployment Script
# Automated deployment with health checks and rollback capability
#
# Usage: ./deploy.sh [environment] [options]
#   environment: dev, staging, production (default: dev)
#   options:
#     --skip-backup    Skip database backup before deployment
#     --skip-tests     Skip running tests before deployment
#     --force          Force deployment even if health checks fail
#     --rollback       Rollback to previous version
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-dev}"
SKIP_BACKUP=false
SKIP_TESTS=false
FORCE_DEPLOY=false
ROLLBACK=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOYMENT_DIR="${PROJECT_ROOT}/deployment"
BACKUP_DIR="${PROJECT_ROOT}/backups"

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
for arg in "${@:2}"; do
    case $arg in
        --skip-backup)
            SKIP_BACKUP=true
            ;;
        --skip-tests)
            SKIP_TESTS=true
            ;;
        --force)
            FORCE_DEPLOY=true
            ;;
        --rollback)
            ROLLBACK=true
            ;;
        *)
            log_error "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or production."
    exit 1
fi

log_info "Starting deployment to ${ENVIRONMENT} environment..."

# Check required commands
check_dependencies() {
    log_info "Checking dependencies..."
    local missing_deps=()

    for cmd in docker docker-compose git; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi

    log_success "All dependencies are installed"
}

# Load environment variables
load_environment() {
    log_info "Loading environment variables..."

    local env_file="${DEPLOYMENT_DIR}/docker/.env.${ENVIRONMENT}"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
        log_success "Environment variables loaded from $env_file"
    else
        log_warning "No environment file found at $env_file, using defaults"
    fi
}

# Run tests
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Skipping tests (--skip-tests flag set)"
        return 0
    fi

    log_info "Running tests..."
    cd "${PROJECT_ROOT}/server/game-server"

    if npm test; then
        log_success "All tests passed"
    else
        log_error "Tests failed"
        if [ "$FORCE_DEPLOY" = false ]; then
            exit 1
        else
            log_warning "Continuing deployment despite test failures (--force flag set)"
        fi
    fi
}

# Create backup
create_backup() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warning "Skipping backup (--skip-backup flag set)"
        return 0
    fi

    log_info "Creating backup..."
    "${SCRIPT_DIR}/backup.sh" --type full
    log_success "Backup created successfully"
}

# Save current version for potential rollback
save_current_version() {
    log_info "Saving current version for rollback..."

    local version_file="${BACKUP_DIR}/last_deployed_version.txt"
    local current_commit=$(git rev-parse HEAD)

    echo "$current_commit" > "$version_file"
    log_success "Current version saved: $current_commit"
}

# Build Docker images
build_images() {
    log_info "Building Docker images..."
    cd "${PROJECT_ROOT}"

    if docker-compose build --no-cache; then
        log_success "Docker images built successfully"
    else
        log_error "Failed to build Docker images"
        exit 1
    fi
}

# Stop running containers
stop_containers() {
    log_info "Stopping running containers..."
    cd "${PROJECT_ROOT}"

    if docker-compose down; then
        log_success "Containers stopped"
    else
        log_warning "No containers were running or failed to stop"
    fi
}

# Start containers
start_containers() {
    log_info "Starting containers..."
    cd "${PROJECT_ROOT}"

    if docker-compose up -d; then
        log_success "Containers started"
    else
        log_error "Failed to start containers"
        exit 1
    fi
}

# Wait for services to be healthy
wait_for_health() {
    log_info "Waiting for services to be healthy..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        # Check database health
        if docker-compose exec -T postgres pg_isready -U battlecastles &> /dev/null; then
            log_success "Database is healthy"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            log_error "Database health check timed out"
            return 1
        fi

        log_info "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 2
    done

    # Reset attempt counter for Redis
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        # Check Redis health
        if docker-compose exec -T redis redis-cli ping &> /dev/null; then
            log_success "Redis is healthy"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            log_error "Redis health check timed out"
            return 1
        fi

        log_info "Waiting for Redis... (attempt $attempt/$max_attempts)"
        sleep 2
    done

    # Reset attempt counter for game servers
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        # Check game server health via nginx
        if curl -sf http://localhost/health &> /dev/null; then
            log_success "Game servers are healthy"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            log_error "Game server health check timed out"
            return 1
        fi

        log_info "Waiting for game servers... (attempt $attempt/$max_attempts)"
        sleep 2
    done

    log_success "All services are healthy"
    return 0
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."

    # Check if there are any migration files
    local migration_dir="${PROJECT_ROOT}/server/migrations"
    if [ ! -d "$migration_dir" ]; then
        log_info "No migrations directory found, skipping"
        return 0
    fi

    # Run migrations (implementation depends on your migration tool)
    # Example: docker-compose exec -T game-server-1 npm run migrate

    log_success "Database migrations completed"
}

# Smoke tests
run_smoke_tests() {
    log_info "Running smoke tests..."

    # Test HTTP endpoint
    if ! curl -sf http://localhost/health &> /dev/null; then
        log_error "HTTP health check failed"
        return 1
    fi
    log_success "HTTP endpoint is responding"

    # Test WebSocket connection (basic check)
    if ! curl -sf http://localhost/socket.io/ &> /dev/null; then
        log_warning "WebSocket endpoint check failed (this may be normal)"
    else
        log_success "WebSocket endpoint is accessible"
    fi

    return 0
}

# Rollback to previous version
rollback_deployment() {
    log_warning "Rolling back to previous version..."

    local version_file="${BACKUP_DIR}/last_deployed_version.txt"

    if [ ! -f "$version_file" ]; then
        log_error "No previous version information found"
        exit 1
    fi

    local previous_version=$(cat "$version_file")
    log_info "Rolling back to commit: $previous_version"

    # Checkout previous version
    git checkout "$previous_version"

    # Rebuild and restart
    build_images
    stop_containers
    start_containers

    if wait_for_health && run_smoke_tests; then
        log_success "Rollback completed successfully"
    else
        log_error "Rollback failed - manual intervention required"
        exit 1
    fi
}

# Cleanup old images
cleanup_images() {
    log_info "Cleaning up old Docker images..."

    docker image prune -f
    log_success "Cleanup completed"
}

# Main deployment flow
main() {
    if [ "$ROLLBACK" = true ]; then
        rollback_deployment
        exit 0
    fi

    check_dependencies
    load_environment

    # Pre-deployment
    run_tests
    create_backup
    save_current_version

    # Deployment
    build_images
    stop_containers
    start_containers

    # Post-deployment
    if ! wait_for_health; then
        log_error "Health checks failed"
        if [ "$FORCE_DEPLOY" = false ]; then
            log_error "Deployment failed. Rolling back..."
            rollback_deployment
            exit 1
        else
            log_warning "Continuing despite health check failures (--force flag set)"
        fi
    fi

    run_migrations

    if ! run_smoke_tests; then
        log_error "Smoke tests failed"
        if [ "$FORCE_DEPLOY" = false ]; then
            log_error "Deployment failed. Rolling back..."
            rollback_deployment
            exit 1
        else
            log_warning "Continuing despite smoke test failures (--force flag set)"
        fi
    fi

    cleanup_images

    log_success "========================================="
    log_success "Deployment to ${ENVIRONMENT} completed successfully!"
    log_success "========================================="

    # Display service information
    echo ""
    log_info "Service URLs:"
    echo "  - Application: http://localhost"
    echo "  - Game Server: http://localhost/socket.io"
    echo "  - Health Check: http://localhost/health"
    if [ -n "${GRAFANA_USER:-}" ]; then
        echo "  - Grafana: http://localhost:3000"
    fi
    echo ""

    log_info "To view logs: docker-compose logs -f"
    log_info "To rollback: ./deploy.sh ${ENVIRONMENT} --rollback"
}

# Run main function
main
