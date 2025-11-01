extends Node2D
class_name ArenaEffects

# Manages environmental and background effects for the battle arena
# Includes animated backgrounds, weather effects, and ambient particles

signal weather_changed(weather_type: String)
signal time_of_day_changed(time: String)

# Weather types
enum WeatherType {
	CLEAR,
	RAIN,
	SNOW,
	FOG,
	STORM,
	WINDY
}

# Time of day
enum TimeOfDay {
	DAWN,
	DAY,
	DUSK,
	NIGHT
}

# Current states
var current_weather: WeatherType = WeatherType.CLEAR
var current_time: TimeOfDay = TimeOfDay.DAY
var wind_strength: float = 0.0
var wind_direction: Vector2 = Vector2(1, 0)

# Effect nodes
var weather_particles: GPUParticles2D
var fog_layer: ColorRect
var cloud_layer: Node2D
var flag_container: Node2D
var water_effects: Node2D
var ambient_particles: GPUParticles2D
var lightning_overlay: ColorRect

# Animation parameters
var cloud_speed: float = 10.0
var flag_wave_speed: float = 2.0
var flag_wave_amplitude: float = 5.0
var water_wave_speed: float = 1.5
var water_wave_amplitude: float = 3.0

# Quality settings
var quality_level: VFXManager.QualityLevel = VFXManager.QualityLevel.MEDIUM

# Timers and animation values
var time_accumulator: float = 0.0
var lightning_timer: float = 0.0
var lightning_cooldown: float = 0.0

# Cloud properties
var clouds: Array = []
var max_clouds: int = 5

# Flag properties
var flags: Array = []

# Water properties
var water_shader: Shader
var water_material: ShaderMaterial

func _ready() -> void:
	set_process(true)
	_setup_layers()
	_setup_weather_system()
	_setup_environmental_objects()
	_apply_time_of_day()

func _setup_layers() -> void:
	# Background layer (behind everything)
	z_index = -100

	# Cloud layer
	cloud_layer = Node2D.new()
	cloud_layer.z_index = -90
	add_child(cloud_layer)

	# Flag container
	flag_container = Node2D.new()
	flag_container.z_index = -50
	add_child(flag_container)

	# Water effects layer
	water_effects = Node2D.new()
	water_effects.z_index = -80
	add_child(water_effects)

	# Weather particles (in front of background, behind units)
	weather_particles = GPUParticles2D.new()
	weather_particles.z_index = -40
	weather_particles.emitting = false
	add_child(weather_particles)

	# Ambient particles
	ambient_particles = GPUParticles2D.new()
	ambient_particles.z_index = -45
	ambient_particles.emitting = false
	add_child(ambient_particles)

	# Fog overlay
	fog_layer = ColorRect.new()
	fog_layer.color = Color(0.7, 0.7, 0.8, 0.0)
	fog_layer.size = get_viewport_rect().size * 2
	fog_layer.position = -get_viewport_rect().size * 0.5
	fog_layer.z_index = -30
	fog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog_layer)

	# Lightning overlay
	lightning_overlay = ColorRect.new()
	lightning_overlay.color = Color(1, 1, 1, 0)
	lightning_overlay.size = get_viewport_rect().size * 2
	lightning_overlay.position = -get_viewport_rect().size * 0.5
	lightning_overlay.z_index = 50
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lightning_overlay)

func _setup_weather_system() -> void:
	# Configure weather particles material
	var weather_material = ParticleProcessMaterial.new()
	weather_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	weather_material.emission_box_extents = Vector3(
		get_viewport_rect().size.x,
		10,
		0
	)
	weather_particles.process_material = weather_material
	weather_particles.position = Vector2(0, -get_viewport_rect().size.y * 0.5)

	# Default texture (will be replaced based on weather)
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	weather_particles.texture = ImageTexture.create_from_image(image)

func _setup_environmental_objects() -> void:
	# Create clouds
	_spawn_clouds()

	# Create flags
	_spawn_flags()

	# Create water effect
	_setup_water_effect()

	# Setup ambient particles
	_setup_ambient_particles()

func _spawn_clouds() -> void:
	for i in range(max_clouds):
		var cloud = _create_cloud()
		cloud.position = Vector2(
			randf() * get_viewport_rect().size.x,
			randf_range(50, 200)
		)
		cloud_layer.add_child(cloud)
		clouds.append(cloud)

func _create_cloud() -> Sprite2D:
	var cloud = Sprite2D.new()

	# Create simple cloud texture
	var size = randi_range(64, 128)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Draw cloud shape (multiple overlapping circles)
	for i in range(5):
		var circle_pos = Vector2(
			randf_range(size * 0.2, size * 0.8),
			randf_range(size * 0.3, size * 0.7)
		)
		var radius = randf_range(size * 0.15, size * 0.3)
		_draw_soft_circle(image, circle_pos, radius, Color(1, 1, 1, 0.6))

	cloud.texture = ImageTexture.create_from_image(image)
	cloud.modulate = Color(1, 1, 1, 0.7)

	# Random properties
	cloud.scale = Vector2.ONE * randf_range(0.8, 1.5)
	cloud.set_meta("speed", randf_range(5, 15))

	return cloud

