## Unified input handling system for all game controls
## Handles mouse, touch, keyboard input and deployment validation
## Add to Project Settings -> Autoload as "InputManager"
extends Node

## Signals for input events
signal card_deployment_started(card_id: int, position: Vector2)
signal card_deployment_moved(position: Vector2)
signal card_deployment_confirmed(card_id: int, position: Vector2)
signal card_deployment_cancelled()
signal card_selected(card_index: int)
signal pause_requested()
signal cancel_requested()

## Input state
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var current_drag_position: Vector2 = Vector2.ZERO
var selected_card_id: int = -1
var deployment_valid: bool = false

## Touch/mouse settings
var drag_threshold: float = 10.0  # Minimum pixels to start drag
var double_tap_time: float = 0.3  # Seconds
var last_tap_time: float = 0.0
var last_tap_position: Vector2 = Vector2.ZERO

## Deployment constraints
var deployment_area: Rect2 = Rect2()
var min_deployment_y: float = 0.0
var max_deployment_y: float = 540.0  # Half screen for player side

## Keyboard shortcuts
var shortcuts_enabled: bool = true
var card_hotkeys: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4]

## Input mode
enum InputMode {
	MOUSE,
	TOUCH,
	CONTROLLER
}
var current_input_mode: InputMode = InputMode.MOUSE


func _ready() -> void:
	set_process_input(true)
	_detect_input_mode()
	print("InputManager initialized")


## Main input handling
func _input(event: InputEvent) -> void:
	# Update input mode based on event type
	if event is InputEventMouse:
		current_input_mode = InputMode.MOUSE
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		current_input_mode = InputMode.TOUCH
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		current_input_mode = InputMode.CONTROLLER

	# Handle keyboard shortcuts
	if shortcuts_enabled:
		_handle_keyboard_input(event)

	# Handle mouse/touch input
	_handle_pointer_input(event)


## Handles keyboard shortcuts
func _handle_keyboard_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Card selection hotkeys (1-4)
	for i in range(card_hotkeys.size()):
		if key_event.keycode == card_hotkeys[i]:
			select_card(i)
			get_viewport().set_input_as_handled()
			return

	# Pause/menu
	if key_event.keycode == KEY_ESCAPE:
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return

	# Cancel deployment
	if key_event.keycode == KEY_Q or key_event.keycode == KEY_X:
		if is_dragging:
			cancel_deployment()
			get_viewport().set_input_as_handled()


## Handles mouse and touch input
func _handle_pointer_input(event: InputEvent) -> void:
	# Mouse button press
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_on_pointer_down(mouse_event.position)
			else:
				_on_pointer_up(mouse_event.position)

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if is_dragging:
				cancel_deployment()

	# Mouse motion
	elif event is InputEventMouseMotion:
		if is_dragging:
			_on_pointer_move(event.position)

	# Touch screen
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch

		if touch_event.pressed:
			_on_pointer_down(touch_event.position)
		else:
			_on_pointer_up(touch_event.position)

	# Touch drag
	elif event is InputEventScreenDrag:
		if is_dragging:
			_on_pointer_move(event.position)


## Called when pointer/touch begins
func _on_pointer_down(position: Vector2) -> void:
	drag_start_position = position
	current_drag_position = position

	# Check for double tap
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_tap_time < double_tap_time:
		if position.distance_to(last_tap_position) < drag_threshold:
			_on_double_tap(position)
			return

	last_tap_time = current_time
	last_tap_position = position


## Called when pointer/touch moves
func _on_pointer_move(position: Vector2) -> void:
	current_drag_position = position

	# Start drag if threshold exceeded
	if not is_dragging:
		var distance: float = position.distance_to(drag_start_position)
		if distance > drag_threshold and selected_card_id >= 0:
			_start_deployment(selected_card_id, drag_start_position)

	if is_dragging:
		# Validate deployment position
		deployment_valid = is_valid_deployment_position(position)
		card_deployment_moved.emit(position)


