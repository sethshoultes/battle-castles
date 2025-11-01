extends Node
## MusicController - Dynamic music system with adaptive transitions
## Handles battle music phases, intensity scaling, and smooth transitions

class_name MusicController

signal music_phase_changed(phase: MusicPhase)
signal intensity_changed(intensity: float)
signal transition_started(from_phase: MusicPhase, to_phase: MusicPhase)
signal transition_completed()

# Music phases
enum MusicPhase {
	NONE,
	MENU,
	BATTLE_INTRO,
	BATTLE_MAIN,
	BATTLE_OVERTIME,
	VICTORY,
	DEFEAT,
	RESULTS
}

# Transition types
enum TransitionType {
	INSTANT,
	CROSSFADE,
	FADE_OUT_IN,
	MUSICAL_TRANSITION,  # Wait for musical beat/bar
	STINGER  # Play a short transition sound
}

# Music track configuration
const MUSIC_TRACKS := {
	MusicPhase.MENU: {
		"track": "menu_theme",
		"loop": true,
		"base_intensity": 0.3,
		"supports_layers": false
	},
	MusicPhase.BATTLE_INTRO: {
		"track": "battle_intro",
		"loop": false,
		"base_intensity": 0.5,
		"supports_layers": false,
		"next_phase": MusicPhase.BATTLE_MAIN
	},
	MusicPhase.BATTLE_MAIN: {
		"track": "battle_main",
		"loop": true,
		"base_intensity": 0.7,
		"supports_layers": true,
		"layers": ["drums", "bass", "melody", "harmony"]
	},
	MusicPhase.BATTLE_OVERTIME: {
		"track": "battle_overtime",
		"loop": true,
		"base_intensity": 1.0,
		"supports_layers": true,
		"layers": ["drums", "bass", "melody", "harmony", "tension"]
	},
	MusicPhase.VICTORY: {
		"track": "victory_fanfare",
		"loop": false,
		"base_intensity": 0.8,
		"supports_layers": false
	},
	MusicPhase.DEFEAT: {
		"track": "defeat_theme",
		"loop": false,
		"base_intensity": 0.4,
		"supports_layers": false
	},
	MusicPhase.RESULTS: {
		"track": "results_screen",
		"loop": true,
		"base_intensity": 0.5,
		"supports_layers": false
	}
}

# State management
var current_phase: MusicPhase = MusicPhase.NONE
var next_phase: MusicPhase = MusicPhase.NONE
var current_intensity: float = 0.0
var target_intensity: float = 0.0
var is_transitioning: bool = false

# Music players
var main_player: AudioStreamPlayer
var layer_players: Dictionary = {}  # For layered music tracks
var transition_player: AudioStreamPlayer  # For stinger transitions
var beat_tracker: Timer  # For musical timing

# Configuration
@export var enable_dynamic_intensity: bool = true
@export var enable_layered_music: bool = true
@export var default_transition_type: TransitionType = TransitionType.CROSSFADE
@export var crossfade_duration: float = 2.0
@export var intensity_smoothing: float = 2.0  # Seconds to smooth intensity changes
@export var bpm: float = 120.0  # Beats per minute for musical transitions

# Battle state tracking (for dynamic intensity)
var battle_data: Dictionary = {
	"player_health_percent": 100.0,
	"enemy_health_percent": 100.0,
	"time_remaining": 180.0,
	"units_deployed": 0,
	"combat_intensity": 0.0,  # Recent combat activity
	"is_overtime": false,
	"tower_health_percent": 100.0
}

# Debug
var debug_mode: bool = true

func _ready() -> void:
	_setup_players()
	_setup_beat_tracker()

	# Connect to game manager if available
	if has_node("/root/GameManager"):
		_connect_game_events()

	if debug_mode:
		print("[MusicController] Initialized")

func _setup_players() -> void:
	"""Setup audio players for music system"""
	# Main music player
	main_player = AudioStreamPlayer.new()
	main_player.name = "MainMusicPlayer"
	main_player.bus = AudioManager.BUS_MUSIC
	add_child(main_player)

	# Transition player for stingers
	transition_player = AudioStreamPlayer.new()
	transition_player.name = "TransitionPlayer"
	transition_player.bus = AudioManager.BUS_MUSIC
	add_child(transition_player)

	# Layer players for dynamic music
	if enable_layered_music:
		for i in range(5):  # Support up to 5 layers
			var layer_player := AudioStreamPlayer.new()
			layer_player.name = "LayerPlayer_%d" % i
			layer_player.bus = AudioManager.BUS_MUSIC
			add_child(layer_player)
			layer_players[i] = layer_player

