## Interactive battle tutorial system
## Guides new players through their first match with step-by-step instructions
## Attach to battle scene to enable tutorial mode
extends Node

## Signals
signal tutorial_started()
signal tutorial_step_completed(step_index: int)
signal tutorial_completed()
signal tutorial_skipped()

## Tutorial steps
enum TutorialStep {
	WELCOME,
	EXPLAIN_ELIXIR,
	EXPLAIN_CARDS,
	FIRST_DEPLOYMENT,
	EXPLAIN_MOVEMENT,
	EXPLAIN_COMBAT,
	EXPLAIN_TOWERS,
	EXPLAIN_CASTLE,
	FIRST_VICTORY,
	TUTORIAL_COMPLETE
}

## Tutorial state
var current_step: TutorialStep = TutorialStep.WELCOME
var tutorial_active: bool = false
var tutorial_completed_flag: bool = false
var can_skip: bool = true

## References (set these in the battle scene)
var battle_manager: Node = null
var elixir_manager: Node = null
var battle_ui: Control = null
var battlefield: Node2D = null

## Tutorial UI elements
var tutorial_overlay: ColorRect = null
var tutorial_panel: Panel = null
var tutorial_label: RichTextLabel = null
var tutorial_button: Button = null
var highlight_area: Control = null
var arrow_pointer: Control = null

## Tutorial settings
var forced_first_card_index: int = 0  # Knight card for first deploy
var tutorial_enemy_health: int = 500  # Weakened enemy castle
var player_starting_elixir: int = 10  # Extra elixir to start

## Step tracking
var deployment_count: int = 0
var units_created: int = 0
var enemy_damaged: bool = false

## Tutorial dialog text
var tutorial_texts: Dictionary = {
	TutorialStep.WELCOME: {
		"title": "Welcome to Battle Castles!",
		"text": "Let me show you how to battle! Your goal is to destroy the enemy castle while protecting yours.",
		"button": "Let's Go!"
	},
	TutorialStep.EXPLAIN_ELIXIR: {
		"title": "Elixir - Your Resource",
		"text": "Elixir automatically fills over time. You need elixir to deploy units. Watch the purple bar at the top!",
		"button": "Got it!"
	},
	TutorialStep.EXPLAIN_CARDS: {
		"title": "Your Card Hand",
		"text": "These are your unit cards. Each card shows the elixir cost in the corner. Tap a card to select it!",
		"button": "Next"
	},
	TutorialStep.FIRST_DEPLOYMENT: {
		"title": "Deploy Your First Unit!",
		"text": "Select the Knight card, then tap on your side of the battlefield to deploy it. Units automatically move and attack!",
		"button": ""  # No button, wait for action
	},
	TutorialStep.EXPLAIN_MOVEMENT: {
		"title": "Units Move Automatically",
		"text": "Great! Your knight moves toward the enemy automatically. Ground units follow lanes to reach the enemy castle!",
		"button": "Cool!"
	},
	TutorialStep.EXPLAIN_COMBAT: {
		"title": "Automatic Combat",
		"text": "When your units encounter enemies, they fight automatically. Deploy units strategically to win battles!",
		"button": "Understood!"
	},
	TutorialStep.EXPLAIN_TOWERS: {
		"title": "Destroy the Towers",
		"text": "The enemy has 2 towers protecting their castle. Destroy them first to make reaching the castle easier!",
		"button": "Okay!"
	},
	TutorialStep.EXPLAIN_CASTLE: {
		"title": "Victory Condition",
		"text": "Destroy the enemy castle to win! Keep deploying units and overwhelming your opponent!",
		"button": "Let's win!"
	},
	TutorialStep.FIRST_VICTORY: {
		"title": "You're Winning!",
		"text": "The enemy castle is weakening! Keep the pressure on to secure your first victory!",
		"button": "Finish them!"
	},
	TutorialStep.TUTORIAL_COMPLETE: {
		"title": "Tutorial Complete!",
		"text": "Excellent work! You've mastered the basics. Now go forth and conquer in real battles!",
		"button": "Start Playing!"
	}
}


func _ready() -> void:
	# Create tutorial UI
	_create_tutorial_ui()
	print("BattleTutorial ready")


## Starts the tutorial
func start_tutorial() -> void:
	if tutorial_completed_flag:
		return

	tutorial_active = true
	current_step = TutorialStep.WELCOME
	deployment_count = 0
	units_created = 0
	enemy_damaged = false

	# Setup tutorial battle conditions
	_setup_tutorial_battle()

	# Show first step
	_show_step(current_step)

	tutorial_started.emit()
	print("Tutorial started")


