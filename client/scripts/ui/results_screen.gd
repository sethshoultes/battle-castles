extends Control

class_name ResultsScreen

# UI Elements
@onready var result_label: Label = $ResultContainer/ResultLabel
@onready var crown_display: HBoxContainer = $ResultContainer/CrownDisplay
@onready var player_crowns: Label = $ResultContainer/CrownDisplay/PlayerCrowns
@onready var versus_label: Label = $ResultContainer/CrownDisplay/VersusLabel
@onready var enemy_crowns: Label = $ResultContainer/CrownDisplay/EnemyCrowns

# Trophy display
@onready var trophy_container: VBoxContainer = $ResultContainer/TrophyContainer
@onready var trophy_change_label: Label = $ResultContainer/TrophyContainer/TrophyChangeLabel
@onready var current_trophies_label: Label = $ResultContainer/TrophyContainer/CurrentTrophiesLabel
@onready var trophy_progress_bar: ProgressBar = $ResultContainer/TrophyContainer/TrophyProgressBar

# Rewards section
@onready var rewards_container: VBoxContainer = $ResultContainer/RewardsContainer
@onready var rewards_title: Label = $ResultContainer/RewardsContainer/RewardsTitle
@onready var gold_reward: HBoxContainer = $ResultContainer/RewardsContainer/GoldReward
@onready var gold_amount_label: Label = $ResultContainer/RewardsContainer/GoldReward/AmountLabel
@onready var chest_reward: HBoxContainer = $ResultContainer/RewardsContainer/ChestReward
@onready var chest_type_label: Label = $ResultContainer/RewardsContainer/ChestReward/ChestTypeLabel
@onready var crown_chest_progress: ProgressBar = $ResultContainer/RewardsContainer/CrownChestProgress

# Buttons
@onready var rematch_button: Button = $ButtonContainer/RematchButton
@onready var home_button: Button = $ButtonContainer/HomeButton
@onready var share_button: Button = $ButtonContainer/ShareButton
@onready var replay_button: Button = $ButtonContainer/ReplayButton

# Animation elements
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particles: CPUParticles2D = $VictoryParticles

# Match data
var match_result: String = "victory" # victory, defeat, draw
var player_crown_count: int = 0
var enemy_crown_count: int = 0
var trophy_change: int = 0
var previous_trophies: int = 0
var new_trophies: int = 0
var rewards: Dictionary = {}
var match_replay_id: String = ""

# Animation state
var animation_sequence_complete: bool = false

# Signals
signal rematch_requested()
signal home_requested()
signal replay_requested(replay_id: String)
signal share_requested(match_data: Dictionary)

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	visible = false

func _setup_ui() -> void:
	# Set button texts
	rematch_button.text = "REMATCH"
	home_button.text = "HOME"
	share_button.text = "SHARE"
	replay_button.text = "WATCH REPLAY"

	# Initially disable buttons during animation
	_set_buttons_enabled(false)

	# Hide rewards initially
	rewards_container.visible = false

func _connect_signals() -> void:
	rematch_button.pressed.connect(_on_rematch_pressed)
	home_button.pressed.connect(_on_home_pressed)
	share_button.pressed.connect(_on_share_pressed)
	replay_button.pressed.connect(_on_replay_pressed)

func show_results(result: String, player_crowns: int, enemy_crowns: int,
		trophies_change: int, match_rewards: Dictionary = {}, replay_id: String = "") -> void:
	match_result = result
	player_crown_count = player_crowns
	enemy_crown_count = enemy_crowns
	trophy_change = trophies_change
	rewards = match_rewards
	match_replay_id = replay_id

	visible = true
	_play_result_animation()

func _play_result_animation() -> void:
	# Reset UI elements
	_reset_ui_for_animation()

	# Start animation sequence
	match match_result:
		"victory":
			_play_victory_animation()
		"defeat":
			_play_defeat_animation()
		"draw":
			_play_draw_animation()

func _reset_ui_for_animation() -> void:
	result_label.modulate.a = 0.0
	crown_display.modulate.a = 0.0
	trophy_container.modulate.a = 0.0
	rewards_container.modulate.a = 0.0
	rewards_container.visible = false

	for button in [rematch_button, home_button, share_button, replay_button]:
		button.modulate.a = 0.0

func _play_victory_animation() -> void:
	result_label.text = "VICTORY!"
	result_label.modulate = Color(1.0, 0.8, 0.0, 0.0) # Gold color

	# Play victory particles
	if particles:
		particles.emitting = true

	# Animate result label
	var tween = create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(result_label, "scale", Vector2(1.2, 1.2), 0.5)\
		.from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.2)

	# Continue animation sequence
	tween.tween_callback(_animate_crowns)

func _play_defeat_animation() -> void:
	result_label.text = "DEFEAT"
	result_label.modulate = Color(0.8, 0.2, 0.2, 0.0) # Red color

	# Animate result label (more subtle for defeat)
	var tween = create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(result_label, "position:y", result_label.position.y, 0.5)\
		.from(result_label.position.y - 50)

	# Continue animation sequence
	tween.tween_callback(_animate_crowns)