func _setup_beat_tracker() -> void:
	"""Setup timer for tracking musical beats"""
	beat_tracker = Timer.new()
	beat_tracker.name = "BeatTracker"
	beat_tracker.one_shot = false
	add_child(beat_tracker)
	_update_beat_timer()

func _update_beat_timer() -> void:
	"""Update beat timer based on current BPM"""
	var beat_duration := 60.0 / bpm  # Duration of one beat in seconds
	beat_tracker.wait_time = beat_duration
	if not beat_tracker.timeout.is_connected(_on_beat):
		beat_tracker.timeout.connect(_on_beat)

func _connect_game_events() -> void:
	"""Connect to game events for dynamic music"""
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Connect to relevant game events
		if game_manager.has_signal("battle_started"):
			game_manager.battle_started.connect(_on_battle_started)
		if game_manager.has_signal("battle_ended"):
			game_manager.battle_ended.connect(_on_battle_ended)

func _process(delta: float) -> void:
	"""Update intensity and handle smooth transitions"""
	if enable_dynamic_intensity and current_phase in [MusicPhase.BATTLE_MAIN, MusicPhase.BATTLE_OVERTIME]:
		_update_intensity(delta)

	# Smooth intensity changes
	if abs(current_intensity - target_intensity) > 0.01:
		current_intensity = move_toward(current_intensity, target_intensity, delta / intensity_smoothing)
		_apply_intensity(current_intensity)

## Phase Management
func play_phase(phase: MusicPhase, transition: TransitionType = TransitionType.CROSSFADE) -> void:
	"""Play a specific music phase"""
	if current_phase == phase and not is_transitioning:
		return

	if is_transitioning:
		# Queue the next phase
		next_phase = phase
		return

	if debug_mode:
		print("[MusicController] Transitioning from %s to %s" % [MusicPhase.keys()[current_phase], MusicPhase.keys()[phase]])

	is_transitioning = true
	transition_started.emit(current_phase, phase)

	match transition:
		TransitionType.INSTANT:
			_instant_transition(phase)
		TransitionType.CROSSFADE:
			_crossfade_transition(phase)
		TransitionType.FADE_OUT_IN:
			_fade_out_in_transition(phase)
		TransitionType.MUSICAL_TRANSITION:
			_musical_transition(phase)
		TransitionType.STINGER:
			_stinger_transition(phase)

func stop_music(fade_out: bool = true) -> void:
	"""Stop all music"""
	if fade_out:
		var tween := create_tween()
		tween.tween_property(main_player, "volume_db", -80.0, crossfade_duration)
		for player in layer_players.values():
			tween.parallel().tween_property(player, "volume_db", -80.0, crossfade_duration)
		tween.tween_callback(_stop_all_players)
	else:
		_stop_all_players()

	current_phase = MusicPhase.NONE

func _stop_all_players() -> void:
	"""Stop all music players"""
	main_player.stop()
	for player in layer_players.values():
		player.stop()
	transition_player.stop()

## Transition Methods
func _instant_transition(phase: MusicPhase) -> void:
	"""Instantly switch to new music"""
	_stop_all_players()
	_load_and_play_phase(phase)
	_complete_transition(phase)

func _crossfade_transition(phase: MusicPhase) -> void:
	"""Crossfade between music phases"""
	var new_player := _get_available_layer_player()
	if not new_player:
		new_player = main_player

	_load_phase_to_player(phase, new_player)
	new_player.volume_db = -80.0
	new_player.play()

	var tween := create_tween()
	tween.set_parallel(true)

	# Fade out current
	if main_player.playing:
		tween.tween_property(main_player, "volume_db", -80.0, crossfade_duration)

	# Fade in new
	tween.tween_property(new_player, "volume_db", 0.0, crossfade_duration)

	tween.set_parallel(false)
	tween.tween_callback(func():
		main_player.stop()
		if new_player != main_player:
			# Swap players
			var temp_stream := main_player.stream
			main_player.stream = new_player.stream
			main_player.volume_db = 0.0
			main_player.play()
			new_player.stop()
		_complete_transition(phase)
	)

