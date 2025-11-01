extends Node
## AudioManager - Singleton for managing all game audio
## Handles audio buses, volume controls, sound pooling, and music transitions

signal volume_changed(bus_name: String, volume: float)
signal music_changed(track_name: String)
signal sfx_played(sound_name: String)

# Audio bus names
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const BUS_VOICE := "Voice"
const BUS_AMBIENT := "Ambient"

# Audio settings
const SETTINGS_FILE := "user://audio_settings.cfg"
const DEFAULT_VOLUME := 80.0
const MIN_DB := -80.0
const MAX_DB := 0.0
const DUCKING_DB := -10.0
const DUCKING_DURATION := 0.3

# Volume settings (0-100)
var master_volume: float = DEFAULT_VOLUME : set = set_master_volume
var music_volume: float = DEFAULT_VOLUME : set = set_music_volume
var sfx_volume: float = DEFAULT_VOLUME : set = set_sfx_volume
var ui_volume: float = DEFAULT_VOLUME : set = set_ui_volume
var voice_volume: float = DEFAULT_VOLUME : set = set_voice_volume
var ambient_volume: float = DEFAULT_VOLUME : set = set_ambient_volume

# Music system
var current_music_player: AudioStreamPlayer
var fade_music_player: AudioStreamPlayer
var music_tween: Tween
var current_music_track: String = ""
var music_fade_duration: float = 1.5
var is_music_ducked: bool = false

# Sound effect pooling
var sound_pool: Node
var max_concurrent_sounds: int = 20
var active_sounds: Array[AudioStreamPlayer2D] = []

# Placeholder sound generator for testing
var placeholder_stream: AudioStreamGenerator

# Audio file paths
const AUDIO_PATH := "res://audio/"
const MUSIC_PATH := AUDIO_PATH + "music/"
const SFX_PATH := AUDIO_PATH + "sfx/"

# Supported audio formats
const AUDIO_EXTENSIONS := ["ogg", "mp3", "wav"]

# Debug mode
var debug_audio: bool = true

func _ready() -> void:
	print("[AudioManager] Initializing audio system...")
	_setup_audio_buses()
	_setup_music_players()
	_setup_sound_pool()
	_setup_placeholder_audio()
	_load_settings()

	# Connect to tree for cleanup
	get_tree().node_added.connect(_on_node_added)

	print("[AudioManager] Audio system initialized successfully")

func _setup_audio_buses() -> void:
	"""Setup audio buses if they don't exist"""
	var bus_layout := AudioServer.bus_count

	# Ensure we have all required buses
	var required_buses := [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI, BUS_VOICE, BUS_AMBIENT]

	for bus_name in required_buses:
		if not AudioServer.get_bus_index(bus_name) >= 0:
			AudioServer.add_bus()
			var bus_idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus_idx, bus_name)

			# Route all buses to Master (except Master itself)
			if bus_name != BUS_MASTER:
				AudioServer.set_bus_send(bus_idx, BUS_MASTER)

			print("[AudioManager] Created audio bus: %s" % bus_name)

func _setup_music_players() -> void:
	"""Setup music players for crossfading"""
	current_music_player = AudioStreamPlayer.new()
	current_music_player.name = "CurrentMusicPlayer"
	current_music_player.bus = BUS_MUSIC
	add_child(current_music_player)

	fade_music_player = AudioStreamPlayer.new()
	fade_music_player.name = "FadeMusicPlayer"
	fade_music_player.bus = BUS_MUSIC
	add_child(fade_music_player)

	print("[AudioManager] Music players initialized")

func _setup_sound_pool() -> void:
	"""Setup the sound effect pool"""
	sound_pool = Node.new()
	sound_pool.name = "SoundPool"
	add_child(sound_pool)

	# Pre-create pool of audio players
	for i in range(max_concurrent_sounds):
		var player := AudioStreamPlayer2D.new()
		player.name = "PooledSound_%d" % i
		player.bus = BUS_SFX
		player.max_distance = 2000.0
		player.attenuation = 1.0
		sound_pool.add_child(player)
		player.finished.connect(_on_sound_finished.bind(player))

	print("[AudioManager] Sound pool created with %d players" % max_concurrent_sounds)

