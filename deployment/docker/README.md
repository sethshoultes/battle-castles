# Docker Deployment for Battle Castles

This directory contains Docker-specific configuration files for deploying Battle Castles.

## Files

- `.env.example` - Example environment variables (copy to `.env` and customize)
- `init-db.sql` - PostgreSQL initialization script

## Quick Start

### 1. Create Environment File

```bash
cp .env.example .env
# Edit .env with your actual values
```

### 2. Generate Secure Passwords

```bash
# Generate secure passwords for production
openssl rand -base64 32
```

Update the following variables in `.env`:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `SESSION_SECRET`

### 3. Start Services

From the project root:

```bash
docker-compose up -d
```

### 4. Check Status

```bash
docker-compose ps
docker-compose logs -f
```

## Environment Variables

### Required Variables

- `POSTGRES_PASSWORD` - PostgreSQL database password
- `REDIS_PASSWORD` - Redis cache password
- `JWT_SECRET` - JWT token signing secret
- `SESSION_SECRET` - Session encryption secret

### Optional Variables

See `.env.example` for all available configuration options.

## Database Initialization

The `init-db.sql` script automatically:
1. Creates necessary tables
2. Sets up indexes
3. Creates database functions and triggers
4. Inserts default data

The script runs automatically on first PostgreSQL startup.

## Security Considerations

### Development

- Default passwords are acceptable
- CORS is set to `*` for easy development
- SSL is disabled by default

### Production

1. **Generate strong passwords**:
   ```bash
   openssl rand -base64 32
   ```

2. **Enable SSL/TLS**:
   - Set `SSL_ENABLED=true`
   - Provide valid SSL certificates
   - Update nginx configuration

3. **Restrict CORS**:
   - Set `CORS_ORIGIN` to your domain
   - Remove wildcard `*`

4. **Use secrets management**:
   - AWS Secrets Manager
   - HashiCorp Vault
   - Docker Secrets
   - Kubernetes Secrets

5. **Enable monitoring**:
   - Set up Prometheus/Grafana
   - Configure alerting
   - Monitor logs

## Backup and Restore

### Manual Backup

```bash
# Run backup script
../scripts/backup.sh --type full
```

### Automated Backups

Set up cron job:

```bash
# Add to crontab
0 2 * * * cd /path/to/battle-castles && ./deployment/scripts/backup.sh --type full --s3
```

### Restore from Backup

```bash
# Restore database
../scripts/backup.sh --restore /path/to/backup.sql.gz

# Restore configuration
../scripts/backup.sh --restore /path/to/config_backup.tar.gz
```

## Troubleshooting

### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U battlecastles -d battlecastles
```

### Redis Connection Issues

```bash
# Check if Redis is running
docker-compose ps redis

# Check Redis logs
docker-compose logs redis

# Test connection
docker-compose exec redis redis-cli ping
```

### Game Server Not Starting

```bash
# Check game server logs
docker-compose logs game-server-1

# Check health status
curl http://localhost/health

# Restart game servers
docker-compose restart game-server-1 game-server-2
```

### Port Conflicts

If ports are already in use:

1. Stop conflicting services
2. Or modify ports in `docker-compose.yml`
3. Update `.env` with new ports

## Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f game-server-1

# Last 100 lines
docker-compose logs --tail=100
```

### Check Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df
```

### Access Grafana

If monitoring profile is enabled:

```bash
# Start with monitoring
docker-compose --profile monitoring up -d

# Access Grafana
open http://localhost:3000
# Default credentials: admin / admin
```

## Updating

### Pull Latest Images

```bash
docker-compose pull
```

### Rebuild and Restart

```bash
docker-compose up -d --build
```

### Zero-Downtime Updates

```bash
# Use the deployment script
../scripts/deploy.sh production
```

## Clean Up

### Stop All Services

```bash
docker-compose down
```

### Remove Volumes (CAUTION: Deletes all data)

```bash
docker-compose down -v
```

### Remove Images

```bash
docker-compose down --rmi all
```

## Performance Tuning

### PostgreSQL

Edit `docker-compose.yml` to add PostgreSQL performance settings:

```yaml
command:
  - postgres
  - -c
  - shared_buffers=256MB
  - -c
  - max_connections=200
  - -c
  - work_mem=4MB
```

### Redis

Edit `docker-compose.yml` to add Redis performance settings:

```yaml
command:
  - redis-server
  - --maxmemory 512mb
  - --maxmemory-policy allkeys-lru
```

### Game Servers

Adjust resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '1'
      memory: 512M
```

## Development Tips

### Local Development

```bash
# Use development environment
NODE_ENV=development docker-compose up
```

### Hot Reload

For development with hot reload:

```bash
# Mount source code as volume
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Debug Mode

```bash
# Enable debug logging
DEBUG=true LOG_LEVEL=debug docker-compose up
```
