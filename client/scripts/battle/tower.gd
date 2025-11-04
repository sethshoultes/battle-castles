extends Area2D
class_name Tower

# Tower properties
@export var max_health: float = 2534.0  # Princess tower health
@export var current_health: float = max_health
@export var attack_damage: float = 109.0
@export var attack_speed: float = 0.8  # Attacks per second
@export var attack_range: float = 6.0 * 64  # 6.0 tiles * 64 pixels
@export var team: int = 0  # 0 = Player, 1 = Opponent
@export var tower_type: String = "princess"  # "princess" or "castle"

# State
var is_active: bool = true
var is_destroyed: bool = false
var current_target: Node2D = null
var time_since_last_attack: float = 0.0
var enemies_in_range: Array = []

# Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_timer: Timer = $AttackTimer
@onready var range_area: Area2D = $RangeArea
@onready var range_circle: CollisionShape2D = $RangeArea/CollisionShape2D

# Signals
signal tower_destroyed(team: int, tower_type: String)
signal tower_damaged(damage: float, remaining_health: float)
signal tower_attacked(target: Node2D)

func _ready() -> void:
	setup_range()
	setup_health_bar()
	connect_signals()

	# Set attack timer
	if attack_timer:
		attack_timer.wait_time = 1.0 / attack_speed
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func setup_range() -> void:
	if range_circle and range_circle.shape is CircleShape2D:
		range_circle.shape.radius = attack_range

func setup_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false

		# Style health bar based on team
		var style_box = StyleBoxFlat.new()
		if team == 0:  # Player team
			style_box.bg_color = Color(0.2, 0.5, 1.0, 1.0)  # Bright blue
		else:  # Enemy team
			style_box.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # Bright red
		style_box.corner_radius_top_left = 2
		style_box.corner_radius_top_right = 2
		style_box.corner_radius_bottom_left = 2
		style_box.corner_radius_bottom_right = 2
		health_bar.add_theme_stylebox_override("fill", style_box)

		# Dark background
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.corner_radius_top_left = 2
		bg_style.corner_radius_top_right = 2
		bg_style.corner_radius_bottom_left = 2
		bg_style.corner_radius_bottom_right = 2
		health_bar.add_theme_stylebox_override("background", bg_style)

func connect_signals() -> void:
	if range_area:
		range_area.body_entered.connect(_on_body_entered_range)
		range_area.body_exited.connect(_on_body_exited_range)

func _process(delta: float) -> void:
	if not is_active or is_destroyed:
		return

	# Update targeting
	if current_target == null or not is_instance_valid(current_target):
		acquire_target()

	# Attack if we have a target and timer is ready
	if current_target and attack_timer.is_stopped():
		attack_timer.start()

func acquire_target() -> void:
	current_target = null
	var closest_distance := INF

	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is on opposite team
		if enemy.has_method("get_team") and enemy.get_team() != team:
			var distance := global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				current_target = enemy

func _on_attack_timer_timeout() -> void:
	if current_target and is_instance_valid(current_target):
		perform_attack()
	else:
		attack_timer.stop()
		acquire_target()

func perform_attack() -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	# Check if target is still in range
	var distance := global_position.distance_to(current_target.global_position)
	if distance > attack_range:
		current_target = null
		return

	# Deal damage to target
	if current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage, self)
		tower_attacked.emit(current_target)

	# Play attack animation (to be implemented)
	play_attack_animation()

func play_attack_animation() -> void:
	# Placeholder for attack animation
	# This would trigger projectile spawning or attack effects
	pass

func take_damage(damage: float, attacker: Node2D = null) -> void:
	if is_destroyed:
		return

	current_health = max(0, current_health - damage)

	if health_bar:
		health_bar.value = current_health

	tower_damaged.emit(damage, current_health)

	if current_health <= 0:
		destroy()

func destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	is_active = false

	# Emit destruction signal
	tower_destroyed.emit(team, tower_type)

	# Play destruction animation
	play_destruction_animation()

func play_destruction_animation() -> void:
	# Placeholder for destruction animation
	# For now, just hide the tower
	visible = false

	# In a real implementation, this would:
	# - Play destruction particles
	# - Play destruction sound
	# - Fade out or crumble animation
	# - Then queue_free() after animation completes

	# Disable collision
	set_collision_layer(0)
	set_collision_mask(0)

	# Remove from scene after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_body_entered_range(body: Node2D) -> void:
	if body.has_method("get_team") and body.get_team() != team:
		enemies_in_range.append(body)
		if current_target == null:
			acquire_target()

func _on_body_exited_range(body: Node2D) -> void:
	enemies_in_range.erase(body)
	if body == current_target:
		current_target = null
		acquire_target()

func get_team() -> int:
	return team

func activate() -> void:
	# Used for castle activation after princess tower destruction
	is_active = true

func deactivate() -> void:
	is_active = false
	current_target = null
	if attack_timer:
		attack_timer.stop()