func _setup_placeholder_audio() -> void:
	"""Setup placeholder audio generator for testing"""
	placeholder_stream = AudioStreamGenerator.new()
	placeholder_stream.mix_rate = 44100
	placeholder_stream.buffer_length = 0.1

func _on_node_added(node: Node) -> void:
	"""Auto-configure audio nodes when they're added to the tree"""
	if node is AudioStreamPlayer2D:
		# Auto-assign to appropriate bus based on node group or name
		if "ui" in node.name.to_lower():
			node.bus = BUS_UI
		elif "music" in node.name.to_lower():
			node.bus = BUS_MUSIC
		elif "voice" in node.name.to_lower():
			node.bus = BUS_VOICE
		elif "ambient" in node.name.to_lower():
			node.bus = BUS_AMBIENT
		else:
			node.bus = BUS_SFX

## Volume Control Functions
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_MASTER, master_volume)
	volume_changed.emit(BUS_MASTER, master_volume)
	_save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_MUSIC, music_volume)
	volume_changed.emit(BUS_MUSIC, music_volume)
	_save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_SFX, sfx_volume)
	volume_changed.emit(BUS_SFX, sfx_volume)
	_save_settings()

func set_ui_volume(value: float) -> void:
	ui_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_UI, ui_volume)
	volume_changed.emit(BUS_UI, ui_volume)
	_save_settings()

func set_voice_volume(value: float) -> void:
	voice_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_VOICE, voice_volume)
	volume_changed.emit(BUS_VOICE, voice_volume)
	_save_settings()

func set_ambient_volume(value: float) -> void:
	ambient_volume = clamp(value, 0.0, 100.0)
	_set_bus_volume(BUS_AMBIENT, ambient_volume)
	volume_changed.emit(BUS_AMBIENT, ambient_volume)
	_save_settings()

func _set_bus_volume(bus_name: String, volume_percent: float) -> void:
	"""Convert percentage to decibels and apply to bus"""
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db_value: float
		if volume_percent <= 0.0:
			db_value = MIN_DB
		else:
			# Logarithmic scale for more natural volume control
			db_value = linear_to_db(volume_percent / 100.0)

		AudioServer.set_bus_volume_db(bus_idx, db_value)

		if debug_audio:
			print("[AudioManager] Set %s volume to %.1f%% (%.1f dB)" % [bus_name, volume_percent, db_value])

## Music System Functions
func play_music(track_name: String, fade_in: bool = true, loop: bool = true) -> void:
	"""Play a music track with optional fade-in"""
	if current_music_track == track_name and current_music_player.playing:
		return

	var music_path := _find_audio_file(MUSIC_PATH + track_name)

	if music_path.is_empty():
		_play_placeholder_music(track_name)
		return

	var stream := load(music_path) as AudioStream
	if not stream:
		push_error("[AudioManager] Failed to load music: %s" % music_path)
		return

	if loop and stream.has_method("set_loop"):
		stream.set_loop(true)

	# Crossfade if music is already playing
	if current_music_player.playing and fade_in:
		_crossfade_music(stream, track_name)
	else:
		current_music_player.stream = stream
		current_music_player.volume_db = 0.0 if not fade_in else MIN_DB
		current_music_player.play()

		if fade_in:
			var tween := create_tween()
			tween.tween_property(current_music_player, "volume_db", 0.0, music_fade_duration)

		current_music_track = track_name
		music_changed.emit(track_name)

		if debug_audio:
			print("[AudioManager] Playing music: %s" % track_name)

func _crossfade_music(new_stream: AudioStream, track_name: String) -> void:
	"""Crossfade between two music tracks"""
	# Swap players
	var temp := current_music_player
	current_music_player = fade_music_player
	fade_music_player = temp

	# Setup new track
	current_music_player.stream = new_stream
	current_music_player.volume_db = MIN_DB
	current_music_player.play()

	# Create crossfade
	if music_tween:
		music_tween.kill()

	music_tween = create_tween()
	music_tween.set_parallel(true)
	music_tween.tween_property(current_music_player, "volume_db", 0.0, music_fade_duration)
	music_tween.tween_property(fade_music_player, "volume_db", MIN_DB, music_fade_duration)
	music_tween.set_parallel(false)
	music_tween.tween_callback(fade_music_player.stop)

	current_music_track = track_name
	music_changed.emit(track_name)

	if debug_audio:
		print("[AudioManager] Crossfading to music: %s" % track_name)

