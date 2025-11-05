# Battle Castles Client Networking System

A comprehensive WebSocket-based networking system for the Battle Castles multiplayer tower defense game, designed to work with the Node.js authoritative game server.

## Architecture Overview

The client networking system follows a strict server-authoritative model where:
- The client never trusts its own state
- All game logic validation happens on the server
- Client provides input prediction for responsive gameplay
- Server state corrections are applied through rollback and replay

## Core Components

### 1. NetworkManager (`network_manager.gd`)
**Singleton autoload for WebSocket connection management**

Features:
- WebSocket connection to `ws://localhost:3001`
- Automatic reconnection with exponential backoff (max 5 attempts)
- Connection state management (DISCONNECTED, CONNECTING, CONNECTED, RECONNECTING)
- Heartbeat system for connection monitoring
- Message queuing for offline/reconnecting states

Key Methods:
```gdscript
# Connect to game server
network_manager.connect_to_server()

# Send a command to server
network_manager.send_command({"action": "spawnUnit", "params": {...}})

# Check connection status
if network_manager.is_connected():
    # Connected and ready
```

Signals:
- `connected()` - Successfully connected to server
- `disconnected()` - Connection lost
- `connection_error(error: String)` - Connection error occurred
- `state_received(state: Dictionary)` - Game state update from server
- `message_received(type: String, data: Dictionary)` - Generic message received

### 2. BattleSynchronizer (`battle_synchronizer.gd`)
**Manages game state synchronization with the authoritative server**

Features:
- Receives and applies server state updates
- Interpolates unit positions for smooth movement
- Handles entity spawning/destruction
- Manages state reconciliation after network corrections
- Buffers states for interpolation

Key Methods:
```gdscript
# Initialize with game node references
battle_sync.initialize(battle_node, unit_mgr, tower_mgr, resource_mgr)

# Client-side prediction
battle_sync.predict_unit_spawn("warrior", lane, player_id)
battle_sync.predict_tower_build("archer", position, player_id)
```

Signals:
- `unit_spawned(unit_data: Dictionary)` - Unit created
- `tower_built(tower_data: Dictionary)` - Tower created
- `castle_damaged(player_id: String, damage: int, new_health: int)`
- `battle_ended(winner_id: String)` - Match concluded

### 3. CommandBuffer (`command_buffer.gd`)
**Buffers and manages player input commands**

Features:
- Buffers commands with timestamps and tick numbers
- Handles command acknowledgments from server
- Implements rollback/replay for state corrections
- Tracks unacknowledged commands with timeout
- Provides latency estimation

Key Methods:
```gdscript
# Queue a player command
var cmd_id = command_buffer.queue_command("spawnUnit", {
    "unitType": "warrior",
    "lane": 1
})

# Get network statistics
var latency = command_buffer.get_latency_estimate()
var buffer_size = command_buffer.get_buffer_size()
```

Signals:
- `command_acknowledged(command_id: String)` - Server accepted command
- `command_rejected(command_id: String, reason: String)` - Command failed
- `rollback_required(to_tick: int)` - State correction needed

### 4. MatchmakingClient (`matchmaking_client.gd`)
**Handles matchmaking queue and room management**

Features:
- Join/leave matchmaking queue
- Queue position updates
- Match acceptance/declining
- Rematch requests
- Timeout handling (5 min search, 30 sec preparation)

Key Methods:
```gdscript
# Join matchmaking
matchmaking.join_queue("1v1", preferences)

# Accept found match
matchmaking.accept_match()

# Leave current match
matchmaking.leave_match()

# Get queue status
var position = matchmaking.get_queue_position()
var search_time = matchmaking.get_search_time()
```

Signals:
- `queue_joined(position: int)` - Entered matchmaking queue
- `queue_updated(position: int, total: int)` - Queue status changed
- `match_found(room_id: String, opponent: Dictionary)` - Match available
- `match_ready(initial_state: Dictionary)` - Game starting
- `match_cancelled(reason: String)` - Match aborted

## Setup Instructions

### 1. Add Autoloads
In Project Settings > Autoload, add these scripts in order:

