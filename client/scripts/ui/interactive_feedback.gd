## Interactive Feedback Component
## Attach to any UI element to add automatic visual feedback
## Works with buttons, cards, and any interactive Control nodes
extends Control

## Feedback settings
@export var enable_hover: bool = true
@export var enable_press: bool = true
@export var enable_particles: bool = false
@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95
@export var transition_duration: float = 0.15

## Visual effects
@export var glow_on_hover: bool = true
@export var glow_color: Color = Color(1.0, 1.0, 1.0, 0.3)

## Audio feedback
@export var play_hover_sound: bool = true
@export var play_click_sound: bool = true
@export var hover_sound: String = "ui_hover"
@export var click_sound: String = "ui_click"

## State
var is_hovered: bool = false
var is_pressed: bool = false
var original_scale: Vector2 = Vector2.ONE
var original_modulate: Color = Color.WHITE

## References
var juice_manager: Node = null
var audio_manager: Node = null
var glow_overlay: ColorRect = null


func _ready() -> void:
	# Store original values
	original_scale = scale
	original_modulate = modulate

	# Get manager references
	if has_node("/root/JuiceManager"):
		juice_manager = get_node("/root/JuiceManager")
	if has_node("/root/AudioManager"):
		audio_manager = get_node("/root/AudioManager")

	# Create glow overlay if needed
	if glow_on_hover:
		_create_glow_overlay()

	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Connect button signals if this is a button
	if self is BaseButton:
		var button := self as BaseButton
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
		button.pressed.connect(_on_pressed)


## Creates glow overlay
func _create_glow_overlay() -> void:
	glow_overlay = ColorRect.new()
	glow_overlay.name = "GlowOverlay"
	glow_overlay.color = glow_color
	glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_overlay.modulate.a = 0.0
	add_child(glow_overlay)
	move_child(glow_overlay, 0)  # Behind other children


## Mouse enter handler
func _on_mouse_entered() -> void:
	if not enable_hover:
		return

	is_hovered = true

	# Scale up
	_animate_scale(original_scale * hover_scale)

	# Show glow
	if glow_overlay:
		_animate_glow(1.0)

	# Play hover sound
	if play_hover_sound and audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(hover_sound)

	# Use juice manager effect
	if juice_manager and juice_manager.has_method("button_hover"):
		juice_manager.button_hover(self)


## Mouse exit handler
func _on_mouse_exited() -> void:
	if not enable_hover:
		return

	is_hovered = false

	# Scale back to normal
	_animate_scale(original_scale)

	# Hide glow
	if glow_overlay:
		_animate_glow(0.0)


## Button down handler
func _on_button_down() -> void:
	if not enable_press:
		return

	is_pressed = true

	# Scale down
	_animate_scale(original_scale * press_scale)


## Button up handler
func _on_button_up() -> void:
	if not enable_press:
		return

	is_pressed = false

	# Scale back
	if is_hovered:
		_animate_scale(original_scale * hover_scale)
	else:
		_animate_scale(original_scale)


## Button pressed handler (actual click)
func _on_pressed() -> void:
	# Play click sound
	if play_click_sound and audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(click_sound)

	# Use juice manager effect
	if juice_manager and juice_manager.has_method("button_press"):
		juice_manager.button_press(self)

	# Spawn particles
	if enable_particles:
		_spawn_click_particles()


## Animates scale change
func _animate_scale(target_scale: Vector2) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", target_scale, transition_duration)


## Animates glow opacity
func _animate_glow(target_alpha: float) -> void:
	if not glow_overlay:
		return

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(glow_overlay, "modulate:a", target_alpha, transition_duration)


## Spawns click particles
func _spawn_click_particles() -> void:
	# Simple particle effect at mouse position
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	# Visual settings
	particles.direction = Vector2.UP
	particles.spread = 360.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(1.0, Color.TRANSPARENT)
	particles.color_ramp = gradient

	add_child(particles)
	particles.global_position = get_global_mouse_position()

	# Auto-cleanup
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()


## Public method to trigger feedback manually
func trigger_hover_feedback() -> void:
	_on_mouse_entered()


## Public method to trigger press feedback manually
func trigger_press_feedback() -> void:
	_on_button_down()
	await get_tree().create_timer(0.1).timeout
	_on_button_up()
	_on_pressed()