func _fade_out_in_transition(phase: MusicPhase) -> void:
	"""Fade out current music, then fade in new music"""
	var tween := create_tween()

	# Fade out
	if main_player.playing:
		tween.tween_property(main_player, "volume_db", -80.0, crossfade_duration / 2)
		tween.tween_callback(main_player.stop)

	# Silence gap
	tween.tween_interval(0.2)

	# Fade in new
	tween.tween_callback(func():
		_load_and_play_phase(phase)
		main_player.volume_db = -80.0
		var fade_in := create_tween()
		fade_in.tween_property(main_player, "volume_db", 0.0, crossfade_duration / 2)
		fade_in.tween_callback(func(): _complete_transition(phase))
	)

func _musical_transition(phase: MusicPhase) -> void:
	"""Wait for next musical beat/bar to transition"""
	# Wait for next bar (4 beats)
	var beats_until_bar := 4 - (beat_tracker.time_left / beat_tracker.wait_time) % 4
	var wait_time := beats_until_bar * beat_tracker.wait_time

	await get_tree().create_timer(wait_time).timeout
	_crossfade_transition(phase)

func _stinger_transition(phase: MusicPhase) -> void:
	"""Play a transition stinger before switching"""
	var stinger_path := "res://audio/music/stinger_%s_to_%s.ogg" % [
		MusicPhase.keys()[current_phase].to_lower(),
		MusicPhase.keys()[phase].to_lower()
	]

	if ResourceLoader.exists(stinger_path):
		transition_player.stream = load(stinger_path)
		transition_player.play()
		transition_player.finished.connect(func():
			_load_and_play_phase(phase)
			_complete_transition(phase)
		, CONNECT_ONE_SHOT)
	else:
		# Fallback to crossfade if no stinger exists
		_crossfade_transition(phase)

## Phase Loading
func _load_and_play_phase(phase: MusicPhase) -> void:
	"""Load and play a music phase"""
	if not MUSIC_TRACKS.has(phase):
		push_error("[MusicController] Unknown music phase: %s" % phase)
		return

	var config := MUSIC_TRACKS[phase]
	var track_name := config["track"]

	# Load main track
	var track_path := "res://audio/music/%s.ogg" % track_name
	if ResourceLoader.exists(track_path):
		main_player.stream = load(track_path)
		if config.get("loop", false):
			main_player.stream.set_loop(true)
		main_player.play()
	else:
		# Use placeholder
		_play_placeholder_music(track_name)

	# Load layers if supported
	if enable_layered_music and config.get("supports_layers", false):
		_load_music_layers(track_name, config.get("layers", []))

	# Set base intensity
	target_intensity = config.get("base_intensity", 0.5)

	if debug_mode:
		print("[MusicController] Playing phase: %s" % MusicPhase.keys()[phase])

func _load_phase_to_player(phase: MusicPhase, player: AudioStreamPlayer) -> void:
	"""Load a phase to a specific player"""
	if not MUSIC_TRACKS.has(phase):
		return

	var config := MUSIC_TRACKS[phase]
	var track_path := "res://audio/music/%s.ogg" % config["track"]

	if ResourceLoader.exists(track_path):
		player.stream = load(track_path)
		if config.get("loop", false):
			player.stream.set_loop(true)

func _load_music_layers(base_track: String, layers: Array) -> void:
	"""Load layered music tracks"""
	for i in range(min(layers.size(), layer_players.size())):
		var layer_name := layers[i]
		var layer_path := "res://audio/music/%s_%s.ogg" % [base_track, layer_name]

		if ResourceLoader.exists(layer_path):
			var player := layer_players[i]
			player.stream = load(layer_path)
			player.stream.set_loop(true)
			player.volume_db = -80.0  # Start muted
			player.play()

			if debug_mode:
				print("[MusicController] Loaded layer: %s" % layer_name)

## Intensity System
func _update_intensity(delta: float) -> void:
	"""Calculate dynamic music intensity based on battle state"""
	var new_intensity := 0.0

	# Health-based intensity
	var health_factor := 1.0 - min(battle_data["player_health_percent"], battle_data["enemy_health_percent"]) / 100.0
	new_intensity += health_factor * 0.3

	# Time pressure
	if battle_data["time_remaining"] < 60.0:
		var time_factor := 1.0 - (battle_data["time_remaining"] / 60.0)
		new_intensity += time_factor * 0.2

	# Combat activity
	new_intensity += battle_data["combat_intensity"] * 0.3

	# Tower danger
	if battle_data["tower_health_percent"] < 30.0:
		new_intensity += 0.2

	# Overtime boost
	if battle_data["is_overtime"]:
		new_intensity = max(new_intensity, 0.8)

	# Clamp and smooth
	target_intensity = clamp(new_intensity, 0.0, 1.0)

