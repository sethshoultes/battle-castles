extends Control
## AudioTestUI - Test interface for the audio system

@onready var master_slider: HSlider = $VBoxContainer/VolumeControls/MasterVolume/Slider
@onready var master_value: Label = $VBoxContainer/VolumeControls/MasterVolume/Value
@onready var music_slider: HSlider = $VBoxContainer/VolumeControls/MusicVolume/Slider
@onready var music_value: Label = $VBoxContainer/VolumeControls/MusicVolume/Value
@onready var sfx_slider: HSlider = $VBoxContainer/VolumeControls/SFXVolume/Slider
@onready var sfx_value: Label = $VBoxContainer/VolumeControls/SFXVolume/Value
@onready var ui_slider: HSlider = $VBoxContainer/VolumeControls/UIVolume/Slider
@onready var ui_value: Label = $VBoxContainer/VolumeControls/UIVolume/Value
@onready var status_label: RichTextLabel = $VBoxContainer/StatusLabel

var music_controller: MusicController
var test_position := Vector2(960, 540)  # Center of screen

func _ready() -> void:
	# Initialize music controller
	music_controller = MusicController.new()
	add_child(music_controller)

	# Setup volume sliders
	_setup_volume_controls()

	# Connect button signals
	_connect_buttons()

	# Connect to audio manager signals
	AudioManager.volume_changed.connect(_on_volume_changed)
	AudioManager.music_changed.connect(_on_music_changed)
	AudioManager.sfx_played.connect(_on_sfx_played)

	# Update initial status
	_update_status("Audio Test System Ready")

func _setup_volume_controls() -> void:
	# Set initial values from AudioManager
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	ui_slider.value = AudioManager.ui_volume

	# Update value labels
	master_value.text = "%d%%" % master_slider.value
	music_value.text = "%d%%" % music_slider.value
	sfx_value.text = "%d%%" % sfx_slider.value
	ui_value.text = "%d%%" % ui_slider.value

	# Connect slider signals
	master_slider.value_changed.connect(func(value):
		AudioManager.master_volume = value
		master_value.text = "%d%%" % value
	)

	music_slider.value_changed.connect(func(value):
		AudioManager.music_volume = value
		music_value.text = "%d%%" % value
	)

	sfx_slider.value_changed.connect(func(value):
		AudioManager.sfx_volume = value
		sfx_value.text = "%d%%" % value
	)

	ui_slider.value_changed.connect(func(value):
		AudioManager.ui_volume = value
		ui_value.text = "%d%%" % value
	)

func _connect_buttons() -> void:
	# Music buttons
	$VBoxContainer/MusicControls/PlayMenuMusic.pressed.connect(func():
		music_controller.play_phase(MusicController.MusicPhase.MENU)
		_update_status("Playing Menu Music (placeholder)")
	)

	$VBoxContainer/MusicControls/PlayBattleMusic.pressed.connect(func():
		music_controller.play_phase(MusicController.MusicPhase.BATTLE_MAIN)
		_update_status("Playing Battle Music (placeholder)")
		# Simulate battle intensity
		music_controller.update_battle_state({
			"player_health_percent": 75.0,
			"enemy_health_percent": 60.0,
			"time_remaining": 120.0,
			"is_overtime": false
		})
	)

	$VBoxContainer/MusicControls/PlayVictoryMusic.pressed.connect(func():
		music_controller.play_phase(MusicController.MusicPhase.VICTORY)
		_update_status("Playing Victory Music (placeholder)")
	)

	$VBoxContainer/MusicControls/StopMusic.pressed.connect(func():
		music_controller.stop_music(true)
		_update_status("Music stopped")
	)

	# SFX buttons
	$VBoxContainer/SFXControls/PlaySwordHit.pressed.connect(func():
		var pitch := randf_range(0.9, 1.1)
		AudioManager.play_sfx("combat/sword_hit", test_position, 0.0, pitch)
		_update_status("Playing: Sword Hit (pitch: %.2f)" % pitch)
	)

	$VBoxContainer/SFXControls/PlayArrowFly.pressed.connect(func():
		AudioManager.play_sfx("combat/arrow_fly", test_position)
		_update_status("Playing: Arrow Fly")
	)

	$VBoxContainer/SFXControls/PlayExplosion.pressed.connect(func():
		AudioManager.play_sfx("combat/explosion_medium", test_position, 3.0)
		AudioManager.duck_music(1.0)
		_update_status("Playing: Explosion (with music ducking)")
	)

	$VBoxContainer/SFXControls/PlayUIClick.pressed.connect(func():
		AudioManager.play_ui_sound("button_click")
		_update_status("Playing: UI Button Click")
	)

	# Back button
	$VBoxContainer/BackButton.pressed.connect(func():
		AudioManager.play_ui_sound("button_back")
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

func _on_volume_changed(bus_name: String, volume: float) -> void:
	_update_status("Volume changed - %s: %.1f%%" % [bus_name, volume])

func _on_music_changed(track_name: String) -> void:
	_update_status("Music changed to: %s" % track_name)

func _on_sfx_played(sound_name: String) -> void:
	_update_status("Sound effect played: %s" % sound_name)

func _update_status(message: String) -> void:
	var timestamp := Time.get_time_string_from_system()
	var colored_message := "[color=yellow]%s[/color] - %s" % [timestamp, message]

	# Add to status label (keep last 5 messages)
	var lines := status_label.text.split("\n")
	if lines.size() >= 5:
		lines.remove_at(0)
	lines.append(colored_message)
	status_label.text = "\n".join(lines)

func _input(event: InputEvent) -> void:
	# Test positional audio by clicking
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			test_position = event.position
			AudioManager.play_sfx("ui/card_place", test_position, -3.0)
			_update_status("Positional sound at: %s" % test_position)

	# Keyboard shortcuts for testing
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:  # Toggle music
				if music_controller.is_playing():
					music_controller.stop_music()
				else:
					music_controller.play_phase(MusicController.MusicPhase.MENU)
			KEY_SPACE:  # Random sound effect
				var sounds := ["combat/sword_swing", "combat/arrow_release", "units/knight_deploy"]
				AudioManager.play_random_sfx(sounds, test_position)
			KEY_D:  # Duck music
				AudioManager.duck_music(1.0)
			KEY_S:  # Stop all sounds
				AudioManager.stop_all_sounds()
				_update_status("All sounds stopped")

func _exit_tree() -> void:
	# Clean up when leaving scene
	music_controller.stop_music(false)
	AudioManager.stop_all_sounds()