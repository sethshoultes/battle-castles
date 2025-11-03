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
var elixir_rate: float = 1.0 / 2.8  # Clash Royale: 1 elixir per 2.8 seconds = 0.357 elixir/second
var card_hand: Array = []
var full_deck: Array = []  # Complete deck for cycling
var deck_index: int = 4  # Start after initial 4 cards
var next_card: Resource = null
var match_time: float = 180.0 # 3 minutes
var is_overtime: bool = false
var is_double_elixir: bool = false

# Double elixir visual indicator
var double_elixir_label: Label = null
var elixir_bar_normal_color: Color = Color(0.6, 0.2, 0.8)  # Purple
var elixir_bar_double_color: Color = Color(1.0, 0.3, 0.4)  # Bright pink/red
var pulse_tween: Tween = null

# Card selection state
var selected_card: Resource = null
var selected_slot_index: int = -1

# Signals
signal card_selected(card: Resource, slot_index: int)
signal card_deselected()
signal card_played(card: Resource, position: Vector2)
signal pause_requested()

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_load_initial_cards()
	_create_double_elixir_label()

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
		card_slot.slot_index = i  # Set the slot index
		card_hand_container.add_child(card_slot)
		card_slot.card_clicked.connect(_on_card_clicked)

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

		# Start double elixir at last minute (Clash Royale style)
		if match_time <= 60.0 and not is_double_elixir:
			_start_double_elixir()

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

func _start_double_elixir() -> void:
	is_double_elixir = true
	elixir_rate = 1.0 / 1.4  # Clash Royale double elixir: 1 per 1.4s = 0.714 elixir/second
	print("DOUBLE ELIXIR STARTED!")

	# Visual indicators
	_animate_double_elixir_visual()

func _start_overtime() -> void:
	is_overtime = true
	match_time = 60.0 # 1 minute overtime
	# Keep double elixir rate (already activated in last minute)
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
	if next_card and next_card_preview and next_card is CardData:
		next_card_preview.texture = next_card.icon

func cycle_card(index: int) -> void:
	if index < 0 or index >= 4:
		return

	print("Cycling card at slot ", index)

	if full_deck.is_empty():
		print("No deck available for cycling")
		return

	# Get next card from deck (cycles through the deck)
	var new_card: CardData = full_deck[deck_index % full_deck.size()]

	# Update card hand
	if index < card_hand.size():
		card_hand[index] = new_card

	# Update visual card slot
	var card_slot = card_hand_container.get_child(index)
	if card_slot:
		card_slot.set_card(new_card)
		print("  New card: ", new_card.card_name)

	# Move to next card in deck
	deck_index += 1

	# Update next card preview
	set_next_card(full_deck[deck_index % full_deck.size()])

func use_elixir(amount: float) -> bool:
	if current_elixir >= amount:
		current_elixir -= amount
		_update_elixir_display()
		return true
	return false

func refund_elixir(amount: float) -> void:
	current_elixir = min(current_elixir + amount, max_elixir)
	_update_elixir_display()

func _on_card_clicked(card: Resource, slot_index: int) -> void:
	print("Card clicked at slot ", slot_index, " - Card: ", card.card_name if card else "null")

	if not card:
		return

	# Check if we have enough elixir
	if current_elixir < card.elixir_cost:
		print("  Not enough elixir!")
		_show_elixir_warning()
		return

	# Deselect previous card if different
	if selected_card and selected_slot_index != slot_index:
		var prev_slot = card_hand_container.get_child(selected_slot_index)
		if prev_slot:
			prev_slot.set_selected(false)

	# Toggle selection
	if selected_slot_index == slot_index:
		# Clicking same card deselects it
		selected_card = null
		selected_slot_index = -1
		card_deselected.emit()
		print("  Card deselected")
	else:
		# Select new card
		selected_card = card
		selected_slot_index = slot_index
		card_selected.emit(card, slot_index)
		print("  Card selected - waiting for battlefield click")

