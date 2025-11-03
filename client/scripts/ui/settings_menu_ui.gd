extends Control

class_name SettingsMenuUI

# UI Elements - Audio
@onready var master_volume_slider: HSlider = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/MasterVolume/Slider
@onready var master_volume_value: Label = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/MasterVolume/Value
@onready var sfx_volume_slider: HSlider = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/SFXVolume/Slider
@onready var sfx_volume_value: Label = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/SFXVolume/Value
@onready var music_volume_slider: HSlider = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/MusicVolume/Slider
@onready var music_volume_value: Label = $SettingsPanel/ScrollContainer/SettingsContainer/AudioSection/MusicVolume/Value

# UI Elements - Graphics
@onready var quality_option: OptionButton = $SettingsPanel/ScrollContainer/SettingsContainer/GraphicsSection/Quality/OptionButton
@onready var vsync_checkbox: CheckBox = $SettingsPanel/ScrollContainer/SettingsContainer/GraphicsSection/VSync/CheckBox

# UI Elements - Gameplay
@onready var confirm_placement_checkbox: CheckBox = $SettingsPanel/ScrollContainer/SettingsContainer/GameplaySection/ConfirmPlacement/CheckBox
@onready var vibration_checkbox: CheckBox = $SettingsPanel/ScrollContainer/SettingsContainer/GameplaySection/Vibration/CheckBox
@onready var ai_difficulty_option: OptionButton = $SettingsPanel/ScrollContainer/SettingsContainer/GameplaySection/AIDifficulty/OptionButton

# Buttons
@onready var apply_button: Button = $SettingsPanel/ButtonContainer/ApplyButton
@onready var cancel_button: Button = $SettingsPanel/ButtonContainer/CancelButton
@onready var close_button: Button = $SettingsPanel/CloseButton

# Settings data
var settings: Dictionary = {
	"audio": {
		"master_volume": 75,
		"sfx_volume": 75,
		"music_volume": 50
	},
	"graphics": {
		"quality": 1,  # 0: Low, 1: Medium, 2: High, 3: Ultra
		"vsync": true
	},
	"gameplay": {
		"confirm_placement": false,
		"vibration": true,
		"ai_difficulty": 1  # 0: Easy, 1: Medium, 2: Hard
	}
}

var original_settings: Dictionary = {}
var settings_changed: bool = false

# Signals
signal settings_applied(settings: Dictionary)
signal settings_closed()

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_load_settings()
	visible = false

func _setup_ui() -> void:
	# Setup quality options
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.add_item("Ultra")

	# Setup AI difficulty options
	ai_difficulty_option.add_item("Easy")
	ai_difficulty_option.add_item("Medium")
	ai_difficulty_option.add_item("Hard")

	# Set initial button states
	apply_button.disabled = true

