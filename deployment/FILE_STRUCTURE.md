# Battle Castles Deployment File Structure

Complete overview of all deployment-related files and their purposes.

## Root Directory Files

```
battle-castles/
├── docker-compose.yml          # Docker Compose orchestration (main deployment)
├── .dockerignore              # Docker build exclusions
├── Makefile                   # Convenient CLI commands (40+ targets)
├── DEPLOYMENT.md              # Master deployment guide
├── QUICKSTART.md              # 5-minute quick start guide
└── .github/
    └── workflows/
        ├── ci.yml             # Continuous Integration pipeline
        └── deploy.yml         # Continuous Deployment pipeline
```

## Deployment Directory Structure

```
deployment/
├── DEPLOYMENT_SUMMARY.md      # This summary document
├── FILE_STRUCTURE.md          # This file
│
├── docker/                    # Docker-specific configuration
│   ├── .env.example          # Environment variables template (80+ vars)
│   ├── init-db.sql           # PostgreSQL initialization script
│   └── README.md             # Docker deployment guide
│
├── kubernetes/                # Kubernetes manifests
│   ├── namespace.yaml        # K8s namespace definition
│   ├── configmap.yaml        # Application configuration
│   ├── secrets.yaml          # Sensitive credentials
│   ├── postgres-deployment.yaml   # PostgreSQL StatefulSet + Service
│   ├── redis-deployment.yaml      # Redis Deployment + Service
│   ├── game-server-deployment.yaml # Game server Deployment + Service
│   ├── hpa.yaml              # Horizontal Pod Autoscaler (2-10 pods)
│   ├── ingress.yaml          # Ingress with SSL/TLS support
│   ├── network-policy.yaml   # Network security policies
│   ├── service-monitor.yaml  # Prometheus monitoring + alerts
│   ├── kustomization.yaml    # Kustomize configuration
│   └── README.md             # Kubernetes deployment guide
│
├── nginx/                     # Nginx configuration
│   └── nginx.conf            # Production nginx config with WebSocket
│
├── monitoring/                # Monitoring stack
│   ├── prometheus.yml        # Prometheus scrape configuration
│   └── grafana/
│       ├── datasources/
│       │   └── prometheus.yaml    # Grafana datasource config
│       └── dashboards/
│           └── dashboard.yaml     # Dashboard provisioning
│
└── scripts/                   # Deployment automation
    ├── deploy.sh             # Main deployment script (executable)
    ├── backup.sh             # Backup and restore script (executable)
    ├── build_all_platforms.sh    # Multi-platform build script
    └── package_rpi5.sh       # Raspberry Pi 5 packaging
```

## File Purposes

### Core Configuration Files

| File | Purpose | Key Features |
|------|---------|--------------|
| `docker-compose.yml` | Main orchestration | 2 game servers, PostgreSQL, Redis, Nginx, optional monitoring |
| `.dockerignore` | Build optimization | Excludes unnecessary files from Docker image |
| `Makefile` | CLI convenience | 40+ commands for dev, deploy, backup, monitoring |

### Documentation

| File | Purpose | Audience |
|------|---------|----------|
| `DEPLOYMENT.md` | Master guide | DevOps engineers, complete deployment instructions |
| `QUICKSTART.md` | Quick start | Developers, 5-minute setup |
| `deployment/DEPLOYMENT_SUMMARY.md` | Overview | All stakeholders, feature summary |
| `deployment/docker/README.md` | Docker guide | Docker users, detailed Docker instructions |
| `deployment/kubernetes/README.md` | K8s guide | K8s users, detailed K8s instructions |

### Environment & Configuration

| File | Purpose | Configuration Items |
|------|---------|-------------------|
| `deployment/docker/.env.example` | Env template | 80+ variables: DB, Redis, secrets, features, backups |
| `deployment/docker/init-db.sql` | DB initialization | Tables, indexes, triggers, views, permissions |
| `deployment/kubernetes/configmap.yaml` | K8s config | Game settings, feature flags |
| `deployment/kubernetes/secrets.yaml` | K8s secrets | Passwords, tokens, API keys |

### Deployment Scripts

| Script | Purpose | Capabilities |
|--------|---------|-------------|
| `deploy.sh` | Automated deployment | Health checks, tests, migrations, rollback |
| `backup.sh` | Backup/restore | Full/partial backups, S3 upload, retention |

### Kubernetes Resources

| File | Purpose | Resources |
|------|---------|-----------|
| `namespace.yaml` | Namespace | Creates `battlecastles` namespace |
| `postgres-deployment.yaml` | Database | StatefulSet, PVC (20Gi), Service |
| `redis-deployment.yaml` | Cache | Deployment, PVC (5Gi), Service |
| `game-server-deployment.yaml` | Application | Deployment (2-10 pods), Service |
| `hpa.yaml` | Auto-scaling | CPU/Memory based scaling |
| `ingress.yaml` | Traffic | NGINX/ALB, SSL/TLS, WebSocket |
| `network-policy.yaml` | Security | Pod-to-pod restrictions |
| `service-monitor.yaml` | Monitoring | Prometheus metrics & alerts |

