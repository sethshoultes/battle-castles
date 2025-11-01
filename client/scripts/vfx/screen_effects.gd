extends Node
class_name ScreenEffects

# Screen effects handler - manages camera shakes, flashes, and other visual effects
# Uses a trauma-based system for organic camera shake

signal effect_started(effect_name: String)
signal effect_ended(effect_name: String)

# Camera shake parameters
var shake_trauma: float = 0.0
var shake_max_offset: Vector2 = Vector2(30, 20)
var shake_max_rotation: float = 0.05  # In radians
var shake_decay_rate: float = 2.0  # How fast trauma decreases
var shake_noise_speed: float = 30.0  # Speed of noise sampling

# Noise for smooth random shake
var noise_x: FastNoiseLite
var noise_y: FastNoiseLite
var noise_r: FastNoiseLite
var noise_time: float = 0.0

# References
var camera: Camera2D
var flash_overlay: ColorRect
var vignette_overlay: TextureRect

# Flash effect
var flash_tween: Tween
var is_flashing: bool = false

# Freeze frame
var freeze_timer: float = 0.0
var freeze_duration: float = 0.0
var is_frozen: bool = false
var cached_time_scale: float = 1.0

# Slow motion
var slow_motion_tween: Tween
var is_slow_motion: bool = false
var base_time_scale: float = 1.0

# Chromatic aberration (color split effect)
var chromatic_aberration_shader: Shader
var chromatic_aberration_amount: float = 0.0

# Screen transitions
var transition_overlay: ColorRect
var transition_tween: Tween

# Zoom effects
var zoom_tween: Tween
var base_zoom: Vector2 = Vector2.ONE

# Quality settings
var quality_level: VFXManager.QualityLevel = VFXManager.QualityLevel.MEDIUM

func _ready() -> void:
	set_process(true)
	_setup_noise()
	_setup_overlays()
	_find_camera()

func _setup_noise() -> void:
	# Create different noise generators for each axis
	noise_x = FastNoiseLite.new()
	noise_x.seed = randi()
	noise_x.frequency = 0.1
	noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise_y = FastNoiseLite.new()
	noise_y.seed = randi()
	noise_y.frequency = 0.1
	noise_y.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise_r = FastNoiseLite.new()
	noise_r.seed = randi()
	noise_r.frequency = 0.15
	noise_r.noise_type = FastNoiseLite.TYPE_SIMPLEX

func _setup_overlays() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer for UI overlays
	add_child(canvas_layer)

	# Flash overlay
	flash_overlay = ColorRect.new()
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash_overlay)

	# Transition overlay
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 101
	canvas_layer.add_child(transition_overlay)

	# Vignette overlay
	vignette_overlay = TextureRect.new()
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vignette_overlay.modulate = Color(1, 1, 1, 0)
	canvas_layer.add_child(vignette_overlay)

	# Create vignette texture
	_create_vignette_texture()

func _create_vignette_texture() -> void:
	var size = 512
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / max_dist
			dist = clamp(dist, 0.0, 1.0)

			# Smooth gradient from center to edges
			var alpha = smoothstep(0.3, 1.0, dist)
			image.set_pixel(x, y, Color(0, 0, 0, alpha))

	var texture = ImageTexture.create_from_image(image)
	vignette_overlay.texture = texture

func _find_camera() -> void:
	# Try to find the main camera
	var viewport = get_viewport()
	if viewport:
		camera = viewport.get_camera_2d()

func _process(delta: float) -> void:
	if not camera:
		_find_camera()
		return

	_process_shake(delta)
	_process_freeze_frame(delta)

