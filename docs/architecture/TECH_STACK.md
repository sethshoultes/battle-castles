# Technology Stack Specification

## Overview

This document details the complete technology stack for Battle Castles, including rationale for each choice, version requirements, and integration strategies.

## Client Technology

### Game Engine: Godot 4.3

**Version:** 4.3.0+ (Latest stable)

**Rationale:**
- Cross-platform support including ARM64 (Raspberry Pi)
- Lightweight runtime (~50MB)
- Open source (MIT license)
- Built-in networking (ENet/WebSocket)
- Excellent 2D performance
- Active community support

**Configuration:**
```ini
# project.godot key settings
config/name="Battle Castles"
config/version="1.0.0"
rendering/renderer/rendering_method="mobile"
rendering/textures/vram_compression/import_etc2_astc=true
physics/2d/default_gravity=0.0
network/limits/packet_peer_stream/max_buffer_po2=20
```

### Programming Languages

#### GDScript (Primary - 80%)
**Version:** GDScript 2.0 (Godot 4.x)

**Use Cases:**
- Game logic implementation
- UI/UX systems
- Network client code
- AI behavior scripts
- Scene management

**Example Structure:**
```gdscript
# Follows Godot style guide
class_name BattleUnit extends CharacterBody2D

signal unit_deployed(unit: BattleUnit)
signal unit_destroyed(unit: BattleUnit)

@export var unit_resource: UnitResource
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var current_health: int
var target: Node2D
```

#### C++ (Performance Critical - 20%)
**Version:** C++17 with GDExtension

**Use Cases:**
- Pathfinding algorithms (A*)
- Combat damage calculations
- Network packet processing
- Deterministic math operations

**Build Configuration:**
```python
# SConstruct for GDExtension
env = SConscript("godot-cpp/SConstruct")
env.Append(CPPPATH=["src/"])
env.SharedLibrary(
    "bin/battle_castles",
    source=Glob("src/*.cpp"),
    target_name="battle_castles"
)
```

## Server Technology

### Game Server

#### Node.js + TypeScript
**Version:** Node.js 20.x LTS, TypeScript 5.x

**Packages:**
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.6.0",
    "ws": "^8.14.0",
    "uuid": "^9.0.0",
    "dotenv": "^16.3.0",
    "winston": "^3.11.0",
    "joi": "^17.11.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0",
    "ts-node": "^10.9.0",
    "nodemon": "^3.0.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.0",
    "supertest": "^6.3.0"
  }
}
```

**Architecture:**
```typescript
// server/game-server/src/BattleRoom.ts
export class BattleRoom {
  private readonly roomId: string;
  private readonly players: Map<string, Player>;
  private gameState: GameState;
  private readonly tickRate: number = 20; // 20Hz

  constructor(roomId: string) {
    this.roomId = roomId;
    this.players = new Map();
    this.gameState = new GameState();
    this.startGameLoop();
  }

  private startGameLoop(): void {
    setInterval(() => this.tick(), 1000 / this.tickRate);
  }
}
```

### Matchmaking Service

#### Go
**Version:** Go 1.21+

**Dependencies:**
```go
// go.mod
module github.com/battle-castles/matchmaking

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-redis/redis/v8 v8.11.5
    github.com/google/uuid v1.4.0
    github.com/sirupsen/logrus v1.9.3
    github.com/stretchr/testify v1.8.4
)
```

**Structure:**
```go
// server/matchmaking/internal/queue/queue.go
package queue

type MatchmakingQueue struct {
    mutex    sync.RWMutex
    players  []Player
    ticker   *time.Ticker
}

func (q *MatchmakingQueue) AddPlayer(p Player) {
    q.mutex.Lock()
    defer q.mutex.Unlock()
    q.players = append(q.players, p)
}

func (q *MatchmakingQueue) FindMatches() []Match {
    // Skill-based matching algorithm
}
```

### Economy Service

#### Python + FastAPI
**Version:** Python 3.11+, FastAPI 0.104+

**Requirements:**
```txt
# requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
alembic==1.12.1
pydantic==2.5.0
redis==5.0.1
httpx==0.25.2
pytest==7.4.3
pytest-asyncio==0.21.1
```

**Structure:**
```python
# server/economy/app/api/transactions.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Transaction
from ..schemas import TransactionCreate, TransactionResponse

