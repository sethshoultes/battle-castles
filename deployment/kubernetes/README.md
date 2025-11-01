# Battle Castles Kubernetes Deployment

This directory contains Kubernetes manifests for deploying Battle Castles to a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured to access your cluster
- NGINX Ingress Controller installed
- cert-manager installed (for SSL/TLS)
- Prometheus Operator installed (optional, for monitoring)

## Quick Start

### 1. Create Namespace and Secrets

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Update secrets with actual values
# IMPORTANT: Never commit real secrets to version control
kubectl apply -f secrets.yaml
```

### 2. Deploy Infrastructure

```bash
# Deploy PostgreSQL
kubectl apply -f postgres-deployment.yaml

# Deploy Redis
kubectl apply -f redis-deployment.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n battlecastles --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n battlecastles --timeout=300s
```

### 3. Deploy Game Servers

```bash
# Deploy ConfigMap
kubectl apply -f configmap.yaml

# Deploy game servers
kubectl apply -f game-server-deployment.yaml

# Deploy HPA (auto-scaling)
kubectl apply -f hpa.yaml

# Wait for game servers to be ready
kubectl wait --for=condition=ready pod -l app=game-server -n battlecastles --timeout=300s
```

### 4. Configure Networking

```bash
# Apply network policies
kubectl apply -f network-policy.yaml

# Deploy ingress
kubectl apply -f ingress.yaml
```

### 5. Set Up Monitoring (Optional)

```bash
# Deploy ServiceMonitor and PrometheusRule
kubectl apply -f service-monitor.yaml
```

## Using Kustomize

For easier management, use Kustomize:

```bash
# Deploy everything at once
kubectl apply -k .

# Or using kustomize directly
kustomize build . | kubectl apply -f -
```

## Configuration

### Environment Variables

Edit `configmap.yaml` to modify game server configuration.

### Secrets

Update `secrets.yaml` with actual credentials:

```bash
# Generate secure passwords
openssl rand -base64 32

# Update secrets
kubectl create secret generic battlecastles-secrets \
  --from-literal=POSTGRES_PASSWORD="your-secure-password" \
  --from-literal=REDIS_PASSWORD="your-secure-password" \
  --from-literal=JWT_SECRET="your-secure-secret" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Scaling

Manual scaling:

```bash
# Scale game servers
kubectl scale deployment game-server --replicas=5 -n battlecastles
```

The HPA will automatically scale based on CPU/memory usage.

### SSL/TLS Certificates

Using cert-manager with Let's Encrypt:

```bash
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

## Monitoring

### View Logs

```bash
# View game server logs
kubectl logs -l app=game-server -n battlecastles -f

# View specific pod logs
kubectl logs <pod-name> -n battlecastles -f
```

### Check Status

```bash
# Check all resources
kubectl get all -n battlecastles

# Check pods
kubectl get pods -n battlecastles

# Describe deployment
kubectl describe deployment game-server -n battlecastles

# Check HPA status
kubectl get hpa -n battlecastles
```

### Access Services

```bash
# Port forward to access services locally
kubectl port-forward svc/game-server 3001:3001 -n battlecastles

# Access PostgreSQL
kubectl port-forward svc/postgres 5432:5432 -n battlecastles

# Access Redis
kubectl port-forward svc/redis 6379:6379 -n battlecastles
```

## Troubleshooting

### Pods not starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n battlecastles

# Check logs
kubectl logs <pod-name> -n battlecastles

# Check previous container logs (if crashed)
kubectl logs <pod-name> -n battlecastles --previous
```

### Database connection issues

```bash
# Test PostgreSQL connection
kubectl exec -it <game-server-pod> -n battlecastles -- sh
nc -zv postgres 5432

# Test Redis connection
kubectl exec -it <game-server-pod> -n battlecastles -- sh
nc -zv redis 6379
```

### Network issues

```bash
# Check network policies
kubectl get networkpolicies -n battlecastles

# Test connectivity between pods
kubectl exec -it <game-server-pod> -n battlecastles -- wget -O- http://postgres:5432
```

## Backup and Restore

### Manual Backup

```bash
# Backup PostgreSQL
kubectl exec -it <postgres-pod> -n battlecastles -- \
  pg_dump -U battlecastles battlecastles > backup.sql

# Backup Redis
kubectl exec -it <redis-pod> -n battlecastles -- redis-cli SAVE
kubectl cp <redis-pod>:/data/dump.rdb ./redis-backup.rdb -n battlecastles
```

### Restore

```bash
# Restore PostgreSQL
cat backup.sql | kubectl exec -i <postgres-pod> -n battlecastles -- \
  psql -U battlecastles battlecastles

# Restore Redis
kubectl cp ./redis-backup.rdb <redis-pod>:/data/dump.rdb -n battlecastles
kubectl delete pod <redis-pod> -n battlecastles
```

## Production Considerations

1. **Secrets Management**: Use external secret managers (AWS Secrets Manager, Vault, etc.)
2. **Persistent Storage**: Use appropriate storage classes for your cloud provider
3. **High Availability**: Use multiple replicas for databases (consider managed services)
4. **Backup Strategy**: Implement automated backups with retention policies
5. **Monitoring**: Set up comprehensive monitoring with Prometheus/Grafana
6. **Logging**: Use centralized logging (ELK, Loki, CloudWatch, etc.)
7. **Resource Limits**: Adjust resource requests/limits based on actual usage
8. **Security**: Implement pod security policies and network policies
9. **DNS**: Configure proper DNS records for your domain
10. **CDN**: Use CDN for static assets

## Cloud Provider Examples

### AWS (EKS)

```bash
# Create EKS cluster
eksctl create cluster --name battlecastles --region us-east-1

# Use AWS Load Balancer Controller instead of NGINX
# Uncomment ALB annotations in ingress.yaml
```

### GCP (GKE)

```bash
# Create GKE cluster
gcloud container clusters create battlecastles --region us-central1

# Use GCP Load Balancer
# Update ingress to use GCP ingress class
```

### Azure (AKS)

```bash
# Create AKS cluster
az aks create --resource-group battlecastles --name battlecastles

# Use Azure Application Gateway
# Update ingress annotations for Azure
```

## Clean Up

```bash
# Delete all resources
kubectl delete -k .

# Or delete namespace (removes everything)
kubectl delete namespace battlecastles
```
