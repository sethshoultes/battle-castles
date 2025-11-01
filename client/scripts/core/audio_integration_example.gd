extends Node
## AudioIntegrationExample - Example script showing how to integrate the audio system
## This file demonstrates best practices for using the AudioManager in your game

class_name AudioIntegrationExample

# This is an example script showing how to use the audio system in Battle Castles
# Copy these patterns into your actual game scripts

func _ready() -> void:
	# The AudioManager is available globally as a singleton
	print("Audio system example ready")

## PLAYING MUSIC
func example_play_music() -> void:
	# Play menu music
	AudioManager.play_music("menu_theme", true, true)  # track_name, fade_in, loop

	# Stop music with fade out
	AudioManager.stop_music(true)

	# Pause/resume music
	AudioManager.pause_music()
	AudioManager.resume_music()

	# Duck music temporarily (for important sounds)
	AudioManager.duck_music(0.5)  # Duration in seconds

## PLAYING SOUND EFFECTS
func example_play_sfx() -> void:
	# Play a simple sound effect at a position
	var position := Vector2(500, 300)
	AudioManager.play_sfx("combat/sword_hit", position)

	# Play with custom volume and pitch
	AudioManager.play_sfx("combat/arrow_fly", position, -3.0, 1.2)  # -3 dB, 1.2x pitch

	# Play a random sound from a list
	var footstep_sounds := ["units/footstep_grass", "units/footstep_dirt"]
	AudioManager.play_random_sfx(footstep_sounds, position)

	# Play UI sound (non-positional)
	AudioManager.play_ui_sound("button_click")

	# Stop all sound effects
	AudioManager.stop_all_sounds()

## VOLUME CONTROL
func example_volume_control() -> void:
	# Set volume for different buses (0-100%)
	AudioManager.master_volume = 80.0
	AudioManager.music_volume = 70.0
	AudioManager.sfx_volume = 90.0
	AudioManager.ui_volume = 85.0

	# Get current volume
	var current_music_volume := AudioManager.get_bus_volume(AudioManager.BUS_MUSIC)
	print("Current music volume: %d%%" % current_music_volume)

	# Listen for volume changes
	AudioManager.volume_changed.connect(_on_volume_changed)

func _on_volume_changed(bus_name: String, volume: float) -> void:
	print("Volume changed - %s: %.1f%%" % [bus_name, volume])

## USING THE MUSIC CONTROLLER
func example_music_controller() -> void:
	# Access the music controller
	var music_controller := MusicController.new()
	add_child(music_controller)

	# Play different music phases
	music_controller.play_phase(MusicController.MusicPhase.MENU)
	music_controller.play_phase(MusicController.MusicPhase.BATTLE_INTRO)
	music_controller.play_phase(MusicController.MusicPhase.BATTLE_MAIN)

	# Update battle state for dynamic intensity
	music_controller.update_battle_state({
		"player_health_percent": 50.0,
		"enemy_health_percent": 30.0,
		"time_remaining": 45.0,
		"is_overtime": false
	})

	# Set combat intensity (spikes during action)
	music_controller.set_combat_intensity(0.8, 2.0)  # intensity, decay_time

	# Listen for phase changes
	music_controller.music_phase_changed.connect(_on_music_phase_changed)

func _on_music_phase_changed(phase: MusicController.MusicPhase) -> void:
	print("Music phase changed to: %s" % MusicController.MusicPhase.keys()[phase])

## BATTLE SCENE INTEGRATION
func example_battle_integration() -> void:
	# In your battle scene, trigger sounds based on events

	# Unit deployment
	AudioManager.play_sfx("units/knight_deploy", Vector2(100, 200))

	# Combat sounds
	AudioManager.play_sfx("combat/sword_swing", Vector2(150, 250))
	await get_tree().create_timer(0.2).timeout
	AudioManager.play_sfx("combat/sword_hit", Vector2(150, 250))

	# Tower damage
	AudioManager.play_ui_sound("tower_damage")
	AudioManager.duck_music(0.3)  # Duck music during important sound

	# Victory/Defeat
	AudioManager.play_ui_sound("victory_announcement")

## CARD SYSTEM INTEGRATION
func example_card_sounds() -> void:
	# Card hover
	AudioManager.play_ui_sound("card_hover", -6.0)  # Quieter hover sound

	# Card selection
	AudioManager.play_ui_sound("card_select")

	# Card placement
	var placement_pos := Vector2(300, 400)
	AudioManager.play_sfx("ui/card_place", placement_pos)

	# Invalid placement
	AudioManager.play_ui_sound("card_invalid")

	# Elixir sounds
	AudioManager.play_ui_sound("elixir_spend")
	AudioManager.play_ui_sound("elixir_gain", -3.0, 1.1)  # Slightly higher pitch

## SETTINGS MENU INTEGRATION
func example_settings_menu() -> void:
	# Create volume sliders in your settings menu
	var master_slider := HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = AudioManager.master_volume
	master_slider.value_changed.connect(func(value): AudioManager.master_volume = value)

	var music_slider := HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = AudioManager.music_volume
	music_slider.value_changed.connect(func(value): AudioManager.music_volume = value)

	# Settings are automatically saved when changed