router = APIRouter()

@router.post("/transactions", response_model=TransactionResponse)
async def create_transaction(
    transaction: TransactionCreate,
    db: Session = Depends(get_db)
):
    # Validate and process transaction
    pass
```

## Database Stack

### PostgreSQL
**Version:** 14.x or 15.x

**Schema Example:**
```sql
-- Primary database schema
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(32) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE player_stats (
    player_id UUID REFERENCES players(id),
    trophies INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    PRIMARY KEY (player_id)
);

CREATE TABLE card_collection (
    player_id UUID REFERENCES players(id),
    card_id VARCHAR(50),
    quantity INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    PRIMARY KEY (player_id, card_id)
);
```

**Connection Configuration:**
```javascript
// Node.js connection
const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.DB_HOST,
  port: 5432,
  database: 'battle_castles',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### Redis
**Version:** 7.x

**Use Cases:**
- Session management
- Matchmaking queues
- Real-time leaderboards
- Cache layer
- Rate limiting

**Configuration:**
```javascript
// Redis client setup
const redis = require('redis');
const client = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: 6379
  },
  password: process.env.REDIS_PASSWORD,
  database: 0
});

// Data structures used
// Sorted Set for leaderboard
await client.zAdd('leaderboard:global', {
  score: trophyCount,
  value: playerId
});

// List for matchmaking queue
await client.lPush('queue:matchmaking', JSON.stringify(playerData));

// Hash for session data
await client.hSet(`session:${sessionId}`, {
  playerId,
  lastActive: Date.now()
});
```

## Infrastructure & DevOps

### Containerization

#### Docker
**Version:** Docker Engine 24.x, Docker Compose 2.x

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: battle_castles
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

  game-server:
    build:
      context: ./server/game-server
      dockerfile: Dockerfile
    environment:
      NODE_ENV: development
      DB_HOST: postgres
      REDIS_HOST: redis
    ports:
      - "3001:3001"
    depends_on:
      - postgres
      - redis

  matchmaking:
    build:
      context: ./server/matchmaking
      dockerfile: Dockerfile
    environment:
      REDIS_HOST: redis
    ports:
      - "3002:3002"
    depends_on:
      - redis

  economy:
    build:
      context: ./server/economy
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres/battle_castles
    ports:
      - "3003:3003"
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:
```

### CI/CD

#### GitHub Actions
**Workflows:**

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint GDScript
        run: |
          pip install gdtoolkit
          gdformat --check client/

      - name: Lint TypeScript
        working-directory: ./server/game-server
        run: |
          npm ci
          npm run lint

      - name: Lint Go
        working-directory: ./server/matchmaking
        run: |
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          golangci-lint run

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: |
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit

  build:
    runs-on: ubuntu-latest
    needs: test
    strategy:
      matrix:
        platform: [linux, windows, macos]
    steps:
      - uses: actions/checkout@v4
      - name: Build Client
        uses: chickensoft/setup-godot@v1
        with:
          version: 4.3.0
      - run: |
          godot --export "${{ matrix.platform }}" \
                "builds/battle_castles_${{ matrix.platform }}"
```

## Development Tools

### Version Control

#### Git Configuration
**.gitignore:**
```gitignore
# Godot
.godot/
*.tmp
export_presets.cfg

# Node.js
node_modules/
dist/
*.log
.env

# Python
__pycache__/
*.py[cod]
.venv/
*.egg-info/

# Go
vendor/
*.exe
*.test

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Builds
builds/
*.apk
*.ipa
```

**.gitattributes:**
```gitattributes
# Auto detect text files
* text=auto

# Godot files
*.tscn text eol=lf
*.tres text eol=lf
*.gd text eol=lf
*.cfg text eol=lf

# Images
*.png binary
*.jpg binary
*.svg text

# Audio
*.ogg binary
*.wav binary

# Git LFS
*.psd filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
```

### Testing Frameworks

#### Client Testing

**GdUnit4 for Godot:**
```gdscript
# tests/unit/test_elixir_system.gd
extends GdUnitTestSuite

func test_elixir_regeneration():
    var elixir_manager = ElixirManager.new()
    elixir_manager.current_elixir = 0

    # Simulate 2.8 seconds
    for i in range(168):  # 2.8s * 60fps
        elixir_manager._process(1.0/60.0)

    assert_float(elixir_manager.current_elixir).is_equal_approx(1.0, 0.01)
```

