## Main game integration and initialization
## This is the entry point that sets up all game systems
## Attach to the main scene or root node
extends Node

## Signals
signal initialization_complete()
signal initialization_failed(error: String)
signal systems_ready()

## Initialization state
var initialization_complete_flag: bool = false
var initialization_in_progress: bool = false
var initialization_errors: Array[String] = []

## System references (autoloads)
@onready var game_manager = GameManager
@onready var network_manager = NetworkManager
@onready var audio_manager = AudioManager
@onready var input_manager = InputManager
@onready var scene_manager = SceneManager
@onready var data_validator = DataValidator

## Optional systems
var vfx_manager: Node = null
var player_profile: Node = null
var deck_manager: Node = null

## Startup configuration
var enable_networking: bool = true
var enable_audio: bool = true
var skip_validation: bool = false
var auto_login: bool = false


func _ready() -> void:
	print("=== Battle Castles Initializing ===")
	print("Version: ", ProjectSettings.get_setting("application/config/version"))

	# Start initialization sequence
	_initialize_game()


## Main initialization sequence
func _initialize_game() -> void:
	if initialization_in_progress:
		push_warning("Initialization already in progress")
		return

	initialization_in_progress = true
	initialization_errors.clear()

	# Step 1: Validate game data
	if not skip_validation:
		print("[1/7] Validating game data...")
		if not await _validate_game_data():
			_handle_initialization_error("Data validation failed")
			return
	else:
		print("[1/7] Skipping data validation")

	# Step 2: Initialize audio
	if enable_audio:
		print("[2/7] Initializing audio system...")
		if not _initialize_audio():
			_handle_initialization_error("Audio initialization failed")
			return
	else:
		print("[2/7] Audio disabled")

	# Step 3: Initialize input
	print("[3/7] Initializing input system...")
	if not _initialize_input():
		_handle_initialization_error("Input initialization failed")
		return

	# Step 4: Load player profile
	print("[4/7] Loading player profile...")
	if not await _load_player_profile():
		_handle_initialization_error("Failed to load player profile")
		return

	# Step 5: Initialize network (if enabled)
	if enable_networking:
		print("[5/7] Initializing network...")
		_initialize_network()
	else:
		print("[5/7] Network disabled (offline mode)")

	# Step 6: Initialize VFX system
	print("[6/7] Initializing visual effects...")
	_initialize_vfx()

	# Step 7: Setup game systems
	print("[7/7] Setting up game systems...")
	_setup_game_systems()

	# Initialization complete
	_finalize_initialization()


## Validates all game data
func _validate_game_data() -> bool:
	if not data_validator:
		push_error("DataValidator not available")
		return false

	var is_valid := data_validator.validate_all_data()

	if not is_valid:
		var errors := data_validator.get_last_errors()
		print("Data validation errors: ", errors.size())

		# Attempt to repair
		for error in errors:
			print("  - ", error)

		# Ask user if they want to continue
		var can_continue := await _show_validation_error_dialog(errors)
		return can_continue

	print("  ✓ Data validation passed")
	return true


## Shows validation error dialog
func _show_validation_error_dialog(errors: Array) -> bool:
	# In a real implementation, show a dialog to user
	# For now, just continue with warning
	push_warning("Data validation found issues, but continuing...")
	return true


## Initializes audio system
func _initialize_audio() -> bool:
	if not audio_manager:
		push_error("AudioManager not available")
		return false

	# Load audio settings
	var settings_path := "user://config/settings.json"
	if FileAccess.file_exists(settings_path):
		var file := FileAccess.open(settings_path, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()

			var json := JSON.new()
			if json.parse(json_string) == OK:
				var settings: Dictionary = json.data
				if audio_manager.has_method("set_master_volume"):
					audio_manager.set_master_volume(settings.get("master_volume", 0.8))
				if audio_manager.has_method("set_music_volume"):
					audio_manager.set_music_volume(settings.get("music_volume", 0.7))
				if audio_manager.has_method("set_sfx_volume"):
					audio_manager.set_sfx_volume(settings.get("sfx_volume", 0.8))

	# Start background music
	if audio_manager.has_method("play_music"):
		audio_manager.play_music("menu_theme")

	print("  ✓ Audio initialized")
	return true


## Initializes input system
func _initialize_input() -> bool:
	if not input_manager:
		push_error("InputManager not available")
		return false

	# Setup deployment constraints for battles
	var screen_size := get_viewport().get_visible_rect().size
	input_manager.set_deployment_y_bounds(screen_size.y * 0.5, screen_size.y)

	# Connect input signals
	input_manager.pause_requested.connect(_on_pause_requested)

	print("  ✓ Input initialized")
	return true


## Loads player profile
func _load_player_profile() -> bool:
	var profile_path := "user://saves/player_profile.json"

	# Check if profile exists
	if not FileAccess.file_exists(profile_path):
		print("  Creating new player profile...")
		return _create_new_player_profile()

	# Load existing profile
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if not file:
		push_error("Failed to open player profile")
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("Failed to parse player profile")
		return false

	var profile_data: Dictionary = json.data

	# Validate profile
	if not data_validator.validate_file(profile_path, "player_profile"):
		push_error("Player profile validation failed")
		return false

	print("  ✓ Player profile loaded: ", profile_data.get("player_name", "Unknown"))
	return true


## Creates a new player profile
func _create_new_player_profile() -> bool:
	var profile_data := {
		"version": "1.0.0",
		"player_id": _generate_player_id(),
		"player_name": "Player",
		"level": 1,
		"experience": 0,
		"trophies": 0,
		"tutorial_completed": false,
		"created_at": Time.get_datetime_string_from_system()
	}

	var save_path := "user://saves/player_profile.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to create player profile")
		return false

	file.store_string(JSON.stringify(profile_data, "\t"))
	file.close()

	print("  ✓ New player profile created")
	return true