func _process_shake(delta: float) -> void:
	if shake_trauma > 0:
		# Decay trauma over time
		shake_trauma = max(shake_trauma - shake_decay_rate * delta, 0)

		# Calculate shake intensity (squared for better feel)
		var shake_amount = pow(shake_trauma, 2)

		# Update noise sampling time
		noise_time += delta * shake_noise_speed

		# Sample noise for smooth random movement
		var offset_x = shake_max_offset.x * shake_amount * noise_x.get_noise_1d(noise_time)
		var offset_y = shake_max_offset.y * shake_amount * noise_y.get_noise_1d(noise_time)
		var rotation = shake_max_rotation * shake_amount * noise_r.get_noise_1d(noise_time)

		# Apply to camera
		camera.offset = Vector2(offset_x, offset_y)
		camera.rotation = rotation

		# Add slight zoom pulse for big shakes
		if shake_amount > 0.5 and quality_level != VFXManager.QualityLevel.LOW:
			var zoom_factor = 1.0 - (shake_amount * 0.05)
			camera.zoom = base_zoom * zoom_factor
	else:
		# Reset camera when not shaking
		if camera.offset != Vector2.ZERO:
			camera.offset = camera.offset.lerp(Vector2.ZERO, delta * 10.0)
		if camera.rotation != 0:
			camera.rotation = lerp(camera.rotation, 0.0, delta * 10.0)
		if camera.zoom != base_zoom:
			camera.zoom = camera.zoom.lerp(base_zoom, delta * 10.0)

func _process_freeze_frame(delta: float) -> void:
	if freeze_timer > 0:
		freeze_timer -= delta
		if freeze_timer <= 0:
			_end_freeze_frame()

# Public API

func add_trauma(amount: float) -> void:
	shake_trauma = min(shake_trauma + amount, 1.0)
	effect_started.emit("shake")

func shake(intensity: float = 0.5, duration: float = 0.5) -> void:
	add_trauma(intensity)

	# Optional: schedule trauma boost for sustained shake
	if duration > 0.1:
		var timer = Timer.new()
		timer.wait_time = duration * 0.5
		timer.one_shot = true
		timer.timeout.connect(func(): add_trauma(intensity * 0.3))
		add_child(timer)
		timer.start()

func flash(color: Color = Color.WHITE, duration: float = 0.1, intensity: float = 0.8) -> void:
	if is_flashing:
		return

	is_flashing = true
	effect_started.emit("flash")

	# Kill existing tween if any
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	# Create new flash tween
	flash_tween = create_tween()
	flash_tween.set_trans(Tween.TRANS_CUBIC)

	# Flash in
	flash_overlay.color = Color(color.r, color.g, color.b, 0)
	flash_tween.tween_property(flash_overlay, "color:a", intensity, duration * 0.3)

	# Flash out
	flash_tween.tween_property(flash_overlay, "color:a", 0.0, duration * 0.7)

	# Reset flag
	flash_tween.tween_callback(func():
		is_flashing = false
		effect_ended.emit("flash")
	)

func freeze_frame(duration: float = 0.05) -> void:
	if is_frozen:
		return

	is_frozen = true
	freeze_duration = duration
	freeze_timer = duration

	# Store current time scale and pause
	cached_time_scale = Engine.time_scale
	Engine.time_scale = 0.001  # Near-pause but not complete pause

	effect_started.emit("freeze_frame")

func _end_freeze_frame() -> void:
	if not is_frozen:
		return

	is_frozen = false
	Engine.time_scale = cached_time_scale
	effect_ended.emit("freeze_frame")

func slow_motion(time_scale: float = 0.3, duration: float = 1.0) -> void:
	if is_slow_motion:
		return

	is_slow_motion = true
	base_time_scale = Engine.time_scale

	effect_started.emit("slow_motion")

	# Kill existing tween if any
	if slow_motion_tween and slow_motion_tween.is_valid():
		slow_motion_tween.kill()

	# Create smooth time scale transition
	slow_motion_tween = create_tween()
	slow_motion_tween.set_trans(Tween.TRANS_CUBIC)
	slow_motion_tween.set_ease(Tween.EASE_IN_OUT)

	# Slow down
	slow_motion_tween.tween_property(Engine, "time_scale", time_scale, 0.2)

	# Wait
	slow_motion_tween.tween_interval(duration)

	# Speed up
	slow_motion_tween.tween_property(Engine, "time_scale", base_time_scale, 0.3)

	# Reset flag
	slow_motion_tween.tween_callback(func():
		is_slow_motion = false
		effect_ended.emit("slow_motion")
	)

