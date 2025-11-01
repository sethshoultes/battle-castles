extends GdUnitTestSuite

class_name TestMemory

var baseline_memory: int
var memory_samples: Array = []
var leak_detection: Dictionary = {}

func before_each() -> void:
	# Force garbage collection if available
	if OS.has_feature("debug"):
		print("Collecting garbage before test...")

	baseline_memory = OS.get_static_memory_usage()
	memory_samples.clear()
	leak_detection.clear()

func test_memory_usage_over_time() -> void:
	# Monitor memory usage during typical gameplay
	var test_duration = 5000  # 5 seconds
	var sample_interval = 100  # Sample every 100ms
	var start_time = Time.get_ticks_msec()

	while Time.get_ticks_msec() - start_time < test_duration:
		# Simulate game activity
		var units = []
		for i in 10:
			units.append(create_temp_unit())

		# Sample memory
		var current_memory = OS.get_static_memory_usage()
		memory_samples.append({
			"time": Time.get_ticks_msec() - start_time,
			"memory": current_memory
		})

		# Cleanup
		for unit in units:
			unit.queue_free()

		await get_tree().create_timer(sample_interval / 1000.0).timeout

	# Analyze memory trend
	var first_sample = memory_samples[0].memory
	var last_sample = memory_samples[-1].memory
	var memory_growth = last_sample - first_sample

	# Convert to MB for readability
	var growth_mb = memory_growth / 1048576.0

	assert_less(growth_mb, 10.0, "Memory should not grow more than 10MB over 5 seconds")
	print("Memory growth over 5 seconds: %.2f MB" % growth_mb)

func test_unit_memory_footprint() -> void:
	# Measure memory per unit type
	var unit_types = ["knight", "archer", "wizard", "giant"]
	var units_per_type = 10

	for unit_type in unit_types:
		var before = OS.get_static_memory_usage()
		var units = []

		# Create units
		for i in units_per_type:
			var unit = create_full_unit(unit_type)
			units.append(unit)

		var after = OS.get_static_memory_usage()
		var total_memory = after - before
		var per_unit = total_memory / float(units_per_type)

		leak_detection[unit_type] = {
			"total_memory": total_memory,
			"per_unit": per_unit,
			"per_unit_kb": per_unit / 1024.0
		}

		# Cleanup
		for unit in units:
			unit.queue_free()

		await get_tree().create_timer(0.1).timeout

	# Check memory usage per unit
	for unit_type in unit_types:
		var per_unit_kb = leak_detection[unit_type].per_unit_kb
		assert_less(per_unit_kb, 500, "%s should use less than 500KB per unit" % unit_type)
		print("%s memory: %.2f KB per unit" % [unit_type, per_unit_kb])

func test_texture_memory_management() -> void:
	# Test texture loading and unloading
	var textures = []
	var texture_paths = [
		"res://assets/sprites/unit_knight.png",
		"res://assets/sprites/unit_archer.png",
		"res://assets/sprites/unit_wizard.png"
	]

	# Load textures
	var before_load = OS.get_static_memory_usage()

	for path in texture_paths:
		if FileAccess.file_exists(path):
			var texture = load(path)
			textures.append(texture)

	var after_load = OS.get_static_memory_usage()
	var texture_memory = after_load - before_load
	var texture_memory_mb = texture_memory / 1048576.0

	assert_less(texture_memory_mb, 50, "Textures should use less than 50MB")
	print("Texture memory usage: %.2f MB" % texture_memory_mb)

	# Clear texture references
	textures.clear()
	await get_tree().create_timer(0.5).timeout

	# Check if memory is released
	var after_clear = OS.get_static_memory_usage()
	var retained_memory = after_clear - before_load
	var retained_mb = retained_memory / 1048576.0

	# Some memory may be cached, but should be significantly less
	assert_less(retained_mb, texture_memory_mb * 0.3, "Most texture memory should be released")

