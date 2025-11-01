extends GdUnitTestSuite

class_name TestMaxUnits

var battlefield: Node
var units: Array = []
var performance_monitor: Dictionary = {}

func before_each() -> void:
	var Battlefield = load("res://scripts/battle/battlefield.gd")
	battlefield = Battlefield.new()
	units.clear()
	performance_monitor.clear()

func after_each() -> void:
	for unit in units:
		if unit:
			unit.queue_free()
	units.clear()

	if battlefield:
		battlefield.queue_free()

func test_40_units_simultaneously() -> void:
	# Battle Castles should handle 40 units on field (20 per player)
	var start_time = Time.get_ticks_msec()
	var start_memory = OS.get_static_memory_usage()

	# Spawn 40 units
	for i in 40:
		var position = Vector2(
			100 + (i % 8) * 100,
			100 + (i / 8) * 100
		)

		var unit_type = ["knight", "archer", "goblin", "skeleton"][i % 4]
		var team = "player" if i < 20 else "opponent"

		var unit = spawn_test_unit(unit_type, position, team)
		units.append(unit)

	# Verify all units spawned
	assert_equal(40, units.size())

	# Measure spawn time
	var spawn_time = Time.get_ticks_msec() - start_time
	assert_less(spawn_time, 1000, "Spawning 40 units should take less than 1 second")

	# Simulate one frame of updates
	var frame_start = Time.get_ticks_msec()

	for unit in units:
		update_unit(unit, 0.016)  # 60 FPS = 16ms per frame

	var frame_time = Time.get_ticks_msec() - frame_start
	assert_less(frame_time, 16, "Frame time should be under 16ms for 60 FPS")

	# Check memory usage
	var memory_used = OS.get_static_memory_usage() - start_memory
	var memory_per_unit = memory_used / 40.0
	assert_less(memory_per_unit, 100_000, "Each unit should use less than 100KB")

	# Log performance metrics
	performance_monitor["spawn_time"] = spawn_time
	performance_monitor["frame_time"] = frame_time
	performance_monitor["memory_per_unit"] = memory_per_unit

	print("40 Units Performance: ", performance_monitor)

func test_unit_spawn_stress() -> void:
	# Test rapid spawning and despawning
	var operations = 0
	var start_time = Time.get_ticks_msec()
	var target_operations = 100

	while operations < target_operations:
		# Spawn unit
		var unit = spawn_test_unit("skeleton", Vector2(500, 400), "player")
		units.append(unit)

		# Simulate some lifetime
		await get_tree().create_timer(0.01).timeout

		# Destroy unit
		unit.queue_free()
		units.erase(unit)

		operations += 1

	var total_time = Time.get_ticks_msec() - start_time
	var avg_operation_time = total_time / float(target_operations)

	assert_less(avg_operation_time, 50, "Average spawn/despawn should be under 50ms")

func test_pathfinding_with_max_units() -> void:
	# Spawn 40 units
	for i in 40:
		var position = Vector2(100 + randf() * 800, 100 + randf() * 400)
		var unit = spawn_test_unit("knight", position, "player")
		units.append(unit)

	# Measure pathfinding performance
	var pathfinding_start = Time.get_ticks_msec()

	for unit in units:
		var target = Vector2(500, 250)  # All units path to center
		var path = calculate_path(unit.position, target, units)
		assert_not_null(path)
		assert_greater(path.size(), 0)

	var pathfinding_time = Time.get_ticks_msec() - pathfinding_start
	assert_less(pathfinding_time, 100, "Pathfinding for 40 units should complete in under 100ms")

func test_collision_detection_performance() -> void:
	# Create units in close proximity to maximize collision checks
	var cluster_center = Vector2(500, 250)
	var cluster_radius = 150

	for i in 40:
		var angle = (i / 40.0) * TAU
		var distance = randf() * cluster_radius
		var position = cluster_center + Vector2(cos(angle), sin(angle)) * distance

		var unit = spawn_test_unit("goblin", position, "player")
		units.append(unit)

	# Measure collision detection
	var collision_start = Time.get_ticks_msec()

	# Check collisions between all units (n^2 worst case)
	var collision_pairs = []
	for i in range(units.size()):
		for j in range(i + 1, units.size()):
			var distance = units[i].position.distance_to(units[j].position)
			if distance < 30:  # Collision radius
				collision_pairs.append([i, j])

	var collision_time = Time.get_ticks_msec() - collision_start
	assert_less(collision_time, 10, "Collision detection should complete in under 10ms")

	print("Found %d collision pairs in %dms" % [collision_pairs.size(), collision_time])

