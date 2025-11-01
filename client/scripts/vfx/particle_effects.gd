extends Node
class_name ParticleEffects

# Common particle effect definitions and utilities
# This class provides preset configurations for various particle effects

# Effect presets with configurable parameters
const EFFECT_PRESETS = {
	"sparkle": {
		"amount": 20,
		"lifetime": 1.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 50.0,
		"velocity_max": 150.0,
		"scale_min": 0.3,
		"scale_max": 0.8,
		"color": Color(1.0, 1.0, 0.5, 1.0),
		"gravity": Vector2.ZERO
	},
	"smoke": {
		"amount": 30,
		"lifetime": 2.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 20.0,
		"velocity_max": 50.0,
		"scale_min": 1.0,
		"scale_max": 2.0,
		"color": Color(0.3, 0.3, 0.3, 0.7),
		"gravity": Vector2(0, -50),
		"damping": 2.0
	},
	"fire": {
		"amount": 40,
		"lifetime": 1.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 50.0,
		"velocity_max": 100.0,
		"scale_min": 0.5,
		"scale_max": 1.5,
		"color": Color(1.0, 0.5, 0.0, 1.0),
		"gravity": Vector2(0, -100)
	},
	"blood": {
		"amount": 15,
		"lifetime": 1.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
		"velocity_min": 100.0,
		"velocity_max": 300.0,
		"scale_min": 0.5,
		"scale_max": 1.0,
		"color": Color(0.8, 0.1, 0.1, 1.0),
		"gravity": Vector2(0, 500),
		"damping": 1.0
	},
	"magic": {
		"amount": 25,
		"lifetime": 1.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_RING,
		"velocity_min": 30.0,
		"velocity_max": 80.0,
		"scale_min": 0.4,
		"scale_max": 0.8,
		"color": Color(0.5, 0.3, 1.0, 0.8),
		"gravity": Vector2(0, -30),
		"orbit_velocity": 2.0
	},
	"dust": {
		"amount": 20,
		"lifetime": 2.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"velocity_min": 10.0,
		"velocity_max": 30.0,
		"scale_min": 0.5,
		"scale_max": 1.0,
		"color": Color(0.6, 0.5, 0.4, 0.6),
		"gravity": Vector2(0, 20),
		"damping": 3.0
	},
	"electric": {
		"amount": 15,
		"lifetime": 0.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 100.0,
		"velocity_max": 400.0,
		"scale_min": 0.2,
		"scale_max": 0.5,
		"color": Color(0.7, 0.9, 1.0, 1.0),
		"gravity": Vector2.ZERO,
		"angular_velocity": 720.0
	},
	"poison": {
		"amount": 20,
		"lifetime": 2.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 20.0,
		"velocity_max": 60.0,
		"scale_min": 0.4,
		"scale_max": 1.0,
		"color": Color(0.2, 0.8, 0.2, 0.8),
		"gravity": Vector2(0, -40),
		"damping": 1.5
	},
	"ice": {
		"amount": 25,
		"lifetime": 1.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"velocity_min": 50.0,
		"velocity_max": 150.0,
		"scale_min": 0.3,
		"scale_max": 0.7,
		"color": Color(0.8, 0.9, 1.0, 0.9),
		"gravity": Vector2(0, 100),
		"angular_velocity": 360.0
	},
	"coin": {
		"amount": 10,
		"lifetime": 2.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
		"velocity_min": 100.0,
		"velocity_max": 250.0,
		"scale_min": 0.8,
		"scale_max": 1.2,
		"color": Color(1.0, 0.84, 0.0, 1.0),
		"gravity": Vector2(0, 300),
		"angular_velocity": 540.0,
		"damping": 0.5
	}
}

# Create a configured GPUParticles2D node from preset
static func create_from_preset(preset_name: String, override_params: Dictionary = {}) -> GPUParticles2D:
	if not EFFECT_PRESETS.has(preset_name):
		push_warning("Unknown particle preset: " + preset_name)
		return null

	var preset = EFFECT_PRESETS[preset_name].duplicate()

	# Apply overrides
	for key in override_params:
		preset[key] = override_params[key]

	return _create_particles_from_config(preset)

# Create custom particle effect with specific configuration
static func create_custom(config: Dictionary) -> GPUParticles2D:
	return _create_particles_from_config(config)