func test_particle_memory_usage() -> void:
	# Test memory usage of particle effects
	var particle_systems = []
	var before = OS.get_static_memory_usage()

	# Create various particle effects
	for i in 10:
		var particles = CPUParticles2D.new()
		particles.amount = 100
		particles.lifetime = 2.0
		particles.emitting = true
		particle_systems.append(particles)

	var after = OS.get_static_memory_usage()
	var particle_memory = (after - before) / 1048576.0

	assert_less(particle_memory, 5.0, "10 particle systems should use less than 5MB")
	print("Particle systems memory: %.2f MB" % particle_memory)

	# Cleanup
	for particles in particle_systems:
		particles.queue_free()

func test_memory_leak_detection() -> void:
	# Repeatedly create and destroy objects to detect leaks
	var iterations = 50
	var memory_checkpoints = []

	for iteration in iterations:
		# Take memory snapshot every 10 iterations
		if iteration % 10 == 0:
			memory_checkpoints.append(OS.get_static_memory_usage())

		# Create and destroy objects
		var objects = []
		for i in 5:
			objects.append(create_complex_object())

		# Use objects
		for obj in objects:
			obj.process_data()

		# Cleanup
		for obj in objects:
			obj.cleanup()
			obj.queue_free()

		await get_tree().create_timer(0.01).timeout

	# Analyze memory trend
	if memory_checkpoints.size() > 2:
		var memory_growth_rate = []
		for i in range(1, memory_checkpoints.size()):
			var growth = memory_checkpoints[i] - memory_checkpoints[i-1]
			memory_growth_rate.append(growth)

		var avg_growth = memory_growth_rate.reduce(func(a, b): return a + b) / memory_growth_rate.size()
		var avg_growth_kb = avg_growth / 1024.0

		assert_less(abs(avg_growth_kb), 100, "Average memory growth should be minimal (<100KB per 10 iterations)")
		print("Average memory growth: %.2f KB per 10 iterations" % avg_growth_kb)

func test_string_memory_optimization() -> void:
	# Test string memory usage (common source of leaks)
	var strings = []
	var before = OS.get_static_memory_usage()

	# Create many strings
	for i in 1000:
		strings.append("Battle Unit ID: %d at position (%d, %d)" % [i, randi() % 1000, randi() % 500])

	var after_creation = OS.get_static_memory_usage()
	var string_memory = (after_creation - before) / 1024.0

	assert_less(string_memory, 500, "1000 strings should use less than 500KB")

	# Test string interning/pooling
	var duplicate_strings = []
	for i in 100:
		duplicate_strings.append("knight")  # Same string repeated

	var after_duplicates = OS.get_static_memory_usage()
	var duplicate_memory = (after_duplicates - after_creation) / 1024.0

	assert_less(duplicate_memory, 10, "Duplicate strings should be efficiently stored (<10KB)")

	strings.clear()
	duplicate_strings.clear()

func test_audio_memory_management() -> void:
	# Test audio resource memory
	var audio_streams = []
	var audio_paths = [
		"res://assets/audio/sfx_attack.ogg",
		"res://assets/audio/sfx_deploy.ogg",
		"res://assets/audio/music_battle.ogg"
	]

	var before = OS.get_static_memory_usage()

	for path in audio_paths:
		if FileAccess.file_exists(path):
			var stream = load(path)
			audio_streams.append(stream)

	var after = OS.get_static_memory_usage()
	var audio_memory_mb = (after - before) / 1048576.0

	assert_less(audio_memory_mb, 20, "Audio resources should use less than 20MB")
	print("Audio memory usage: %.2f MB" % audio_memory_mb)

	audio_streams.clear()

