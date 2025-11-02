## Game "Juice" Manager - Adds polish and visual feedback to all interactions
## Makes the game feel responsive and satisfying
## Add to Project Settings -> Autoload as "JuiceManager"
extends Node

## Screen shake settings
var screen_shake_enabled: bool = true
var shake_trauma: float = 0.0
var shake_decay: float = 2.0
var max_shake_offset: float = 20.0
var max_shake_rotation: float = 5.0

## Camera reference for shake
var camera: Camera2D = null

## Particle pools
var particle_pools: Dictionary = {}
var max_particles: int = 100

## Tween pools for effects
var active_tweens: Array[Tween] = []

## Hitstop settings
var hitstop_enabled: bool = true
var hitstop_duration: float = 0.05

## Feedback settings
var haptic_enabled: bool = true
var juice_intensity: float = 1.0  # 0.0 to 1.0 multiplier


func _ready() -> void:
	set_process(true)
	print("JuiceManager initialized")


func _process(delta: float) -> void:
	# Update screen shake
	if shake_trauma > 0.0:
		shake_trauma = max(shake_trauma - shake_decay * delta, 0.0)
		_apply_screen_shake()


## Adds screen shake
func add_screen_shake(intensity: float = 0.5) -> void:
	if not screen_shake_enabled:
		return

	shake_trauma = min(shake_trauma + intensity * juice_intensity, 1.0)


## Applies screen shake to camera
func _apply_screen_shake() -> void:
	if not camera:
		_find_camera()
		if not camera:
			return

	var shake_amount: float = shake_trauma * shake_trauma
	var offset_x: float = randf_range(-max_shake_offset, max_shake_offset) * shake_amount
	var offset_y: float = randf_range(-max_shake_offset, max_shake_offset) * shake_amount
	var rotation: float = randf_range(-max_shake_rotation, max_shake_rotation) * shake_amount

	camera.offset = Vector2(offset_x, offset_y)
	camera.rotation_degrees = rotation


## Finds active camera
func _find_camera() -> void:
	var viewport := get_viewport()
	if viewport:
		camera = viewport.get_camera_2d()


## Sets camera for screen shake
func set_camera(cam: Camera2D) -> void:
	camera = cam


## Creates a hit flash effect on a node
func hit_flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.1) -> void:
	if not node:
		return

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# Flash white
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, duration)

	active_tweens.append(tween)
	_cleanup_finished_tweens()


## Creates a damage number popup
func damage_popup(position: Vector2, damage: int, critical: bool = false) -> void:
	var label := Label.new()
	label.text = str(damage)
	label.position = position

	# Style the label
	if critical:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color.ORANGE_RED)
	else:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)

	# Add outline
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	get_tree().root.add_child(label)

	# Animate popup
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)

	var target_pos := position + Vector2(0, -100)
	tween.tween_property(label, "position", target_pos, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	await tween.finished
	label.queue_free()


## Creates a healing number popup
func healing_popup(position: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = "+" + str(amount)
	label.position = position
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	get_tree().root.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)

	var target_pos := position + Vector2(0, -80)
	tween.tween_property(label, "position", target_pos, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)

	await tween.finished
	label.queue_free()


## Squash and stretch animation
func squash_stretch(node: CanvasItem, intensity: float = 1.2, duration: float = 0.2) -> void:
	if not node:
		return

	var original_scale: Vector2 = node.scale

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# Squash
	var squash_scale := Vector2(intensity, 1.0 / intensity)
	tween.tween_property(node, "scale", original_scale * squash_scale, duration * 0.3)

	# Back to normal with overshoot
	tween.tween_property(node, "scale", original_scale, duration * 0.7)

	active_tweens.append(tween)


## Bounce animation
func bounce(node: CanvasItem, height: float = 20.0, bounces: int = 2, duration: float = 0.5) -> void:
	if not node:
		return

	var original_y: float = node.position.y

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)

	for i in bounces:
		var bounce_height := height * (1.0 - float(i) / bounces)
		tween.tween_property(node, "position:y", original_y - bounce_height, duration / (bounces * 2))
		tween.tween_property(node, "position:y", original_y, duration / (bounces * 2))

	active_tweens.append(tween)


## Pulse animation (for emphasis)
func pulse(node: CanvasItem, scale_multiplier: float = 1.2, duration: float = 0.3, loops: int = 1) -> void:
	if not node:
		return

	var original_scale: Vector2 = node.scale
	var target_scale: Vector2 = original_scale * scale_multiplier

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops(loops)

	tween.tween_property(node, "scale", target_scale, duration * 0.5)
	tween.tween_property(node, "scale", original_scale, duration * 0.5)

	active_tweens.append(tween)