func _play_draw_animation() -> void:
	result_label.text = "DRAW"
	result_label.modulate = Color(0.5, 0.5, 0.5, 0.0) # Gray color

	# Animate result label
	var tween = create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.5)

	# Continue animation sequence
	tween.tween_callback(_animate_crowns)

func _animate_crowns() -> void:
	# Set crown counts
	player_crowns.text = str(player_crown_count) + " 👑"
	versus_label.text = "VS"
	enemy_crowns.text = str(enemy_crown_count) + " 👑"

	# Animate crown display
	var tween = create_tween()
	tween.tween_property(crown_display, "modulate:a", 1.0, 0.3)

	# Animate each crown with a pop effect
	for i in range(player_crown_count):
		tween.tween_callback(_pop_crown_animation.bind(true, i))
		tween.tween_interval(0.2)

	for i in range(enemy_crown_count):
		tween.tween_callback(_pop_crown_animation.bind(false, i))
		tween.tween_interval(0.2)

	# Continue to trophy animation
	tween.tween_callback(_animate_trophies)

func _pop_crown_animation(is_player: bool, index: int) -> void:
	# Visual/audio feedback for each crown
	pass

func _animate_trophies() -> void:
	# Setup trophy display
	if trophy_change > 0:
		trophy_change_label.text = "+" + str(trophy_change) + " 🏆"
		trophy_change_label.modulate = Color.GREEN
	elif trophy_change < 0:
		trophy_change_label.text = str(trophy_change) + " 🏆"
		trophy_change_label.modulate = Color.RED
	else:
		trophy_change_label.text = "+0 🏆"
		trophy_change_label.modulate = Color.WHITE

	current_trophies_label.text = "Trophies: " + str(new_trophies)

	# Animate trophy container
	var tween = create_tween()
	tween.tween_property(trophy_container, "modulate:a", 1.0, 0.3)

	# Animate trophy progress bar if needed
	if trophy_progress_bar:
		_animate_trophy_progress()

	# Continue to rewards
	tween.tween_callback(_animate_rewards)

func _animate_trophy_progress() -> void:
	# Calculate progress to next arena
	var progress_value = float(new_trophies % 100) / 100.0
	trophy_progress_bar.value = 0.0

	var tween = create_tween()
	tween.tween_property(trophy_progress_bar, "value", progress_value, 1.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _animate_rewards() -> void:
	if rewards.is_empty():
		_finish_animation()
		return

	rewards_container.visible = true

	# Setup reward displays
	if rewards.has("gold"):
		gold_amount_label.text = str(rewards["gold"]) + " Gold"
		gold_reward.visible = true
	else:
		gold_reward.visible = false

	if rewards.has("chest"):
		chest_type_label.text = rewards["chest"].capitalize() + " Chest"
		chest_reward.visible = true
	else:
		chest_reward.visible = false

	if rewards.has("crowns"):
		crown_chest_progress.value = float(rewards["crowns"]) / 10.0
		crown_chest_progress.visible = true
	else:
		crown_chest_progress.visible = false

	# Animate rewards container
	var tween = create_tween()
	tween.tween_property(rewards_container, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_animate_buttons)

func _animate_buttons() -> void:
	# Enable and animate buttons
	_set_buttons_enabled(true)

	var delay = 0.0
	for button in [home_button, rematch_button, replay_button, share_button]:
		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(button, "modulate:a", 1.0, 0.2)
		delay += 0.1

	# Mark animation as complete
	await get_tree().create_timer(0.5).timeout
	animation_sequence_complete = true

func _finish_animation() -> void:
	_animate_buttons()

func _set_buttons_enabled(enabled: bool) -> void:
	rematch_button.disabled = not enabled
	home_button.disabled = not enabled
	share_button.disabled = not enabled
	replay_button.disabled = not enabled or match_replay_id.is_empty()

func _on_rematch_pressed() -> void:
	if not animation_sequence_complete:
		return

	_animate_button_press(rematch_button)
	rematch_requested.emit()

func _on_home_pressed() -> void:
	if not animation_sequence_complete:
		return

	_animate_button_press(home_button)
	home_requested.emit()
	_hide_screen()

func _on_share_pressed() -> void:
	if not animation_sequence_complete:
		return

	_animate_button_press(share_button)

	var match_data = {
		"result": match_result,
		"player_crowns": player_crown_count,
		"enemy_crowns": enemy_crown_count,
		"trophy_change": trophy_change,
		"replay_id": match_replay_id
	}
	share_requested.emit(match_data)

func _on_replay_pressed() -> void:
	if not animation_sequence_complete or match_replay_id.is_empty():
		return

	_animate_button_press(replay_button)
	replay_requested.emit(match_replay_id)

func _animate_button_press(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2.ONE, 0.05)

func _hide_screen() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func set_player_data(trophies: int) -> void:
	previous_trophies = trophies - trophy_change
	new_trophies = trophies

func quick_show_results() -> void:
	# Skip animations for testing
	animation_sequence_complete = true
	_set_buttons_enabled(true)

	result_label.modulate.a = 1.0
	crown_display.modulate.a = 1.0
	trophy_container.modulate.a = 1.0
	rewards_container.modulate.a = 1.0
	rewards_container.visible = true

	for button in [rematch_button, home_button, share_button, replay_button]:
		button.modulate.a = 1.0