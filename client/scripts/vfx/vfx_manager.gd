extends Node
class_name VFXManager

# Singleton for managing all visual effects
# Handles spawning, pooling, and lifecycle of effects

signal screen_shake_requested(intensity: float, duration: float)
signal flash_effect_requested(color: Color, duration: float)
signal freeze_frame_requested(duration: float)
signal slow_motion_requested(time_scale: float, duration: float)

# Effect pools
var _effect_pools: Dictionary = {}
var _pool_sizes: Dictionary = {
	"deploy": 10,
	"impact": 20,
	"explosion": 10,
	"arrow_trail": 30,
	"heal": 10,
	"confetti": 5
}

# Quality settings
enum QualityLevel { LOW, MEDIUM, HIGH }
var current_quality: QualityLevel = QualityLevel.MEDIUM

# Screen effects
var _camera: Camera2D
var _shake_trauma: float = 0.0
var _shake_decay: float = 2.0
var _max_shake_offset: Vector2 = Vector2(30, 20)
var _max_shake_rotation: float = 0.1

# Slow motion
var _original_time_scale: float = 1.0
var _slow_motion_timer: float = 0.0
var _target_time_scale: float = 1.0

# Flash effect
var _flash_overlay: ColorRect
var _flash_timer: float = 0.0
var _flash_duration: float = 0.0
var _flash_color: Color = Color.WHITE

# Freeze frame
var _freeze_timer: float = 0.0
var _is_frozen: bool = false

func _ready() -> void:
	set_process(true)
	_setup_effect_pools()
	_setup_screen_effects()

	# Load quality settings
	_load_quality_settings()

func _setup_effect_pools() -> void:
	# Pre-instantiate particle effects for pooling
	for effect_type in _pool_sizes.keys():
		_effect_pools[effect_type] = []
		var pool_size = _get_adjusted_pool_size(effect_type)

		for i in range(pool_size):
			var effect = _create_effect_instance(effect_type)
			if effect:
				effect.visible = false
				add_child(effect)
				_effect_pools[effect_type].append({
					"instance": effect,
					"in_use": false
				})

func _create_effect_instance(effect_type: String) -> Node2D:
	# Load and instantiate effect scenes
	var scene_path = "res://scenes/vfx/%s_effect.tscn" % effect_type
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			return scene.instantiate()

	# Fallback to creating basic particle effect
	return _create_fallback_effect(effect_type)

func _create_fallback_effect(effect_type: String) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = false
	particles.amount = _get_particle_count(effect_type)
	particles.lifetime = 1.0
	particles.one_shot = true

	# Create process material
	var process_material = ParticleProcessMaterial.new()

	match effect_type:
		"deploy":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			process_material.initial_velocity_min = 50.0
			process_material.initial_velocity_max = 150.0
			process_material.angular_velocity_min = -180.0
			process_material.angular_velocity_max = 180.0
			process_material.scale_min = 0.5
			process_material.scale_max = 1.5
			process_material.color = Color(1.0, 0.8, 0.2, 1.0)  # Golden

		"impact":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			process_material.direction = Vector2(0, -1)
			process_material.spread = 45.0
			process_material.initial_velocity_min = 100.0
			process_material.initial_velocity_max = 300.0
			process_material.gravity = Vector2(0, 500)
			process_material.scale_min = 0.3
			process_material.scale_max = 0.8
			process_material.color = Color(1.0, 0.5, 0.0, 1.0)  # Orange

		"explosion":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			process_material.initial_velocity_min = 200.0
			process_material.initial_velocity_max = 500.0
			process_material.angular_velocity_min = -360.0
			process_material.angular_velocity_max = 360.0
			process_material.scale_min = 1.0
			process_material.scale_max = 3.0
			process_material.color = Color(1.0, 0.3, 0.0, 1.0)  # Red-orange
			process_material.damping_min = 2.0
			process_material.damping_max = 5.0

		"arrow_trail":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			process_material.initial_velocity_min = 0.0
			process_material.initial_velocity_max = 50.0
			process_material.scale_min = 0.2
			process_material.scale_max = 0.5
			process_material.color = Color(0.5, 0.8, 1.0, 0.8)  # Light blue
			particles.lifetime = 0.5

		"heal":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			process_material.direction = Vector2(0, -1)
			process_material.initial_velocity_min = 20.0
			process_material.initial_velocity_max = 80.0
			process_material.gravity = Vector2(0, -100)
			process_material.scale_min = 0.5
			process_material.scale_max = 1.0
			process_material.color = Color(0.0, 1.0, 0.3, 1.0)  # Green

		"confetti":
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			process_material.emission_box_extents = Vector3(200, 10, 0)
			process_material.direction = Vector2(0, 1)
			process_material.spread = 20.0
			process_material.initial_velocity_min = 100.0
			process_material.initial_velocity_max = 300.0
			process_material.gravity = Vector2(0, 200)
			process_material.angular_velocity_min = -720.0
			process_material.angular_velocity_max = 720.0
			process_material.scale_min = 0.5
			process_material.scale_max = 1.5
			# Random colors for confetti
			process_material.color = Color(1.0, 1.0, 1.0, 1.0)
			process_material.hue_variation_min = -1.0
			process_material.hue_variation_max = 1.0
			particles.lifetime = 3.0

	particles.process_material = process_material

	# Add simple texture (square for now)
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	particles.texture = texture

	return particles