### Monitoring

| File | Purpose | Monitors |
|------|---------|----------|
| `prometheus.yml` | Metrics collection | Game servers, PostgreSQL, Redis, Nginx |
| `grafana/datasources/` | Data sources | Prometheus connection |
| `grafana/dashboards/` | Visualization | Dashboard provisioning |

### CI/CD

| File | Purpose | Triggers |
|------|---------|----------|
| `.github/workflows/ci.yml` | CI pipeline | Push to any branch, PRs |
| `.github/workflows/deploy.yml` | CD pipeline | Push to main/staging, manual |

## File Statistics

- **Total deployment files**: 27
- **Shell scripts**: 4 (all executable)
- **YAML manifests**: 15
- **Documentation files**: 6
- **Configuration files**: 5
- **Total lines of code**: ~5,000+

## Dependencies Between Files

### Docker Deployment Flow
```
docker-compose.yml
    ├── Uses: deployment/docker/.env (environment)
    ├── Uses: deployment/docker/init-db.sql (database init)
    ├── Uses: deployment/nginx/nginx.conf (reverse proxy)
    ├── Uses: deployment/monitoring/prometheus.yml (metrics)
    └── Uses: server/game-server/Dockerfile (game server image)
```

### Kubernetes Deployment Flow
```
deployment/kubernetes/kustomization.yaml
    ├── Includes: namespace.yaml
    ├── Includes: configmap.yaml
    ├── Includes: secrets.yaml
    ├── Includes: postgres-deployment.yaml
    ├── Includes: redis-deployment.yaml
    ├── Includes: game-server-deployment.yaml
    ├── Includes: hpa.yaml
    ├── Includes: ingress.yaml
    ├── Includes: network-policy.yaml
    └── Includes: service-monitor.yaml
```

### Deployment Script Flow
```
deployment/scripts/deploy.sh
    ├── Calls: deployment/scripts/backup.sh (backup)
    ├── Uses: docker-compose.yml (Docker deploy)
    ├── Uses: deployment/kubernetes/* (K8s deploy)
    └── Uses: deployment/docker/.env (configuration)
```

## File Ownership & Permissions

All scripts should be executable:
```bash
chmod +x deployment/scripts/*.sh
```

Sensitive files (in production):
```bash
chmod 600 deployment/docker/.env
chmod 600 deployment/kubernetes/secrets.yaml
```

## Version Control

### Files to commit:
- All `.yaml` and `.yml` files
- All `.sh` scripts
- All `.md` documentation
- `.env.example` (NOT `.env`)
- `docker-compose.yml`
- `Makefile`
- `.dockerignore`

### Files to ignore (.gitignore):
- `deployment/docker/.env` (actual secrets)
- `deployment/nginx/ssl/*.pem` (SSL certificates)
- `backups/*` (backup files)
- `logs/*` (log files)
- `.DS_Store`

## Quick Reference

### Most Important Files
1. `docker-compose.yml` - Start here for Docker deployment
2. `deployment/scripts/deploy.sh` - Automated deployment
3. `deployment/kubernetes/kustomization.yaml` - K8s one-command deploy
4. `Makefile` - Convenient CLI commands
5. `DEPLOYMENT.md` - Complete documentation

### Configuration Files Priority
1. `deployment/docker/.env.example` - Copy to `.env` and customize
2. `deployment/kubernetes/secrets.yaml` - Update with real secrets
3. `deployment/kubernetes/configmap.yaml` - Adjust game settings
4. `deployment/nginx/nginx.conf` - Customize for your domain

### Troubleshooting Files
1. Check logs: `docker-compose logs` or `kubectl logs`
2. Review: `deployment/docker/README.md`
3. Review: `deployment/kubernetes/README.md`
4. Review: `DEPLOYMENT.md`

## Updates and Maintenance

To update deployment configuration:

1. **Environment changes**: Edit `deployment/docker/.env` or K8s `configmap.yaml`
2. **Secrets rotation**: Use `deployment/scripts/backup.sh` before updating secrets
3. **Scale adjustments**: Edit `hpa.yaml` or use `kubectl scale`
4. **Nginx changes**: Edit `deployment/nginx/nginx.conf` and restart
5. **Monitoring**: Edit `deployment/monitoring/prometheus.yml`

## Support

For questions about specific files:
- **Docker**: See `deployment/docker/README.md`
- **Kubernetes**: See `deployment/kubernetes/README.md`
- **Scripts**: Run script with `--help` flag
- **General**: See `DEPLOYMENT.md`

---

**Last Updated**: November 1, 2025
**Version**: 1.0.0
