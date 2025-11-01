extends Control

class_name BattleUI

# UI Elements
@onready var elixir_bar: ProgressBar = $ElixirContainer/ElixirBar
@onready var elixir_label: Label = $ElixirContainer/ElixirLabel
@onready var timer_label: Label = $TopBar/TimerContainer/TimerLabel
@onready var card_hand_container: HBoxContainer = $BottomPanel/CardHandContainer
@onready var next_card_preview: TextureRect = $BottomPanel/NextCardPreview

# Crown displays
@onready var player_crowns: Label = $TopBar/PlayerInfo/CrownCount
@onready var player_name: Label = $TopBar/PlayerInfo/PlayerName
@onready var player_avatar: TextureRect = $TopBar/PlayerInfo/Avatar
@onready var enemy_crowns: Label = $TopBar/EnemyInfo/CrownCount
@onready var enemy_name: Label = $TopBar/EnemyInfo/EnemyName
@onready var enemy_avatar: TextureRect = $TopBar/EnemyInfo/Avatar

# Game state
var current_elixir: float = 5.0
var max_elixir: float = 10.0
var elixir_rate: float = 2.8 # Elixir per second (normal speed)
var card_hand: Array = []
var next_card: Resource = null
var match_time: float = 180.0 # 3 minutes
var is_overtime: bool = false

# Signals
signal card_played(card: Resource, position: Vector2)
signal pause_requested()

func _ready() -> void:
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	# Set up elixir bar
	elixir_bar.max_value = max_elixir
	elixir_bar.value = current_elixir
	_update_elixir_display()

	# Initialize timer
	_update_timer_display()

	# Set up card hand slots
	for i in range(4):
		var card_slot = preload("res://scenes/ui/card_slot.tscn").instantiate()
		card_slot.name = "CardSlot" + str(i)
		card_hand_container.add_child(card_slot)
		card_slot.card_dropped.connect(_on_card_dropped)

func _connect_signals() -> void:
	# Connect to game manager signals when implemented
	pass

func _process(delta: float) -> void:
	# Update elixir
	if current_elixir < max_elixir:
		current_elixir = min(current_elixir + elixir_rate * delta, max_elixir)
		_update_elixir_display()

	# Update timer
	if match_time > 0:
		match_time -= delta
		_update_timer_display()

		# Check for overtime
		if match_time <= 0 and not is_overtime:
			_start_overtime()

func _update_elixir_display() -> void:
	elixir_bar.value = current_elixir
	elixir_label.text = str(int(current_elixir)) + "/" + str(int(max_elixir))

	# Update card availability based on elixir
	for i in range(card_hand.size()):
		var card_slot = card_hand_container.get_child(i)
		if card_slot and card_hand[i]:
			card_slot.set_playable(current_elixir >= card_hand[i].elixir_cost)

func _update_timer_display() -> void:
	var minutes = int(match_time) / 60
	var seconds = int(match_time) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	# Change color in final seconds
	if match_time <= 10:
		timer_label.modulate = Color.RED
	elif match_time <= 30:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE

func _start_overtime() -> void:
	is_overtime = true
	match_time = 60.0 # 1 minute overtime
	elixir_rate = 5.6 # Double elixir in overtime
	timer_label.text = "OVERTIME"
	await get_tree().create_timer(1.0).timeout

func set_player_info(player_name_text: String, crowns: int, avatar_texture: Texture2D = null) -> void:
	player_name.text = player_name_text
	player_crowns.text = str(crowns) + " 👑"
	if avatar_texture:
		player_avatar.texture = avatar_texture

func set_enemy_info(enemy_name_text: String, crowns: int, avatar_texture: Texture2D = null) -> void:
	enemy_name.text = enemy_name_text
	enemy_crowns.text = str(crowns) + " 👑"
	if avatar_texture:
		enemy_avatar.texture = avatar_texture

func update_crown_count(is_player: bool, crowns: int) -> void:
	if is_player:
		player_crowns.text = str(crowns) + " 👑"
	else:
		enemy_crowns.text = str(crowns) + " 👑"

func set_card_hand(cards: Array) -> void:
	card_hand = cards
	for i in range(min(4, cards.size())):
		var card_slot = card_hand_container.get_child(i)
		if card_slot:
			card_slot.set_card(cards[i])

func set_next_card(card: Resource) -> void:
	next_card = card
	# Update next card preview visual
	if next_card and next_card_preview:
		# Set preview texture when card resources are implemented
		pass

func cycle_card(index: int) -> void:
	if index < 0 or index >= card_hand.size():
		return

	# Move next card to played card position
	if next_card:
		card_hand[index] = next_card
		var card_slot = card_hand_container.get_child(index)
		if card_slot:
			card_slot.set_card(next_card)

		# Request new next card from game manager
		# This will be connected to the game manager later

func use_elixir(amount: float) -> bool:
	if current_elixir >= amount:
		current_elixir -= amount
		_update_elixir_display()
		return true
	return false

func refund_elixir(amount: float) -> void:
	current_elixir = min(current_elixir + amount, max_elixir)
	_update_elixir_display()

func _on_card_dropped(card: Resource, position: Vector2, slot_index: int) -> void:
	if use_elixir(card.elixir_cost):
		card_played.emit(card, position)
		cycle_card(slot_index)
	else:
		# Show not enough elixir feedback
		_show_elixir_warning()

func _show_elixir_warning() -> void:
	elixir_label.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(elixir_label, "modulate", Color.WHITE, 0.5)

func show_emote(emote: String, is_player: bool) -> void:
	# Implement emote display
	pass

func pause_game() -> void:
	pause_requested.emit()

func resume_game() -> void:
	# Resume timer and elixir generation
	pass