func zoom_punch(zoom_amount: float = 0.2, duration: float = 0.3) -> void:
	if not camera:
		return

	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_trans(Tween.TRANS_BACK)
	zoom_tween.set_ease(Tween.EASE_OUT)

	var target_zoom = base_zoom * (1.0 + zoom_amount)

	# Zoom in
	zoom_tween.tween_property(camera, "zoom", target_zoom, duration * 0.3)

	# Zoom back
	zoom_tween.set_trans(Tween.TRANS_CUBIC)
	zoom_tween.tween_property(camera, "zoom", base_zoom, duration * 0.7)

func vignette_fade(intensity: float = 0.5, duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_property(vignette_overlay, "modulate:a", intensity, duration)

func fade_to_black(duration: float = 1.0, stay_duration: float = 0.0) -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	transition_tween = create_tween()

	# Fade in
	transition_tween.tween_property(transition_overlay, "color:a", 1.0, duration)

	# Stay
	if stay_duration > 0:
		transition_tween.tween_interval(stay_duration)

func fade_from_black(duration: float = 1.0) -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "color:a", 0.0, duration)

func radial_blur(center: Vector2, strength: float = 0.5, duration: float = 0.5) -> void:
	# This would require a custom shader
	# For now, just do a zoom punch as placeholder
	zoom_punch(strength * 0.3, duration)

func chromatic_aberration(amount: float = 5.0, duration: float = 0.2) -> void:
	# This requires a shader effect
	# As a fallback, do a color flash
	flash(Color(1.0, 0.5, 0.5), duration, 0.3)

func set_quality(level: VFXManager.QualityLevel) -> void:
	quality_level = level

	# Adjust effect parameters based on quality
	match quality_level:
		VFXManager.QualityLevel.LOW:
			shake_noise_speed = 20.0
			# Disable some effects
			vignette_overlay.visible = false

		VFXManager.QualityLevel.MEDIUM:
			shake_noise_speed = 30.0
			vignette_overlay.visible = true

		VFXManager.QualityLevel.HIGH:
			shake_noise_speed = 40.0
			vignette_overlay.visible = true

# Combo effects

func impact_effect(intensity: float = 0.5) -> void:
	# Combine multiple effects for impact
	shake(intensity * 0.8, 0.3)
	flash(Color.WHITE, 0.1, intensity * 0.5)

	if intensity > 0.7:
		freeze_frame(0.03)

func explosion_effect(intensity: float = 1.0) -> void:
	shake(intensity, 0.5)
	flash(Color(1.0, 0.7, 0.0), 0.2, intensity * 0.7)
	zoom_punch(intensity * 0.15, 0.4)

	if intensity > 0.8:
		freeze_frame(0.05)

func victory_effect() -> void:
	slow_motion(0.5, 2.0)
	vignette_fade(0.3, 1.0)
	flash(Color(1.0, 0.9, 0.0), 0.5, 0.5)

func death_effect() -> void:
	slow_motion(0.3, 0.5)
	flash(Color(0.8, 0.0, 0.0), 0.3, 0.6)
	vignette_fade(0.7, 0.5)

	# Fade to black after delay
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): fade_to_black(1.0))
	add_child(timer)
	timer.start()

func critical_hit_effect() -> void:
	freeze_frame(0.05)
	zoom_punch(0.3, 0.3)
	flash(Color(1.0, 0.0, 0.0), 0.15, 0.8)
	shake(0.7, 0.4)