func _draw_soft_circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var size = image.get_size()

	for x in range(max(0, center.x - radius * 2), min(size.x, center.x + radius * 2)):
		for y in range(max(0, center.y - radius * 2), min(size.y, center.y + radius * 2)):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha = 1.0 - (dist / radius)
				alpha = smoothstep(0, 1, alpha)
				var pixel = image.get_pixel(x, y)
				var new_alpha = min(1.0, pixel.a + color.a * alpha)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, new_alpha))

func _spawn_flags() -> void:
	# Create flags at castle positions
	var flag_positions = [
		Vector2(100, 300),  # Left castle
		Vector2(get_viewport_rect().size.x - 100, 300)  # Right castle
	]

	for pos in flag_positions:
		var flag = _create_flag()
		flag.position = pos
		flag_container.add_child(flag)
		flags.append(flag)

func _create_flag() -> Node2D:
	var flag_node = Node2D.new()

	# Flag pole
	var pole = ColorRect.new()
	pole.color = Color(0.4, 0.3, 0.2)
	pole.size = Vector2(4, 150)
	pole.position = Vector2(-2, -150)
	flag_node.add_child(pole)

	# Flag cloth (will be animated)
	var flag = Polygon2D.new()
	flag.color = Color(0.8, 0.2, 0.2)

	# Initial flag shape
	var points = PackedVector2Array()
	for i in range(10):
		var x = i * 8.0
		var y = sin(i * 0.5) * 5.0
		points.append(Vector2(x, y - 140))
		points.append(Vector2(x, y - 100))

	flag.polygon = points
	flag_node.add_child(flag)

	# Store reference for animation
	flag_node.set_meta("flag_mesh", flag)
	flag_node.set_meta("base_points", points)

	return flag_node

func _setup_water_effect() -> void:
	# Create animated water surface
	var water_rect = ColorRect.new()
	water_rect.color = Color(0.2, 0.4, 0.6, 0.5)
	water_rect.size = Vector2(get_viewport_rect().size.x, 100)
	water_rect.position = Vector2(0, get_viewport_rect().size.y - 50)
	water_effects.add_child(water_rect)

	# Add water particles for splash effects
	var water_particles = GPUParticles2D.new()
	water_particles.emitting = false
	water_particles.amount = 30
	water_particles.lifetime = 1.0

	var water_mat = ParticleProcessMaterial.new()
	water_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	water_mat.emission_box_extents = Vector3(get_viewport_rect().size.x * 0.5, 10, 0)
	water_mat.direction = Vector2(0, -1)
	water_mat.initial_velocity_min = 20.0
	water_mat.initial_velocity_max = 50.0
	water_mat.gravity = Vector2(0, 100)
	water_mat.scale_min = 0.3
	water_mat.scale_max = 0.7
	water_mat.color = Color(0.5, 0.7, 1.0, 0.6)

	water_particles.process_material = water_mat
	water_particles.position = Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y - 50)
	water_effects.add_child(water_particles)

func _setup_ambient_particles() -> void:
	# Floating dust/pollen particles
	ambient_particles.amount = _get_ambient_particle_count()
	ambient_particles.lifetime = 10.0
	ambient_particles.preprocess = 5.0

	var ambient_mat = ParticleProcessMaterial.new()
	ambient_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ambient_mat.emission_box_extents = Vector3(
		get_viewport_rect().size.x,
		get_viewport_rect().size.y,
		0
	)
	ambient_mat.initial_velocity_min = 5.0
	ambient_mat.initial_velocity_max = 15.0
	ambient_mat.gravity = Vector2(0, -2)
	ambient_mat.scale_min = 0.2
	ambient_mat.scale_max = 0.5
	ambient_mat.color = Color(1.0, 1.0, 0.8, 0.3)

	# Add some turbulence for organic movement
	ambient_mat.turbulence_enabled = true
	ambient_mat.turbulence_noise_strength = 0.5
	ambient_mat.turbulence_noise_scale = 1.0

	ambient_particles.process_material = ambient_mat
	ambient_particles.position = Vector2.ZERO

	# Simple dot texture
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for x in range(4):
		for y in range(4):
			var dist = Vector2(x - 2, y - 2).length() / 2.0
			var alpha = max(0, 1.0 - dist)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	ambient_particles.texture = ImageTexture.create_from_image(image)
	ambient_particles.emitting = quality_level != VFXManager.QualityLevel.LOW

