# Battle Castles Deployment Guide

Complete guide for deploying Battle Castles to production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Docker Deployment](#docker-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Configuration](#configuration)
5. [Monitoring & Logging](#monitoring--logging)
6. [Backup & Recovery](#backup--recovery)
7. [Security](#security)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker** 24.0+ and Docker Compose 2.0+
- **Node.js** 20 LTS (for local development)
- **Git** 2.30+
- **PostgreSQL** 16+ (if not using Docker)
- **Redis** 7+ (if not using Docker)

### Optional Software

- **Kubernetes** 1.25+ (for K8s deployment)
- **kubectl** (Kubernetes CLI)
- **Helm** 3+ (for Kubernetes package management)
- **Prometheus** & **Grafana** (for monitoring)

### System Requirements

#### Minimum (Development)
- 2 CPU cores
- 4 GB RAM
- 20 GB disk space

#### Recommended (Production)
- 4+ CPU cores
- 8+ GB RAM
- 100+ GB SSD storage
- Load balancer
- CDN (for static assets)

## Docker Deployment

### Quick Start

```bash
# 1. Clone repository
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles

# 2. Create environment file
cp deployment/docker/.env.example deployment/docker/.env

# 3. Generate secure passwords
openssl rand -base64 32  # Use for POSTGRES_PASSWORD
openssl rand -base64 32  # Use for REDIS_PASSWORD
openssl rand -base64 32  # Use for JWT_SECRET

# 4. Edit .env with your values
nano deployment/docker/.env

# 5. Deploy
./deployment/scripts/deploy.sh production
```

### Manual Deployment

```bash
# 1. Build Docker images
docker-compose build --no-cache

# 2. Start services
docker-compose up -d

# 3. Check health
curl http://localhost/health

# 4. View logs
docker-compose logs -f
```

### Scaling Game Servers

```bash
# Scale to 4 instances
docker-compose up -d --scale game-server=4

# Or edit docker-compose.yml:
# Set GAME_SERVER_REPLICAS=4 in .env
```

## Kubernetes Deployment

### Prerequisites

1. **Kubernetes cluster** (EKS, GKE, AKS, or self-hosted)
2. **kubectl** configured to access cluster
3. **NGINX Ingress Controller** installed
4. **cert-manager** installed (for SSL)

### Quick Start

```bash
# 1. Navigate to Kubernetes directory
cd deployment/kubernetes

# 2. Update secrets
# Edit secrets.yaml with actual values
nano secrets.yaml

# 3. Deploy using Kustomize
kubectl apply -k .

# 4. Check status
kubectl get all -n battlecastles

# 5. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=game-server -n battlecastles --timeout=300s
```

### Step-by-Step Deployment

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create secrets
kubectl apply -f secrets.yaml

# 3. Deploy databases
kubectl apply -f postgres-deployment.yaml
kubectl apply -f redis-deployment.yaml

# Wait for databases
kubectl wait --for=condition=ready pod -l app=postgres -n battlecastles --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n battlecastles --timeout=300s

# 4. Deploy game servers
kubectl apply -f configmap.yaml
kubectl apply -f game-server-deployment.yaml

# 5. Configure networking
kubectl apply -f network-policy.yaml
kubectl apply -f ingress.yaml

# 6. Enable auto-scaling
kubectl apply -f hpa.yaml

# 7. Set up monitoring
kubectl apply -f service-monitor.yaml
```

### Cloud Provider Specific Setup

#### AWS (EKS)

```bash
# Create EKS cluster
eksctl create cluster \
  --name battlecastles \
  --region us-east-1 \
  --nodegroup-name standard-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds"
helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system
```

#### GCP (GKE)

```bash
# Create GKE cluster
gcloud container clusters create battlecastles \
  --region us-central1 \
  --machine-type n1-standard-2 \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 10

# Get credentials
gcloud container clusters get-credentials battlecastles --region us-central1
```

#### Azure (AKS)

```bash
# Create resource group
az group create --name battlecastles-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group battlecastles-rg \
  --name battlecastles \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group battlecastles-rg --name battlecastles
```

## Configuration

### Environment Variables

Key configuration variables (see `.env.example` for full list):

```bash
# Application
NODE_ENV=production
LOG_LEVEL=info

# Database
POSTGRES_PASSWORD=your-secure-password
DATABASE_URL=postgresql://user:pass@host:5432/db

# Cache
REDIS_PASSWORD=your-redis-password
REDIS_URL=redis://:pass@host:6379

# Security
JWT_SECRET=your-jwt-secret
SESSION_SECRET=your-session-secret

# Game Settings
MAX_ROOMS=100
TICK_RATE=20
GAME_DURATION=180
```

### SSL/TLS Configuration

#### Using Let's Encrypt (Recommended)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@battlecastles.game
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

#### Using Custom Certificates

```bash
# Create TLS secret
kubectl create secret tls battlecastles-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem \
  -n battlecastles
```

## Monitoring & Logging

### Prometheus & Grafana

```bash
# Start with monitoring profile
docker-compose --profile monitoring up -d

# Access Grafana
open http://localhost:3000
# Default: admin / admin
```

### View Logs

```bash
# Docker
docker-compose logs -f game-server-1

# Kubernetes
kubectl logs -l app=game-server -n battlecastles -f
```

### Metrics Endpoints

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
- **Game Server Metrics**: http://localhost:9100/metrics

## Backup & Recovery

### Automated Backups

```bash
# Full backup
./deployment/scripts/backup.sh --type full

# Database only
./deployment/scripts/backup.sh --type db

# With S3 upload
./deployment/scripts/backup.sh --type full --s3
```

### Set Up Automated Backups

```bash
# Add to crontab
crontab -e

# Add line (daily at 2 AM):
0 2 * * * cd /path/to/battle-castles && ./deployment/scripts/backup.sh --type full --s3
```

### Restore from Backup

```bash
# Restore database
./deployment/scripts/backup.sh --restore /path/to/db_backup.sql.gz

# Restore configuration
./deployment/scripts/backup.sh --restore /path/to/config_backup.tar.gz
```

## Security

### Security Checklist

- [ ] Generate strong passwords for all services
- [ ] Enable SSL/TLS with valid certificates
- [ ] Restrict CORS to specific domains
- [ ] Set up network policies (Kubernetes)
- [ ] Enable database encryption at rest
- [ ] Configure firewall rules
- [ ] Set up WAF (Web Application Firewall)
- [ ] Enable rate limiting
- [ ] Implement DDoS protection
- [ ] Regular security audits
- [ ] Keep dependencies updated
- [ ] Enable audit logging

### Hardening

```bash
# 1. Run as non-root user (already configured in Dockerfile)

# 2. Enable network policies (Kubernetes)
kubectl apply -f deployment/kubernetes/network-policy.yaml

# 3. Set resource limits
# Already configured in deployment manifests

# 4. Enable pod security policies
kubectl apply -f deployment/kubernetes/pod-security-policy.yaml
```

## Troubleshooting

### Common Issues

#### Game Servers Not Starting

```bash
# Check logs
docker-compose logs game-server-1

# Check health
curl http://localhost/health

# Restart
docker-compose restart game-server-1
```

#### Database Connection Failed

```bash
# Check PostgreSQL status
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U battlecastles

# Check network
docker-compose exec game-server-1 nc -zv postgres 5432
```

#### High Memory Usage

```bash
# Check stats
docker stats

# Adjust limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
```

#### WebSocket Connection Issues

```bash
# Check nginx logs
docker-compose logs nginx

# Test WebSocket
wscat -c ws://localhost/socket.io/

# Verify nginx config
docker-compose exec nginx nginx -t
```

### Performance Optimization

#### Database Tuning

```sql
-- Increase shared buffers
ALTER SYSTEM SET shared_buffers = '256MB';

-- Increase work memory
ALTER SYSTEM SET work_mem = '4MB';

-- Reload configuration
SELECT pg_reload_conf();
```

#### Redis Tuning

```bash
# Set maxmemory policy
docker-compose exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Set maxmemory
docker-compose exec redis redis-cli CONFIG SET maxmemory 512mb
```

### Getting Help

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/battle-castles/issues)
- **Discord**: [Community Discord](#)
- **Email**: support@battlecastles.game

## Production Deployment Workflow

```bash
# 1. Test locally
docker-compose up -d
npm test

# 2. Create backup
./deployment/scripts/backup.sh --type full

# 3. Deploy to production
./deployment/scripts/deploy.sh production

# 4. Verify deployment
curl https://battlecastles.game/health

# 5. Monitor for issues
docker-compose logs -f

# 6. If issues occur, rollback
./deployment/scripts/deploy.sh production --rollback
```

## License

This project is proprietary software. All rights reserved.

## Support

For deployment support, contact: devops@battlecastles.game
