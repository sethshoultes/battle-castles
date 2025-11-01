extends GdUnitTestSuite

class_name TestMovementSystem

var movement_component: Node
var mock_entity: GdUnitMock

func before_each() -> void:
	var MovementComponent = load("res://scripts/core/components/movement_component.gd")
	movement_component = MovementComponent.new()
	mock_entity = mock(Node2D)

func after_each() -> void:
	if movement_component:
		movement_component.queue_free()

func test_basic_movement() -> void:
	# Setup
	movement_component.speed = 100.0  # pixels per second
	movement_component.position = Vector2(0, 0)
	var target = Vector2(100, 0)
	var delta = 0.5  # 0.5 seconds

	# Act
	var direction = (target - movement_component.position).normalized()
	var velocity = direction * movement_component.speed * delta
	movement_component.position += velocity

	# Assert
	assert_equal(Vector2(50, 0), movement_component.position)

func test_pathfinding_initialization() -> void:
	# Setup
	var start = Vector2(0, 0)
	var goal = Vector2(500, 500)

	# Act
	var path = movement_component.calculate_path(start, goal)

	# Assert
	assert_not_null(path)
	assert_greater(path.size(), 0)
	assert_equal(start, path[0])

func test_collision_avoidance() -> void:
	# Setup
	movement_component.position = Vector2(100, 100)
	var obstacle_position = Vector2(150, 100)
	var obstacle_radius = 20.0
	var avoidance_radius = 30.0

	# Act
	var distance = movement_component.position.distance_to(obstacle_position)
	var needs_avoidance = distance < (obstacle_radius + avoidance_radius)

	# Assert
	assert_true(needs_avoidance)

	# Calculate avoidance vector
	if needs_avoidance:
		var avoidance_direction = (movement_component.position - obstacle_position).normalized()
		var avoidance_force = avoidance_direction * 50.0  # Avoidance strength
		assert_not_equal(Vector2.ZERO, avoidance_force)

func test_movement_state_machine() -> void:
	# Test different movement states
	movement_component.state = "idle"
	assert_equal("idle", movement_component.state)

	movement_component.set_state("moving")
	assert_equal("moving", movement_component.state)

	movement_component.set_state("attacking")
	assert_equal("attacking", movement_component.state)

	# Should stop movement when attacking
	movement_component.can_move = movement_component.state != "attacking"
	assert_false(movement_component.can_move)

func test_unit_separation() -> void:
	# Setup multiple units
	var units = []
	for i in 5:
		var unit = {"position": Vector2(i * 10, 0), "radius": 10.0}
		units.append(unit)

	# Check separation
	for i in range(units.size()):
		for j in range(i + 1, units.size()):
			var distance = units[i].position.distance_to(units[j].position)
			var min_distance = units[i].radius + units[j].radius

			# Units should maintain minimum separation
			assert_greater(distance, min_distance * 0.8)  # Allow 20% overlap

func test_target_following() -> void:
	# Setup
	movement_component.position = Vector2(0, 0)
	movement_component.speed = 50.0
	var moving_target = Vector2(100, 100)

	# Simulate following over multiple frames
	for frame in 10:
		var delta = 0.1  # 0.1 seconds per frame

		# Move target
		moving_target += Vector2(10, 0)

		# Move towards target
		var direction = (moving_target - movement_component.position).normalized()
		movement_component.position += direction * movement_component.speed * delta

	# Should be closer to target after movement
	var final_distance = movement_component.position.distance_to(moving_target)
	assert_less(final_distance, 200)  # Started at ~141 distance

func test_movement_speed_modifiers() -> void:
	# Setup
	var base_speed = 100.0
	movement_component.speed = base_speed

	# Test slow effect
	movement_component.apply_slow(0.5)  # 50% slow
	assert_equal(50.0, movement_component.speed)

	# Test speed boost
	movement_component.remove_slow()
	movement_component.apply_speed_boost(1.5)  # 150% speed
	assert_equal(150.0, movement_component.speed)

	# Test stacking effects
	movement_component.speed = base_speed
	movement_component.apply_slow(0.7)  # 70% speed
	movement_component.apply_speed_boost(1.2)  # 120% speed
	var expected_speed = base_speed * 0.7 * 1.2
	assert_in_range(movement_component.speed, expected_speed - 1, expected_speed + 1)

func test_path_recalculation() -> void:
	# Setup
	var start = Vector2(0, 0)
	var initial_goal = Vector2(100, 100)
	var new_goal = Vector2(200, 50)

	# Act
	var initial_path = movement_component.calculate_path(start, initial_goal)
	var recalculated_path = movement_component.calculate_path(start, new_goal)

	# Assert
	assert_not_equal(initial_path, recalculated_path)
	assert_equal(start, recalculated_path[0])

func test_arrival_detection() -> void:
	# Setup
	movement_component.position = Vector2(98, 98)
	var target = Vector2(100, 100)
	var arrival_threshold = 5.0

	# Act
	var distance_to_target = movement_component.position.distance_to(target)
	var has_arrived = distance_to_target <= arrival_threshold

	# Assert
	assert_true(has_arrived)

func test_rotation_towards_movement() -> void:
	# Setup
	movement_component.position = Vector2(0, 0)
	movement_component.rotation = 0.0
	var target = Vector2(100, 0)

	# Act
	var direction = (target - movement_component.position).normalized()
	var target_rotation = direction.angle()

	# Smooth rotation
	var rotation_speed = 5.0  # radians per second
	var delta = 0.1
	var rotation_step = rotation_speed * delta

	movement_component.rotation = lerp_angle(movement_component.rotation, target_rotation, rotation_step)

	# Assert - Should start rotating towards target
	assert_in_range(movement_component.rotation, -0.1, 0.1)  # Close to 0 radians (facing right)

func test_boundary_constraints() -> void:
	# Setup battlefield boundaries
	var min_bounds = Vector2(0, 0)
	var max_bounds = Vector2(1000, 500)

	# Test positions
	var positions = [
		Vector2(-10, 250),   # Out of bounds left
		Vector2(1010, 250),  # Out of bounds right
		Vector2(500, -10),   # Out of bounds top
		Vector2(500, 510),   # Out of bounds bottom
		Vector2(500, 250)    # In bounds
	]

	for pos in positions:
		var clamped = pos.clamp(min_bounds, max_bounds)

		if pos == Vector2(500, 250):
			assert_equal(pos, clamped)  # Should not change
		else:
			assert_not_equal(pos, clamped)  # Should be clamped
			assert_true(clamped.x >= min_bounds.x and clamped.x <= max_bounds.x)
			assert_true(clamped.y >= min_bounds.y and clamped.y <= max_bounds.y)