## Creates the tutorial UI overlay
func _create_tutorial_ui() -> void:
	# Semi-transparent overlay
	tutorial_overlay = ColorRect.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.color = Color(0, 0, 0, 0.7)
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_overlay.visible = false
	add_child(tutorial_overlay)

	# Tutorial panel (center)
	tutorial_panel = Panel.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.custom_minimum_size = Vector2(600, 300)
	tutorial_panel.position = Vector2(660, 390)  # Center-ish
	tutorial_overlay.add_child(tutorial_panel)

	# Tutorial text
	tutorial_label = RichTextLabel.new()
	tutorial_label.name = "TutorialLabel"
	tutorial_label.bbcode_enabled = true
	tutorial_label.fit_content = true
	tutorial_label.position = Vector2(20, 20)
	tutorial_label.size = Vector2(560, 200)
	tutorial_panel.add_child(tutorial_label)

	# Continue button
	tutorial_button = Button.new()
	tutorial_button.name = "TutorialButton"
	tutorial_button.text = "Next"
	tutorial_button.custom_minimum_size = Vector2(200, 50)
	tutorial_button.position = Vector2(200, 230)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	tutorial_panel.add_child(tutorial_button)

	# Highlight area (for pointing at UI elements)
	highlight_area = Control.new()
	highlight_area.name = "HighlightArea"
	highlight_area.visible = false
	add_child(highlight_area)

	# Arrow pointer
	arrow_pointer = Control.new()
	arrow_pointer.name = "ArrowPointer"
	arrow_pointer.visible = false
	add_child(arrow_pointer)


## Sets up tutorial-specific battle conditions
func _setup_tutorial_battle() -> void:
	if not battle_manager or not elixir_manager:
		push_warning("Battle manager or elixir manager not set for tutorial")
		return

	# Give player extra starting elixir
	if elixir_manager.has_method("add_elixir"):
		elixir_manager.add_elixir(player_starting_elixir)

	# Weaken enemy castle
	if battlefield:
		var enemy_castle = battlefield.get_node_or_null("EnemyCastle")
		if enemy_castle and enemy_castle.has_method("set_max_health"):
			enemy_castle.set_max_health(tutorial_enemy_health)

	# Disable AI for tutorial (or make it very passive)
	if battle_manager.has_method("set_ai_enabled"):
		battle_manager.set_ai_enabled(false)


## Shows a tutorial step
func _show_step(step: TutorialStep) -> void:
	if not tutorial_texts.has(step):
		return

	var step_data: Dictionary = tutorial_texts[step]

	# Update UI
	var title: String = step_data.get("title", "")
	var text: String = step_data.get("text", "")
	var button_text: String = step_data.get("button", "Next")

	tutorial_label.text = "[b][font_size=24]" + title + "[/font_size][/b]\n\n" + text

	if button_text.is_empty():
		tutorial_button.visible = false
	else:
		tutorial_button.visible = true
		tutorial_button.text = button_text

	tutorial_overlay.visible = true

	# Add specific step behaviors
	match step:
		TutorialStep.EXPLAIN_CARDS:
			_highlight_cards()

		TutorialStep.FIRST_DEPLOYMENT:
			_highlight_deployment_area()
			_force_card_selection(forced_first_card_index)

		TutorialStep.EXPLAIN_ELIXIR:
			_highlight_elixir_bar()


## Highlights the card hand
func _highlight_cards() -> void:
	if not battle_ui:
		return

	# Find card container in UI
	var card_container = battle_ui.get_node_or_null("CardContainer")
	if card_container:
		_show_highlight_around(card_container)


## Highlights the elixir bar
func _highlight_elixir_bar() -> void:
	if not battle_ui:
		return

	var elixir_bar = battle_ui.get_node_or_null("ElixirBar")
	if elixir_bar:
		_show_highlight_around(elixir_bar)


## Highlights the deployment area
func _highlight_deployment_area() -> void:
	highlight_area.visible = true
	# Draw or position highlight to show valid deployment zone


## Shows highlight around a control
func _show_highlight_around(control: Control) -> void:
	if not control:
		return

	highlight_area.visible = true
	highlight_area.position = control.global_position - Vector2(10, 10)
	highlight_area.size = control.size + Vector2(20, 20)