#### Server Testing

**Jest for Node.js:**
```javascript
// server/game-server/tests/battle.test.js
describe('Battle System', () => {
  test('damage calculation', () => {
    const damage = calculateDamage(knightStats, goblinStats);
    expect(damage).toBe(75);
  });

  test('elixir regeneration', () => {
    const manager = new ElixirManager();
    manager.update(2.8);
    expect(manager.current).toBeCloseTo(6.0);
  });
});
```

**Go Testing:**
```go
// server/matchmaking/internal/queue/queue_test.go
func TestMatchmaking(t *testing.T) {
    queue := NewMatchmakingQueue()

    player1 := Player{ID: "1", Trophy: 1000}
    player2 := Player{ID: "2", Trophy: 1050}

    queue.AddPlayer(player1)
    queue.AddPlayer(player2)

    matches := queue.FindMatches()

    assert.Len(t, matches, 1)
    assert.Contains(t, matches[0].Players, player1)
    assert.Contains(t, matches[0].Players, player2)
}
```

**Pytest for Python:**
```python
# server/economy/tests/test_transactions.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_create_transaction():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/transactions", json={
            "player_id": "123",
            "currency": "gold",
            "amount": 100,
            "type": "reward"
        })
        assert response.status_code == 200
        assert response.json()["amount"] == 100
```

## Monitoring & Analytics

### Application Monitoring

**Prometheus + Grafana:**
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'game-server'
    static_configs:
      - targets: ['game-server:3001']

  - job_name: 'matchmaking'
    static_configs:
      - targets: ['matchmaking:3002']
```

### Logging

**Winston (Node.js):**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});
```

**Logrus (Go):**
```go
import "github.com/sirupsen/logrus"

func init() {
    logrus.SetFormatter(&logrus.JSONFormatter{})
    logrus.SetLevel(logrus.InfoLevel)
}
```

## Security

### Authentication

**JWT Implementation:**
```javascript
const jwt = require('jsonwebtoken');

function generateToken(userId) {
  return jwt.sign(
    { userId, timestamp: Date.now() },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function verifyToken(token) {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    throw new Error('Invalid token');
  }
}
```

### Environment Variables

**.env.example:**
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=battle_castles
DB_USER=postgres
DB_PASSWORD=changeme

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-secret-key-here

# Server Ports
GAME_SERVER_PORT=3001
MATCHMAKING_PORT=3002
ECONOMY_PORT=3003

# Environment
NODE_ENV=development
LOG_LEVEL=info
```

## Package Management

### Client (Godot)
- Built-in package management via Asset Library
- GDExtension for C++ modules
- Git submodules for custom addons

### Server Package Managers
- **Node.js:** npm/yarn with package-lock.json
- **Go:** Go modules (go.mod)
- **Python:** pip with requirements.txt or Poetry

## API Documentation

### OpenAPI/Swagger
```yaml
# api-spec.yml
openapi: 3.0.0
info:
  title: Battle Castles API
  version: 1.0.0

paths:
  /api/v1/auth/login:
    post:
      summary: Player login
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                username:
                  type: string
                password:
                  type: string
      responses:
        200:
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  token:
                    type: string
                  playerId:
                    type: string
```

## Platform-Specific Configurations

### Raspberry Pi 5
```ini
# project.godot overrides for RPi5
[rendering]
driver/threads/thread_model=1
quality/filters/use_nearest_mipmap_filter=true
quality/shadows/filter_mode=0
quality/reflections/texture_array_reflections=false
limits/rendering/max_renderable_lights=8
```

### Windows Build
```gdscript
# Export configuration
export_presets.cfg:
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
custom_features=""
export_filter="all_resources"
```

## Summary

This technology stack provides:
1. **Cross-platform compatibility** via Godot
2. **Scalable backend** with microservices
3. **Real-time networking** with WebSocket
4. **Robust data storage** with PostgreSQL/Redis
5. **Modern DevOps** with Docker/CI/CD
6. **Comprehensive testing** across all layers
7. **Security best practices** with JWT auth
8. **Performance monitoring** with Prometheus

The stack is optimized for rapid development while maintaining production-grade quality and supporting all target platforms including Raspberry Pi 5.