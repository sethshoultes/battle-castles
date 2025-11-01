# Battle Castles Game Server

Authoritative multiplayer game server for Battle Castles, built with Node.js, TypeScript, and Socket.IO.

## Features

- **Fully Authoritative Server**: All game logic runs server-side to prevent cheating
- **Real-time Multiplayer**: WebSocket-based communication with Socket.IO
- **20Hz Tick Rate**: Smooth gameplay with 50ms update intervals
- **Anti-Cheat Protection**: Command validation, rate limiting, and state verification
- **Automatic Matchmaking**: Queue-based system that pairs players
- **Docker Support**: Containerized deployment ready

## Architecture

### Core Components

1. **GameRoom** (`src/GameRoom.ts`)
   - Manages 2-player battle sessions
   - Handles command processing and game loop
   - Synchronizes state to clients

2. **BattleState** (`src/BattleState.ts`)
   - Authoritative game state management
   - Unit movement and combat simulation
   - Tower mechanics and win conditions

3. **CommandValidator** (`src/CommandValidator.ts`)
   - Validates all player inputs
   - Anti-cheat verification
   - Rate limiting protection

4. **MatchmakingQueue** (`src/MatchmakingQueue.ts`)
   - Pairs players for battles
   - Manages room lifecycle
   - Handles disconnections

## Setup

### Prerequisites

- Node.js 20+
- npm or yarn
- Docker (optional)

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Build TypeScript
npm run build

# Start development server
npm run dev
```

### Docker Deployment

```bash
# Build Docker image
docker build -t battle-castles-server .

# Run container
docker run -p 3001:3001 --env-file .env battle-castles-server
```

## Game Mechanics

### Units
- **Knight**: Balanced melee fighter (3 elixir)
- **Archer**: Ranged damage dealer (2 elixir)
- **Wizard**: Area damage caster (4 elixir)
- **Giant**: High HP tank (5 elixir)
- **Goblin**: Fast, cheap unit (1 elixir)
- **Dragon**: Flying powerhouse (7 elixir)

### Towers
- **Main Tower**: 4000 HP, must be destroyed to win
- **Side Towers**: 2500 HP each, provide map control

### Win Conditions
1. Destroy enemy's main tower
2. Have more crowns when time runs out
3. Opponent surrenders or disconnects

## API Endpoints

### HTTP Endpoints

- `GET /health` - Server health check and statistics
- `GET /info` - Server configuration information

### WebSocket Events

#### Client → Server
- `join_queue` - Enter matchmaking
- `leave_queue` - Exit matchmaking
- `game_command` - Send game action
- `ping` - Latency check

#### Server → Client
- `queue_joined` - Confirmed in queue
- `game_found` - Match started
- `game_state_update` - State synchronization
- `game_ended` - Match complete
- `error` - Error notification

## Environment Variables

```env
PORT=3001                    # Server port
CORS_ORIGIN=http://localhost:3000  # Client origin
LOG_LEVEL=info              # Logging verbosity
MAX_ROOMS=100               # Maximum concurrent games
TICK_RATE=20                # Updates per second
```

## Security Features

- **Command Validation**: Every player action is verified
- **Rate Limiting**: Prevents command spam (10 commands/second)
- **Timestamp Verification**: Prevents replay attacks
- **Elixir Tracking**: Server-authoritative resource management
- **Position Validation**: Deployment zone enforcement

## Development

```bash
# Run tests
npm test

# Lint code
npm run lint

# Watch mode for development
npm run dev
```

## Production Considerations

1. **Scaling**: Use Redis for session storage when scaling horizontally
2. **Monitoring**: Implement metrics collection (Prometheus/Grafana)
3. **Load Balancing**: Use sticky sessions for WebSocket connections
4. **Database**: Add persistent storage for player stats and match history
5. **Authentication**: Implement JWT-based authentication system

## License

ISC