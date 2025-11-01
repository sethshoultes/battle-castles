# Network System Autoload Configuration

To use the networking system, add these scripts as autoloads in your Godot project settings:

## Project Settings > Autoload

Add the following autoloads in this order:

1. **NetworkManager**
   - Name: `NetworkManager`
   - Path: `res://scripts/network/network_manager.gd`
   - Enabled: ✓

2. **BattleSynchronizer**
   - Name: `BattleSynchronizer`
   - Path: `res://scripts/network/battle_synchronizer.gd`
   - Enabled: ✓

3. **CommandBuffer**
   - Name: `CommandBuffer`
   - Path: `res://scripts/network/command_buffer.gd`
   - Enabled: ✓

4. **MatchmakingClient**
   - Name: `MatchmakingClient`
   - Path: `res://scripts/network/matchmaking_client.gd`
   - Enabled: ✓

## Order is Important!

The NetworkManager must be loaded first as other components depend on it.