static func _create_particles_from_config(config: Dictionary) -> GPUParticles2D:
	var particles = GPUParticles2D.new()

	# Basic properties
	particles.emitting = false
	particles.amount = config.get("amount", 20)
	particles.lifetime = config.get("lifetime", 1.0)
	particles.one_shot = config.get("one_shot", true)
	particles.preprocess = config.get("preprocess", 0.0)
	particles.speed_scale = config.get("speed_scale", 1.0)
	particles.explosiveness = config.get("explosiveness", 1.0)
	particles.randomness = config.get("randomness", 0.0)
	particles.fixed_fps = config.get("fixed_fps", 0)
	particles.interpolate = config.get("interpolate", true)

	# Create and configure process material
	var material = ParticleProcessMaterial.new()

	# Emission shape
	material.emission_shape = config.get("emission_shape", ParticleProcessMaterial.EMISSION_SHAPE_POINT)

	if material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
		material.emission_sphere_radius = config.get("emission_sphere_radius", 10.0)
	elif material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_BOX:
		material.emission_box_extents = config.get("emission_box_extents", Vector3(50, 50, 0))
	elif material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_RING:
		material.emission_ring_radius = config.get("emission_ring_radius", 30.0)
		material.emission_ring_inner_radius = config.get("emission_ring_inner_radius", 20.0)
		material.emission_ring_height = config.get("emission_ring_height", 0.0)

	# Direction and spread
	material.direction = config.get("direction", Vector2(0, -1))
	material.spread = config.get("spread", 45.0)

	# Velocity
	material.initial_velocity_min = config.get("velocity_min", 50.0)
	material.initial_velocity_max = config.get("velocity_max", 100.0)

	# Angular velocity
	if config.has("angular_velocity"):
		material.angular_velocity_min = -config["angular_velocity"]
		material.angular_velocity_max = config["angular_velocity"]
	else:
		material.angular_velocity_min = config.get("angular_velocity_min", 0.0)
		material.angular_velocity_max = config.get("angular_velocity_max", 0.0)

	# Orbit velocity
	if config.has("orbit_velocity"):
		material.orbit_velocity_min = config["orbit_velocity"]
		material.orbit_velocity_max = config["orbit_velocity"]

	# Forces
	material.gravity = config.get("gravity", Vector2(0, 98))

	# Damping
	if config.has("damping"):
		material.damping_min = config["damping"]
		material.damping_max = config["damping"]
	else:
		material.damping_min = config.get("damping_min", 0.0)
		material.damping_max = config.get("damping_max", 0.0)

	# Scale
	material.scale_min = config.get("scale_min", 1.0)
	material.scale_max = config.get("scale_max", 1.0)

	# Scale curve for size over lifetime
	if config.has("scale_curve"):
		material.scale_curve = config["scale_curve"]

	# Color
	material.color = config.get("color", Color.WHITE)

	# Color gradients
	if config.has("color_ramp"):
		material.color_ramp = config["color_ramp"]

	# Hue variation for randomized colors
	if config.has("hue_variation"):
		material.hue_variation_min = -config["hue_variation"]
		material.hue_variation_max = config["hue_variation"]

	# Animation
	if config.has("anim_speed"):
		material.anim_speed_min = config["anim_speed"]
		material.anim_speed_max = config["anim_speed"]

	if config.has("anim_offset"):
		material.anim_offset_min = 0.0
		material.anim_offset_max = config["anim_offset"]

	# Turbulence (for more organic movement)
	if config.has("turbulence_enabled") and config["turbulence_enabled"]:
		material.turbulence_enabled = true
		material.turbulence_noise_strength = config.get("turbulence_strength", 1.0)
		material.turbulence_noise_scale = config.get("turbulence_scale", 1.0)
		material.turbulence_noise_speed = Vector2(config.get("turbulence_speed", 0.5), config.get("turbulence_speed", 0.5))

	particles.process_material = material

	# Texture
	var texture = config.get("texture", null)
	if texture == null:
		# Create default circular texture
		particles.texture = _create_default_texture(config.get("texture_type", "circle"))
	else:
		particles.texture = texture

	return particles

static func _create_default_texture(type: String = "circle") -> Texture2D:
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	match type:
		"circle":
			_draw_circle(image, size)
		"square":
			image.fill(Color.WHITE)
		"star":
			_draw_star(image, size)
		"diamond":
			_draw_diamond(image, size)
		"glow":
			_draw_glow(image, size)
		_:
			_draw_circle(image, size)

	return ImageTexture.create_from_image(image)

static func _draw_circle(image: Image, size: int) -> void:
	var center = size / 2.0
	var radius = size / 2.0 - 1

	for x in range(size):
		for y in range(size):
			var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))
			if dist <= radius:
				var alpha = 1.0 - (dist / radius) * 0.3  # Soft edges
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

static func _draw_star(image: Image, size: int) -> void:
	var center = Vector2(size / 2.0, size / 2.0)
	var points = []

	# Create star points (5-pointed star)
	for i in range(10):
		var angle = (PI * 2.0 / 10.0) * i - PI / 2.0
		var radius = (size / 2.0 - 2) if i % 2 == 0 else (size / 4.0)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

	# Simple fill (not perfect but functional)
	image.fill(Color(0, 0, 0, 0))
	for x in range(size):
		for y in range(size):
			if _point_in_star(Vector2(x, y), center, size / 2.0 - 2):
				image.set_pixel(x, y, Color.WHITE)

