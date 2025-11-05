extends Node
class_name UnitNavigation

## Navigation helper for units to find paths on the battlefield
## Handles pathfinding around obstacles (river) and through bridges

signal path_calculated(path: PackedVector2Array)

## Reference to the NavigationAgent2D
var agent: NavigationAgent2D

## Current target position
var current_target: Vector2 = Vector2.ZERO

## Whether navigation is active
var is_navigating: bool = false


func _ready() -> void:
	# Create navigation agent
	agent = NavigationAgent2D.new()
	add_child(agent)

	# Configure agent properties
	agent.path_desired_distance = 10.0
	agent.target_desired_distance = 10.0
	agent.radius = 20.0
	agent.neighbor_distance = 50.0
	agent.max_neighbors = 10
	agent.time_horizon = 0.5
	agent.max_speed = 200.0
	agent.avoidance_enabled = true

	# Connect signals
	agent.velocity_computed.connect(_on_velocity_computed)
	agent.navigation_finished.connect(_on_navigation_finished)


## Sets a new navigation target
func set_target(target_pos: Vector2) -> void:
	current_target = target_pos

	# Wait for navigation map to be ready
	if not agent.is_navigation_finished():
		await get_tree().process_frame

	agent.target_position = target_pos
	is_navigating = true


## Gets the next position to move towards
func get_next_position() -> Vector2:
	if not is_navigating or agent.is_navigation_finished():
		return Vector2.ZERO

	return agent.get_next_path_position()


## Gets the remaining distance to target
func get_distance_to_target() -> float:
	if not is_navigating:
		return 0.0

	return agent.distance_to_target()


## Checks if navigation has reached the target
func is_target_reached() -> bool:
	return agent.is_navigation_finished()


## Gets the current velocity for avoidance
func get_safe_velocity(desired_velocity: Vector2) -> Vector2:
	if not agent.avoidance_enabled:
		return desired_velocity

	agent.set_velocity(desired_velocity)
	return desired_velocity


## Stops navigation
func stop() -> void:
	is_navigating = false
	current_target = Vector2.ZERO


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	# This signal is emitted when avoidance velocity is computed
	pass


func _on_navigation_finished() -> void:
	is_navigating = false
	current_target = Vector2.ZERO


## Draws debug path (for development)
func draw_debug_path(parent: Node2D) -> void:
	if not agent or agent.is_navigation_finished():
		return

	var path = agent.get_current_navigation_path()
	if path.size() < 2:
		return

	# Draw line through path points
	for i in range(path.size() - 1):
		parent.draw_line(path[i], path[i + 1], Color.GREEN, 2.0)
