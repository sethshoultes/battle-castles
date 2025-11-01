# Battle Castles - Quick Start Guide

Get Battle Castles running in 5 minutes!

## Prerequisites

- Docker 24.0+
- Docker Compose 2.0+
- 4GB RAM minimum
- 10GB free disk space

## Option 1: One-Command Start (Recommended)

```bash
make quick-start
```

That's it! The game will:
1. Install dependencies
2. Build Docker images
3. Start all services
4. Display access URLs

## Option 2: Manual Start

```bash
# 1. Clone repository (if not already done)
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles

# 2. Create environment file
cp deployment/docker/.env.example deployment/docker/.env

# 3. Start services
docker-compose up -d

# 4. Wait for services to be ready (~30 seconds)
docker-compose ps
```

## Verify Everything is Working

```bash
# Check health
curl http://localhost/health

# View logs
docker-compose logs -f

# Check status
make status
```

## Access Points

- **Game Application**: http://localhost
- **Health Check**: http://localhost/health
- **WebSocket**: ws://localhost/socket.io
- **API**: http://localhost/api

## Common Commands

```bash
# Start services
make up

# Stop services
make down

# View logs
make logs

# Restart services
make restart

# Run tests
make test

# Create backup
make backup

# Check status
make status
```

## Monitoring (Optional)

```bash
# Start with monitoring
docker-compose --profile monitoring up -d

# Access dashboards
make grafana      # Opens http://localhost:3000
make prometheus   # Opens http://localhost:9090
```

## Troubleshooting

### Services won't start

```bash
# Check if ports are in use
lsof -i :80
lsof -i :5432
lsof -i :6379

# View detailed logs
docker-compose logs
```

### Database connection errors

```bash
# Check PostgreSQL
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### "Port already in use" error

Edit `docker-compose.yml` and change the conflicting port:

```yaml
ports:
  - "8080:80"  # Change from 80 to 8080
```

## Development Mode

```bash
# Start in development mode with hot reload
make dev

# Run tests in watch mode
make test-watch

# View game server logs only
make logs-game
```

## Next Steps

1. **Configure the environment** - Edit `deployment/docker/.env`
2. **Read full documentation** - See `DEPLOYMENT.md`
3. **Set up monitoring** - Follow monitoring guide
4. **Deploy to production** - Use `make deploy-prod`

## Quick Reference

| Task | Command |
|------|---------|
| Start | `make up` or `docker-compose up -d` |
| Stop | `make down` or `docker-compose down` |
| Logs | `make logs` or `docker-compose logs -f` |
| Status | `make status` or `docker-compose ps` |
| Health | `make health` or `curl http://localhost/health` |
| Test | `make test` |
| Backup | `make backup` |
| Clean | `make clean` |

## Getting Help

- **Full documentation**: `DEPLOYMENT.md`
- **Docker guide**: `deployment/docker/README.md`
- **Kubernetes guide**: `deployment/kubernetes/README.md`
- **Makefile commands**: `make help`
- **Issues**: [GitHub Issues](https://github.com/yourusername/battle-castles/issues)

## Default Credentials (Development Only)

**⚠️ CHANGE THESE IN PRODUCTION!**

- **PostgreSQL**:
  - User: `battlecastles`
  - Password: `battlecastles_dev_password`
  - Database: `battlecastles`

- **Redis**:
  - Password: `battlecastles_redis_password`

- **Grafana** (if monitoring enabled):
  - User: `admin`
  - Password: `admin`

## Security Notice

The default configuration is for **development only**. Before deploying to production:

1. Generate strong passwords: `openssl rand -base64 32`
2. Update all secrets in `deployment/docker/.env`
3. Enable SSL/TLS
4. Restrict CORS origins
5. Review security checklist in `DEPLOYMENT.md`

---

**Need more help?** See the full [Deployment Guide](DEPLOYMENT.md) or run `make help`