func test_network_buffer_memory() -> void:
	# Test network message buffer memory
	var network_buffers = []
	var message_size = 256  # bytes per message
	var buffer_count = 100

	var before = OS.get_static_memory_usage()

	for i in buffer_count:
		var buffer = PackedByteArray()
		buffer.resize(message_size)
		for j in message_size:
			buffer[j] = randi() % 256
		network_buffers.append(buffer)

	var after = OS.get_static_memory_usage()
	var buffer_memory = after - before
	var expected_memory = message_size * buffer_count

	# Allow 50% overhead for array management
	assert_less(buffer_memory, expected_memory * 1.5, "Network buffers should not have excessive overhead")

	var overhead_percentage = ((buffer_memory - expected_memory) / float(expected_memory)) * 100
	print("Network buffer overhead: %.1f%%" % overhead_percentage)

	network_buffers.clear()

func test_scene_memory_usage() -> void:
	# Test memory usage of complete scenes
	var scenes = {
		"battle": "res://scenes/battle/battle.tscn",
		"menu": "res://scenes/ui/main_menu.tscn",
		"deck_builder": "res://scenes/ui/deck_builder.tscn"
	}

	for scene_name in scenes:
		var path = scenes[scene_name]
		if not FileAccess.file_exists(path):
			continue

		var before = OS.get_static_memory_usage()
		var scene = load(path)
		var instance = scene.instantiate() if scene else null

		if instance:
			var after = OS.get_static_memory_usage()
			var scene_memory_mb = (after - before) / 1048576.0

			assert_less(scene_memory_mb, 100, "%s scene should use less than 100MB" % scene_name)
			print("%s scene memory: %.2f MB" % [scene_name, scene_memory_mb])

			instance.queue_free()

		await get_tree().create_timer(0.1).timeout

func test_cache_memory_management() -> void:
	# Test various caching strategies
	var cache = {}
	var cache_size = 100
	var before = OS.get_static_memory_usage()

	# Fill cache
	for i in cache_size:
		cache[i] = {
			"data": PackedFloat32Array([randf(), randf(), randf()]),
			"timestamp": Time.get_ticks_msec()
		}

	var after_fill = OS.get_static_memory_usage()
	var cache_memory_kb = (after_fill - before) / 1024.0

	assert_less(cache_memory_kb, 50, "Cache of 100 entries should use less than 50KB")

	# Test cache eviction
	var eviction_threshold = 50
	if cache.size() > eviction_threshold:
		var keys_to_remove = []
		for key in cache:
			if cache.size() - keys_to_remove.size() <= eviction_threshold:
				break
			keys_to_remove.append(key)

		for key in keys_to_remove:
			cache.erase(key)

	var after_eviction = OS.get_static_memory_usage()
	var released_memory_kb = (after_fill - after_eviction) / 1024.0

	assert_greater(released_memory_kb, cache_memory_kb * 0.3, "Cache eviction should release significant memory")

	cache.clear()

# Helper functions
func create_temp_unit() -> Node2D:
	var unit = Node2D.new()
	unit.set_meta("health", 100)
	unit.set_meta("damage", 50)
	return unit

func create_full_unit(type: String) -> Node2D:
	var unit = Node2D.new()

	# Add components
	var health_comp = Node.new()
	health_comp.name = "HealthComponent"
	unit.add_child(health_comp)

	var attack_comp = Node.new()
	attack_comp.name = "AttackComponent"
	unit.add_child(attack_comp)

	var movement_comp = Node.new()
	movement_comp.name = "MovementComponent"
	unit.add_child(movement_comp)

	# Add metadata
	unit.set_meta("type", type)
	unit.set_meta("team", "player")
	unit.set_meta("state", "idle")
	unit.set_meta("path", [])

	return unit

func create_complex_object() -> Node:
	var obj = Node.new()

	obj.set_meta("data", {
		"array": range(100),
		"dict": {"key": "value"},
		"nested": {"deep": {"data": "test"}}
	})

	obj.process_data = func():
		var temp = obj.get_meta("data")
		temp["processed"] = true

	obj.cleanup = func():
		obj.remove_meta("data")

	return obj