## Called when pointer/touch ends
func _on_pointer_up(position: Vector2) -> void:
	if is_dragging:
		if deployment_valid:
			confirm_deployment(position)
		else:
			cancel_deployment()

	is_dragging = false


## Called on double tap
func _on_double_tap(position: Vector2) -> void:
	# Quick deploy at position if card selected
	if selected_card_id >= 0 and is_valid_deployment_position(position):
		_start_deployment(selected_card_id, position)
		confirm_deployment(position)


## Starts card deployment
func _start_deployment(card_id: int, position: Vector2) -> void:
	is_dragging = true
	selected_card_id = card_id
	deployment_valid = is_valid_deployment_position(position)
	card_deployment_started.emit(card_id, position)
	print("Card deployment started: ", card_id)


## Confirms card deployment
func confirm_deployment(position: Vector2) -> void:
	if not is_dragging or selected_card_id < 0:
		return

	if is_valid_deployment_position(position):
		card_deployment_confirmed.emit(selected_card_id, position)
		print("Card deployed at: ", position)
	else:
		cancel_deployment()

	is_dragging = false
	selected_card_id = -1


## Cancels card deployment
func cancel_deployment() -> void:
	if not is_dragging:
		return

	card_deployment_cancelled.emit()
	is_dragging = false
	selected_card_id = -1
	deployment_valid = false
	print("Card deployment cancelled")


## Selects a card by index
func select_card(card_index: int) -> void:
	selected_card_id = card_index
	card_selected.emit(card_index)
	print("Card selected: ", card_index)


## Checks if position is valid for deployment
func is_valid_deployment_position(position: Vector2) -> bool:
	# Check if within deployment area
	if deployment_area.size != Vector2.ZERO:
		if not deployment_area.has_point(position):
			return false

	# Check Y bounds (player's side only)
	if position.y < min_deployment_y or position.y > max_deployment_y:
		return false

	return true


## Sets the deployment area constraints
func set_deployment_area(area: Rect2) -> void:
	deployment_area = area
	print("Deployment area set: ", area)


## Sets Y-axis deployment constraints
func set_deployment_y_bounds(min_y: float, max_y: float) -> void:
	min_deployment_y = min_y
	max_deployment_y = max_y
	print("Deployment Y bounds set: ", min_y, " to ", max_y)


## Enables/disables keyboard shortcuts
func set_shortcuts_enabled(enabled: bool) -> void:
	shortcuts_enabled = enabled


## Gets current input mode
func get_input_mode() -> InputMode:
	return current_input_mode


## Detects initial input mode
func _detect_input_mode() -> void:
	# Check if touch screen available
	if DisplayServer.is_touchscreen_available():
		current_input_mode = InputMode.TOUCH
	else:
		current_input_mode = InputMode.MOUSE


## Checks if currently deploying
func is_deploying() -> bool:
	return is_dragging


## Gets current drag position
func get_drag_position() -> Vector2:
	return current_drag_position


## Gets selected card ID
func get_selected_card() -> int:
	return selected_card_id


## Resets input state
func reset() -> void:
	is_dragging = false
	selected_card_id = -1
	deployment_valid = false
	drag_start_position = Vector2.ZERO
	current_drag_position = Vector2.ZERO
	last_tap_time = 0.0
	last_tap_position = Vector2.ZERO
	print("InputManager reset")


## Vibrate feedback for touch devices (if supported)
func vibrate_feedback(duration_ms: int = 50) -> void:
	if current_input_mode == InputMode.TOUCH:
		if Engine.has_singleton("Android"):
			var android = Engine.get_singleton("Android")
			if android.has_method("vibrate"):
				android.vibrate(duration_ms)
		elif Engine.has_singleton("iOS"):
			var ios = Engine.get_singleton("iOS")
			if ios.has_method("vibrate"):
				ios.vibrate()


## Force feedback for controllers
func controller_rumble(weak_magnitude: float = 0.5, strong_magnitude: float = 0.5, duration: float = 0.2) -> void:
	if current_input_mode == InputMode.CONTROLLER:
		Input.start_joy_vibration(0, weak_magnitude, strong_magnitude, duration)
