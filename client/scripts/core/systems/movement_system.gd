## System that processes entity movement and pathfinding
class_name MovementSystem
extends Node

## Signal emitted when an entity starts moving
signal entity_movement_started(entity: Entity)

## Signal emitted when an entity stops moving
signal entity_movement_stopped(entity: Entity)

## Signal emitted when an entity reaches its destination
signal entity_reached_destination(entity: Entity)

## Reference to the game manager
var game_manager: GameManager = null

## Navigation agent for pathfinding (if using Godot's navigation)
var navigation_region: NavigationRegion2D = null

## Grid size for simple grid-based pathfinding
var grid_size: Vector2 = Vector2(32, 32)

## Movement statistics
var total_distance_traveled: float = 0.0
var entities_moving: int = 0


func _init() -> void:
	name = "MovementSystem"


## Initializes the movement system with a game manager reference
func initialize(manager: GameManager, nav_region: NavigationRegion2D = null) -> void:
	game_manager = manager
	navigation_region = nav_region


## Processes movement for all entities
func process_movement(entities: Array, delta: float) -> void:
	if entities.is_empty():
		return

	entities_moving = 0

	for entity in entities:
		if not _is_movement_ready(entity):
			continue

		_process_entity_movement(entity, entities, delta)

		var movement_comp: MovementComponent = entity.get_component("MovementComponent") as MovementComponent
		if movement_comp and movement_comp.is_moving:
			entities_moving += 1


## Processes movement for a single entity
func _process_entity_movement(entity: Entity, all_entities: Array, delta: float) -> void:
	var movement_comp: MovementComponent = entity.get_component("MovementComponent") as MovementComponent
	if not movement_comp or not movement_comp.enabled:
		return

	# Update movement
	movement_comp.update(delta)

	# Track distance traveled
	if movement_comp.velocity.length() > 0:
		total_distance_traveled += movement_comp.velocity.length() * delta

	# Apply collision avoidance if needed
	if movement_comp.is_moving:
		_apply_collision_avoidance(entity, movement_comp, all_entities)


## Moves an entity to a target position
func move_to_position(entity: Entity, target_position: Vector2, use_pathfinding: bool = true) -> bool:
	var movement_comp: MovementComponent = entity.get_component("MovementComponent") as MovementComponent
	if not movement_comp:
		push_error("Entity lacks MovementComponent")
		return false

	if use_pathfinding and movement_comp.use_pathfinding:
		var path: PackedVector2Array = find_path(entity.global_position, target_position)
		if path.size() > 0:
			movement_comp.set_movement_path(path)
			entity_movement_started.emit(entity)
			return true
		else:
			# Fall back to direct movement if pathfinding fails
			movement_comp.set_target_position(target_position)
			entity_movement_started.emit(entity)
			return true
	else:
		movement_comp.set_target_position(target_position)
		entity_movement_started.emit(entity)
		return true


## Moves an entity towards another entity
func move_to_entity(entity: Entity, target_entity: Entity, maintain_distance: float = 0.0) -> bool:
	if not target_entity or not target_entity.is_active:
		return false

	var target_position: Vector2 = target_entity.global_position

	# Adjust target position to maintain distance
	if maintain_distance > 0.0:
		var direction: Vector2 = (entity.global_position - target_position).normalized()
		target_position += direction * maintain_distance

	return move_to_position(entity, target_position)


## Stops an entity's movement
func stop_entity(entity: Entity) -> void:
	var movement_comp: MovementComponent = entity.get_component("MovementComponent") as MovementComponent
	if movement_comp:
		movement_comp.stop_movement()
		entity_movement_stopped.emit(entity)


## Finds a path between two positions
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	# If we have a NavigationRegion2D, use Godot's built-in pathfinding
	if navigation_region and navigation_region.is_inside_tree():
		var navigation_agent: NavigationAgent2D = NavigationAgent2D.new()
		navigation_agent.set_navigation_map(navigation_region.get_navigation_map())
		var path: PackedVector2Array = NavigationServer2D.map_get_path(
			navigation_region.get_navigation_map(),
			from,
			to,
			true  # optimize
		)
		navigation_agent.queue_free()
		return path

	# Otherwise, use simple A* pathfinding
	return _find_path_astar(from, to)


## Simple A* pathfinding implementation
func _find_path_astar(from: Vector2, to: Vector2) -> PackedVector2Array:
	var path: PackedVector2Array = PackedVector2Array()

	# For simplicity, we'll use straight-line path with obstacle avoidance
	# In a real implementation, you'd want proper A* with a grid or navmesh

	# Get obstacles from game manager
	var obstacles: Array = _get_obstacles()

	# Check if straight line is clear
	if _is_path_clear(from, to, obstacles):
		path.append(from)
		path.append(to)
		return path

	# Otherwise, find waypoints around obstacles
	path = _find_path_with_waypoints(from, to, obstacles)

	return path


## Checks if a straight path is clear of obstacles
func _is_path_clear(from: Vector2, to: Vector2, obstacles: Array) -> bool:
	# Simplified line-of-sight check
	# In a real implementation, you'd do proper collision detection

	for obstacle in obstacles:
		if not obstacle is Entity:
			continue

		var obstacle_pos: Vector2 = obstacle.global_position
		var distance_to_line: float = _point_to_line_distance(obstacle_pos, from, to)

		# Check if obstacle is too close to the path
		if distance_to_line < 50.0:  # Arbitrary clearance distance
			return false

	return true