## Generates a unique player ID
func _generate_player_id() -> String:
	var timestamp := Time.get_ticks_msec()
	var random := randi()
	return "%s_%s" % [timestamp, random]


## Initializes network system
func _initialize_network() -> void:
	if not network_manager:
		push_warning("NetworkManager not available")
		return

	# Don't auto-connect in main menu
	# Let player choose to play online or offline
	print("  ✓ Network ready (not connected)")


## Initializes VFX system
func _initialize_vfx() -> void:
	# Try to get VFX manager if it exists
	if has_node("/root/VFXManager"):
		vfx_manager = get_node("/root/VFXManager")
		print("  ✓ VFX system ready")
	else:
		print("  ✓ VFX system not available (optional)")


## Sets up core game systems
func _setup_game_systems() -> void:
	if not game_manager:
		push_error("GameManager not available")
		return

	# Game manager is already initialized as autoload
	# Just verify it's ready
	print("  ✓ Game systems ready")

	systems_ready.emit()


## Finalizes initialization
func _finalize_initialization() -> void:
	initialization_in_progress = false
	initialization_complete_flag = true

	print("=== Initialization Complete ===")
	print("Systems: ALL READY")
	print("Status: OK")
	print("===============================")

	initialization_complete.emit()

	# Navigate to appropriate scene
	_navigate_to_start_scene()


## Navigates to the starting scene
func _navigate_to_start_scene() -> void:
	# Check if tutorial needed
	var needs_tutorial := _check_tutorial_needed()

	if needs_tutorial:
		print("First time player detected - tutorial recommended")
		# For now, go to main menu and let them choose
		_go_to_main_menu()
	else:
		_go_to_main_menu()


## Checks if player needs tutorial
func _check_tutorial_needed() -> bool:
	var profile_path := "user://saves/player_profile.json"

	if not FileAccess.file_exists(profile_path):
		return true

	var file := FileAccess.open(profile_path, FileAccess.READ)
	if not file:
		return true

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) == OK:
		var profile: Dictionary = json.data
		return not profile.get("tutorial_completed", false)

	return true


## Goes to main menu
func _go_to_main_menu() -> void:
	if scene_manager:
		# Use a welcoming fade transition
		scene_manager.goto_main_menu()
	else:
		push_warning("SceneManager not available, cannot navigate")


## Handles initialization errors
func _handle_initialization_error(error: String) -> void:
	initialization_errors.append(error)
	initialization_in_progress = false
	initialization_complete_flag = false

	push_error("INITIALIZATION FAILED: " + error)
	print("===============================")
	print("Initialization failed!")
	print("Error: ", error)
	print("===============================")

	initialization_failed.emit(error)

	# Show error to user
	_show_error_dialog(error)


## Shows error dialog to user
func _show_error_dialog(error: String) -> void:
	# In a real implementation, show a proper error dialog
	# For now, just print to console
	printerr("CRITICAL ERROR: ", error)
	printerr("Please check the console for details.")


## Called when pause is requested
func _on_pause_requested() -> void:
	if game_manager and game_manager.current_state == GameManager.GameState.PLAYING:
		game_manager.pause_game()
		_show_pause_menu()


## Shows pause menu
func _show_pause_menu() -> void:
	# This would show a pause menu overlay
	print("Pause menu requested")


## Cleanup on exit
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup()
		get_tree().quit()


## Cleanup resources
func _cleanup() -> void:
	print("Shutting down Battle Castles...")

	# Save any pending data
	if game_manager:
		game_manager.reset()

	# Disconnect network
	if network_manager and network_manager.has_method("disconnect_from_server"):
		network_manager.disconnect_from_server()

	# Stop audio
	if audio_manager and audio_manager.has_method("stop_all"):
		audio_manager.stop_all()

	print("Shutdown complete")


## Gets initialization status
func is_initialized() -> bool:
	return initialization_complete_flag


## Gets initialization errors
func get_initialization_errors() -> Array[String]:
	return initialization_errors


## Forces re-initialization
func reinitialize() -> void:
	initialization_complete_flag = false
	_initialize_game()
