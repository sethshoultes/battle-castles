extends Node
## SoundPool - Advanced audio pooling system for efficient sound management
## Prevents audio cutoff and manages concurrent sound limits

class_name SoundPool

signal pool_exhausted()
signal sound_played(sound_name: String, player: AudioStreamPlayer2D)
signal sound_stopped(player: AudioStreamPlayer2D)

# Pool configuration
const DEFAULT_POOL_SIZE := 20
const MAX_POOL_SIZE := 50
const CLEANUP_INTERVAL := 5.0  # Seconds between cleanup checks

# Pool settings
@export var pool_size: int = DEFAULT_POOL_SIZE
@export var allow_dynamic_growth: bool = true
@export var max_same_sound: int = 3  # Max instances of the same sound playing
@export var priority_system: bool = true
@export var auto_cleanup: bool = true

# Pool management
var available_players: Array[AudioStreamPlayer2D] = []
var active_players: Array[AudioStreamPlayer2D] = []
var player_data: Dictionary = {}  # Store metadata for each player

# Sound tracking
var playing_sounds: Dictionary = {}  # Track count of each sound playing
var sound_priorities: Dictionary = {}  # Priority levels for different sounds

# Performance monitoring
var total_sounds_played: int = 0
var pool_exhaustion_count: int = 0
var sounds_interrupted: int = 0

# Cleanup timer
var cleanup_timer: Timer

# Debug
var debug_mode: bool = false

func _ready() -> void:
	_initialize_pool()
	_setup_cleanup_timer()

	if debug_mode:
		print("[SoundPool] Initialized with %d players" % pool_size)

func _initialize_pool() -> void:
	"""Create the initial pool of audio players"""
	for i in range(pool_size):
		_create_pool_player(i)

func _create_pool_player(index: int) -> AudioStreamPlayer2D:
	"""Create a single pooled audio player"""
	var player := AudioStreamPlayer2D.new()
	player.name = "PooledSound_%d" % index
	player.bus = AudioManager.BUS_SFX
	player.max_distance = 2000.0
	player.attenuation = 1.0
	add_child(player)

	# Connect signals
	player.finished.connect(_on_sound_finished.bind(player))

	# Initialize player data
	player_data[player] = {
		"sound_name": "",
		"priority": 0,
		"start_time": 0.0,
		"original_position": Vector2.ZERO,
		"is_looping": false
	}

	available_players.append(player)
	return player

func _setup_cleanup_timer() -> void:
	"""Setup timer for periodic cleanup"""
	if not auto_cleanup:
		return

	cleanup_timer = Timer.new()
	cleanup_timer.name = "CleanupTimer"
	cleanup_timer.wait_time = CLEANUP_INTERVAL
	cleanup_timer.timeout.connect(_perform_cleanup)
	cleanup_timer.autostart = true
	add_child(cleanup_timer)

## Main Play Functions
func play_sound(stream: AudioStream, sound_name: String, position: Vector2 = Vector2.ZERO,
		volume_db: float = 0.0, pitch: float = 1.0, priority: int = 0) -> AudioStreamPlayer2D:
	"""Play a sound with pooling and priority management"""

	# Check if we've hit the limit for this specific sound
	if _check_sound_limit(sound_name):
		if debug_mode:
			print("[SoundPool] Sound limit reached for: %s" % sound_name)
		return null

	# Get an available player
	var player := get_available_player(priority)
	if not player:
		pool_exhausted.emit()
		return null

	# Configure and play
	_configure_player(player, stream, sound_name, position, volume_db, pitch, priority)
	player.play()

	# Update tracking
	_track_sound_start(sound_name, player)

	total_sounds_played += 1
	sound_played.emit(sound_name, player)

	return player