func play_selected_card(position: Vector2) -> void:
	if not selected_card or selected_slot_index < 0:
		return

	if use_elixir(selected_card.elixir_cost):
		print("  Elixir spent: ", selected_card.elixir_cost)

		# Emit signal to notify battlefield to spawn unit
		card_played.emit(selected_card, position)

		# Deselect and cycle card
		var card_slot = card_hand_container.get_child(selected_slot_index)
		if card_slot:
			card_slot.set_selected(false)

		await get_tree().create_timer(0.1).timeout
		cycle_card(selected_slot_index)

		selected_card = null
		selected_slot_index = -1
		card_deselected.emit()

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

func _create_double_elixir_label() -> void:
	# Create label
	double_elixir_label = Label.new()
	double_elixir_label.text = "2X ELIXIR"
	double_elixir_label.add_theme_font_size_override("font_size", 28)
	double_elixir_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Gold
	double_elixir_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	double_elixir_label.add_theme_constant_override("outline_size", 3)

	# Center text alignment
	double_elixir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Start hidden
	double_elixir_label.modulate.a = 0.0
	double_elixir_label.scale = Vector2(0.5, 0.5)

	add_child(double_elixir_label)

	# Position will be set after elixir_bar is ready
	if elixir_bar:
		# Position above elixir bar
		double_elixir_label.global_position = Vector2(
			elixir_bar.global_position.x + elixir_bar.size.x / 2 - 60,
			elixir_bar.global_position.y - 40
		)

func _animate_double_elixir_visual() -> void:
	# Change elixir bar color
	if elixir_bar:
		var color_tween = create_tween()
		color_tween.tween_property(elixir_bar, "modulate", elixir_bar_double_color, 0.5)

		# Add pulsing glow effect
		_add_pulsing_effect()

	# Animate label entrance
	if double_elixir_label:
		var label_tween = create_tween()
		label_tween.set_parallel(true)
		label_tween.tween_property(double_elixir_label, "modulate:a", 1.0, 0.3)
		label_tween.tween_property(double_elixir_label, "scale", Vector2.ONE, 0.3)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _add_pulsing_effect() -> void:
	# Stop existing pulse if any
	if pulse_tween:
		pulse_tween.kill()

	# Create repeating pulse animation
	pulse_tween = create_tween()
	pulse_tween.set_loops()  # Infinite loop
	pulse_tween.tween_property(elixir_bar, "modulate:a", 0.7, 0.5)
	pulse_tween.tween_property(elixir_bar, "modulate:a", 1.0, 0.5)

func _load_initial_cards() -> void:
	# Try to load saved deck first
	full_deck = _load_deck_from_file()

	# If no saved deck or invalid, use default cards
	if full_deck.is_empty():
		print("No saved deck found, using default cards")
		var knight: CardData = load("res://resources/cards/knight.tres")
		var goblin: CardData = load("res://resources/cards/goblin.tres")
		var archer: CardData = load("res://resources/cards/archer.tres")
		var giant: CardData = load("res://resources/cards/giant.tres")
		full_deck = [knight, goblin, archer, giant, knight, goblin, archer, giant]

	# Shuffle the deck
	full_deck.shuffle()

	# Take first 4 cards as starting hand
	var starting_hand: Array = []
	for i in range(min(4, full_deck.size())):
		starting_hand.append(full_deck[i])

	# Store starting hand
	card_hand = starting_hand.duplicate()
	deck_index = 4  # Next card to cycle from deck

	# Set the card hand
	set_card_hand(starting_hand)

	# Set up next card (next card from deck)
	if full_deck.size() > 4:
		set_next_card(full_deck[4])
	else:
		set_next_card(full_deck[0])

	print("Cards loaded - Using ", full_deck.size(), " card deck")

func _load_deck_from_file() -> Array:
	if not FileAccess.file_exists("user://current_deck.json"):
		return []

	var file = FileAccess.open("user://current_deck.json", FileAccess.READ)
	if not file:
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error parsing saved deck")
		return []

	var deck_data = json.data
	var deck: Array = []

	for card_info in deck_data:
		var card_resource = load(card_info.resource_path)
		if card_resource:
			deck.append(card_resource)

	print("Loaded ", deck.size(), " cards from saved deck")
	return deck
