# Development Environment Setup Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [macOS Setup](#macos-setup)
3. [Windows Setup](#windows-setup)
4. [Linux Setup](#linux-setup)
5. [Raspberry Pi 5 Setup](#raspberry-pi-5-setup)
6. [IDE Configuration](#ide-configuration)
7. [Running the Project](#running-the-project)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Git** 2.40+ with Git LFS
- **Godot Engine** 4.3.0+ stable
- **Node.js** 20.x LTS
- **Go** 1.21+
- **Python** 3.11+
- **Docker** 24.x + Docker Compose 2.x
- **PostgreSQL** 14+ (or use Docker)
- **Redis** 7+ (or use Docker)

### Hardware Requirements
- **Minimum:** 8GB RAM, 10GB free disk space
- **Recommended:** 16GB RAM, 20GB free disk space, SSD
- **Network:** LAN connection for multiplayer testing

## macOS Setup

### 1. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Development Tools
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Git with LFS
brew install git git-lfs
git lfs install

# Install programming languages
brew install node@20 go python@3.11

# Install databases (optional if using Docker)
brew install postgresql@14 redis

# Install Docker Desktop
brew install --cask docker

# Install Godot
brew install --cask godot
```

### 3. Configure Environment
```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Reload shell
source ~/.zshrc
```

### 4. Clone and Setup Project
```bash
# Clone repository
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles

# Pull LFS files
git lfs pull

# Install Node.js dependencies
cd server/game-server && npm install
cd ../matchmaking && go mod download
cd ../economy && pip3 install -r requirements.txt

# Return to root
cd ../..
```

## Windows Setup

### 1. Install Package Manager (Chocolatey)
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Install Development Tools
```powershell
# Install Git with LFS
choco install git git-lfs -y
git lfs install

# Install programming languages
choco install nodejs-lts golang python311 -y

# Install Docker Desktop
choco install docker-desktop -y

# Install Godot
choco install godot -y

# Install Visual Studio Build Tools (for C++ compilation)
choco install visualstudio2022-workload-vctools -y
```

### 3. Configure Environment Variables
```powershell
# Add to System Environment Variables
[Environment]::SetEnvironmentVariable("GOPATH", "$env:USERPROFILE\go", "User")
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$env:USERPROFILE\go\bin", "User")

# Restart PowerShell after setting variables
```

### 4. Clone and Setup Project
```powershell
# Clone repository
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles

# Pull LFS files
git lfs pull

# Install dependencies
cd server\game-server
npm install

cd ..\matchmaking
go mod download

cd ..\economy
python -m pip install -r requirements.txt

# Return to root
cd ..\..
```

## Linux Setup

### Ubuntu/Debian

```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install build essentials
sudo apt install -y build-essential curl wget software-properties-common

# Install Git with LFS
sudo apt install -y git git-lfs
git lfs install

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
rm go1.21.5.linux-amd64.tar.gz

# Install Python
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install Docker
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker

# Install Godot (via Flatpak)
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub org.godotengine.Godot -y
```

### Arch Linux

```bash
# Install development tools
sudo pacman -S base-devel git git-lfs nodejs npm go python python-pip docker docker-compose

# Install Godot
sudo pacman -S godot

# Enable Docker service
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### Configure Environment
```bash
# Add to ~/.bashrc or ~/.zshrc
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# Reload shell
source ~/.bashrc
```

## Raspberry Pi 5 Setup

### 1. Update System
```bash
# Update Raspberry Pi OS
sudo apt update && sudo apt full-upgrade -y
sudo rpi-update

# Install essentials
sudo apt install -y build-essential git git-lfs curl wget
```

### 2. Install Development Tools
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Go (ARM64 version)
wget https://go.dev/dl/go1.21.5.linux-arm64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-arm64.tar.gz
rm go1.21.5.linux-arm64.tar.gz

# Install Python
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Godot (compile from source for ARM64)
sudo apt install -y scons pkg-config libx11-dev libxcursor-dev \
    libxinerama-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
    libpulse-dev libudev-dev libxi-dev libxrandr-dev

git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.3-stable
scons platform=linuxbsd target=editor use_llvm=yes -j4
sudo cp bin/godot.linuxbsd.editor.arm64 /usr/local/bin/godot
cd ..
```

### 3. Optimize for Performance
```bash
# Increase GPU memory split
sudo raspi-config
# Navigate to: Advanced Options > Memory Split > Set to 256

# Enable performance governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Add to /boot/config.txt for permanent changes
sudo nano /boot/config.txt
# Add:
# gpu_mem=256
# over_voltage=6
# arm_freq=2400
```

## IDE Configuration

### Visual Studio Code

#### Extensions to Install
```bash
# Install VS Code extensions
code --install-extension geequlim.godot-tools
code --install-extension ms-python.python
code --install-extension golang.go
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-azuretools.vscode-docker
```

#### Settings (.vscode/settings.json)
```json
{
  "godot_tools.editor_path": "/usr/local/bin/godot",
  "godot_tools.gdscript_lsp_server_port": 6008,

  "[gdscript]": {
    "editor.insertSpaces": false,
    "editor.tabSize": 4
  },

  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },

  "[go]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  },

  "[python]": {
    "editor.formatOnSave": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true
  }
}
```

### JetBrains Rider / GoLand / PyCharm

#### Godot Plugin
1. Install Godot Support plugin from marketplace
2. Configure Godot executable path in settings
3. Set GDScript file associations

#### Project Structure
```
File > Project Structure:
- Mark `client/` as Sources Root
- Mark `server/*/src` as Sources Root
- Mark `tests/` as Test Sources Root
```

## Running the Project

### 1. Start Backend Services

#### Using Docker Compose (Recommended)
```bash
# From project root
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

#### Manual Setup (Alternative)
```bash
# Terminal 1: PostgreSQL
postgres -D /usr/local/var/postgres

# Terminal 2: Redis
redis-server

# Terminal 3: Game Server
cd server/game-server
npm run dev

# Terminal 4: Matchmaking Service
cd server/matchmaking
go run cmd/server/main.go

# Terminal 5: Economy Service
cd server/economy
uvicorn app.main:app --reload --port 3003
```

### 2. Initialize Database
```bash
# Run migrations
cd server/game-server
npm run db:migrate

cd ../economy
alembic upgrade head
```

### 3. Launch Godot Client
```bash
# Open Godot project
godot --editor client/project.godot

# Or run directly
godot client/project.godot

# For debugging
godot --verbose --debug client/project.godot
```

### 4. Test Multiplayer Locally
```bash
# Host a game (Player 1)
# In Godot: Run project > Select "Host Game"

# Join game (Player 2)
# In Godot: Debug > Run Multiple Instances > 2
# Select "Join Game" > Enter room code or use LAN discovery
```

## Environment Configuration

### Create .env files

#### Root .env
```bash
# Environment
NODE_ENV=development
LOG_LEVEL=debug

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=battle_castles
DB_USER=postgres
DB_PASSWORD=localdev123

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-secret-key-for-local-dev

# Ports
GAME_SERVER_PORT=3001
MATCHMAKING_PORT=3002
ECONOMY_PORT=3003
API_GATEWAY_PORT=8001
```

#### Client Configuration (client/config.ini)
```ini
[network]
game_server_url="ws://localhost:3001"
matchmaking_url="http://localhost:3002"
api_gateway_url="http://localhost:8001"

[debug]
enable_debug_ui=true
show_fps_counter=true
enable_console=true
```

## Testing Setup

### Running Tests

#### Client Tests (Godot)
```bash
# Run all tests
godot --headless --script client/tests/run_all_tests.gd

# Run specific test suite
godot --headless --script client/tests/unit/test_combat_system.gd
```

#### Server Tests
```bash
# Node.js tests
cd server/game-server
npm test
npm run test:watch  # Watch mode
npm run test:coverage  # With coverage

# Go tests
cd server/matchmaking
go test ./...
go test -v -cover ./...  # Verbose with coverage

# Python tests
cd server/economy
pytest
pytest --cov=app  # With coverage
pytest -v -s  # Verbose with print statements
```

### Performance Testing
```bash
# Load testing with k6
k6 run tests/performance/load_test.js

# Stress testing
k6 run --vus 100 --duration 5m tests/performance/stress_test.js
```

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port
lsof -i :3001  # macOS/Linux
netstat -ano | findstr :3001  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### Docker Issues
```bash
# Reset Docker
docker-compose down -v
docker system prune -a
docker-compose up --build

# Check Docker logs
docker-compose logs <service_name>
```

#### Godot Can't Connect to Server
1. Check firewall settings
2. Verify server is running: `curl http://localhost:3001/health`
3. Check WebSocket support: `wscat -c ws://localhost:3001`
4. Review client logs: Enable verbose logging in Godot

#### Database Connection Failed
```bash
# Verify PostgreSQL is running
pg_isready -h localhost -p 5432

# Check credentials
psql -U postgres -h localhost -d battle_castles

# Reset database
dropdb battle_castles
createdb battle_castles
npm run db:migrate
```

#### Node Module Issues
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Debug Mode

#### Enable Debug Logging
```gdscript
# In Godot project settings
debug/settings/stdout/print_fps = true
debug/settings/stdout/verbose_stdout = true
network/limits/debugger_stdout/max_messages_per_frame = 100
```

#### Server Debug Mode
```javascript
// Add to server startup
if (process.env.NODE_ENV === 'development') {
  require('longjohn');  // Better stack traces
  process.env.DEBUG = '*';  // Enable all debug output
}
```

## Next Steps

After setting up your development environment:

1. Read the [Coding Standards Guide](../guides/CODING_STANDARDS.md)
2. Review the [Architecture Documentation](../architecture/README.md)
3. Check the [Sprint Planning](../SPRINT_PLAN.md)
4. Join the team communication channels
5. Pick a task from the current sprint backlog

## Getting Help

- **Documentation:** Check `/docs` folder
- **Team Chat:** Join the Slack/Discord
- **Issue Tracker:** Report bugs on GitHub
- **Wiki:** Additional resources on project wiki

---

**Remember:**
- Always pull latest changes before starting work
- Run tests before committing
- Follow the branching strategy
- Update documentation when adding features