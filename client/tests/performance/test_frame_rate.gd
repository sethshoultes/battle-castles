extends GdUnitTestSuite

class_name TestFrameRate

var performance_metrics: Dictionary = {}
var frame_times: Array = []

func before_each() -> void:
	performance_metrics.clear()
	frame_times.clear()
	Engine.max_fps = 0  # Uncap FPS for testing

func after_each() -> void:
	Engine.max_fps = 60  # Reset to normal

func test_baseline_frame_rate() -> void:
	# Measure FPS with minimal load
	var start_time = Time.get_ticks_msec()
	var frame_count = 0
	var test_duration = 1000  # 1 second

	while Time.get_ticks_msec() - start_time < test_duration:
		await get_tree().process_frame
		frame_count += 1

	var fps = frame_count / (test_duration / 1000.0)
	performance_metrics["baseline_fps"] = fps

	assert_greater(fps, 60, "Baseline FPS should exceed 60")
	print("Baseline FPS: %.2f" % fps)

func test_combat_frame_rate() -> void:
	# Simulate combat scenario
	var units = []
	var projectiles = []

	# Create units
	for i in 20:
		units.append(create_mock_unit())

	# Create projectiles
	for i in 10:
		projectiles.append(create_mock_projectile())

	# Measure FPS during combat
	var frame_count = 0
	var start_time = Time.get_ticks_msec()

	for frame in 60:  # 60 frames
		var frame_start = Time.get_ticks_usec()

		# Simulate combat calculations
		for unit in units:
			update_unit_combat(unit)

		for projectile in projectiles:
			update_projectile(projectile)

		# Check unit-projectile collisions
		for projectile in projectiles:
			for unit in units:
				check_collision(projectile, unit)

		var frame_time = (Time.get_ticks_usec() - frame_start) / 1000.0
		frame_times.append(frame_time)

		await get_tree().process_frame
		frame_count += 1

	var total_time = Time.get_ticks_msec() - start_time
	var avg_fps = frame_count / (total_time / 1000.0)

	performance_metrics["combat_fps"] = avg_fps
	assert_greater(avg_fps, 55, "Combat FPS should stay above 55")

	# Cleanup
	for unit in units:
		unit.queue_free()
	for projectile in projectiles:
		projectile.queue_free()

func test_particle_effects_performance() -> void:
	# Test particle system performance
	var particle_systems = []

	# Create multiple particle effects
	for i in 5:
		var particles = create_particle_system()
		particles.amount = 100
		particles.lifetime = 2.0
		particle_systems.append(particles)

	# Measure performance with particles
	var start_time = Time.get_ticks_msec()
	var frame_count = 0

	while frame_count < 60:
		for particles in particle_systems:
			particles.emitting = true

		await get_tree().process_frame
		frame_count += 1

	var elapsed = Time.get_ticks_msec() - start_time
	var fps = frame_count / (elapsed / 1000.0)

	performance_metrics["particle_fps"] = fps
	assert_greater(fps, 50, "FPS with particles should stay above 50")

	# Cleanup
	for particles in particle_systems:
		particles.queue_free()

func test_ui_update_performance() -> void:
	# Test UI update performance
	var ui_elements = []

	# Create UI elements
	for i in 20:
		var element = create_mock_ui_element()
		ui_elements.append(element)

	var frame_count = 0
	var update_times = []

	for frame in 60:
		var update_start = Time.get_ticks_usec()

		# Update all UI elements
		for element in ui_elements:
			element.text = "Frame: %d" % frame
			element.modulate.a = (sin(frame * 0.1) + 1.0) / 2.0

		var update_time = (Time.get_ticks_usec() - update_start) / 1000.0
		update_times.append(update_time)

		await get_tree().process_frame
		frame_count += 1

	var avg_update_time = update_times.reduce(func(a, b): return a + b) / update_times.size()
	performance_metrics["ui_update_time"] = avg_update_time

	assert_less(avg_update_time, 2.0, "UI updates should take less than 2ms")

	# Cleanup
	for element in ui_elements:
		element.queue_free()

func test_frame_time_consistency() -> void:
	# Test for frame time spikes
	frame_times.clear()

	for frame in 120:  # 2 seconds at 60 FPS
		var frame_start = Time.get_ticks_usec()

		# Simulate typical frame workload
		for i in 100:
			var calc = sqrt(randf() * 1000)

		await get_tree().process_frame

		var frame_time = (Time.get_ticks_usec() - frame_start) / 1000.0
		frame_times.append(frame_time)

	# Calculate statistics
	var avg_frame_time = frame_times.reduce(func(a, b): return a + b) / frame_times.size()
	var max_frame_time = frame_times.max()
	var min_frame_time = frame_times.min()

	# Calculate standard deviation
	var variance = 0.0
	for time in frame_times:
		variance += pow(time - avg_frame_time, 2)
	variance /= frame_times.size()
	var std_deviation = sqrt(variance)

	performance_metrics["avg_frame_time"] = avg_frame_time
	performance_metrics["max_frame_time"] = max_frame_time
	performance_metrics["frame_time_std_dev"] = std_deviation

	# Check for consistency
	assert_less(max_frame_time, 33.3, "No frame should take longer than 33.3ms (30 FPS minimum)")
	assert_less(std_deviation, 5.0, "Frame times should be consistent (low std deviation)")

	print("Frame time stats - Avg: %.2fms, Max: %.2fms, StdDev: %.2fms" %
		[avg_frame_time, max_frame_time, std_deviation])