func _setup_screen_effects() -> void:
	# Create flash overlay
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color(1, 1, 1, 0)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.z_index = 100

	# Add to canvas layer for UI overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	canvas_layer.add_child(_flash_overlay)

func _process(delta: float) -> void:
	_process_screen_shake(delta)
	_process_flash_effect(delta)
	_process_freeze_frame(delta)
	_process_slow_motion(delta)

func _process_screen_shake(delta: float) -> void:
	if not _camera:
		_camera = get_viewport().get_camera_2d()
		if not _camera:
			return

	if _shake_trauma > 0:
		_shake_trauma = max(_shake_trauma - _shake_decay * delta, 0)

		# Calculate shake intensity (trauma^2 for better feel)
		var shake_amount = pow(_shake_trauma, 2)

		# Apply random offset
		var offset_x = randf_range(-_max_shake_offset.x, _max_shake_offset.x) * shake_amount
		var offset_y = randf_range(-_max_shake_offset.y, _max_shake_offset.y) * shake_amount
		_camera.offset = Vector2(offset_x, offset_y)

		# Apply random rotation
		var rotation = randf_range(-_max_shake_rotation, _max_shake_rotation) * shake_amount
		_camera.rotation = rotation
	else:
		if _camera:
			_camera.offset = Vector2.ZERO
			_camera.rotation = 0