func play_sound_3d(stream: AudioStream, sound_name: String, node_3d: Node3D,
		volume_db: float = 0.0, pitch: float = 1.0, priority: int = 0) -> AudioStreamPlayer3D:
	"""Play a 3D positional sound (requires 3D audio setup)"""
	# Note: This is a placeholder for 3D audio support
	# In a real implementation, you'd have a separate pool for AudioStreamPlayer3D
	push_warning("[SoundPool] 3D audio not yet implemented, using 2D fallback")
	var pos_2d := Vector2(node_3d.global_position.x, node_3d.global_position.z)
	return play_sound(stream, sound_name, pos_2d, volume_db, pitch, priority)

func play_looping_sound(stream: AudioStream, sound_name: String, position: Vector2 = Vector2.ZERO,
		volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	"""Play a looping sound that won't be automatically returned to pool"""
	var player := play_sound(stream, sound_name, position, volume_db, pitch, 100)  # High priority
	if player:
		player_data[player]["is_looping"] = true
		# Looping sounds must be manually stopped
	return player

func stop_sound(player: AudioStreamPlayer2D) -> void:
	"""Manually stop a sound and return it to the pool"""
	if not player or not player.playing:
		return

	player.stop()
	_on_sound_finished(player)
	sound_stopped.emit(player)

func stop_all_sounds() -> void:
	"""Stop all active sounds immediately"""
	for player in active_players.duplicate():
		stop_sound(player)

	playing_sounds.clear()

	if debug_mode:
		print("[SoundPool] All sounds stopped")

func stop_sounds_by_name(sound_name: String) -> void:
	"""Stop all instances of a specific sound"""
	for player in active_players:
		if player_data[player]["sound_name"] == sound_name:
			stop_sound(player)

## Player Management
func get_available_player(priority: int = 0) -> AudioStreamPlayer2D:
	"""Get an available player from the pool"""
	# First, try to get a free player
	if not available_players.is_empty():
		return available_players.pop_back()

	# Try to grow the pool if allowed
	if allow_dynamic_growth and get_child_count() < MAX_POOL_SIZE:
		var new_player := _create_pool_player(get_child_count())
		if debug_mode:
			print("[SoundPool] Dynamically grew pool to %d players" % get_child_count())
		return new_player

	# If priority system is enabled, try to interrupt a lower priority sound
	if priority_system:
		var lowest_priority_player := _find_lowest_priority_player(priority)
		if lowest_priority_player:
			stop_sound(lowest_priority_player)
			sounds_interrupted += 1
			return lowest_priority_player

	# No players available
	pool_exhaustion_count += 1
	if debug_mode:
		print("[SoundPool] Pool exhausted! Consider increasing pool size.")
	return null

func _find_lowest_priority_player(min_priority: int) -> AudioStreamPlayer2D:
	"""Find the lowest priority active player that can be interrupted"""
	var lowest_player: AudioStreamPlayer2D = null
	var lowest_priority := INF

	for player in active_players:
		var data := player_data[player] as Dictionary
		if data["priority"] < min_priority and data["priority"] < lowest_priority:
			if not data["is_looping"]:  # Don't interrupt looping sounds
				lowest_player = player
				lowest_priority = data["priority"]

	return lowest_player

func _configure_player(player: AudioStreamPlayer2D, stream: AudioStream, sound_name: String,
		position: Vector2, volume_db: float, pitch: float, priority: int) -> void:
	"""Configure a player with the given parameters"""
	player.stream = stream
	player.position = position
	player.volume_db = volume_db
	player.pitch_scale = pitch

	# Update metadata
	player_data[player]["sound_name"] = sound_name
	player_data[player]["priority"] = priority
	player_data[player]["start_time"] = Time.get_ticks_msec() / 1000.0
	player_data[player]["original_position"] = position
	player_data[player]["is_looping"] = false

## Sound Tracking
func _check_sound_limit(sound_name: String) -> bool:
	"""Check if we've hit the limit for this sound"""
	if max_same_sound <= 0:
		return false

	var count := playing_sounds.get(sound_name, 0)
	return count >= max_same_sound

func _track_sound_start(sound_name: String, player: AudioStreamPlayer2D) -> void:
	"""Track when a sound starts playing"""
	# Move from available to active
	available_players.erase(player)
	active_players.append(player)

	# Update sound count
	var count := playing_sounds.get(sound_name, 0)
	playing_sounds[sound_name] = count + 1

func _track_sound_end(sound_name: String, player: AudioStreamPlayer2D) -> void:
	"""Track when a sound stops playing"""
	# Move from active to available
	active_players.erase(player)
	available_players.append(player)

	# Update sound count
	var count := playing_sounds.get(sound_name, 0)
	if count > 0:
		playing_sounds[sound_name] = count - 1
		if playing_sounds[sound_name] <= 0:
			playing_sounds.erase(sound_name)

## Callbacks
func _on_sound_finished(player: AudioStreamPlayer2D) -> void:
	"""Called when a sound finishes playing"""
	var data := player_data[player] as Dictionary

	# Don't auto-return looping sounds
	if data["is_looping"] and player.playing:
		return

	_track_sound_end(data["sound_name"], player)

	# Reset player
	player.position = Vector2.ZERO
	player.volume_db = 0.0
	player.pitch_scale = 1.0

	# Reset metadata
	data["sound_name"] = ""
	data["priority"] = 0
	data["start_time"] = 0.0
	data["is_looping"] = false

func _perform_cleanup() -> void:
	"""Perform periodic cleanup of the pool"""
	if debug_mode:
		print("[SoundPool] Performing cleanup - Active: %d, Available: %d" %
			[active_players.size(), available_players.size()])

	# Check for stuck players (playing for too long)
	var current_time := Time.get_ticks_msec() / 1000.0
	for player in active_players.duplicate():
		var data := player_data[player] as Dictionary
		if not data["is_looping"]:
			var play_time := current_time - data["start_time"]
			if play_time > 30.0:  # Sound playing for more than 30 seconds
				push_warning("[SoundPool] Cleaning up stuck sound: %s" % data["sound_name"])
				stop_sound(player)

## Priority Management
func set_sound_priority(sound_name: String, priority: int) -> void:
	"""Set the default priority for a specific sound"""
	sound_priorities[sound_name] = priority

func get_sound_priority(sound_name: String) -> int:
	"""Get the priority for a specific sound"""
	return sound_priorities.get(sound_name, 0)

## Pool Configuration
func resize_pool(new_size: int) -> void:
	"""Resize the pool (can grow or shrink)"""
	new_size = clamp(new_size, 1, MAX_POOL_SIZE)

	if new_size > get_child_count():
		# Grow pool
		for i in range(get_child_count(), new_size):
			_create_pool_player(i)
	elif new_size < get_child_count():
		# Shrink pool (remove available players first)
		while get_child_count() > new_size and not available_players.is_empty():
			var player := available_players.pop_back()
			player_data.erase(player)
			player.queue_free()

	pool_size = new_size

	if debug_mode:
		print("[SoundPool] Resized pool to %d players" % pool_size)

func set_max_same_sound(max_count: int) -> void:
	"""Set the maximum number of instances for the same sound"""
	max_same_sound = max(0, max_count)

## Statistics and Debugging
func get_pool_stats() -> Dictionary:
	"""Get statistics about pool usage"""
	return {
		"pool_size": get_child_count(),
		"active_players": active_players.size(),
		"available_players": available_players.size(),
		"total_sounds_played": total_sounds_played,
		"pool_exhaustions": pool_exhaustion_count,
		"sounds_interrupted": sounds_interrupted,
		"unique_sounds_playing": playing_sounds.size(),
		"playing_sounds": playing_sounds.duplicate()
	}

func print_debug_info() -> void:
	"""Print detailed debug information"""
	print("=== SoundPool Debug Info ===")
	var stats := get_pool_stats()
	for key in stats:
		print("  %s: %s" % [key, stats[key]])
	print("===========================")

func enable_debug(enabled: bool) -> void:
	"""Enable or disable debug mode"""
	debug_mode = enabled