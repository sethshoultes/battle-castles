extends Control

class_name CardUI

# Card properties
@export var card_data: Resource = null
@export var is_draggable: bool = true
@export var slot_index: int = -1

# Visual elements
@onready var card_background: Panel = $CardBackground
@onready var card_icon: TextureRect = $CardBackground/CardIcon
@onready var elixir_badge: Panel = $CardBackground/ElixirBadge
@onready var elixir_cost_label: Label = $CardBackground/ElixirBadge/CostLabel
@onready var unit_preview: Control = $UnitPreview
@onready var range_indicator: Control = $RangeIndicator

# Drag and drop state
var is_dragging: bool = false
var drag_start_position: Vector2
var can_play: bool = true
var is_playable: bool = true
var is_hovering: bool = false
var drag_offset: Vector2

# Visual states
var default_scale: Vector2 = Vector2.ONE
var hover_scale: Vector2 = Vector2(1.1, 1.1)
var drag_scale: Vector2 = Vector2(1.2, 1.2)

# Deployment validation
var valid_deployment_area: Rect2
var battlefield_node: Node2D = null

# Signals
signal card_dropped(card: Resource, position: Vector2, slot_index: int)
signal card_selected(card: Resource)
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

	# Create unit preview (initially hidden)
	if unit_preview:
		unit_preview.visible = false
		unit_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create range indicator (initially hidden)
	if range_indicator:
		range_indicator.visible = false
		range_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _connect_signals() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_card(new_card_data: Resource) -> void:
	card_data = new_card_data
	_update_card_visual()

func _update_card_visual() -> void:
	if not card_data:
		visible = false
		return

	visible = true

	# Update elixir cost
	if elixir_cost_label:
		elixir_cost_label.text = str(card_data.elixir_cost)

	# Update card icon (placeholder for now)
	if card_icon and card_data.has("icon_texture"):
		card_icon.texture = card_data.icon_texture

	# Update card background color based on rarity
	if card_background and card_data.has("rarity"):
		card_background.modulate = _get_rarity_color(card_data.rarity)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
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

func _on_gui_input(event: InputEvent) -> void:
	if not is_draggable or not is_playable or not card_data:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.global_position)
		else:
			_end_drag(event.global_position)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_dragging:
		_update_drag(event.global_position)

func _start_drag(mouse_pos: Vector2) -> void:
	if not can_play:
		return

	is_dragging = true
	drag_start_position = global_position
	drag_offset = global_position - mouse_pos

	# Visual feedback
	scale = drag_scale
	z_index = 100

	# Show unit preview and range
	_show_unit_preview()
	_show_range_indicator()

	# Emit signal
	card_selected.emit(card_data)

	# Make sure we capture mouse
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func _update_drag(mouse_pos: Vector2) -> void:
	if not is_dragging:
		return

	global_position = mouse_pos + drag_offset

	# Update unit preview position
	if unit_preview:
		unit_preview.global_position = _get_battlefield_position(mouse_pos)

	# Update range indicator
	if range_indicator:
		range_indicator.global_position = _get_battlefield_position(mouse_pos)

	# Validate deployment position
	_validate_deployment_position(mouse_pos)

func _end_drag(mouse_pos: Vector2) -> void:
	if not is_dragging:
		return

	is_dragging = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# Hide previews
	_hide_unit_preview()
	_hide_range_indicator()

	# Check if drop is valid
	var battlefield_pos = _get_battlefield_position(mouse_pos)
	if _is_valid_deployment_position(battlefield_pos):
		# Successful deployment
		card_dropped.emit(card_data, battlefield_pos, slot_index)
		scale = default_scale
		z_index = 0
	else:
		# Return to original position
		_animate_return_to_position()

func _animate_return_to_position() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", drag_start_position, 0.3)
	tween.parallel().tween_property(self, "scale", default_scale, 0.3)
	tween.finished.connect(func(): z_index = 0)

func _get_battlefield_position(mouse_pos: Vector2) -> Vector2:
	# Convert screen position to battlefield position
	if battlefield_node:
		return battlefield_node.to_local(mouse_pos)
	return mouse_pos

func _is_valid_deployment_position(pos: Vector2) -> bool:
	# Check if position is within valid deployment area
	if not card_data:
		return false

	# Check if within player's side of the battlefield
	if valid_deployment_area.has_point(pos):
		# Additional checks based on card type
		if card_data.has("type"):
			match card_data.type:
				"building":
					return _is_valid_building_position(pos)
				"spell":
					return _is_valid_spell_target(pos)
				_:
					return true
	return false

func _is_valid_building_position(pos: Vector2) -> bool:
	# Check if building can be placed at this position
	# Check for overlaps with other buildings
	return true # Placeholder

func _is_valid_spell_target(pos: Vector2) -> bool:
	# Check if spell can target this position
	return true # Placeholder

func _validate_deployment_position(mouse_pos: Vector2) -> void:
	var battlefield_pos = _get_battlefield_position(mouse_pos)
	var is_valid = _is_valid_deployment_position(battlefield_pos)

	# Visual feedback for valid/invalid position
	if unit_preview:
		if is_valid:
			unit_preview.modulate = Color(0, 1, 0, 0.5)
		else:
			unit_preview.modulate = Color(1, 0, 0, 0.5)

func _show_unit_preview() -> void:
	if unit_preview and card_data:
		unit_preview.visible = true
		# Set up preview based on card type

func _hide_unit_preview() -> void:
	if unit_preview:
		unit_preview.visible = false

func _show_range_indicator() -> void:
	if range_indicator and card_data and card_data.has("range"):
		range_indicator.visible = true
		# Set range size based on card data

func _hide_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = false

func _on_mouse_entered() -> void:
	if not is_dragging and is_playable:
		is_hovering = true
		scale = hover_scale
		card_hover_started.emit(card_data)

func _on_mouse_exited() -> void:
	if not is_dragging:
		is_hovering = false
		scale = default_scale
		card_hover_ended.emit(card_data)

func set_battlefield_reference(battlefield: Node2D) -> void:
	battlefield_node = battlefield

func set_valid_deployment_area(area: Rect2) -> void:
	valid_deployment_area = area