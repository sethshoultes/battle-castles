# Battle Castles Makefile
# Convenient commands for development and deployment

.PHONY: help install build dev test lint deploy clean backup restore logs status

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_COMPOSE := docker-compose
KUBECTL := kubectl
NAMESPACE := battlecastles

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

##@ General

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(BLUE)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

install: ## Install dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	cd server/game-server && npm install

build: ## Build Docker images
	@echo "$(GREEN)Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache

dev: ## Start development environment
	@echo "$(GREEN)Starting development environment...$(NC)"
	$(DOCKER_COMPOSE) up

dev-detached: ## Start development environment in background
	@echo "$(GREEN)Starting development environment in background...$(NC)"
	$(DOCKER_COMPOSE) up -d

dev-with-monitoring: ## Start development environment with monitoring
	@echo "$(GREEN)Starting development environment with monitoring...$(NC)"
	$(DOCKER_COMPOSE) --profile monitoring up -d

##@ Testing

test: ## Run all tests
	@echo "$(GREEN)Running tests...$(NC)"
	cd server/game-server && npm test

test-watch: ## Run tests in watch mode
	@echo "$(GREEN)Running tests in watch mode...$(NC)"
	cd server/game-server && npm run test:watch

lint: ## Run linter
	@echo "$(GREEN)Running linter...$(NC)"
	cd server/game-server && npm run lint

##@ Deployment

deploy-dev: ## Deploy to development environment
	@echo "$(GREEN)Deploying to development...$(NC)"
	./deployment/scripts/deploy.sh dev

deploy-staging: ## Deploy to staging environment
	@echo "$(GREEN)Deploying to staging...$(NC)"
	./deployment/scripts/deploy.sh staging

deploy-prod: ## Deploy to production environment
	@echo "$(YELLOW)Deploying to production...$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	./deployment/scripts/deploy.sh production

rollback: ## Rollback to previous version
	@echo "$(YELLOW)Rolling back to previous version...$(NC)"
	./deployment/scripts/deploy.sh production --rollback

##@ Docker Operations

up: ## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	$(DOCKER_COMPOSE) up -d

down: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	$(DOCKER_COMPOSE) down

restart: ## Restart all services
	@echo "$(YELLOW)Restarting all services...$(NC)"
	$(DOCKER_COMPOSE) restart

logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-game: ## View game server logs
	$(DOCKER_COMPOSE) logs -f game-server-1 game-server-2

logs-db: ## View database logs
	$(DOCKER_COMPOSE) logs -f postgres

logs-redis: ## View Redis logs
	$(DOCKER_COMPOSE) logs -f redis

logs-nginx: ## View Nginx logs
	$(DOCKER_COMPOSE) logs -f nginx

status: ## Show status of all services
	@echo "$(BLUE)Docker Services:$(NC)"
	$(DOCKER_COMPOSE) ps

ps: status ## Alias for status

##@ Database

db-shell: ## Connect to PostgreSQL shell
	$(DOCKER_COMPOSE) exec postgres psql -U battlecastles -d battlecastles

db-migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(NC)"
	$(DOCKER_COMPOSE) exec game-server-1 npm run migrate

db-seed: ## Seed database with test data
	@echo "$(GREEN)Seeding database...$(NC)"
	$(DOCKER_COMPOSE) exec game-server-1 npm run seed

redis-shell: ## Connect to Redis CLI
	$(DOCKER_COMPOSE) exec redis redis-cli

##@ Backup & Restore

backup: ## Create full backup
	@echo "$(GREEN)Creating backup...$(NC)"
	./deployment/scripts/backup.sh --type full

backup-db: ## Backup database only
	@echo "$(GREEN)Backing up database...$(NC)"
	./deployment/scripts/backup.sh --type db

backup-config: ## Backup configuration only
	@echo "$(GREEN)Backing up configuration...$(NC)"
	./deployment/scripts/backup.sh --type config