func _apply_intensity(intensity: float) -> void:
	"""Apply intensity to music layers"""
	if not enable_layered_music:
		return

	# Gradually bring in layers based on intensity
	var layer_thresholds := [0.0, 0.25, 0.5, 0.75, 0.9]

	for i in range(layer_players.size()):
		if i >= layer_thresholds.size():
			break

		var player := layer_players[i]
		if not player.playing:
			continue

		var target_volume: float
		if intensity >= layer_thresholds[i]:
			# Calculate volume based on how far above threshold
			var range_start := layer_thresholds[i]
			var range_end := layer_thresholds[min(i + 1, layer_thresholds.size() - 1)]
			var range_intensity := remap(intensity, range_start, range_end, 0.0, 1.0)
			target_volume = linear_to_db(range_intensity)
		else:
			target_volume = -80.0

		# Smooth volume changes
		if abs(player.volume_db - target_volume) > 0.1:
			var tween := create_tween()
			tween.tween_property(player, "volume_db", target_volume, 0.5)

	intensity_changed.emit(intensity)

## Battle Integration
func update_battle_state(state: Dictionary) -> void:
	"""Update battle state for dynamic intensity"""
	for key in state:
		if battle_data.has(key):
			battle_data[key] = state[key]

	# Check for phase changes
	if battle_data["is_overtime"] and current_phase == MusicPhase.BATTLE_MAIN:
		play_phase(MusicPhase.BATTLE_OVERTIME)

func set_combat_intensity(intensity: float, decay_time: float = 2.0) -> void:
	"""Set combat intensity with automatic decay"""
	battle_data["combat_intensity"] = clamp(intensity, 0.0, 1.0)

	# Decay over time
	var tween := create_tween()
	tween.tween_property(battle_data, "combat_intensity", 0.0, decay_time)

## Helper Functions
func _get_available_layer_player() -> AudioStreamPlayer:
	"""Get an available layer player"""
	for player in layer_players.values():
		if not player.playing:
			return player
	return null

func _complete_transition(phase: MusicPhase) -> void:
	"""Complete a music transition"""
	current_phase = phase
	is_transitioning = false
	music_phase_changed.emit(phase)
	transition_completed.emit()

	# Check for auto-progression
	if MUSIC_TRACKS.has(phase):
		var config := MUSIC_TRACKS[phase]
		if config.has("next_phase") and not config.get("loop", false):
			# Wait for track to finish then auto-progress
			main_player.finished.connect(func():
				play_phase(config["next_phase"])
			, CONNECT_ONE_SHOT)

	# Process queued phase
	if next_phase != MusicPhase.NONE:
		var queued := next_phase
		next_phase = MusicPhase.NONE
		play_phase(queued)

	if debug_mode:
		print("[MusicController] Transition complete to: %s" % MusicPhase.keys()[phase])

func _play_placeholder_music(track_name: String) -> void:
	"""Play placeholder music for missing tracks"""
	if debug_mode:
		print("[MusicController] Playing placeholder for: %s" % track_name)

	# Use AudioManager's placeholder system
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager._play_placeholder_music(track_name)

## Event Handlers
func _on_beat() -> void:
	"""Called on every musical beat"""
	# Can be used for rhythm-based events
	pass

func _on_battle_started() -> void:
	"""Handle battle start"""
	play_phase(MusicPhase.BATTLE_INTRO)

func _on_battle_ended(victory: bool) -> void:
	"""Handle battle end"""
	if victory:
		play_phase(MusicPhase.VICTORY)
	else:
		play_phase(MusicPhase.DEFEAT)

	# Transition to results after victory/defeat music
	await get_tree().create_timer(5.0).timeout
	play_phase(MusicPhase.RESULTS)

## Public API
func get_current_phase() -> MusicPhase:
	"""Get the current music phase"""
	return current_phase

func get_intensity() -> float:
	"""Get the current music intensity"""
	return current_intensity

func is_playing() -> bool:
	"""Check if music is currently playing"""
	return main_player.playing

func set_bpm(new_bpm: float) -> void:
	"""Set the BPM for musical transitions"""
	bpm = new_bpm
	_update_beat_timer()

func enable_debug(enabled: bool) -> void:
	"""Enable or disable debug mode"""
	debug_mode = enabled