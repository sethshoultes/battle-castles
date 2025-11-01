## Complete Integration Example
## This shows how to use all the new integration systems together
## Use as reference when building your scenes
extends Node2D

## Scene references
@onready var camera = $Camera2D
@onready var ui_container = $UIContainer
@onready var game_objects = $GameObjects

## State
var is_paused: bool = false
var tutorial_active: bool = false


func _ready():
	print("=== Integration Example ===")
	_setup_all_systems()


## Sets up all integration systems
func _setup_all_systems():
	_setup_input()
	_setup_juice()
	_setup_data()
	_setup_ui_feedback()


## 1. INPUT MANAGER SETUP
func _setup_input():
	print("[1/4] Setting up InputManager...")

	# Configure deployment area (bottom half of screen)
	var screen_size = get_viewport().get_visible_rect().size
	var deployment_rect = Rect2(
		0,
		screen_size.y * 0.5,
		screen_size.x,
		screen_size.y * 0.5
	)
	InputManager.set_deployment_area(deployment_rect)

	# Connect signals
	InputManager.card_deployment_confirmed.connect(_on_card_deployed)
	InputManager.card_deployment_cancelled.connect(_on_deployment_cancelled)
	InputManager.card_selected.connect(_on_card_selected)
	InputManager.pause_requested.connect(_on_pause_requested)

	# Enable keyboard shortcuts
	InputManager.set_shortcuts_enabled(true)

	print("  ✓ Input configured")


## 2. JUICE MANAGER SETUP
func _setup_juice():
	print("[2/4] Setting up JuiceManager...")

	# Set camera for screen shake
	if camera:
		JuiceManager.set_camera(camera)

	# Configure accessibility (example - could be from settings)
	JuiceManager.set_juice_intensity(1.0)
	JuiceManager.set_screen_shake_enabled(true)
	JuiceManager.set_hitstop_enabled(true)

	print("  ✓ Juice configured")


## 3. DATA VALIDATOR SETUP
func _setup_data():
	print("[3/4] Setting up DataValidator...")

	# Validate data on scene load
	if DataValidator.validate_all_data():
		print("  ✓ Data validated successfully")
	else:
		print("  ⚠ Data validation warnings:")
		for error in DataValidator.get_last_errors():
			print("    - ", error)

	# Create backup before important operations
	# DataValidator.create_backup()


## 4. UI INTERACTIVE FEEDBACK
func _setup_ui_feedback():
	print("[4/4] Setting up UI feedback...")

	# Add interactive feedback to all buttons
	var buttons = get_tree().get_nodes_in_group("ui_buttons")
	for button in buttons:
		if button is Control and not button.has_node("InteractiveFeedback"):
			var feedback_script = preload("res://scripts/ui/interactive_feedback.gd")
			var feedback = feedback_script.new()
			button.add_child(feedback)

	print("  ✓ UI feedback configured")
	print("=== Setup Complete ===\n")


## INPUT CALLBACKS

func _on_card_deployed(card_id: int, position: Vector2):
	print("Card ", card_id, " deployed at ", position)

	# Visual feedback
	JuiceManager.deployment_success(position)
	JuiceManager.add_screen_shake(0.2)

	# Spawn unit
	_spawn_unit(card_id, position)


func _on_deployment_cancelled():
	print("Deployment cancelled")
	# Could play cancel sound
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("cancel")


func _on_card_selected(card_index: int):
	print("Card selected: ", card_index)

	# Find card UI element
	var card = ui_container.get_node_or_null("Card" + str(card_index))
	if card:
		JuiceManager.card_selected(card)


func _on_pause_requested():
	print("Pause requested")
	_toggle_pause()


## GAME LOGIC EXAMPLES

func _spawn_unit(card_id: int, position: Vector2):
	# Create a simple visual representation
	var unit = ColorRect.new()
	unit.size = Vector2(40, 40)
	unit.position = position - unit.size / 2
	unit.color = Color(randf(), randf(), randf())
	game_objects.add_child(unit)

	# Pop-in animation
	JuiceManager.pop_in(unit, 0.3)

	# Simulate unit taking damage after 2 seconds
	await get_tree().create_timer(2.0).timeout
	_unit_take_damage(unit, 50)


func _unit_take_damage(unit: Node2D, damage: int):
	if not is_instance_valid(unit):
		return

	# Impact feedback
	JuiceManager.impact(unit, 0.8)

	# Damage popup
	JuiceManager.damage_popup(unit.global_position + Vector2(0, -20), damage, false)

	# Shake the unit
	JuiceManager.shake_node(unit, 5.0, 0.2)

	# Destroy after another 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(unit):
		_destroy_unit(unit)


func _destroy_unit(unit: Node2D):
	if not is_instance_valid(unit):
		return

	# Pop-out animation with auto-destroy
	JuiceManager.pop_out(unit, 0.3)

	# Screen shake
	JuiceManager.add_screen_shake(0.3)


## SCENE TRANSITION EXAMPLES

func go_to_main_menu():
	SceneManager.goto_main_menu()