## Calculates distance from a point to a line segment
func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec: Vector2 = line_end - line_start
	var point_vec: Vector2 = point - line_start
	var line_length: float = line_vec.length()

	if line_length == 0:
		return point_vec.length()

	var t: float = clamp(point_vec.dot(line_vec) / (line_length * line_length), 0.0, 1.0)
	var projection: Vector2 = line_start + t * line_vec

	return point.distance_to(projection)


## Finds a path using waypoints to avoid obstacles
func _find_path_with_waypoints(from: Vector2, to: Vector2, obstacles: Array) -> PackedVector2Array:
	var path: PackedVector2Array = PackedVector2Array()

	# Simple waypoint generation around obstacles
	# This is a very basic implementation - real pathfinding would be more sophisticated

	path.append(from)

	# Add intermediate waypoints if needed
	var current_pos: Vector2 = from
	var max_iterations: int = 10
	var iteration: int = 0

	while iteration < max_iterations:
		iteration += 1

		if _is_path_clear(current_pos, to, obstacles):
			path.append(to)
			break

		# Find a waypoint that gets us closer to the target
		var waypoint: Vector2 = _find_waypoint(current_pos, to, obstacles)
		if waypoint == Vector2.ZERO:
			# No valid waypoint found, use direct path
			path.append(to)
			break

		path.append(waypoint)
		current_pos = waypoint

	return path


## Finds a waypoint that avoids obstacles
func _find_waypoint(from: Vector2, to: Vector2, obstacles: Array) -> Vector2:
	# Try different angles to find a clear path
	var direction: Vector2 = (to - from).normalized()
	var distance: float = min(100.0, from.distance_to(to) * 0.5)

	for angle in [0, 30, -30, 60, -60, 90, -90]:
		var rotated_dir: Vector2 = direction.rotated(deg_to_rad(angle))
		var waypoint: Vector2 = from + rotated_dir * distance

		if _is_path_clear(from, waypoint, obstacles):
			return waypoint

	return Vector2.ZERO


## Gets obstacles from the game world
func _get_obstacles() -> Array:
	if not game_manager:
		return []

	var obstacles: Array = []
	var all_entities: Array = game_manager.get_all_entities()

	for entity in all_entities:
		# Consider static entities as obstacles
		if not entity.has_component("MovementComponent"):
			obstacles.append(entity)

	return obstacles


## Applies collision avoidance between entities
func _apply_collision_avoidance(entity: Entity, movement_comp: MovementComponent, all_entities: Array) -> void:
	if not movement_comp.is_moving:
		return

	var avoidance_force: Vector2 = Vector2.ZERO
	var neighbor_count: int = 0

	for other_entity in all_entities:
		if other_entity == entity or not other_entity.is_active:
			continue

		var distance: float = entity.global_position.distance_to(other_entity.global_position)

		# Check if within avoidance radius
		if distance < movement_comp.avoidance_radius and distance > 0:
			# Calculate repulsion force
			var diff: Vector2 = entity.global_position - other_entity.global_position
			var force_strength: float = (movement_comp.avoidance_radius - distance) / movement_comp.avoidance_radius
			avoidance_force += diff.normalized() * force_strength
			neighbor_count += 1

	# Apply avoidance force to velocity
	if neighbor_count > 0:
		avoidance_force = avoidance_force.normalized() * movement_comp.separation_weight
		movement_comp.velocity += avoidance_force * movement_comp.get_effective_speed() * 0.1


## Checks if an entity is ready for movement
func _is_movement_ready(entity: Entity) -> bool:
	if not entity or not entity.is_active:
		return false

	if not entity.has_component("MovementComponent"):
		return false

	var health_comp: HealthComponent = entity.get_component("HealthComponent") as HealthComponent
	if health_comp and health_comp.is_dead:
		return false

	return true


## Forms a group of entities to move together
func move_group_to_position(entities: Array[Entity], target_position: Vector2, formation_spacing: float = 50.0) -> void:
	if entities.is_empty():
		return

	# Calculate formation positions
	var formation_positions: Array[Vector2] = _calculate_formation_positions(
		target_position,
		entities.size(),
		formation_spacing
	)

	# Assign each entity to a formation position
	for i in range(entities.size()):
		if i < formation_positions.size():
			move_to_position(entities[i], formation_positions[i])


## Calculates formation positions for a group
func _calculate_formation_positions(center: Vector2, count: int, spacing: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []

	# Simple grid formation
	var cols: int = ceil(sqrt(count))
	var rows: int = ceil(float(count) / cols)

	var start_x: float = center.x - (cols - 1) * spacing * 0.5
	var start_y: float = center.y - (rows - 1) * spacing * 0.5

	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols

		var pos: Vector2 = Vector2(
			start_x + col * spacing,
			start_y + row * spacing
		)
		positions.append(pos)

	return positions


## Gets movement statistics
func get_statistics() -> Dictionary:
	return {
		"total_distance_traveled": total_distance_traveled,
		"entities_moving": entities_moving
	}


## Resets movement statistics
func reset_statistics() -> void:
	total_distance_traveled = 0.0
	entities_moving = 0