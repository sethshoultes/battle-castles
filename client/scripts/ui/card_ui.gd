extends Control

class_name CardUI

# Card properties
@export var card_data: Resource = null
@export var slot_index: int = -1

# Visual elements
@onready var card_background: Panel = $CardBackground
@onready var card_icon: TextureRect = $CardBackground/CardIcon
@onready var elixir_badge: Panel = $CardBackground/ElixirBadge
@onready var elixir_cost_label: Label = $CardBackground/ElixirBadge/CostLabel

# Selection state
var is_selected: bool = false
var can_play: bool = true
var is_playable: bool = true
var is_hovering: bool = false

# Visual states
var default_scale: Vector2 = Vector2.ONE
var hover_scale: Vector2 = Vector2(1.1, 1.1)
var selected_scale: Vector2 = Vector2(1.15, 1.15)

# Signals
signal card_clicked(card: Resource, slot_index: int)
signal card_hover_started(card: Resource)
signal card_hover_ended(card: Resource)

func _ready() -> void:
	_setup_card()
	_connect_signals()
	mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_card() -> void:
	if card_data:
		_update_card_visual()

	# Set up initial visual state
	modulate = Color.WHITE
	scale = default_scale

	# Make ALL child nodes ignore mouse input so parent Control handles it
	_set_all_children_mouse_filter_ignore(self)

func _set_all_children_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue  # Don't modify self
		if child.has_method("set"):
			if "mouse_filter" in child:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_all_children_mouse_filter_ignore(child)  # Recursive

func _connect_signals() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_card(new_card_data: Resource) -> void:
	card_data = new_card_data
	print("CardUI: Setting card data: ", card_data)
	if card_data and card_data is CardData:
		print("  - Card name: ", card_data.card_name)
		print("  - Elixir cost: ", card_data.elixir_cost)
	_update_card_visual()

func _update_card_visual() -> void:
	if not card_data:
		visible = false
		return

	visible = true

	# Update elixir cost
	if elixir_cost_label and card_data is CardData:
		elixir_cost_label.text = str(card_data.elixir_cost)

	# Add card name label if it doesn't exist
	if card_background and card_data is CardData:
		var name_label = card_background.get_node_or_null("CardNameLabel")
		if not name_label:
			name_label = Label.new()
			name_label.name = "CardNameLabel"
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 10)
			name_label.add_theme_color_override("font_color", Color.WHITE)
			name_label.add_theme_color_override("font_outline_color", Color.BLACK)
			name_label.add_theme_constant_override("outline_size", 1)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_label.anchor_left = 0.0
			name_label.anchor_top = 0.75
			name_label.anchor_right = 1.0
			name_label.anchor_bottom = 1.0
			card_background.add_child(name_label)

		name_label.text = card_data.card_name

	# Update card icon
	if card_icon and card_data is CardData and card_data.icon:
		card_icon.texture = card_data.icon

	# Update card background color based on rarity
	if card_background and card_data is CardData:
		card_background.modulate = _get_rarity_color(card_data.rarity)

func _get_rarity_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common":
			return Color(0.7, 0.7, 0.7, 1.0)
		"rare":
			return Color(1.0, 0.6, 0.2, 1.0)
		"epic":
			return Color(0.7, 0.3, 0.9, 1.0)
		"legendary":
			return Color(1.0, 0.9, 0.3, 1.0)
		_:
			return Color.WHITE

func set_playable(playable: bool) -> void:
	is_playable = playable
	if not is_playable:
		modulate = Color(0.5, 0.5, 0.5, 0.8)
	else:
		modulate = Color.WHITE

func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		scale = selected_scale
		z_index = 10
		# Visual highlight
		modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight yellow tint
	else:
		scale = default_scale if not is_hovering else hover_scale
		z_index = 0
		modulate = Color.WHITE if is_playable else Color(0.5, 0.5, 0.5, 0.8)

func _on_gui_input(event: InputEvent) -> void:
	if not is_playable:
		return
	if not card_data:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_card_clicked()
		accept_event()  # Consume the event to prevent drag

func _on_card_clicked() -> void:
	print("CardUI: Card clicked - ", card_data.card_name if card_data else "null")

	if not can_play:
		print("  - Cannot play card")
		return

	# Toggle selection
	set_selected(!is_selected)

	# Emit signal to notify BattleUI
	card_clicked.emit(card_data, slot_index)

func _on_mouse_entered() -> void:
	if not is_selected and is_playable:
		is_hovering = true
		scale = hover_scale
		card_hover_started.emit(card_data)

func _on_mouse_exited() -> void:
	if not is_selected:
		is_hovering = false
		scale = default_scale
		card_hover_ended.emit(card_data)