static func _point_in_star(point: Vector2, center: Vector2, radius: float) -> bool:
	# Simplified star check using distance and angle
	var dist = point.distance_to(center)
	if dist > radius:
		return false

	var angle = atan2(point.y - center.y, point.x - center.x)
	var segment = int((angle + PI) / (PI * 2.0 / 5.0))
	var segment_angle = (PI * 2.0 / 5.0) * segment - PI
	var next_angle = segment_angle + (PI * 2.0 / 5.0)

	var inner_radius = radius * 0.5
	var angle_factor = abs(angle - (segment_angle + next_angle) * 0.5) / (PI * 2.0 / 10.0)
	var max_dist = lerp(inner_radius, radius, 1.0 - angle_factor)

	return dist <= max_dist

static func _draw_diamond(image: Image, size: int) -> void:
	var center = size / 2.0

	for x in range(size):
		for y in range(size):
			var dist_x = abs(x - center)
			var dist_y = abs(y - center)
			if dist_x + dist_y <= center - 1:
				var alpha = 1.0 - ((dist_x + dist_y) / center) * 0.3
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

static func _draw_glow(image: Image, size: int) -> void:
	var center = size / 2.0
	var radius = size / 2.0

	for x in range(size):
		for y in range(size):
			var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))
			var alpha = max(0.0, 1.0 - (dist / radius))
			alpha = pow(alpha, 2.0)  # Exponential falloff for glow effect
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

# Utility functions for creating specific effect types

static func create_unit_deploy_effect() -> GPUParticles2D:
	return create_from_preset("sparkle", {
		"amount": 30,
		"lifetime": 0.8,
		"explosiveness": 1.0,
		"color": Color(1.0, 0.9, 0.3, 1.0)
	})

static func create_impact_effect(damage_type: String = "physical") -> GPUParticles2D:
	var color = Color.WHITE

	match damage_type:
		"physical":
			color = Color(1.0, 0.5, 0.0, 1.0)
		"magic":
			color = Color(0.5, 0.3, 1.0, 1.0)
		"fire":
			color = Color(1.0, 0.3, 0.0, 1.0)
		"ice":
			color = Color(0.7, 0.9, 1.0, 1.0)
		"electric":
			color = Color(1.0, 1.0, 0.0, 1.0)
		"poison":
			color = Color(0.3, 0.9, 0.1, 1.0)

	return create_from_preset("blood" if damage_type == "physical" else "magic", {
		"color": color,
		"amount": 20
	})

static func create_death_effect(unit_type: String = "normal") -> GPUParticles2D:
	var preset = "explosion" if unit_type == "normal" else "magic"
	var amount = 50 if unit_type == "boss" else 30

	return create_custom({
		"amount": amount,
		"lifetime": 1.2,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 20.0,
		"velocity_min": 100.0,
		"velocity_max": 300.0,
		"scale_min": 0.5,
		"scale_max": 2.0,
		"color": Color(1.0, 0.3, 0.0, 1.0),
		"gravity": Vector2(0, 300),
		"damping": 2.0,
		"texture_type": "circle"
	})

static func create_tower_destruction_effect() -> GPUParticles2D:
	return create_custom({
		"amount": 100,
		"lifetime": 2.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 50.0,
		"velocity_min": 200.0,
		"velocity_max": 500.0,
		"scale_min": 1.0,
		"scale_max": 3.0,
		"color": Color(1.0, 0.4, 0.0, 1.0),
		"gravity": Vector2(0, 500),
		"damping": 3.0,
		"spread": 180.0,
		"texture_type": "square"  # Debris pieces
	})

static func create_victory_confetti() -> GPUParticles2D:
	return create_custom({
		"amount": 200,
		"lifetime": 4.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(400, 10, 0),
		"direction": Vector2(0, 1),
		"spread": 30.0,
		"velocity_min": 200.0,
		"velocity_max": 500.0,
		"scale_min": 0.5,
		"scale_max": 1.5,
		"gravity": Vector2(0, 300),
		"angular_velocity": 720.0,
		"hue_variation": 1.0,
		"texture_type": "diamond",
		"one_shot": true,
		"explosiveness": 1.0
	})

static func create_arrow_trail() -> GPUParticles2D:
	return create_custom({
		"amount": 20,
		"lifetime": 0.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
		"velocity_min": 0.0,
		"velocity_max": 20.0,
		"scale_min": 0.3,
		"scale_max": 0.6,
		"color": Color(0.5, 0.8, 1.0, 0.6),
		"gravity": Vector2.ZERO,
		"one_shot": false,
		"texture_type": "glow"
	})

static func create_heal_effect() -> GPUParticles2D:
	return create_custom({
		"amount": 25,
		"lifetime": 1.5,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_RING,
		"emission_ring_radius": 30.0,
		"emission_ring_inner_radius": 20.0,
		"direction": Vector2(0, -1),
		"velocity_min": 30.0,
		"velocity_max": 80.0,
		"scale_min": 0.5,
		"scale_max": 1.0,
		"color": Color(0.2, 1.0, 0.3, 0.8),
		"gravity": Vector2(0, -50),
		"texture_type": "star",
		"angular_velocity": 180.0
	})