## Shake a specific node
func shake_node(node: CanvasItem, intensity: float = 10.0, duration: float = 0.3) -> void:
	if not node:
		return

	var original_pos: Vector2 = node.position
	var shake_count := int(duration * 60)  # Shake at 60fps

	var tween := create_tween()

	for i in shake_count:
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		var shake_duration := duration / shake_count
		tween.tween_property(node, "position", original_pos + offset, shake_duration)

	tween.tween_property(node, "position", original_pos, duration * 0.1)

	active_tweens.append(tween)


## Pop-in animation (for spawning)
func pop_in(node: CanvasItem, duration: float = 0.3) -> void:
	if not node:
		return

	var original_scale: Vector2 = node.scale
	node.scale = Vector2.ZERO

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(node, "scale", original_scale, duration)

	active_tweens.append(tween)


## Pop-out animation (for destruction)
func pop_out(node: CanvasItem, duration: float = 0.2) -> void:
	if not node:
		return

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)

	tween.tween_property(node, "scale", Vector2.ZERO, duration)
	tween.tween_property(node, "modulate:a", 0.0, duration)

	await tween.finished
	node.queue_free()


## Fade in animation
func fade_in(node: CanvasItem, duration: float = 0.3) -> void:
	if not node:
		return

	node.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)

	active_tweens.append(tween)


## Fade out animation
func fade_out(node: CanvasItem, duration: float = 0.3, destroy: bool = false) -> void:
	if not node:
		return

	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)

	if destroy:
		await tween.finished
		node.queue_free()
	else:
		active_tweens.append(tween)


## Slide in from direction
func slide_in(node: Control, from: Vector2, duration: float = 0.3) -> void:
	if not node:
		return

	var original_pos: Vector2 = node.position
	node.position = from

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(node, "position", original_pos, duration)

	active_tweens.append(tween)


## Impact effect (combines shake, flash, and hitstop)
func impact(node: CanvasItem, intensity: float = 1.0) -> void:
	if not node:
		return

	var scaled_intensity := intensity * juice_intensity

	# Screen shake
	add_screen_shake(0.3 * scaled_intensity)

	# Hit flash
	if node is CanvasItem:
		hit_flash(node, Color.WHITE, 0.1)

	# Squash on impact
	squash_stretch(node, 1.0 + 0.2 * scaled_intensity, 0.15)

	# Hitstop
	if hitstop_enabled and scaled_intensity > 0.5:
		hitstop(hitstop_duration * scaled_intensity)

	# Haptic feedback
	if haptic_enabled:
		Input.vibrate_handheld(int(50 * scaled_intensity))


## Brief pause (hitstop) for impact feel
func hitstop(duration: float) -> void:
	if not hitstop_enabled:
		return

	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


## UI button press effect
func button_press(button: Control) -> void:
	if not button:
		return

	squash_stretch(button, 0.9, 0.1)

	# Play click sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")


## UI button hover effect
func button_hover(button: Control) -> void:
	if not button:
		return

	pulse(button, 1.05, 0.2, 1)

	# Play hover sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_hover")


## Card selection effect
func card_selected(card: Control) -> void:
	if not card:
		return

	# Pop and glow
	pop_in(card, 0.2)
	pulse(card, 1.1, 0.3, 2)

	# Play card sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("card_select")


## Deployment success effect
func deployment_success(position: Vector2) -> void:
	add_screen_shake(0.2)

	# Spawn visual effect
	if has_node("/root/VFXManager"):
		var vfx_manager = get_node("/root/VFXManager")
		if vfx_manager.has_method("spawn_effect"):
			vfx_manager.spawn_effect("deploy", position)

	# Play deploy sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("unit_deploy")


## Victory celebration effect
func victory_celebration() -> void:
	add_screen_shake(1.0)

	# Massive particles
	if has_node("/root/VFXManager"):
		var vfx_manager = get_node("/root/VFXManager")
		if vfx_manager.has_method("spawn_effect"):
			vfx_manager.spawn_effect("victory", get_viewport().get_visible_rect().size / 2)

	# Play victory sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("victory")


## Defeat effect
func defeat_effect() -> void:
	# Slow motion
	Engine.time_scale = 0.5
	await get_tree().create_timer(1.0, true, false, true).timeout
	Engine.time_scale = 1.0

	# Play defeat sound
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("defeat")


## Cleans up finished tweens
func _cleanup_finished_tweens() -> void:
	for i in range(active_tweens.size() - 1, -1, -1):
		var tween: Tween = active_tweens[i]
		if not tween.is_valid() or not tween.is_running():
			active_tweens.remove_at(i)


## Sets juice intensity (for accessibility)
func set_juice_intensity(intensity: float) -> void:
	juice_intensity = clamp(intensity, 0.0, 1.0)


## Enables/disables screen shake
func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	if not enabled and camera:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0


## Enables/disables hitstop
func set_hitstop_enabled(enabled: bool) -> void:
	hitstop_enabled = enabled


## Enables/disables haptic feedback
func set_haptic_enabled(enabled: bool) -> void:
	haptic_enabled = enabled