## ADVANCED SOUND POOLING
func example_sound_pooling() -> void:
	# Direct access to sound pool for advanced features
	var sound_pool := SoundPool.new()
	add_child(sound_pool)

	# Configure pool
	sound_pool.pool_size = 30  # Increase pool size
	sound_pool.max_same_sound = 5  # Max 5 instances of same sound
	sound_pool.enable_debug(true)  # Enable debug output

	# Set sound priorities (higher priority sounds can interrupt lower ones)
	sound_pool.set_sound_priority("combat/explosion_large", 10)
	sound_pool.set_sound_priority("units/footstep_grass", 1)

	# Play looping sound (must be manually stopped)
	var stream := preload("res://audio/sfx/ambient/torch_burning.ogg")
	var looping_player := sound_pool.play_looping_sound(stream, "torch_burning", Vector2(200, 200))

	# Stop looping sound later
	await get_tree().create_timer(5.0).timeout
	sound_pool.stop_sound(looping_player)

	# Get pool statistics
	var stats := sound_pool.get_pool_stats()
	print("Active sounds: %d/%d" % [stats["active_players"], stats["pool_size"]])

## UNIT-SPECIFIC SOUNDS
func example_unit_sounds(unit_type: String, position: Vector2) -> void:
	# Play appropriate sound based on unit type
	match unit_type:
		"knight":
			AudioManager.play_sfx("units/knight_deploy", position)
			AudioManager.play_sfx("units/knight_battlecry", position, 0.0, randf_range(0.9, 1.1))
		"archer":
			AudioManager.play_sfx("units/archer_deploy", position)
			AudioManager.play_sfx("combat/arrow_draw", position)
		"wizard":
			AudioManager.play_sfx("units/wizard_deploy", position)
			AudioManager.play_sfx("units/wizard_chant", position)
		"giant":
			AudioManager.play_sfx("units/giant_deploy", position, 3.0)  # Louder
			AudioManager.play_sfx("units/giant_roar", position)
			# Giant footsteps shake the ground
			AudioManager.duck_music(0.5)

## PLACEHOLDER AUDIO (FOR TESTING)
func example_placeholder_audio() -> void:
	# When audio files don't exist yet, the system plays placeholder beeps
	# This allows you to test audio integration before having final assets

	# Enable debug mode to see what sounds are being triggered
	AudioManager.set_debug_mode(true)

	# These will play placeholder beeps if files don't exist
	AudioManager.play_music("non_existent_track")
	AudioManager.play_sfx("missing_sound_effect", Vector2.ZERO)

	# The debug output will show:
	# [AudioManager] Playing placeholder music for: non_existent_track
	# [AudioManager] Playing placeholder SFX for: missing_sound_effect

## CONNECTING TO GAME EVENTS
func example_connect_to_game_events() -> void:
	# Connect audio triggers to your game systems

	# Health component
	if has_node("HealthComponent"):
		var health_component = get_node("HealthComponent")
		health_component.damage_taken.connect(func(damage):
			AudioManager.play_sfx("units/knight_hurt", global_position)
		)
		health_component.died.connect(func():
			AudioManager.play_sfx("units/knight_death", global_position)
		)

	# Battle manager
	if has_node("/root/BattleManager"):
		var battle_manager = get_node("/root/BattleManager")
		battle_manager.battle_started.connect(func():
			var music_controller = get_node_or_null("MusicController")
			if music_controller:
				music_controller.play_phase(MusicController.MusicPhase.BATTLE_INTRO)
		)
		battle_manager.overtime_started.connect(func():
			AudioManager.play_ui_sound("overtime_start")
			var music_controller = get_node_or_null("MusicController")
			if music_controller:
				music_controller.play_phase(MusicController.MusicPhase.BATTLE_OVERTIME)
		)

## BEST PRACTICES
func best_practices_example() -> void:
	# 1. Use appropriate volume levels
	# UI sounds: -6 to 0 dB
	# Combat sounds: -3 to 0 dB
	# Ambient: -12 to -6 dB
	# Music: Controlled by music volume slider

	# 2. Vary pitch for repeated sounds to avoid monotony
	var pitch_variation := randf_range(0.9, 1.1)
	AudioManager.play_sfx("combat/sword_hit", Vector2.ZERO, 0.0, pitch_variation)

	# 3. Use position for spatial sounds
	var world_position := global_position if "global_position" in self else Vector2.ZERO
	AudioManager.play_sfx("combat/explosion_small", world_position)

	# 4. Duck music for important sounds
	AudioManager.play_ui_sound("victory_announcement")
	AudioManager.duck_music(1.0)

	# 5. Clean up looping sounds when scenes change
	# Override _exit_tree() in your scenes
	pass

func _exit_tree() -> void:
	# Clean up any looping sounds when scene exits
	AudioManager.stop_all_sounds()