func _connect_signals() -> void:
	# Audio sliders
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)

	# Graphics options
	quality_option.item_selected.connect(_on_quality_changed)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)

	# Gameplay options
	confirm_placement_checkbox.toggled.connect(_on_confirm_placement_toggled)
	vibration_checkbox.toggled.connect(_on_vibration_toggled)
	ai_difficulty_option.item_selected.connect(_on_ai_difficulty_changed)

	# Buttons
	apply_button.pressed.connect(_on_apply_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _load_settings() -> void:
	# Load settings from file or use defaults
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")

	if err == OK:
		# Load audio settings
		settings.audio.master_volume = config.get_value("audio", "master_volume", 75)
		settings.audio.sfx_volume = config.get_value("audio", "sfx_volume", 75)
		settings.audio.music_volume = config.get_value("audio", "music_volume", 50)

		# Load graphics settings
		settings.graphics.quality = config.get_value("graphics", "quality", 1)
		settings.graphics.vsync = config.get_value("graphics", "vsync", true)

		# Load gameplay settings
		settings.gameplay.confirm_placement = config.get_value("gameplay", "confirm_placement", false)
		settings.gameplay.vibration = config.get_value("gameplay", "vibration", true)
		settings.gameplay.ai_difficulty = config.get_value("gameplay", "ai_difficulty", 1)

	_apply_settings_to_ui()
	_apply_gameplay_settings()  # Apply to GameManager on load
	original_settings = settings.duplicate(true)

func _save_settings() -> void:
	var config = ConfigFile.new()

	# Save audio settings
	config.set_value("audio", "master_volume", settings.audio.master_volume)
	config.set_value("audio", "sfx_volume", settings.audio.sfx_volume)
	config.set_value("audio", "music_volume", settings.audio.music_volume)

	# Save graphics settings
	config.set_value("graphics", "quality", settings.graphics.quality)
	config.set_value("graphics", "vsync", settings.graphics.vsync)

	# Save gameplay settings
	config.set_value("gameplay", "confirm_placement", settings.gameplay.confirm_placement)
	config.set_value("gameplay", "vibration", settings.gameplay.vibration)
	config.set_value("gameplay", "ai_difficulty", settings.gameplay.ai_difficulty)

	config.save("user://settings.cfg")

func _apply_settings_to_ui() -> void:
	# Audio
	master_volume_slider.value = settings.audio.master_volume
	master_volume_value.text = str(settings.audio.master_volume)
	sfx_volume_slider.value = settings.audio.sfx_volume
	sfx_volume_value.text = str(settings.audio.sfx_volume)
	music_volume_slider.value = settings.audio.music_volume
	music_volume_value.text = str(settings.audio.music_volume)

	# Graphics
	quality_option.selected = settings.graphics.quality
	vsync_checkbox.button_pressed = settings.graphics.vsync

	# Gameplay
	confirm_placement_checkbox.button_pressed = settings.gameplay.confirm_placement
	vibration_checkbox.button_pressed = settings.gameplay.vibration
	ai_difficulty_option.selected = settings.gameplay.ai_difficulty

func _on_master_volume_changed(value: float) -> void:
	settings.audio.master_volume = int(value)
	master_volume_value.text = str(int(value))
	_check_settings_changed()
	_apply_audio_settings()

func _on_sfx_volume_changed(value: float) -> void:
	settings.audio.sfx_volume = int(value)
	sfx_volume_value.text = str(int(value))
	_check_settings_changed()
	_apply_audio_settings()

func _on_music_volume_changed(value: float) -> void:
	settings.audio.music_volume = int(value)
	music_volume_value.text = str(int(value))
	_check_settings_changed()
	_apply_audio_settings()

func _on_quality_changed(index: int) -> void:
	settings.graphics.quality = index
	_check_settings_changed()

func _on_vsync_toggled(button_pressed: bool) -> void:
	settings.graphics.vsync = button_pressed
	_check_settings_changed()

func _on_confirm_placement_toggled(button_pressed: bool) -> void:
	settings.gameplay.confirm_placement = button_pressed
	_check_settings_changed()

func _on_vibration_toggled(button_pressed: bool) -> void:
	settings.gameplay.vibration = button_pressed
	_check_settings_changed()

func _on_ai_difficulty_changed(index: int) -> void:
	settings.gameplay.ai_difficulty = index
	_check_settings_changed()

func _check_settings_changed() -> void:
	settings_changed = _are_settings_different()
	apply_button.disabled = not settings_changed

func _are_settings_different() -> bool:
	# Check if current settings differ from original
	if settings.audio.master_volume != original_settings.audio.master_volume:
		return true
	if settings.audio.sfx_volume != original_settings.audio.sfx_volume:
		return true
	if settings.audio.music_volume != original_settings.audio.music_volume:
		return true
	if settings.graphics.quality != original_settings.graphics.quality:
		return true
	if settings.graphics.vsync != original_settings.graphics.vsync:
		return true
	if settings.gameplay.confirm_placement != original_settings.gameplay.confirm_placement:
		return true
	if settings.gameplay.vibration != original_settings.gameplay.vibration:
		return true
	if settings.gameplay.ai_difficulty != original_settings.gameplay.ai_difficulty:
		return true
	return false

func _apply_audio_settings() -> void:
	# Apply audio settings to AudioServer
	var master_bus = AudioServer.get_bus_index("Master")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	var music_bus = AudioServer.get_bus_index("Music")

	if master_bus != -1:
		var master_db = linear_to_db(settings.audio.master_volume / 100.0)
		AudioServer.set_bus_volume_db(master_bus, master_db)

	if sfx_bus != -1:
		var sfx_db = linear_to_db(settings.audio.sfx_volume / 100.0)
		AudioServer.set_bus_volume_db(sfx_bus, sfx_db)

	if music_bus != -1:
		var music_db = linear_to_db(settings.audio.music_volume / 100.0)
		AudioServer.set_bus_volume_db(music_bus, music_db)

func _apply_graphics_settings() -> void:
	# Apply VSync
	if settings.graphics.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Apply quality settings
	match settings.graphics.quality:
		0: # Low
			RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), 0.75)
		1: # Medium
			RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), 1.0)
		2: # High
			RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), 1.25)
		3: # Ultra
			RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), 1.5)

func _apply_gameplay_settings() -> void:
	# Apply AI difficulty to GameManager
	if GameManager:
		GameManager.ai_difficulty = settings.gameplay.ai_difficulty

func _on_apply_pressed() -> void:
	_save_settings()
	_apply_graphics_settings()
	_apply_gameplay_settings()
	original_settings = settings.duplicate(true)
	settings_changed = false
	apply_button.disabled = true
	settings_applied.emit(settings)

func _on_cancel_pressed() -> void:
	# Revert to original settings
	settings = original_settings.duplicate(true)
	_apply_settings_to_ui()
	_apply_audio_settings()
	_apply_graphics_settings()
	_apply_gameplay_settings()
	hide_menu()

func _on_close_pressed() -> void:
	if settings_changed:
		# Show confirmation dialog if there are unsaved changes
		_show_unsaved_changes_dialog()
	else:
		hide_menu()

func _show_unsaved_changes_dialog() -> void:
	# Create a simple confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "You have unsaved changes. Do you want to apply them?"
	dialog.add_button("Apply", true, "apply")
	dialog.add_button("Discard", true, "discard")
	dialog.confirmed.connect(_on_dialog_confirmed)
	dialog.custom_action.connect(_on_dialog_custom_action)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_dialog_confirmed() -> void:
	# Cancel was pressed, just close
	hide_menu()

func _on_dialog_custom_action(action: String) -> void:
	match action:
		"apply":
			_on_apply_pressed()
			hide_menu()
		"discard":
			_on_cancel_pressed()

func show_menu() -> void:
	visible = true
	_load_settings()

	# Animate appearance
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_menu() -> void:
	# Animate disappearance
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		visible = false
		settings_closed.emit()
	)

func get_settings() -> Dictionary:
	return settings

func set_setting(category: String, key: String, value) -> void:
	if settings.has(category) and settings[category].has(key):
		settings[category][key] = value
		_apply_settings_to_ui()
		_check_settings_changed()