func _process(delta: float) -> void:
	time_accumulator += delta

	_animate_clouds(delta)
	_animate_flags(delta)
	_animate_water(delta)
	_process_weather_effects(delta)
	_update_wind(delta)

func _animate_clouds(delta: float) -> void:
	for cloud in clouds:
		var speed = cloud.get_meta("speed", 10.0)
		cloud.position.x += (speed + wind_strength * 20) * delta

		# Wrap around screen
		if cloud.position.x > get_viewport_rect().size.x + 100:
			cloud.position.x = -100

func _animate_flags(delta: float) -> void:
	for flag_node in flags:
		var flag_mesh = flag_node.get_meta("flag_mesh")
		var base_points = flag_node.get_meta("base_points")

		if flag_mesh and base_points:
			var animated_points = PackedVector2Array()

			for i in range(base_points.size()):
				var point = base_points[i]
				var wave_offset = sin(time_accumulator * flag_wave_speed + i * 0.3) * flag_wave_amplitude
				wave_offset *= (1.0 + wind_strength * 2.0)  # Wind influence

				# Add horizontal wind displacement
				var wind_offset = wind_direction.x * wind_strength * 10.0 * (i / float(base_points.size()))

				animated_points.append(Vector2(
					point.x + wind_offset,
					point.y + wave_offset
				))

			flag_mesh.polygon = animated_points

func _animate_water(delta: float) -> void:
	# Animate water surface with waves
	# This would be better with a shader, but using particles for now
	pass

func _process_weather_effects(delta: float) -> void:
	match current_weather:
		WeatherType.STORM:
			_process_lightning(delta)
		WeatherType.WINDY:
			_process_wind_gusts(delta)

func _process_lightning(delta: float) -> void:
	if lightning_cooldown > 0:
		lightning_cooldown -= delta
		return

	lightning_timer -= delta
	if lightning_timer <= 0:
		_trigger_lightning()
		lightning_timer = randf_range(3.0, 8.0)
		lightning_cooldown = 0.5

func _trigger_lightning() -> void:
	# Flash effect
	var tween = create_tween()
	lightning_overlay.color = Color(1, 1, 1, 0)

	tween.tween_property(lightning_overlay, "color:a", 0.8, 0.05)
	tween.tween_property(lightning_overlay, "color:a", 0.0, 0.1)
	tween.tween_interval(0.1)
	tween.tween_property(lightning_overlay, "color:a", 0.4, 0.05)
	tween.tween_property(lightning_overlay, "color:a", 0.0, 0.2)

	# Thunder sound would go here
	# SoundManager.play_thunder()

	# Camera shake
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.add_screen_shake(0.3, 0.5)

func _process_wind_gusts(delta: float) -> void:
	# Vary wind strength with gusts
	var target_strength = 0.5 + sin(time_accumulator * 0.5) * 0.3
	wind_strength = lerp(wind_strength, target_strength, delta * 2.0)

func _update_wind(delta: float) -> void:
	# Slowly rotate wind direction
	var angle = time_accumulator * 0.1
	wind_direction = Vector2(cos(angle), sin(angle) * 0.3).normalized()

func _apply_time_of_day() -> void:
	var light_color: Color
	var ambient_color: Color
	var fog_color: Color
	var fog_alpha: float = 0.0

	match current_time:
		TimeOfDay.DAWN:
			light_color = Color(1.0, 0.8, 0.6)
			ambient_color = Color(0.6, 0.5, 0.7)
			fog_color = Color(0.8, 0.7, 0.9)
			fog_alpha = 0.2

		TimeOfDay.DAY:
			light_color = Color(1.0, 1.0, 0.95)
			ambient_color = Color(0.7, 0.8, 0.9)
			fog_color = Color(0.9, 0.9, 1.0)
			fog_alpha = 0.0

		TimeOfDay.DUSK:
			light_color = Color(1.0, 0.7, 0.5)
			ambient_color = Color(0.5, 0.4, 0.6)
			fog_color = Color(0.9, 0.6, 0.5)
			fog_alpha = 0.15

		TimeOfDay.NIGHT:
			light_color = Color(0.6, 0.7, 0.9)
			ambient_color = Color(0.3, 0.3, 0.5)
			fog_color = Color(0.2, 0.2, 0.4)
			fog_alpha = 0.1

	# Apply colors
	modulate = light_color
	fog_layer.color = Color(fog_color.r, fog_color.g, fog_color.b, fog_alpha)

	# Update ambient particles
	if ambient_particles.process_material:
		ambient_particles.process_material.color = Color(
			ambient_color.r,
			ambient_color.g,
			ambient_color.b,
			0.3
		)

# Public API