1. NetworkManager → `res://scripts/network/network_manager.gd`
2. BattleSynchronizer → `res://scripts/network/battle_synchronizer.gd`
3. CommandBuffer → `res://scripts/network/command_buffer.gd`
4. MatchmakingClient → `res://scripts/network/matchmaking_client.gd`

### 2. Initialize Connection
```gdscript
func _ready():
    var network = get_node("/root/NetworkManager")
    network.connected.connect(_on_connected)
    network.connect_to_server()
```

### 3. Handle Matchmaking
```gdscript
func find_match():
    var matchmaking = get_node("/root/MatchmakingClient")
    matchmaking.match_found.connect(_on_match_found)
    matchmaking.join_queue("1v1")

func _on_match_found(room_id: String, opponent: Dictionary):
    # Show match found UI
    matchmaking.accept_match()
```

### 4. Send Game Commands
```gdscript
func spawn_unit(type: String, lane: int):
    var cmd_buffer = get_node("/root/CommandBuffer")
    cmd_buffer.queue_command("spawnUnit", {
        "unitType": type,
        "lane": lane
    })
```

## Network Protocol

### Message Format
All messages follow this structure:
```json
{
    "type": "messageType",
    "data": {
        // Message-specific data
    },
    "timestamp": 1234567890.123,
    "tick": 120
}
```

### Common Message Types

**Client → Server:**
- `handshake` - Initial connection
- `joinQueue` - Enter matchmaking
- `acceptMatch` - Accept found match
- `command` - Game action
- `ping` - Heartbeat

**Server → Client:**
- `welcome` - Connection confirmed with player ID
- `state` - Full game state update
- `matchFound` - Match available
- `gameStart` - Match beginning
- `commandAck` - Command accepted
- `commandReject` - Command failed

## Error Handling

The system includes comprehensive error handling:

1. **Connection Errors**: Automatic reconnection with exponential backoff
2. **Command Timeouts**: Retry 3 times, then rollback prediction
3. **State Mismatches**: Reconciliation through rollback and replay
4. **Match Cancellations**: Auto-requeue or return to menu

## Performance Considerations

- **State Buffer**: Keeps last 10 states for interpolation
- **Command Buffer**: Maximum 60 commands (1 second at 60 FPS)
- **Prediction Limit**: Maximum 5 frames ahead
- **Interpolation Speed**: Configurable, default 10.0
- **Network Updates**: 20Hz tick rate from server

## Testing

Use the provided test scene to verify networking:

1. Load `tests/network_test_ui.tscn`
2. Ensure server is running on `localhost:3001`
3. Click "Connect" to establish connection
4. Use "Find Match" for matchmaking
5. Test game commands when in match

## Debugging

Enable verbose logging:
```gdscript
# In NetworkManager
func _ready():
    OS.set_environment("VERBOSE_NET", "1")
```

Monitor network statistics:
```gdscript
var stats = {
    "latency": command_buffer.get_latency_estimate(),
    "buffer_size": command_buffer.get_buffer_size(),
    "unacked": command_buffer.get_unacknowledged_count(),
    "state": network_manager.get_connection_state()
}
```

## Best Practices

1. **Never trust client state** - Always validate on server
2. **Use prediction sparingly** - Only for immediate feedback
3. **Handle disconnections gracefully** - Save state, attempt reconnection
4. **Batch commands when possible** - Reduce network overhead
5. **Monitor performance** - Track latency and adjust interpolation

## Troubleshooting

### Connection Issues
- Verify server is running on correct port
- Check firewall settings
- Ensure WebSocket support in network

### State Synchronization Problems
- Increase state buffer size if needed
- Adjust interpolation speed for smoothness
- Check server tick rate matches expectations

### Command Rejections
- Verify command parameters match server expectations
- Check player has required resources/permissions
- Ensure commands sent at appropriate game phase

## Future Enhancements

Planned improvements:
- [ ] UDP support for real-time updates
- [ ] Advanced lag compensation
- [ ] Client-side extrapolation
- [ ] Network quality indicators
- [ ] Replay system integration
- [ ] Spectator mode support