backup-s3: ## Create backup and upload to S3
	@echo "$(GREEN)Creating backup and uploading to S3...$(NC)"
	./deployment/scripts/backup.sh --type full --s3

restore: ## Restore from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(YELLOW)Usage: make restore BACKUP_FILE=/path/to/backup.sql.gz$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from backup...$(NC)"
	./deployment/scripts/backup.sh --restore $(BACKUP_FILE)

##@ Kubernetes

k8s-deploy: ## Deploy to Kubernetes
	@echo "$(GREEN)Deploying to Kubernetes...$(NC)"
	$(KUBECTL) apply -k deployment/kubernetes

k8s-delete: ## Delete from Kubernetes
	@echo "$(YELLOW)Deleting from Kubernetes...$(NC)"
	$(KUBECTL) delete -k deployment/kubernetes

k8s-status: ## Show Kubernetes status
	@echo "$(BLUE)Kubernetes Resources:$(NC)"
	$(KUBECTL) get all -n $(NAMESPACE)

k8s-logs: ## View Kubernetes logs
	$(KUBECTL) logs -l app=game-server -n $(NAMESPACE) -f

k8s-shell: ## Connect to Kubernetes pod
	$(KUBECTL) exec -it deployment/game-server -n $(NAMESPACE) -- sh

k8s-port-forward: ## Port forward to game server
	$(KUBECTL) port-forward svc/game-server 3001:3001 -n $(NAMESPACE)

k8s-scale: ## Scale game servers (requires REPLICAS variable)
	@if [ -z "$(REPLICAS)" ]; then \
		echo "$(YELLOW)Usage: make k8s-scale REPLICAS=5$(NC)"; \
		exit 1; \
	fi
	$(KUBECTL) scale deployment game-server --replicas=$(REPLICAS) -n $(NAMESPACE)

##@ Monitoring

grafana: ## Open Grafana dashboard
	@echo "$(GREEN)Opening Grafana...$(NC)"
	open http://localhost:3000

prometheus: ## Open Prometheus dashboard
	@echo "$(GREEN)Opening Prometheus...$(NC)"
	open http://localhost:9090

metrics: ## Show metrics endpoint
	curl http://localhost:9100/metrics

health: ## Check health endpoint
	@echo "$(BLUE)Checking health...$(NC)"
	curl -s http://localhost/health | jq .

##@ Maintenance

clean: ## Clean up Docker resources
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	$(DOCKER_COMPOSE) down -v
	docker system prune -f

clean-all: ## Clean up everything including images
	@echo "$(YELLOW)WARNING: This will remove all Docker resources!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	$(DOCKER_COMPOSE) down -v --rmi all
	docker system prune -af --volumes

update-deps: ## Update dependencies
	@echo "$(GREEN)Updating dependencies...$(NC)"
	cd server/game-server && npm update

security-audit: ## Run security audit
	@echo "$(GREEN)Running security audit...$(NC)"
	cd server/game-server && npm audit

security-fix: ## Fix security vulnerabilities
	@echo "$(GREEN)Fixing security vulnerabilities...$(NC)"
	cd server/game-server && npm audit fix

##@ CI/CD

ci-build: ## CI build (no cache)
	@echo "$(GREEN)Building for CI...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache --pull

ci-test: ## CI tests
	@echo "$(GREEN)Running CI tests...$(NC)"
	$(DOCKER_COMPOSE) run --rm game-server-1 npm test

ci-lint: ## CI lint
	@echo "$(GREEN)Running CI lint...$(NC)"
	$(DOCKER_COMPOSE) run --rm game-server-1 npm run lint

##@ Quick Actions

quick-start: install build up ## Quick start for new developers
	@echo "$(GREEN)Battle Castles is running!$(NC)"
	@echo "$(BLUE)Access the game at: http://localhost$(NC)"
	@echo "$(BLUE)Health check: http://localhost/health$(NC)"

quick-stop: down ## Quick stop

quick-restart: restart logs ## Quick restart with logs

quick-clean: clean build up ## Clean rebuild and start
