extends Control

# Battle Results Screen UI
# Displays post-battle results including victory/defeat, rewards, and statistics

signal return_to_menu_pressed

# UI References - Main Elements
@onready var background: ColorRect = $Background
@onready var results_panel: PanelContainer = $MainContainer/ResultsPanel
@onready var fade_animation: AnimationPlayer = $AnimationPlayer

# Result Message
@onready var result_message: Label = $MainContainer/ResultsPanel/VBox/ResultMessage

# Crown Section
@onready var player_crowns: Label = $MainContainer/ResultsPanel/VBox/CrownSection/PlayerCrowns
@onready var opponent_crowns: Label = $MainContainer/ResultsPanel/VBox/CrownSection/OpponentCrowns

# Rewards Section
@onready var trophy_change: Label = $MainContainer/ResultsPanel/VBox/RewardsSection/TrophyRow/TrophyChange
@onready var xp_gained: Label = $MainContainer/ResultsPanel/VBox/RewardsSection/XPRow/XPGained

# Stats Section
@onready var battle_time: Label = $MainContainer/ResultsPanel/VBox/StatsSection/StatsGrid/BattleTimeValue
@onready var units_deployed: Label = $MainContainer/ResultsPanel/VBox/StatsSection/StatsGrid/UnitsDeployedValue

# Button
@onready var return_button: Button = $MainContainer/ResultsPanel/VBox/ButtonContainer/ReturnButton

# Battle data
var is_victory: bool = false
var is_draw: bool = false
var player_crown_count: int = 0
var opponent_crown_count: int = 0
var trophy_delta: int = 0
var experience_gained: int = 0
var time_played: float = 0.0
var units_deployed_count: int = 0

func _ready() -> void:
	# Connect button signal
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)

	# Start hidden for fade-in animation
	modulate.a = 0.0

	# Play fade-in animation after a short delay
	await get_tree().create_timer(0.5).timeout
	_animate_fade_in()

func initialize(battle_data: Dictionary) -> void:
	"""Initialize the results screen with battle data
	Expected keys:
	- winner_team: int (0 = player, 1 = opponent, -1 = draw)
	- player_crowns: int
	- opponent_crowns: int
	- trophy_change: int (can be negative)
	- xp_gained: int
	- battle_time: float
	- units_deployed: int
	"""
	# Store battle data
	var winner = battle_data.get("winner_team", -1)
	is_victory = (winner == 0)  # 0 = player team
	is_draw = (winner == -1)

	player_crown_count = battle_data.get("player_crowns", 0)
	opponent_crown_count = battle_data.get("opponent_crowns", 0)
	trophy_delta = battle_data.get("trophy_change", 0)
	experience_gained = battle_data.get("xp_gained", 0)
	time_played = battle_data.get("battle_time", 0.0)
	units_deployed_count = battle_data.get("units_deployed", 0)

	# Update UI
	_update_result_message()
	_update_crowns()
	_update_rewards()
	_update_stats()

func _update_result_message() -> void:
	if not result_message:
		return

	if is_draw:
		result_message.text = "DRAW"
		result_message.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4, 1))  # Yellow-gray
	elif is_victory:
		result_message.text = "VICTORY!"
		result_message.add_theme_color_override("font_color", Color(1, 0.843, 0, 1))  # Gold
	else:
		result_message.text = "DEFEAT"
		result_message.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))  # Red

func _update_crowns() -> void:
	if player_crowns:
		player_crowns.text = str(player_crown_count)

	if opponent_crowns:
		opponent_crowns.text = str(opponent_crown_count)

func _update_rewards() -> void:
	# Update trophy change
	if trophy_change:
		if trophy_delta > 0:
			trophy_change.text = "+" + str(trophy_delta)
			trophy_change.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))  # Green
		elif trophy_delta < 0:
			trophy_change.text = str(trophy_delta)
			trophy_change.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))  # Red
		else:
			trophy_change.text = "0"
			trophy_change.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))  # Gray

	# Update XP gained
	if xp_gained:
		xp_gained.text = "+" + str(experience_gained) + " XP"
		xp_gained.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))  # Blue

func _update_stats() -> void:
	# Format battle time
	if battle_time:
		var minutes = int(time_played) / 60
		var seconds = int(time_played) % 60
		battle_time.text = "%d:%02d" % [minutes, seconds]

	# Update units deployed
	if units_deployed:
		units_deployed.text = str(units_deployed_count)

func _animate_fade_in() -> void:
	# Fade in the entire screen
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Animate the result message
	await tween.finished
	_animate_result_message()

func _animate_result_message() -> void:
	if not result_message:
		return

	# Scale bounce effect
	result_message.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(result_message, "scale", Vector2.ONE, 0.8)

	# Start crown count-up after message
	await tween.finished
	_animate_crown_countup()

func _animate_crown_countup() -> void:
	# Animate player crowns
	if player_crowns:
		var start = 0
		var end = player_crown_count
		var duration = 0.5
		var tween = create_tween()
		tween.tween_method(_update_player_crown_count, start, end, duration)

	# Animate opponent crowns
	if opponent_crowns:
		var start = 0
		var end = opponent_crown_count
		var duration = 0.5
		var tween = create_tween()
		tween.tween_method(_update_opponent_crown_count, start, end, duration)

	# Start trophy animation after crowns
	await get_tree().create_timer(0.6).timeout
	_animate_trophy_countup()

func _update_player_crown_count(value: int) -> void:
	if player_crowns:
		player_crowns.text = str(value)

func _update_opponent_crown_count(value: int) -> void:
	if opponent_crowns:
		opponent_crowns.text = str(value)

func _animate_trophy_countup() -> void:
	if not trophy_change:
		return

	# Animate trophy count-up
	var start = 0
	var end = trophy_delta
	var duration = 0.8
	var tween = create_tween()
	tween.tween_method(_update_trophy_count, start, end, duration)

	# Start XP animation after trophies
	await tween.finished
	_animate_xp_countup()

func _update_trophy_count(value: int) -> void:
	if not trophy_change:
		return

	if value > 0:
		trophy_change.text = "+" + str(value)
	else:
		trophy_change.text = str(value)

func _animate_xp_countup() -> void:
	if not xp_gained:
		return

	# Animate XP count-up
	var start = 0
	var end = experience_gained
	var duration = 0.6
	var tween = create_tween()
	tween.tween_method(_update_xp_count, start, end, duration)

func _update_xp_count(value: int) -> void:
	if xp_gained:
		xp_gained.text = "+" + str(value) + " XP"

func _on_return_button_pressed() -> void:
	return_to_menu_pressed.emit()

	# Return to main menu
	if SceneManager:
		SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		push_error("SceneManager not found")
