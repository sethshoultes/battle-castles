# Battle Castles - API Documentation

Version 0.1.0 | Server API Reference

---

## Table of Contents

1. [Overview](#overview)
2. [WebSocket API](#websocket-api)
3. [HTTP REST API](#http-rest-api)
4. [Message Formats](#message-formats)
5. [Authentication](#authentication)
6. [Error Codes](#error-codes)
7. [Rate Limiting](#rate-limiting)
8. [Code Examples](#code-examples)

---

## Overview

### Architecture

Battle Castles uses a hybrid communication model:

- **WebSocket (Socket.IO)** - Real-time game events, matchmaking, state updates
- **HTTP REST** - Health checks, server info, administrative functions

### Server Endpoints

| Service | Protocol | Port | Purpose |
|---------|----------|------|---------|
| Game Server | WebSocket | 8002 | Real-time multiplayer battles |
| Game Server | HTTP | 8002 | Health checks, server info |

### Base URL

```
Development: ws://localhost:8002
Production: wss://api.battlecastles.game
```

---

## WebSocket API

### Connection

#### Connect to Game Server

**URL:** `ws://localhost:8002`

**Protocol:** Socket.IO (WebSocket + HTTP fallback)

**Connection Example:**

```javascript
// JavaScript (Socket.IO client)
import io from 'socket.io-client';

const socket = io('http://localhost:8002', {
  transports: ['websocket', 'polling'],
  reconnection: true,
  reconnectionAttempts: 5,
  reconnectionDelay: 1000
});

socket.on('connect', () => {
  console.log('Connected to game server');
});

socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason);
});
```

```gdscript
# GDScript (Godot WebSocket)
extends Node

var socket = WebSocketClient.new()
var url = "ws://localhost:8002"

func _ready():
    socket.connect("connection_established", _on_connected)
    socket.connect("connection_closed", _on_disconnected)
    socket.connect("data_received", _on_data)

    var err = socket.connect_to_url(url)
    if err != OK:
        print("Error connecting: ", err)

func _on_connected(protocol):
    print("Connected to server")

func _on_disconnected(was_clean):
    print("Disconnected from server")

func _on_data():
    var data = socket.get_peer(1).get_packet()
    var json = JSON.parse_string(data.get_string_from_utf8())
    _handle_message(json)
```

---

### Events

### Client → Server Events

#### 1. JOIN_QUEUE

Join the matchmaking queue to find an opponent.

**Event Name:** `join_queue`

**Payload:**

```typescript
{
  playerName: string;  // Display name (max 20 chars)
}
```

**Example:**

```javascript
socket.emit('join_queue', {
  playerName: 'Alice'
});
```

**Response:** `queue_joined` or `error`

---

#### 2. LEAVE_QUEUE

Leave the matchmaking queue before a match is found.

**Event Name:** `leave_queue`

**Payload:** None

**Example:**

```javascript
socket.emit('leave_queue');
```

**Response:** `queue_left`

---

#### 3. GAME_COMMAND

Send a gameplay command during an active match.

**Event Name:** `game_command`

**Payload:**

```typescript
{
  command: DeployUnitCommand | CastSpellCommand | SurrenderCommand
}
```

**Command Types:**

##### Deploy Unit Command

```typescript
{
  type: 'deploy_unit',
  unitType: 'knight' | 'goblin' | 'archer' | 'giant',
  position: {
    x: number,  // Pixel coordinates
    y: number
  },
  timestamp: number  // Client timestamp (ms)
}
```

##### Cast Spell Command (Future)

```typescript
{
  type: 'cast_spell',
  spellType: string,
  position: { x: number, y: number },
  timestamp: number
}
```

##### Surrender Command

```typescript
{
  type: 'surrender',
  timestamp: number
}
```

**Example:**

```javascript
socket.emit('game_command', {
  command: {
    type: 'deploy_unit',
    unitType: 'knight',
    position: { x: 500, y: 650 },
    timestamp: Date.now()
  }
});
```

**Response:** `game_state_update` or `error`

**Validation:**
- Sufficient elixir for unit cost
- Position within deployment zone
- Unit count < 8 per player
- Game is active

---

#### 4. PING

Request server latency measurement.

**Event Name:** `ping`

**Payload:**

```typescript
{
  timestamp: number  // Client timestamp
}
```

**Response:** `pong` with server timestamp

---

### Server → Client Events

#### 1. QUEUE_JOINED

Confirmation that you've joined the matchmaking queue.

**Event Name:** `queue_joined`

**Payload:**

```typescript
{
  queuePosition: number,  // Your position in queue
  estimatedWaitTime: number  // Seconds (estimate)
}
```

**Example:**

```javascript
socket.on('queue_joined', (data) => {
  console.log(`Joined queue at position ${data.queuePosition}`);
  console.log(`Estimated wait: ${data.estimatedWaitTime}s`);
});
```

---

#### 2. QUEUE_LEFT

Confirmation that you've left the queue.

**Event Name:** `queue_left`

**Payload:**

```typescript
{
  reason: 'user_request' | 'game_found' | 'timeout'
}
```

---

#### 3. GAME_FOUND

A match has been found! Battle will begin shortly.

**Event Name:** `game_found`

**Payload:**

```typescript
{
  roomId: string,  // Unique room identifier
  opponentName: string,  // Opponent's display name
  yourTeam: 'left' | 'right',  // Your team assignment
  countdown: number  // Seconds until battle starts (usually 3)
}
```

**Example:**

```javascript
socket.on('game_found', (data) => {
  console.log(`Match found! vs ${data.opponentName}`);
  console.log(`You are team: ${data.yourTeam}`);
  // Navigate to battle scene
});
```

---

#### 4. GAME_STATE_UPDATE

Real-time game state synchronization (20 ticks/second).

**Event Name:** `game_state_update`

**Payload:**

```typescript
{
  roomId: string,
  gameTime: number,  // Seconds elapsed
  isActive: boolean,

  players: [
    {
      id: string,
      name: string,
      team: 'left' | 'right',
      elixir: number,  // Current elixir (0-10)
      maxElixir: number,  // Always 10
      crowns: number,  // Towers destroyed (0-3)
      isConnected: boolean
    }
  ],

  units: [
    {
      id: string,  // Unique unit ID
      type: 'knight' | 'goblin' | 'archer' | 'giant',
      team: 'left' | 'right',
      position: { x: number, y: number },
      health: number,
      maxHealth: number,
      target: string | null,  // Target unit/tower ID
      isAlive: boolean
    }
  ],

  towers: [
    {
      id: string,
      type: 'main' | 'left' | 'right',  // Main = King's Castle
      team: 'left' | 'right',
      position: { x: number, y: number },
      health: number,
      maxHealth: number,
      isDestroyed: boolean
    }
  ],

  winner: 'left' | 'right' | null  // Set when game ends
}
```

**Update Frequency:** 20 Hz (every 50ms)

**Example:**

```javascript
socket.on('game_state_update', (state) => {
  // Update local game state
  updateUnits(state.units);
  updateTowers(state.towers);
  updateElixir(state.players[0].elixir);
});
```

---

#### 5. GAME_ENDED

Battle has concluded.

**Event Name:** `game_ended`

**Payload:**

```typescript
{
  winner: 'left' | 'right',
  reason: 'towers_destroyed' | 'time_limit' | 'surrender' | 'disconnect',
  finalState: {
    // Complete final game state
    gameTime: number,
    players: Player[],
    towers: Tower[],
    // ... full state snapshot
  },
  rewards: {
    trophies: number,  // Trophy change (+/-)
    gold: number,
    experience: number
  }
}
```

**Reasons:**
- `towers_destroyed` - King's Castle destroyed
- `time_limit` - 3 minutes elapsed, winner by damage
- `surrender` - Player surrendered
- `disconnect` - Opponent disconnected

**Example:**

```javascript
socket.on('game_ended', (data) => {
  if (data.winner === yourTeam) {
    showVictoryScreen(data.rewards);
  } else {
    showDefeatScreen();
  }
});
```

---

#### 6. ERROR

Server error or validation failure.

**Event Name:** `error`

**Payload:**

```typescript
{
  code: string,  // Error code (see Error Codes section)
  message: string,  // Human-readable message
  details?: any  // Optional additional info
}
```

**Example:**

```javascript
socket.on('error', (error) => {
  console.error(`Error ${error.code}: ${error.message}`);
  showErrorToast(error.message);
});
```

---

#### 7. PONG

Response to ping request (for latency measurement).

**Event Name:** `pong`

**Payload:**

```typescript
{
  clientTimestamp: number,  // Your original timestamp
  serverTimestamp: number,  // Server timestamp
  serverTime: number  // Server game time
}
```

**Example:**

```javascript
socket.emit('ping', { timestamp: Date.now() });

socket.on('pong', (data) => {
  const latency = Date.now() - data.clientTimestamp;
  console.log(`Latency: ${latency}ms`);
});
```

---

## HTTP REST API

### Health Check

Check if server is running and healthy.

**Endpoint:** `GET /health`

**Response:**

```json
{
  "status": "healthy",
  "uptime": 12345.67,
  "timestamp": 1699999999999,
  "activeGames": 42,
  "queuedPlayers": 15,
  "totalConnections": 120
}
```

**Status Codes:**
- `200 OK` - Server is healthy
- `503 Service Unavailable` - Server is down or degraded

---

### Server Info

Get server configuration and metadata.

**Endpoint:** `GET /info`

**Response:**

```json
{
  "name": "Battle Castles Game Server",
  "version": "1.0.0",
  "tickRate": 20,
  "maxPlayers": 2,
  "port": 8002,
  "features": [
    "matchmaking",
    "lan_multiplayer",
    "ai_opponents"
  ]
}
```

---

## Message Formats

### Standard Message Envelope

All WebSocket messages follow this format:

```typescript
{
  type: string,  // Event name
  payload: any,  // Event-specific data
  timestamp?: number  // Server timestamp (optional)
}
```

### Vector2 Format

Positions and coordinates:

```typescript
{
  x: number,  // Pixel X coordinate
  y: number   // Pixel Y coordinate
}
```

**Coordinate System:**
- Origin (0, 0) = Top-left corner
- X increases rightward
- Y increases downward
- Battlefield size: 1920x1080 pixels (standard)

### Team Identifiers

```typescript
type TeamSide = 'left' | 'right';
```

- `left` = Bottom team (usually player in single-player)
- `right` = Top team (usually AI or opponent)

### Unit Types

```typescript
type UnitType = 'knight' | 'goblin' | 'archer' | 'giant';
```

### Tower Types

```typescript
type TowerType = 'main' | 'left' | 'right';
```

- `main` = King's Castle (center tower)
- `left` = Left Princess Tower
- `right` = Right Princess Tower

---

## Authentication

### Version 0.1.0 (LAN Only)

Current version uses **no authentication** for LAN multiplayer.

Players are identified by:
- Socket ID (assigned by server on connection)
- Player name (provided in `join_queue`)

### Future Versions (Online Play)

Planned authentication flow:

1. **Register/Login** - HTTP POST to auth service
2. **Receive JWT token** - Short-lived access token
3. **Connect with token** - Pass token in WebSocket handshake
4. **Token validation** - Server validates on each connection

**Future Auth Header:**

```javascript
const socket = io('http://localhost:8002', {
  auth: {
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  }
});
```

---

## Error Codes

### Client Errors (4xx)

| Code | Message | Cause | Solution |
|------|---------|-------|----------|
| `INVALID_COMMAND` | Invalid game command | Malformed command object | Check command format |
| `INSUFFICIENT_ELIXIR` | Not enough elixir | Unit cost > available elixir | Wait for elixir regen |
| `INVALID_POSITION` | Invalid deployment position | Position outside deployment zone | Deploy in your half |
| `MAX_UNITS_REACHED` | Maximum units deployed | Already have 8 units | Wait for units to die |
| `GAME_NOT_ACTIVE` | Game is not active | Command sent before/after battle | Only send during battle |
| `NOT_IN_GAME` | Not in an active game | Not matched yet | Join queue first |
| `ALREADY_IN_QUEUE` | Already in queue | Tried to join queue twice | Wait for match |

### Server Errors (5xx)

| Code | Message | Cause | Solution |
|------|---------|-------|----------|
| `INTERNAL_ERROR` | Internal server error | Server bug or crash | Report to developers |
| `MATCHMAKING_ERROR` | Matchmaking failed | Queue system error | Retry joining queue |
| `STATE_SYNC_ERROR` | Failed to sync state | Network or state corruption | Reconnect |

### Network Errors

| Code | Message | Cause | Solution |
|------|---------|-------|----------|
| `CONNECTION_LOST` | Connection lost | Network interruption | Reconnect to server |
| `TIMEOUT` | Request timeout | No response from server | Check network, retry |
| `RATE_LIMITED` | Too many requests | Exceeded rate limit | Slow down requests |

---

## Rate Limiting

### Current Limits (v0.1.0)

| Action | Limit | Window | Penalty |
|--------|-------|--------|---------|
| Join Queue | 5 attempts | 1 minute | 30s cooldown |
| Deploy Unit | 20 commands | 1 second | Command rejected |
| Ping | 10 requests | 1 second | Ping ignored |

### Rate Limit Headers (Future HTTP API)

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1699999999
```

### Handling Rate Limits

**Client-side throttling:**

```javascript
// Throttle unit deployment to max 1 per 50ms
const deployUnit = throttle((unitType, position) => {
  socket.emit('game_command', {
    command: {
      type: 'deploy_unit',
      unitType,
      position,
      timestamp: Date.now()
    }
  });
}, 50);
```

---

## Code Examples

### Complete Matchmaking Flow

```javascript
import io from 'socket.io-client';

class GameClient {
  constructor() {
    this.socket = io('http://localhost:8002');
    this.setupListeners();
  }

  setupListeners() {
    this.socket.on('connect', () => {
      console.log('Connected to server');
    });

    this.socket.on('queue_joined', (data) => {
      console.log('Queue joined:', data);
      this.showWaitingScreen(data.estimatedWaitTime);
    });

    this.socket.on('game_found', (data) => {
      console.log('Game found:', data);
      this.startBattle(data.roomId, data.yourTeam);
    });

    this.socket.on('game_state_update', (state) => {
      this.updateGameState(state);
    });

    this.socket.on('game_ended', (result) => {
      this.endBattle(result);
    });

    this.socket.on('error', (error) => {
      console.error('Server error:', error);
      this.showError(error.message);
    });
  }

  joinQueue(playerName) {
    this.socket.emit('join_queue', { playerName });
  }

  deployUnit(unitType, position) {
    this.socket.emit('game_command', {
      command: {
        type: 'deploy_unit',
        unitType,
        position,
        timestamp: Date.now()
      }
    });
  }

  surrender() {
    this.socket.emit('game_command', {
      command: {
        type: 'surrender',
        timestamp: Date.now()
      }
    });
  }

  updateGameState(state) {
    // Update local game objects
    state.units.forEach(unit => {
      this.updateUnit(unit);
    });

    state.towers.forEach(tower => {
      this.updateTower(tower);
    });

    // Update UI
    const myPlayer = state.players.find(p => p.team === this.myTeam);
    this.updateElixirBar(myPlayer.elixir);
    this.updateCrownCount(myPlayer.crowns);
  }

  startBattle(roomId, yourTeam) {
    this.myTeam = yourTeam;
    this.roomId = roomId;
    // Transition to battle scene
  }

  endBattle(result) {
    const won = result.winner === this.myTeam;
    this.showResultsScreen(won, result.rewards);
  }
}

// Usage
const client = new GameClient();
client.joinQueue('PlayerName');
```

### GDScript Client Example

```gdscript
# client/scripts/network/multiplayer_client.gd
extends Node

signal connected()
signal game_found(room_id: String, team: String)
signal state_updated(game_state: Dictionary)
signal game_ended(winner: String, rewards: Dictionary)

var socket: WebSocketPeer
var server_url: String = "ws://localhost:8002"
var player_name: String = "Player"

func _ready() -> void:
    socket = WebSocketPeer.new()

func connect_to_server() -> void:
    var err = socket.connect_to_url(server_url)
    if err != OK:
        push_error("Failed to connect: " + str(err))

func _process(delta: float) -> void:
    socket.poll()

    var state = socket.get_ready_state()

    if state == WebSocketPeer.STATE_OPEN:
        while socket.get_available_packet_count():
            var packet = socket.get_packet()
            var message = packet.get_string_from_utf8()
            _handle_message(JSON.parse_string(message))

func join_queue() -> void:
    _send_message("join_queue", {"playerName": player_name})

func deploy_unit(unit_type: String, position: Vector2) -> void:
    var command = {
        "type": "deploy_unit",
        "unitType": unit_type,
        "position": {"x": position.x, "y": position.y},
        "timestamp": Time.get_ticks_msec()
    }
    _send_message("game_command", {"command": command})

func _send_message(event_type: String, payload: Dictionary) -> void:
    var message = {
        "type": event_type,
        "payload": payload
    }
    var json = JSON.stringify(message)
    socket.send_text(json)

func _handle_message(data: Dictionary) -> void:
    var event_type = data.get("type", "")
    var payload = data.get("payload", {})

    match event_type:
        "queue_joined":
            print("Joined queue at position ", payload.queuePosition)

        "game_found":
            game_found.emit(payload.roomId, payload.yourTeam)

        "game_state_update":
            state_updated.emit(payload)

        "game_ended":
            game_ended.emit(payload.winner, payload.rewards)

        "error":
            push_error("Server error: " + payload.message)
```

### Latency Measurement

```javascript
class LatencyMonitor {
  constructor(socket) {
    this.socket = socket;
    this.latencies = [];
    this.maxSamples = 10;
  }

  measureLatency() {
    const startTime = Date.now();

    this.socket.emit('ping', { timestamp: startTime });

    this.socket.once('pong', (data) => {
      const latency = Date.now() - data.clientTimestamp;
      this.latencies.push(latency);

      if (this.latencies.length > this.maxSamples) {
        this.latencies.shift();
      }
    });
  }

  getAverageLatency() {
    if (this.latencies.length === 0) return 0;
    const sum = this.latencies.reduce((a, b) => a + b, 0);
    return Math.round(sum / this.latencies.length);
  }

  startMonitoring(interval = 5000) {
    setInterval(() => this.measureLatency(), interval);
  }
}

// Usage
const monitor = new LatencyMonitor(socket);
monitor.startMonitoring();

setInterval(() => {
  const avgLatency = monitor.getAverageLatency();
  console.log(`Average latency: ${avgLatency}ms`);
}, 1000);
```

---

## Versioning

### API Version

Current API Version: **v1.0.0**

### Breaking Changes Policy

- Major version (1.x.x → 2.x.x) - Breaking changes
- Minor version (x.1.x → x.2.x) - New features, backward compatible
- Patch version (x.x.1 → x.x.2) - Bug fixes, backward compatible

### Deprecated Features

None in v0.1.0 (initial release)

---

## Troubleshooting

### Common Issues

**Connection Refused**
- Ensure game server is running
- Check firewall settings
- Verify correct port (8002)

**Commands Rejected**
- Check elixir availability
- Verify deployment zone
- Ensure game is active

**High Latency**
- Check network connection
- Close bandwidth-heavy applications
- Use wired connection instead of WiFi

**State Desync**
- Reconnect to server
- Report to developers if persistent

---

## Support

### Reporting Bugs

Please report API bugs with:
1. Error code received
2. Request sent
3. Expected vs actual behavior
4. Network logs

**GitHub Issues:** https://github.com/yourusername/battle-castles/issues

**Email:** support@battlecastles.game

---

**Version:** 0.1.0
**Last Updated:** November 1, 2025
**Protocol:** Socket.IO / WebSocket
**Server:** Node.js + TypeScript