func set_weather(weather: WeatherType, transition_time: float = 2.0) -> void:
	current_weather = weather
	weather_changed.emit(_get_weather_name(weather))

	# Stop current weather effects
	weather_particles.emitting = false

	# Configure new weather
	match weather:
		WeatherType.CLEAR:
			_set_clear_weather()
		WeatherType.RAIN:
			_set_rain_weather()
		WeatherType.SNOW:
			_set_snow_weather()
		WeatherType.FOG:
			_set_fog_weather()
		WeatherType.STORM:
			_set_storm_weather()
		WeatherType.WINDY:
			_set_windy_weather()

	# Transition fog
	var tween = create_tween()
	var target_fog_alpha = 0.0

	match weather:
		WeatherType.FOG:
			target_fog_alpha = 0.4
		WeatherType.STORM:
			target_fog_alpha = 0.2
		WeatherType.RAIN:
			target_fog_alpha = 0.1

	tween.tween_property(fog_layer, "color:a", target_fog_alpha, transition_time)

func _set_clear_weather() -> void:
	weather_particles.emitting = false
	wind_strength = 0.1

func _set_rain_weather() -> void:
	var mat = weather_particles.process_material as ParticleProcessMaterial
	mat.direction = Vector2(0.2, 1)
	mat.initial_velocity_min = 300.0
	mat.initial_velocity_max = 400.0
	mat.scale_min = 0.5
	mat.scale_max = 1.0
	mat.color = Color(0.5, 0.6, 0.7, 0.6)

	weather_particles.amount = _get_weather_particle_count(100)
	weather_particles.lifetime = 2.0

	# Rain streak texture
	var image = Image.create(2, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	weather_particles.texture = ImageTexture.create_from_image(image)

	weather_particles.emitting = true
	wind_strength = 0.3

func _set_snow_weather() -> void:
	var mat = weather_particles.process_material as ParticleProcessMaterial
	mat.direction = Vector2(0, 1)
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.angular_velocity_min = -90.0
	mat.angular_velocity_max = 90.0
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color.WHITE

	weather_particles.amount = _get_weather_particle_count(80)
	weather_particles.lifetime = 5.0

	# Snowflake texture
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length() / 4.0
			var alpha = max(0, 1.0 - dist)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	weather_particles.texture = ImageTexture.create_from_image(image)
	weather_particles.emitting = true
	wind_strength = 0.2

func _set_fog_weather() -> void:
	weather_particles.emitting = false
	wind_strength = 0.05

func _set_storm_weather() -> void:
	_set_rain_weather()  # Storm includes rain
	weather_particles.amount = _get_weather_particle_count(150)
	wind_strength = 0.5
	lightning_timer = 2.0

func _set_windy_weather() -> void:
	weather_particles.emitting = false
	wind_strength = 0.6

	# Add some dust particles
	ambient_particles.amount = _get_ambient_particle_count() * 2
	ambient_particles.emitting = true

func set_time_of_day(time: TimeOfDay, transition_time: float = 3.0) -> void:
	current_time = time
	_apply_time_of_day()
	time_of_day_changed.emit(_get_time_name(time))

func set_quality(level: VFXManager.QualityLevel) -> void:
	quality_level = level

	# Adjust particle counts
	if weather_particles.emitting:
		set_weather(current_weather, 0.0)  # Reapply with new quality

	ambient_particles.amount = _get_ambient_particle_count()
	ambient_particles.emitting = quality_level != VFXManager.QualityLevel.LOW

	# Adjust cloud count
	match quality_level:
		VFXManager.QualityLevel.LOW:
			max_clouds = 2
		VFXManager.QualityLevel.MEDIUM:
			max_clouds = 5
		VFXManager.QualityLevel.HIGH:
			max_clouds = 8

func _get_weather_particle_count(base: int) -> int:
	match quality_level:
		VFXManager.QualityLevel.LOW:
			return int(base * 0.3)
		VFXManager.QualityLevel.MEDIUM:
			return int(base * 0.7)
		VFXManager.QualityLevel.HIGH:
			return base
	return base

func _get_ambient_particle_count() -> int:
	match quality_level:
		VFXManager.QualityLevel.LOW:
			return 0
		VFXManager.QualityLevel.MEDIUM:
			return 20
		VFXManager.QualityLevel.HIGH:
			return 50
	return 20

func _get_weather_name(weather: WeatherType) -> String:
	match weather:
		WeatherType.CLEAR: return "clear"
		WeatherType.RAIN: return "rain"
		WeatherType.SNOW: return "snow"
		WeatherType.FOG: return "fog"
		WeatherType.STORM: return "storm"
		WeatherType.WINDY: return "windy"
	return "clear"

func _get_time_name(time: TimeOfDay) -> String:
	match time:
		TimeOfDay.DAWN: return "dawn"
		TimeOfDay.DAY: return "day"
		TimeOfDay.DUSK: return "dusk"
		TimeOfDay.NIGHT: return "night"
	return "day"