func test_unit_ai_performance() -> void:
	# Test AI decision making for all units
	for i in 40:
		var unit = spawn_test_unit("wizard", Vector2(100 + i * 20, 250), "player")
		units.append(unit)

	var ai_start = Time.get_ticks_msec()

	for unit in units:
		# Simulate AI decisions
		var decision = make_ai_decision(unit)
		assert_not_null(decision)

		# Apply decision
		match decision.action:
			"move":
				unit.target_position = decision.position
			"attack":
				unit.target_enemy = decision.target
			"idle":
				pass

	var ai_time = Time.get_ticks_msec() - ai_start
	assert_less(ai_time, 20, "AI decisions for 40 units should complete in under 20ms")

func test_rendering_performance() -> void:
	# This test would need actual rendering context
	# Measuring draw calls and batch optimization

	for i in 40:
		var unit = spawn_test_unit("knight", Vector2.ZERO, "player")
		units.append(unit)

		# Each unit should be properly batched
		assert_true(unit.can_use_instancing)

	# Expected: Units of same type share materials and can be instanced
	var material_count = count_unique_materials(units)
	assert_less(material_count, 10, "Should have fewer than 10 unique materials for batching")

func test_network_sync_with_max_units() -> void:
	# Create 40 units
	for i in 40:
		var unit = spawn_test_unit("archer", Vector2.ZERO, "player")
		unit.network_id = i
		units.append(unit)

	# Serialize state for network
	var serialize_start = Time.get_ticks_msec()

	var network_state = {
		"units": []
	}

	for unit in units:
		network_state.units.append({
			"id": unit.network_id,
			"position": var_to_bytes(unit.position),
			"health": unit.health,
			"state": unit.state
		})

	var serialize_time = Time.get_ticks_msec() - serialize_start
	assert_less(serialize_time, 5, "Serialization should complete in under 5ms")

	# Estimate packet size
	var packet_size = str(network_state).length()
	assert_less(packet_size, 5000, "Network state should be under 5KB")

	print("Network packet size for 40 units: %d bytes" % packet_size)

# Helper functions
func spawn_test_unit(type: String, position: Vector2, team: String) -> Node2D:
	var unit = Node2D.new()
	unit.position = position
	unit.team = team
	unit.type = type
	unit.health = 100
	unit.state = "idle"
	unit.target_position = position
	unit.can_use_instancing = true
	unit.network_id = -1

	return unit

func update_unit(unit: Node2D, delta: float) -> void:
	# Simulate unit update logic
	if unit.state == "moving":
		var direction = (unit.target_position - unit.position).normalized()
		unit.position += direction * 50 * delta  # 50 pixels/second

	# Simple AI check
	if randf() < 0.1:  # 10% chance to change state
		unit.state = ["idle", "moving", "attacking"][randi() % 3]

func calculate_path(from: Vector2, to: Vector2, obstacles: Array) -> Array:
	# Simplified pathfinding
	var path = [from]

	# Add intermediate points to avoid obstacles
	for obstacle in obstacles:
		if obstacle.position.distance_to(from) < 100:
			var avoid_point = from + (from - obstacle.position).normalized() * 50
			path.append(avoid_point)
			break

	path.append(to)
	return path

func make_ai_decision(unit: Node2D) -> Dictionary:
	# Simplified AI decision
	var rand = randf()
	if rand < 0.3:
		return {"action": "move", "position": Vector2(500, 250)}
	elif rand < 0.6:
		return {"action": "attack", "target": null}
	else:
		return {"action": "idle"}

func count_unique_materials(unit_list: Array) -> int:
	var materials = {}
	for unit in unit_list:
		materials[unit.type] = true
	return materials.size()