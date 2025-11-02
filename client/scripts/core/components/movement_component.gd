## Component that manages an entity's movement properties and behaviors
class_name MovementComponent
extends Component

## Signal emitted when movement starts
signal movement_started()

## Signal emitted when movement stops
signal movement_stopped()

## Signal emitted when target position is reached
signal target_reached()

## Signal emitted when the path is updated
signal path_updated(new_path: PackedVector2Array)

## Movement speed in units per second
@export var speed: float = 100.0

## Current velocity vector
var velocity: Vector2 = Vector2.ZERO

## Target position to move towards
var target_position: Vector2 = Vector2.ZERO

## Current path to follow
var path: PackedVector2Array = PackedVector2Array()

## Current index in the path
var path_index: int = 0

## Whether the entity is currently moving
var is_moving: bool = false

## Distance threshold to consider a point reached
@export var arrival_threshold: float = 5.0

## Whether to rotate the entity to face movement direction
@export var rotate_to_direction: bool = true

## Maximum rotation speed in radians per second
@export var rotation_speed: float = 10.0

## Movement modifiers (for buffs/debuffs)
var speed_multiplier: float = 1.0

## Whether the entity can move
var can_move: bool = true

## Whether to use pathfinding or direct movement
@export var use_pathfinding: bool = true

## Steering behaviors weight
@export var separation_weight: float = 1.5
@export var avoidance_radius: float = 30.0


## Returns the component class name for identification
func get_component_class() -> String:
	return "MovementComponent"


## Called when the component is attached to an entity
func on_attached() -> void:
	velocity = Vector2.ZERO
	is_moving = false
	can_move = true


## Updates the movement component
func update(delta: float) -> void:
	if not enabled or not is_valid() or not can_move:
		if is_moving:
			stop_movement()
		return

	if use_pathfinding and path.size() > 0:
		_follow_path(delta)
	elif target_position != Vector2.ZERO:
		_move_to_target(delta)
	else:
		_apply_velocity(delta)


## Sets a target position to move towards
func set_target_position(position: Vector2) -> void:
	target_position = position
	path.clear()
	path_index = 0

	if not is_moving and can_move:
		is_moving = true
		movement_started.emit()


## Sets a path to follow
func set_movement_path(new_path: PackedVector2Array) -> void:
	path = new_path
	path_index = 0

	if path.size() > 0:
		target_position = path[-1]
		if not is_moving and can_move:
			is_moving = true
			movement_started.emit()

		path_updated.emit(path)
	else:
		stop_movement()


## Stops all movement
func stop_movement() -> void:
	velocity = Vector2.ZERO
	target_position = Vector2.ZERO
	path.clear()
	path_index = 0

	if is_moving:
		is_moving = false
		movement_stopped.emit()


## Gets the current movement speed with modifiers applied
func get_effective_speed() -> float:
	return speed * speed_multiplier


## Applies a speed modifier
func apply_speed_modifier(modifier: float, duration: float = -1.0) -> void:
	speed_multiplier = max(0.0, modifier)

	if duration > 0.0 and entity and entity.is_inside_tree():
		await entity.get_tree().create_timer(duration).timeout
		speed_multiplier = 1.0


## Follows the current path
func _follow_path(delta: float) -> void:
	if path_index >= path.size():
		_on_target_reached()
		return

	var current_target: Vector2 = path[path_index]
	var distance: float = entity.global_position.distance_to(current_target)

	if distance <= arrival_threshold:
		path_index += 1
		if path_index >= path.size():
			_on_target_reached()
		return

	_move_towards_position(current_target, delta)


## Moves directly to the target position
func _move_to_target(delta: float) -> void:
	var distance: float = entity.global_position.distance_to(target_position)

	if distance <= arrival_threshold:
		_on_target_reached()
		return

	_move_towards_position(target_position, delta)


## Moves towards a specific position
func _move_towards_position(position: Vector2, delta: float) -> void:
	var direction: Vector2 = (position - entity.global_position).normalized()

	# Apply steering behaviors
	direction = _apply_steering_behaviors(direction)

	velocity = direction * get_effective_speed()
	_apply_velocity(delta)

	# Rotate to face direction if enabled
	if rotate_to_direction and velocity.length() > 0:
		_rotate_to_direction(velocity.normalized(), delta)


## Applies velocity to the entity's position
func _apply_velocity(delta: float) -> void:
	if velocity.length() < 0.1:
		return

	entity.global_position += velocity * delta


## Rotates the entity to face a direction
func _rotate_to_direction(direction: Vector2, delta: float) -> void:
	if not entity:
		return

	var target_angle: float = direction.angle()
	var current_angle: float = entity.rotation

	# Calculate shortest rotation direction
	var angle_diff: float = wrapf(target_angle - current_angle, -PI, PI)

	# Apply rotation with speed limit
	var rotation_step: float = sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)
	entity.rotation += rotation_step


## Applies steering behaviors for smoother movement
func _apply_steering_behaviors(direction: Vector2) -> Vector2:
	var final_direction: Vector2 = direction

	# Add separation from nearby entities
	# This would be implemented when GameManager is available to get nearby entities

	return final_direction.normalized()


## Called when the target position is reached
func _on_target_reached() -> void:
	stop_movement()
	target_reached.emit()


## Gets the distance to the current target
func get_distance_to_target() -> float:
	if target_position == Vector2.ZERO:
		return 0.0

	return entity.global_position.distance_to(target_position)


## Gets the estimated time to reach the target
func get_time_to_target() -> float:
	var distance: float = get_distance_to_target()
	var effective_speed: float = get_effective_speed()

	if effective_speed <= 0.0:
		return INF

	return distance / effective_speed


## Checks if the entity has a valid path
func has_valid_path() -> bool:
	return path.size() > 0 and path_index < path.size()


## Enables or disables movement
func set_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		stop_movement()


## Resets the component to its default state
func reset() -> void:
	velocity = Vector2.ZERO
	target_position = Vector2.ZERO
	path.clear()
	path_index = 0
	is_moving = false
	speed_multiplier = 1.0
	can_move = true


## Returns a dictionary representation of the component's data
func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["speed"] = speed
	data["arrival_threshold"] = arrival_threshold
	data["rotate_to_direction"] = rotate_to_direction
	data["rotation_speed"] = rotation_speed
	data["use_pathfinding"] = use_pathfinding
	data["separation_weight"] = separation_weight
	data["avoidance_radius"] = avoidance_radius
	return data


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("speed"):
		speed = data["speed"]
	if data.has("arrival_threshold"):
		arrival_threshold = data["arrival_threshold"]
	if data.has("rotate_to_direction"):
		rotate_to_direction = data["rotate_to_direction"]
	if data.has("rotation_speed"):
		rotation_speed = data["rotation_speed"]
	if data.has("use_pathfinding"):
		use_pathfinding = data["use_pathfinding"]
	if data.has("separation_weight"):
		separation_weight = data["separation_weight"]
	if data.has("avoidance_radius"):
		avoidance_radius = data["avoidance_radius"]