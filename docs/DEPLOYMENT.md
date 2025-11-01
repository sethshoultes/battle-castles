# Battle Castles - Deployment Guide

Version 0.1.0 | Deployment & Operations

---

## Table of Contents

1. [Overview](#overview)
2. [Server Setup](#server-setup)
3. [Database Configuration](#database-configuration)
4. [Environment Variables](#environment-variables)
5. [Docker Deployment](#docker-deployment)
6. [Raspberry Pi 5 Deployment](#raspberry-pi-5-deployment)
7. [Client Distribution](#client-distribution)
8. [Monitoring & Logging](#monitoring--logging)
9. [Backup Procedures](#backup-procedures)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### Deployment Options

Battle Castles supports multiple deployment strategies:

| Platform | Use Case | Complexity |
|----------|----------|------------|
| **Docker Compose** | Local development | Low |
| **Bare Metal** | LAN servers, Raspberry Pi | Medium |
| **Kubernetes** | Production, cloud hosting | High |

### System Requirements

#### Game Server

**Minimum:**
- CPU: 2 cores @ 2.0 GHz
- RAM: 2 GB
- Storage: 5 GB
- Network: 10 Mbps up/down

**Recommended:**
- CPU: 4 cores @ 3.0 GHz
- RAM: 4 GB
- Storage: 10 GB SSD
- Network: 100 Mbps up/down

#### Database Server (PostgreSQL)

**Minimum:**
- CPU: 2 cores
- RAM: 2 GB
- Storage: 20 GB

**Recommended:**
- CPU: 4 cores
- RAM: 8 GB
- Storage: 50 GB SSD

---

## Server Setup

### Option 1: Docker Compose (Recommended for Development)

#### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

#### Setup Steps

1. **Clone Repository**

```bash
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles
```

2. **Configure Environment**

```bash
cp server/game-server/.env.example server/game-server/.env
```

Edit `.env` file:

```env
# Server Configuration
NODE_ENV=production
PORT=8002
HOST=0.0.0.0

# CORS Settings
CORS_ORIGIN=*

# Logging
LOG_LEVEL=info
LOG_FILE=logs/game-server.log

# Game Settings
TICK_RATE=20
MAX_GAME_TIME=180
ELIXIR_REGEN_RATE=0.357143  # 1 per 2.8 seconds
```

3. **Start Services**

```bash
docker-compose up -d
```

4. **Verify Deployment**

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f game-server

# Test health endpoint
curl http://localhost:8002/health
```

#### Docker Compose File

```yaml
# docker-compose.yml
version: '3.8'

services:
  game-server:
    build:
      context: ./server/game-server
      dockerfile: Dockerfile
    ports:
      - "8002:8002"
    environment:
      - NODE_ENV=production
      - PORT=8002
      - LOG_LEVEL=info
    volumes:
      - ./server/game-server/logs:/app/logs
    restart: unless-stopped
    networks:
      - battle-castles-net

  # Future: Add PostgreSQL, Redis, etc.
  # postgres:
  #   image: postgres:14-alpine
  #   ...

networks:
  battle-castles-net:
    driver: bridge
```

---

### Option 2: Bare Metal Installation

#### Prerequisites

- Ubuntu 20.04+ or Debian 11+
- Node.js 18 LTS
- npm 9+
- systemd (for service management)

#### Installation Steps

1. **Install Node.js**

```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should be v18.x.x
npm --version   # Should be 9.x.x
```

2. **Create Service User**

```bash
sudo useradd -r -s /bin/false battlecastles
sudo mkdir -p /opt/battle-castles
sudo chown battlecastles:battlecastles /opt/battle-castles
```

3. **Deploy Application**

```bash
# Clone repository
cd /opt/battle-castles
sudo -u battlecastles git clone https://github.com/yourusername/battle-castles.git .

# Install dependencies
cd server/game-server
sudo -u battlecastles npm install --production

# Build TypeScript
sudo -u battlecastles npm run build
```

4. **Configure Environment**

```bash
sudo -u battlecastles cp .env.example .env
sudo nano .env
```

5. **Create systemd Service**

```bash
sudo nano /etc/systemd/system/battle-castles.service
```

```ini
[Unit]
Description=Battle Castles Game Server
After=network.target

[Service]
Type=simple
User=battlecastles
Group=battlecastles
WorkingDirectory=/opt/battle-castles/server/game-server
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=battle-castles

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/battle-castles/server/game-server/logs

[Install]
WantedBy=multi-user.target
```

6. **Start Service**

```bash
sudo systemctl daemon-reload
sudo systemctl enable battle-castles
sudo systemctl start battle-castles

# Check status
sudo systemctl status battle-castles

# View logs
sudo journalctl -u battle-castles -f
```

---

## Database Configuration

### PostgreSQL Setup (Future Version)

Battle Castles v0.1.0 does not require a database (local-only). Future versions will use PostgreSQL for player data.

#### Installation

```bash
# Install PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql-14 postgresql-contrib

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Create Database

```sql
-- Connect to PostgreSQL
sudo -u postgres psql

-- Create database and user
CREATE DATABASE battlecastles;
CREATE USER battlecastles_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE battlecastles TO battlecastles_user;

-- Exit
\q
```

#### Schema (Future)

```sql
-- Player profiles
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    trophies INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0
);

-- Match history
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player1_id UUID REFERENCES players(id),
    player2_id UUID REFERENCES players(id),
    winner_id UUID REFERENCES players(id),
    duration INTEGER,  -- seconds
    ended_at TIMESTAMP DEFAULT NOW(),
    reason VARCHAR(50)  -- towers_destroyed, time_limit, etc.
);

-- Card collections
CREATE TABLE player_cards (
    player_id UUID REFERENCES players(id),
    card_type VARCHAR(50),
    level INTEGER DEFAULT 1,
    count INTEGER DEFAULT 0,
    PRIMARY KEY (player_id, card_type)
);
```

---

## Environment Variables

### Complete Reference

```bash
# ===== Server Configuration =====
NODE_ENV=production          # production | development | test
PORT=8002                   # Server port
HOST=0.0.0.0               # Bind address (0.0.0.0 = all interfaces)

# ===== CORS Configuration =====
CORS_ORIGIN=*              # Allowed origins (* = all, comma-separated list)

# ===== Logging =====
LOG_LEVEL=info             # error | warn | info | debug
LOG_FILE=logs/game-server.log
LOG_MAX_SIZE=10m           # Max log file size
LOG_MAX_FILES=7            # Number of rotated logs to keep

# ===== Game Configuration =====
TICK_RATE=20               # Server update rate (Hz)
MAX_GAME_TIME=180          # Match duration (seconds)
DOUBLE_ELIXIR_TIME=60      # Double elixir starts at (seconds remaining)
INITIAL_ELIXIR=5.0         # Starting elixir
MAX_ELIXIR=10.0            # Maximum elixir capacity
ELIXIR_REGEN_RATE=0.357143 # Elixir per second (1 / 2.8)

# ===== Matchmaking =====
MATCHMAKING_TIMEOUT=60000  # Queue timeout (ms)
MIN_PLAYERS_PER_MATCH=2    # Always 2 for 1v1

# ===== Database (Future) =====
DB_HOST=localhost
DB_PORT=5432
DB_NAME=battlecastles
DB_USER=battlecastles_user
DB_PASSWORD=your_secure_password
DB_POOL_SIZE=20

# ===== Redis (Future) =====
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# ===== Security =====
JWT_SECRET=your_jwt_secret_key  # Future auth
JWT_EXPIRY=86400               # 24 hours

# ===== Monitoring =====
ENABLE_METRICS=true
METRICS_PORT=9090
```

### Production vs Development

**Development:**
```env
NODE_ENV=development
LOG_LEVEL=debug
CORS_ORIGIN=*
```

**Production:**
```env
NODE_ENV=production
LOG_LEVEL=info
CORS_ORIGIN=https://battlecastles.game
```

---

## Docker Deployment

### Dockerfile

```dockerfile
# server/game-server/Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Build TypeScript
RUN npm run build

# ===== Production Image =====
FROM node:18-alpine

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy built app
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Create logs directory
RUN mkdir -p logs && chown nodejs:nodejs logs

USER nodejs

EXPOSE 8002

CMD ["node", "dist/index.js"]
```

### Build and Push

```bash
# Build image
docker build -t battlecastles/game-server:0.1.0 server/game-server/

# Tag latest
docker tag battlecastles/game-server:0.1.0 battlecastles/game-server:latest

# Push to registry (if using Docker Hub)
docker push battlecastles/game-server:0.1.0
docker push battlecastles/game-server:latest
```

### Docker Compose Production

```yaml
version: '3.8'

services:
  game-server:
    image: battlecastles/game-server:0.1.0
    ports:
      - "8002:8002"
    env_file:
      - .env.production
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    restart: unless-stopped
    networks:
      - battle-castles-net
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8002/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  battle-castles-net:
    driver: bridge
```

---

## Raspberry Pi 5 Deployment

### Client Installation on Raspberry Pi 5

Battle Castles is fully compatible with Raspberry Pi 5 (4GB and 16GB models).

#### Prerequisites

- Raspberry Pi 5 (4GB or 16GB RAM)
- Raspberry Pi OS (64-bit, Bookworm or later)
- 10GB free storage

#### Option 1: .deb Package Installation

```bash
# Download .deb package
wget https://releases.battlecastles.game/battle-castles_0.1.0_arm64.deb

# Install package
sudo dpkg -i battle-castles_0.1.0_arm64.deb

# Install dependencies
sudo apt-get install -f

# Launch game
battle-castles
```

#### Option 2: Build from Source

```bash
# Install Godot Engine for ARM64
wget https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux_arm64.zip
unzip Godot_v4.3-stable_linux_arm64.zip
sudo mv Godot_v4.3-stable_linux_arm64 /usr/local/bin/godot
sudo chmod +x /usr/local/bin/godot

# Clone repository
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles

# Install Git LFS for assets
sudo apt-get install git-lfs
git lfs install
git lfs pull

# Export game
godot --headless --export "Linux ARM64" builds/battle-castles

# Run
./builds/battle-castles
```

#### Performance Optimization

Edit `/boot/config.txt`:

```bash
# GPU Memory (recommended: 256MB)
gpu_mem=256

# Overclock (Pi 5 16GB only, optional)
arm_freq=2800
over_voltage=6

# Disable onboard audio if using HDMI
dtparam=audio=off
```

Reboot after changes:
```bash
sudo reboot
```

#### Running as Kiosk Mode

Perfect for dedicated game stations at LAN parties:

```bash
# Install Openbox window manager
sudo apt-get install openbox

# Create autostart script
mkdir -p ~/.config/openbox
nano ~/.config/openbox/autostart
```

Add:
```bash
#!/bin/bash
# Hide cursor after 1 second of inactivity
unclutter -idle 1 &

# Launch Battle Castles in fullscreen
/usr/bin/battle-castles --fullscreen &
```

Make executable:
```bash
chmod +x ~/.config/openbox/autostart
```

Auto-login and start Openbox:
```bash
sudo raspi-config
# System Options > Boot / Auto Login > Desktop Autologin
```

---

## Client Distribution

### Building for Different Platforms

#### Windows

```bash
# From Godot editor or command line
godot --headless --export "Windows Desktop" builds/windows/BattleCastles.exe

# Create installer (using Inno Setup)
iscc deployment/scripts/windows-installer.iss
```

#### macOS

```bash
# Export .app bundle
godot --headless --export "Mac OSX" builds/macos/BattleCastles.app

# Create DMG
hdiutil create -volname "Battle Castles" -srcfolder builds/macos -ov -format UDZO builds/BattleCastles.dmg

# Code sign (requires Apple Developer account)
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" builds/macos/BattleCastles.app
```

#### Linux

```bash
# Export binary
godot --headless --export "Linux/X11" builds/linux/battle-castles

# Create AppImage
./deployment/scripts/create-appimage.sh

# Create .deb package
./deployment/scripts/create-deb.sh
```

### Distribution Channels

1. **GitHub Releases**
   - Upload builds to releases page
   - Include checksums (SHA256)

2. **Itch.io**
   - Upload builds via Butler CLI
   - Automatic version management

3. **Steam** (Future)
   - Steamworks SDK integration
   - Steam Deck compatibility

---

## Monitoring & Logging

### Log Locations

**Docker:**
- Application logs: `docker-compose logs game-server`
- Container logs: `/var/lib/docker/containers/`

**Bare Metal:**
- Application logs: `/opt/battle-castles/server/game-server/logs/`
- System logs: `journalctl -u battle-castles`

### Log Rotation

Configure logrotate:

```bash
sudo nano /etc/logrotate.d/battle-castles
```

```
/opt/battle-castles/server/game-server/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 battlecastles battlecastles
    postrotate
        systemctl reload battle-castles > /dev/null 2>&1 || true
    endscript
}
```

### Monitoring Metrics

**Health Check Endpoint:**

```bash
# Returns server health and stats
curl http://localhost:8002/health
```

Response:
```json
{
  "status": "healthy",
  "uptime": 12345.67,
  "activeGames": 42,
  "queuedPlayers": 15,
  "totalConnections": 120
}
```

**System Monitoring:**

```bash
# CPU usage
top -p $(pgrep -f battle-castles)

# Memory usage
ps aux | grep battle-castles

# Network connections
netstat -an | grep 8002
```

---

## Backup Procedures

### Backup Strategy (Future - When Database Added)

#### What to Backup

1. **Database** - Player data, match history
2. **Configuration** - `.env` files, configs
3. **Logs** - Recent logs for debugging

#### Automated Backups

```bash
#!/bin/bash
# /opt/battle-castles/scripts/backup.sh

BACKUP_DIR="/backups/battle-castles"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL (future)
# pg_dump battlecastles -U battlecastles_user > "$BACKUP_DIR/db_$DATE.sql"

# Backup configuration
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" /opt/battle-castles/server/game-server/.env

# Backup logs (last 7 days)
find /opt/battle-castles/server/game-server/logs -name "*.log" -mtime -7 -exec tar -czf "$BACKUP_DIR/logs_$DATE.tar.gz" {} +

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Schedule with cron:
```bash
crontab -e
```

Add:
```
# Daily backup at 2 AM
0 2 * * * /opt/battle-castles/scripts/backup.sh >> /var/log/battle-castles-backup.log 2>&1
```

---

## Troubleshooting

### Server Won't Start

**Check logs:**
```bash
# Docker
docker-compose logs game-server

# Systemd
sudo journalctl -u battle-castles -n 50
```

**Common issues:**
- Port 8002 already in use
- Missing environment variables
- Node.js version mismatch

**Solutions:**
```bash
# Check port usage
sudo lsof -i :8002

# Kill process using port
sudo kill -9 $(lsof -t -i:8002)

# Verify Node.js version
node --version  # Should be v18.x.x
```

### High Memory Usage

**Check memory:**
```bash
free -h
htop
```

**Optimize Node.js:**
```bash
# Limit Node.js heap size
NODE_OPTIONS=--max-old-space-size=2048 node dist/index.js
```

Add to systemd service:
```ini
[Service]
Environment="NODE_OPTIONS=--max-old-space-size=2048"
```

### Network Issues

**Test connectivity:**
```bash
# From client machine
telnet server-ip 8002

# Or use nc (netcat)
nc -zv server-ip 8002
```

**Firewall configuration:**
```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 8002/tcp
sudo ufw reload

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=8002/tcp
sudo firewall-cmd --reload
```

### Client Connection Failed

**Check server status:**
```bash
curl http://server-ip:8002/health
```

**Verify CORS settings:**
- Ensure `CORS_ORIGIN` includes client domain
- Use `*` for development only

**Client-side debugging:**
- Open browser DevTools (F12)
- Check Network tab for WebSocket connection
- Look for CORS errors in Console

---

## Security Best Practices

### Production Checklist

- [ ] Change default passwords
- [ ] Use environment variables for secrets
- [ ] Enable HTTPS (behind reverse proxy)
- [ ] Configure firewall rules
- [ ] Disable debug mode (`NODE_ENV=production`)
- [ ] Enable log rotation
- [ ] Regular security updates
- [ ] Implement rate limiting
- [ ] Use secure WebSocket (wss://)

### Reverse Proxy with Nginx

```nginx
# /etc/nginx/sites-available/battle-castles
upstream battle_castles {
    server 127.0.0.1:8002;
}

server {
    listen 80;
    server_name api.battlecastles.game;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.battlecastles.game;

    ssl_certificate /etc/letsencrypt/live/battlecastles.game/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/battlecastles.game/privkey.pem;

    # WebSocket support
    location / {
        proxy_pass http://battle_castles;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/battle-castles /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Support

### Getting Help

- **Documentation:** https://docs.battlecastles.game
- **GitHub Issues:** https://github.com/yourusername/battle-castles/issues
- **Discord:** https://discord.gg/battlecastles
- **Email:** support@battlecastles.game

### Reporting Deployment Issues

Please include:
1. Operating system and version
2. Node.js version (`node --version`)
3. Deployment method (Docker, bare metal, etc.)
4. Error logs
5. Steps to reproduce

---

**Version:** 0.1.0
**Last Updated:** November 1, 2025
**Deployment Status:** LAN-Ready