## Forces selection of a specific card
func _force_card_selection(card_index: int) -> void:
	if not battle_ui:
		return

	# This would trigger the card selection in battle UI
	if battle_ui.has_method("select_card"):
		battle_ui.select_card(card_index)


## Called when tutorial button is pressed
func _on_tutorial_button_pressed() -> void:
	_advance_step()


## Advances to next tutorial step
func _advance_step() -> void:
	tutorial_step_completed.emit(current_step)

	# Hide highlights
	highlight_area.visible = false
	arrow_pointer.visible = false

	# Move to next step
	current_step = (current_step + 1) as TutorialStep

	if current_step >= TutorialStep.TUTORIAL_COMPLETE:
		_complete_tutorial()
	else:
		_show_step(current_step)


## Called when a unit is deployed (from battle manager)
func on_unit_deployed(unit: Node2D, team: int) -> void:
	if not tutorial_active:
		return

	if team == 0:  # Player team
		deployment_count += 1
		units_created += 1

		# Progress tutorial on first deployment
		if current_step == TutorialStep.FIRST_DEPLOYMENT:
			_advance_step()


## Called when combat occurs
func on_combat_started(attacker: Node2D, defender: Node2D) -> void:
	if not tutorial_active:
		return

	# Progress if at combat explanation step
	if current_step == TutorialStep.EXPLAIN_MOVEMENT:
		await get_tree().create_timer(2.0).timeout  # Let them see movement
		if tutorial_active:  # Check still active
			_advance_step()


## Called when enemy takes damage
func on_enemy_damaged(damage: int) -> void:
	if not tutorial_active:
		return

	enemy_damaged = true

	# Show victory message when enemy low health
	if current_step >= TutorialStep.EXPLAIN_CASTLE:
		var enemy_castle = battlefield.get_node_or_null("EnemyCastle")
		if enemy_castle and enemy_castle.has_method("get_health"):
			var health: int = enemy_castle.get_health()
			if health < tutorial_enemy_health * 0.3 and current_step != TutorialStep.FIRST_VICTORY:
				current_step = TutorialStep.FIRST_VICTORY
				_show_step(current_step)


## Called when battle ends
func on_battle_ended(winning_team: int) -> void:
	if not tutorial_active:
		return

	if winning_team == 0:  # Player won
		_complete_tutorial()
	else:
		# Player lost tutorial (shouldn't happen, but restart)
		_restart_tutorial()


## Completes the tutorial
func _complete_tutorial() -> void:
	tutorial_active = false
	tutorial_completed_flag = true

	# Show completion message
	current_step = TutorialStep.TUTORIAL_COMPLETE
	_show_step(current_step)

	tutorial_completed.emit()
	print("Tutorial completed!")

	# Save tutorial completion
	_save_tutorial_completion()


## Restarts the tutorial
func _restart_tutorial() -> void:
	tutorial_overlay.visible = false
	await get_tree().create_timer(1.0).timeout
	start_tutorial()


## Skips the tutorial
func skip_tutorial() -> void:
	if not can_skip:
		return

	tutorial_active = false
	tutorial_overlay.visible = false
	tutorial_skipped.emit()
	print("Tutorial skipped")

	_save_tutorial_completion()  # Mark as completed even if skipped


## Saves tutorial completion to player profile
func _save_tutorial_completion() -> void:
	# This would save to player profile
	var save_path := "user://saves/player_profile.json"

	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()

			var json := JSON.new()
			if json.parse(json_string) == OK:
				var data: Dictionary = json.data
				data["tutorial_completed"] = true

				var save_file := FileAccess.open(save_path, FileAccess.WRITE)
				if save_file:
					save_file.store_string(JSON.stringify(data, "\t"))
					save_file.close()


## Checks if tutorial was completed before
func has_completed_tutorial() -> bool:
	var save_path := "user://saves/player_profile.json"

	if not FileAccess.file_exists(save_path):
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) == OK:
		var data: Dictionary = json.data
		return data.get("tutorial_completed", false)

	return false


## Sets battle manager reference
func set_battle_manager(manager: Node) -> void:
	battle_manager = manager


## Sets elixir manager reference
func set_elixir_manager(manager: Node) -> void:
	elixir_manager = manager


## Sets battle UI reference
func set_battle_ui(ui: Control) -> void:
	battle_ui = ui


## Sets battlefield reference
func set_battlefield(field: Node2D) -> void:
	battlefield = field


## Checks if tutorial is active
func is_tutorial_active() -> bool:
	return tutorial_active