func _process_flash_effect(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		var alpha = (_flash_timer / _flash_duration) * 0.8  # Max 80% opacity
		_flash_overlay.color = Color(_flash_color.r, _flash_color.g, _flash_color.b, alpha)

		if _flash_timer <= 0:
			_flash_overlay.color = Color(1, 1, 1, 0)

func _process_freeze_frame(delta: float) -> void:
	if _freeze_timer > 0:
		_freeze_timer -= delta
		if _freeze_timer <= 0:
			_is_frozen = false
			get_tree().paused = false

func _process_slow_motion(delta: float) -> void:
	if _slow_motion_timer > 0:
		_slow_motion_timer -= delta
		if _slow_motion_timer <= 0:
			Engine.time_scale = _original_time_scale
			_target_time_scale = _original_time_scale

	# Smooth time scale transitions
	if Engine.time_scale != _target_time_scale:
		Engine.time_scale = lerp(Engine.time_scale, _target_time_scale, delta * 10.0)

# Public API

func spawn_effect(effect_type: String, global_position: Vector2, params: Dictionary = {}) -> Node2D:
	if not _effect_pools.has(effect_type):
		push_warning("Unknown effect type: " + effect_type)
		return null

	# Find available effect in pool
	for effect_data in _effect_pools[effect_type]:
		if not effect_data["in_use"]:
			var effect = effect_data["instance"]
			effect_data["in_use"] = true

			# Configure and activate effect
			effect.global_position = global_position
			effect.visible = true

			# Apply custom parameters
			if params.has("scale"):
				effect.scale = params["scale"]
			if params.has("rotation"):
				effect.rotation = params["rotation"]
			if params.has("color") and effect is GPUParticles2D:
				effect.process_material.color = params["color"]

			# Start emission
			if effect is GPUParticles2D:
				effect.restart()
				effect.emitting = true

			# Auto-return to pool after lifetime
			_schedule_effect_return(effect_data, effect_type)

			return effect

	# No available effects in pool
	push_warning("Effect pool exhausted for type: " + effect_type)
	return null

func _schedule_effect_return(effect_data: Dictionary, effect_type: String) -> void:
	var effect = effect_data["instance"]
	var lifetime = 1.0  # Default lifetime

	if effect is GPUParticles2D:
		lifetime = effect.lifetime

	# Use timer to return effect to pool
	var timer = Timer.new()
	timer.wait_time = lifetime + 0.5  # Add buffer
	timer.one_shot = true
	timer.timeout.connect(_return_effect_to_pool.bind(effect_data, effect))
	add_child(timer)
	timer.start()

func _return_effect_to_pool(effect_data: Dictionary, effect: Node2D) -> void:
	effect.visible = false
	if effect is GPUParticles2D:
		effect.emitting = false
	effect_data["in_use"] = false

func add_screen_shake(intensity: float = 0.5, duration: float = 0.5) -> void:
	_shake_trauma = min(_shake_trauma + intensity, 1.0)
	screen_shake_requested.emit(intensity, duration)

func add_flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	_flash_color = color
	_flash_duration = duration
	_flash_timer = duration
	flash_effect_requested.emit(color, duration)

func add_freeze_frame(duration: float = 0.05) -> void:
	if not _is_frozen:
		_freeze_timer = duration
		_is_frozen = true
		get_tree().paused = true
		freeze_frame_requested.emit(duration)

func set_slow_motion(time_scale: float = 0.3, duration: float = 1.0) -> void:
	_original_time_scale = Engine.time_scale
	_target_time_scale = time_scale
	_slow_motion_timer = duration
	slow_motion_requested.emit(time_scale, duration)

func set_quality(level: QualityLevel) -> void:
	current_quality = level
	_save_quality_settings()
	_rebuild_effect_pools()

func _get_particle_count(effect_type: String) -> int:
	var base_counts = {
		"deploy": 30,
		"impact": 20,
		"explosion": 50,
		"arrow_trail": 10,
		"heal": 15,
		"confetti": 100
	}

	var count = base_counts.get(effect_type, 20)

	match current_quality:
		QualityLevel.LOW:
			return int(count * 0.3)
		QualityLevel.MEDIUM:
			return int(count * 0.7)
		QualityLevel.HIGH:
			return count

	return count

func _get_adjusted_pool_size(effect_type: String) -> int:
	var base_size = _pool_sizes.get(effect_type, 10)

	match current_quality:
		QualityLevel.LOW:
			return int(base_size * 0.5)
		QualityLevel.MEDIUM:
			return base_size
		QualityLevel.HIGH:
			return int(base_size * 1.5)

	return base_size

func _rebuild_effect_pools() -> void:
	# Clear existing pools
	for effect_type in _effect_pools.keys():
		for effect_data in _effect_pools[effect_type]:
			effect_data["instance"].queue_free()
	_effect_pools.clear()

	# Rebuild with new quality settings
	_setup_effect_pools()

func _load_quality_settings() -> void:
	# Load from user settings if available
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		current_quality = config.get_value("graphics", "vfx_quality", QualityLevel.MEDIUM)

func _save_quality_settings() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")  # Load existing settings
	config.set_value("graphics", "vfx_quality", current_quality)
	config.save("user://settings.cfg")

# Convenience methods for common effects

func spawn_deploy_effect(position: Vector2) -> void:
	spawn_effect("deploy", position, {
		"scale": Vector2(1.2, 1.2)
	})
	add_screen_shake(0.1, 0.2)

func spawn_impact_effect(position: Vector2, damage_percent: float = 0.5) -> void:
	var scale = lerp(0.8, 2.0, damage_percent)
	spawn_effect("impact", position, {
		"scale": Vector2(scale, scale)
	})

	if damage_percent > 0.5:
		add_screen_shake(damage_percent * 0.3, 0.3)
		add_flash(Color(1.0, 0.8, 0.8), 0.1)

func spawn_explosion_effect(position: Vector2, size: float = 1.0) -> void:
	spawn_effect("explosion", position, {
		"scale": Vector2(size, size)
	})
	add_screen_shake(size * 0.5, 0.5)
	add_flash(Color(1.0, 0.5, 0.0), 0.15)

	if size > 1.5:
		add_freeze_frame(0.05)

func spawn_heal_effect(position: Vector2) -> void:
	spawn_effect("heal", position)

func spawn_victory_confetti(position: Vector2) -> void:
	spawn_effect("confetti", position, {
		"scale": Vector2(2.0, 2.0)
	})
	set_slow_motion(0.7, 2.0)