func test_render_call_batching() -> void:
	# Test draw call batching efficiency
	var sprites = []

	# Create many sprites with same texture (should batch)
	for i in 50:
		var sprite = create_mock_sprite()
		sprite.texture = preload("res://assets/sprites/unit_knight.png") if FileAccess.file_exists("res://assets/sprites/unit_knight.png") else null
		sprites.append(sprite)

	# Measure render performance
	var render_start = Time.get_ticks_msec()

	for frame in 30:
		# Move sprites to trigger redraws
		for sprite in sprites:
			sprite.position += Vector2(randf() - 0.5, randf() - 0.5)

		await get_tree().process_frame

	var render_time = Time.get_ticks_msec() - render_start
	var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)

	performance_metrics["batched_draw_calls"] = draw_calls
	assert_less(draw_calls, sprites.size(), "Draw calls should be batched (less than sprite count)")

	# Cleanup
	for sprite in sprites:
		sprite.queue_free()

func test_physics_frame_rate() -> void:
	# Test physics performance
	var physics_bodies = []

	# Create physics bodies
	for i in 30:
		var body = create_mock_physics_body()
		physics_bodies.append(body)

	var physics_frames = 0
	var start_time = Time.get_ticks_msec()

	# Run physics for 1 second
	while Time.get_ticks_msec() - start_time < 1000:
		for body in physics_bodies:
			# Simulate physics calculations
			body.linear_velocity = Vector2(randf() * 100 - 50, randf() * 100 - 50)

		await get_tree().physics_frame
		physics_frames += 1

	var physics_fps = physics_frames
	performance_metrics["physics_fps"] = physics_fps

	assert_greater_equal(physics_fps, 60, "Physics should run at 60 FPS or higher")

	# Cleanup
	for body in physics_bodies:
		body.queue_free()

func test_vsync_performance() -> void:
	# Test with VSync enabled vs disabled
	var vsync_results = {}

	# Test with VSync on
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	await get_tree().create_timer(0.1).timeout

	var vsync_fps = await measure_fps_for_duration(500)
	vsync_results["vsync_on"] = vsync_fps

	# Test with VSync off
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(0.1).timeout

	var no_vsync_fps = await measure_fps_for_duration(500)
	vsync_results["vsync_off"] = no_vsync_fps

	performance_metrics["vsync_results"] = vsync_results

	# VSync should cap FPS to monitor refresh rate (usually 60)
	assert_less_equal(vsync_results["vsync_on"], 61, "VSync should cap FPS")

	# Reset to VSync enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

# Helper functions
func create_mock_unit() -> Node2D:
	var unit = Node2D.new()
	unit.position = Vector2(randf() * 1000, randf() * 500)
	return unit

func create_mock_projectile() -> Node2D:
	var projectile = Node2D.new()
	projectile.position = Vector2(randf() * 1000, randf() * 500)
	projectile.set_meta("velocity", Vector2(randf() * 200 - 100, randf() * 200 - 100))
	return projectile

func create_particle_system() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.position = Vector2(500, 250)
	return particles

func create_mock_ui_element() -> Label:
	var label = Label.new()
	label.text = "Test"
	return label

func create_mock_sprite() -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = Vector2(randf() * 1000, randf() * 500)
	return sprite

func create_mock_physics_body() -> RigidBody2D:
	var body = RigidBody2D.new()
	body.position = Vector2(randf() * 1000, randf() * 500)
	return body

func update_unit_combat(unit: Node2D) -> void:
	# Simulate combat calculations
	var nearest_enemy = Vector2(500, 250)
	var distance = unit.position.distance_to(nearest_enemy)
	if distance < 100:
		unit.modulate = Color.RED
	else:
		unit.modulate = Color.WHITE

func update_projectile(projectile: Node2D) -> void:
	var velocity = projectile.get_meta("velocity")
	projectile.position += velocity * 0.016  # 60 FPS frame time

func check_collision(projectile: Node2D, unit: Node2D) -> bool:
	return projectile.position.distance_to(unit.position) < 20

func measure_fps_for_duration(duration_ms: int) -> float:
	var start = Time.get_ticks_msec()
	var frames = 0

	while Time.get_ticks_msec() - start < duration_ms:
		await get_tree().process_frame
		frames += 1

	return frames / (duration_ms / 1000.0)