func go_to_battle():
	SceneManager.goto_battle()


func go_to_settings():
	SceneManager.goto_settings()


func custom_transition():
	SceneManager.change_scene(
		"res://scenes/custom.tscn",
		SceneManager.TransitionType.CIRCLE_CLOSE
	)


## PAUSE HANDLING

func _toggle_pause():
	is_paused = not is_paused

	if is_paused:
		_pause_game()
	else:
		_resume_game()


func _pause_game():
	get_tree().paused = true
	# Show pause menu
	print("Game paused")


func _resume_game():
	get_tree().paused = false
	# Hide pause menu
	print("Game resumed")


## TUTORIAL INTEGRATION EXAMPLE

func start_tutorial():
	print("Starting tutorial...")
	tutorial_active = true

	# Tutorial would guide through these steps:
	await _tutorial_step_1_welcome()
	await _tutorial_step_2_select_card()
	await _tutorial_step_3_deploy_unit()

	tutorial_active = false
	print("Tutorial complete!")


func _tutorial_step_1_welcome():
	print("Tutorial: Welcome!")
	# Show tutorial UI
	await get_tree().create_timer(2.0).timeout


func _tutorial_step_2_select_card():
	print("Tutorial: Select a card")
	# Highlight first card
	var card = ui_container.get_node_or_null("Card0")
	if card:
		JuiceManager.pulse(card, 1.2, 0.5, 3)
	await get_tree().create_timer(3.0).timeout


func _tutorial_step_3_deploy_unit():
	print("Tutorial: Deploy the unit")
	# Highlight deployment area
	await get_tree().create_timer(3.0).timeout


## DATA MANAGEMENT EXAMPLES

func save_game_state():
	# Create backup first
	var backup_path = DataValidator.create_backup()
	print("Backup created: ", backup_path)

	# Save game data
	var save_data = {
		"version": "1.0.0",
		"player_position": Vector2(100, 200),
		"score": 1000
	}

	var file = FileAccess.open("user://saves/game_state.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved")


func load_game_state():
	var file_path = "user://saves/game_state.json"

	# Validate before loading
	if DataValidator.validate_file(file_path, "settings"):  # Using settings schema as example
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.data
				print("Game loaded: ", data)
			file.close()
	else:
		print("Save file validation failed")


## VICTORY/DEFEAT EXAMPLES

func trigger_victory():
	print("VICTORY!")
	JuiceManager.victory_celebration()

	# Wait for celebration
	await get_tree().create_timer(2.0).timeout

	# Go to results
	SceneManager.change_scene(
		"res://scenes/ui/results.tscn",
		SceneManager.TransitionType.FADE
	)


func trigger_defeat():
	print("DEFEAT")
	JuiceManager.defeat_effect()

	# Wait for effect
	await get_tree().create_timer(2.0).timeout

	# Go to results
	SceneManager.change_scene(
		"res://scenes/ui/results.tscn",
		SceneManager.TransitionType.FADE
	)


## UI BUTTON CALLBACKS (connect these in editor or code)

func _on_menu_button_pressed():
	JuiceManager.button_press($UIContainer/MenuButton)
	go_to_main_menu()


func _on_restart_button_pressed():
	JuiceManager.button_press($UIContainer/RestartButton)
	SceneManager.reload_current_scene()


func _on_settings_button_pressed():
	JuiceManager.button_press($UIContainer/SettingsButton)
	go_to_settings()


## ACCESSIBILITY SETTINGS

func apply_accessibility_settings(settings: Dictionary):
	# Juice intensity
	var juice_intensity = settings.get("juice_intensity", 1.0)
	JuiceManager.set_juice_intensity(juice_intensity)

	# Screen shake
	var shake_enabled = settings.get("screen_shake", true)
	JuiceManager.set_screen_shake_enabled(shake_enabled)

	# Hitstop
	var hitstop_enabled = settings.get("hitstop", true)
	JuiceManager.set_hitstop_enabled(hitstop_enabled)

	# Haptics
	var haptic_enabled = settings.get("haptics", true)
	JuiceManager.set_haptic_enabled(haptic_enabled)

	print("Accessibility settings applied")


## CLEANUP

func _exit_tree():
	# Reset input
	InputManager.reset()

	print("Integration example cleaned up")


## TESTING FUNCTIONS

func test_all_features():
	print("\n=== Testing All Features ===")

	# Test input
	print("\n1. Testing Input:")
	InputManager.select_card(0)
	print("  Card selected programmatically")

	# Test juice effects
	print("\n2. Testing Juice Effects:")
	JuiceManager.add_screen_shake(0.5)
	print("  Screen shake triggered")

	await get_tree().create_timer(0.5).timeout

	# Test scene preloading
	print("\n3. Testing Scene Manager:")
	SceneManager.preload_scene("res://scenes/main_menu.tscn")
	print("  Scene preloaded")

	# Test data validation
	print("\n4. Testing Data Validator:")
	var is_valid = DataValidator.validate_all_data()
	print("  Data valid: ", is_valid)

	print("\n=== All Tests Complete ===\n")