func stop_music(fade_out: bool = true) -> void:
	"""Stop the currently playing music"""
	if not current_music_player.playing:
		return

	if fade_out:
		var tween := create_tween()
		tween.tween_property(current_music_player, "volume_db", MIN_DB, music_fade_duration)
		tween.tween_callback(current_music_player.stop)
		tween.tween_callback(func(): current_music_player.volume_db = 0.0)
	else:
		current_music_player.stop()

	current_music_track = ""

	if debug_audio:
		print("[AudioManager] Music stopped")

func pause_music() -> void:
	"""Pause the current music"""
	current_music_player.stream_paused = true

func resume_music() -> void:
	"""Resume the current music"""
	current_music_player.stream_paused = false

func duck_music(duration: float = DUCKING_DURATION) -> void:
	"""Temporarily lower music volume for important sounds"""
	if is_music_ducked:
		return

	is_music_ducked = true
	var original_db := current_music_player.volume_db

	var tween := create_tween()
	tween.tween_property(current_music_player, "volume_db", original_db + DUCKING_DB, duration * 0.3)
	tween.tween_interval(duration)
	tween.tween_property(current_music_player, "volume_db", original_db, duration * 0.3)
	tween.tween_callback(func(): is_music_ducked = false)

## Sound Effect Functions
func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	"""Play a sound effect at a specific position"""
	var player := _get_available_player()
	if not player:
		push_warning("[AudioManager] No available sound players in pool")
		return null

	var sfx_path := _find_audio_file(SFX_PATH + sound_name)

	if sfx_path.is_empty():
		_play_placeholder_sfx(sound_name, player, position, volume_db, pitch)
		return player

	var stream := load(sfx_path) as AudioStream
	if not stream:
		push_error("[AudioManager] Failed to load SFX: %s" % sfx_path)
		return null

	player.stream = stream
	player.position = position
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

	active_sounds.append(player)
	sfx_played.emit(sound_name)

	if debug_audio:
		print("[AudioManager] Playing SFX: %s at position %s" % [sound_name, position])

	return player

func play_ui_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	"""Play a UI sound (non-positional)"""
	var player := AudioStreamPlayer.new()
	player.bus = BUS_UI
	add_child(player)

	var ui_path := _find_audio_file(SFX_PATH + "ui/" + sound_name)

	if ui_path.is_empty():
		_play_placeholder_ui(sound_name, player, volume_db, pitch)
		return

	var stream := load(ui_path) as AudioStream
	if not stream:
		push_error("[AudioManager] Failed to load UI sound: %s" % ui_path)
		player.queue_free()
		return

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	player.finished.connect(player.queue_free)

	sfx_played.emit("ui/" + sound_name)

	if debug_audio:
		print("[AudioManager] Playing UI sound: %s" % sound_name)

func play_random_sfx(sound_names: Array[String], position: Vector2 = Vector2.ZERO, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	"""Play a random sound from a list"""
	if sound_names.is_empty():
		return null

	var random_sound := sound_names[randi() % sound_names.size()]
	return play_sfx(random_sound, position, volume_db)

func stop_all_sounds() -> void:
	"""Stop all playing sound effects"""
	for player in active_sounds:
		if player and player.playing:
			player.stop()
	active_sounds.clear()

	if debug_audio:
		print("[AudioManager] All sounds stopped")

## Helper Functions
func _get_available_player() -> AudioStreamPlayer2D:
	"""Get an available player from the pool"""
	for child in sound_pool.get_children():
		var player := child as AudioStreamPlayer2D
		if player and not player.playing:
			return player

	# All players are busy, stop the oldest one
	if not active_sounds.is_empty():
		var oldest := active_sounds[0]
		oldest.stop()
		active_sounds.erase(oldest)
		return oldest

	return null

func _on_sound_finished(player: AudioStreamPlayer2D) -> void:
	"""Called when a pooled sound finishes playing"""
	active_sounds.erase(player)
	player.position = Vector2.ZERO
	player.volume_db = 0.0
	player.pitch_scale = 1.0

func _find_audio_file(base_path: String) -> String:
	"""Find an audio file with any supported extension"""
	for ext in AUDIO_EXTENSIONS:
		var full_path := base_path + "." + ext
		if ResourceLoader.exists(full_path):
			return full_path
	return ""

## Placeholder Audio Functions (for testing)
func _play_placeholder_music(track_name: String) -> void:
	"""Play a placeholder beep pattern for missing music"""
	if debug_audio:
		print("[AudioManager] Playing placeholder music for: %s" % track_name)

	current_music_player.stream = placeholder_stream
	current_music_player.play()
	current_music_track = track_name + " (placeholder)"
	music_changed.emit(current_music_track)

	# Generate a simple beep pattern
	_generate_placeholder_pattern(current_music_player, 440.0, 0.5)

func _play_placeholder_sfx(sound_name: String, player: AudioStreamPlayer2D, position: Vector2, volume_db: float, pitch: float) -> void:
	"""Play a placeholder beep for missing SFX"""
	if debug_audio:
		print("[AudioManager] Playing placeholder SFX for: %s" % sound_name)

	player.stream = placeholder_stream
	player.position = position
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

	active_sounds.append(player)
	sfx_played.emit(sound_name + " (placeholder)")

	# Generate a short beep
	_generate_placeholder_pattern(player, 880.0 * pitch, 0.1)

func _play_placeholder_ui(sound_name: String, player: AudioStreamPlayer, volume_db: float, pitch: float) -> void:
	"""Play a placeholder beep for missing UI sound"""
	if debug_audio:
		print("[AudioManager] Playing placeholder UI sound for: %s" % sound_name)

	player.stream = placeholder_stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	player.finished.connect(player.queue_free)

	sfx_played.emit("ui/" + sound_name + " (placeholder)")

	# Generate a click sound
	_generate_placeholder_pattern(player, 1200.0 * pitch, 0.05)

func _generate_placeholder_pattern(player: Node, frequency: float, duration: float) -> void:
	"""Generate a simple sine wave beep pattern"""
	# This is a placeholder - in real implementation, you'd generate actual audio data
	# For now, we'll just use the AudioStreamGenerator with default settings
	pass

## Settings Persistence
func _save_settings() -> void:
	"""Save audio settings to file"""
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)

	var error := config.save(SETTINGS_FILE)
	if error != OK:
		push_error("[AudioManager] Failed to save audio settings: %s" % error)
	elif debug_audio:
		print("[AudioManager] Audio settings saved")

func _load_settings() -> void:
	"""Load audio settings from file"""
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	if error != OK:
		print("[AudioManager] No audio settings found, using defaults")
		_save_settings()
		return

	master_volume = config.get_value("audio", "master_volume", DEFAULT_VOLUME)
	music_volume = config.get_value("audio", "music_volume", DEFAULT_VOLUME)
	sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_VOLUME)
	ui_volume = config.get_value("audio", "ui_volume", DEFAULT_VOLUME)
	voice_volume = config.get_value("audio", "voice_volume", DEFAULT_VOLUME)
	ambient_volume = config.get_value("audio", "ambient_volume", DEFAULT_VOLUME)

	# Apply loaded volumes
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_ui_volume(ui_volume)
	set_voice_volume(voice_volume)
	set_ambient_volume(ambient_volume)

	if debug_audio:
		print("[AudioManager] Audio settings loaded")

## Utility Functions
func get_bus_volume(bus_name: String) -> float:
	"""Get the volume of a specific bus as percentage"""
	match bus_name:
		BUS_MASTER: return master_volume
		BUS_MUSIC: return music_volume
		BUS_SFX: return sfx_volume
		BUS_UI: return ui_volume
		BUS_VOICE: return voice_volume
		BUS_AMBIENT: return ambient_volume
		_: return 0.0

func is_music_playing() -> bool:
	"""Check if music is currently playing"""
	return current_music_player.playing

func get_current_music() -> String:
	"""Get the name of the currently playing music track"""
	return current_music_track

func set_debug_mode(enabled: bool) -> void:
	"""Enable or disable debug logging"""
	debug_audio = enabled
	print("[AudioManager] Debug mode: %s" % ("enabled" if enabled else "disabled"))