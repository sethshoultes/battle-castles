## Wizard unit class
## Level 1 Stats: 600 HP, 130 damage, 1.4s attack speed, 5 elixir
## Ranged unit that hurls fireballs dealing splash damage
class_name Wizard
extends BaseUnit

## Wizard-specific constants
const WIZARD_STATS = {
	"hp": 600,
	"damage": 130,
	"attack_speed": 1.4,
	"movement_speed": 60.0,  # Slow movement
	"attack_range": 256.0,  # 4.0 tiles (4.0 * 64 pixels)
	"elixir_cost": 5,
	"splash_radius": 80.0,  # 1.25 tiles splash radius
	"projectile_speed": 380.0
}

## Projectile scene
@export var projectile_scene: PackedScene

## Projectile pool for performance
var projectile_pool: Array[Node2D] = []
var max_pool_size: int = 10


func _ready() -> void:
	super._ready()
	_setup_wizard()
	_initialize_projectile_pool()


## Setup wizard-specific properties
func _setup_wizard() -> void:
	# Initialize base stats
	initialize(
		WIZARD_STATS.hp,
		WIZARD_STATS.damage,
		WIZARD_STATS.attack_speed,
		WIZARD_STATS.movement_speed,
		WIZARD_STATS.attack_range,
		WIZARD_STATS.elixir_cost,
		"Wizard",
		team_component.team_id if team_component else 0
	)

	# Set wizard-specific stats
	if stats_component:
		stats_component.rarity = "Rare"
		stats_component.splash_damage = true
		stats_component.splash_radius = WIZARD_STATS.splash_radius

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Wizard is a ground unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true
		attack_component.splash_damage = true
		attack_component.splash_radius = WIZARD_STATS.splash_radius

	# Set visual properties
	_setup_visuals()


## Setup wizard visuals
func _setup_visuals() -> void:
	# Set wizard color based on team (magical purple/blue)
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.7, 0.3, 0.9)  # Purple wizard for player 1
		else:
			modulate = Color(0.9, 0.3, 0.5)  # Magenta for player 2

	# Wizard is normal size
	scale = Vector2(1.0, 1.0)


## Initialize projectile pool for performance
func _initialize_projectile_pool() -> void:
	# Pre-create projectiles for pooling
	pass


## Override attack to cast splash damage fireballs
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Create and launch fireball
	_launch_fireball(target)

	# Play casting animation
	if sprite:
		_play_cast_animation()


## Launch a fireball at the target
func _launch_fireball(target: Entity) -> void:
	var projectile: Node2D

	# Get from pool or create new
	if projectile_pool.is_empty():
		projectile = _create_projectile()
	else:
		projectile = projectile_pool.pop_back()

	if not projectile:
		# Fallback: instant damage if no projectile
		_apply_splash_damage(target.global_position)
		return

	# Setup projectile
	projectile.position = global_position
	projectile.visible = true

	# Calculate direction and launch
	var direction = (target.global_position - global_position).normalized()
	_move_projectile(projectile, target, direction)


## Create a new fireball projectile
func _create_projectile() -> Node2D:
	var projectile: Node2D

	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		# Create simple fireball if no scene
		projectile = Node2D.new()
		var sprite_node = Sprite2D.new()
		sprite_node.texture = preload("res://icon.svg") if ResourceLoader.exists("res://icon.svg") else null
		sprite_node.scale = Vector2(0.18, 0.18)
		sprite_node.modulate = Color(1.0, 0.3, 0.8)  # Pink-purple fireball
		projectile.add_child(sprite_node)

	if projectile and not projectile.is_inside_tree():
		get_parent().add_child(projectile)

	return projectile


## Move projectile to target
func _move_projectile(projectile: Node2D, target: Entity, direction: Vector2) -> void:
	if not projectile:
		return

	# Store the target position in case target dies
	var target_pos = target.global_position if is_instance_valid(target) else global_position + direction * 100

	var distance = global_position.distance_to(target_pos)
	var travel_time = distance / WIZARD_STATS.projectile_speed

	# Create tween for projectile movement
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "position", target_pos, travel_time)

	# Add spinning rotation to fireball
	var rotation_tween = get_tree().create_tween()
	rotation_tween.tween_property(projectile, "rotation", randf_range(-TAU, TAU), travel_time)

	# Handle projectile hit
	await tween.finished

	# Apply splash damage at impact point
	_apply_splash_damage(projectile.position)

	# Create explosion effect
	_create_explosion_effect(projectile.position)

	# Return projectile to pool
	_return_projectile_to_pool(projectile)


## Apply splash damage to all units in radius
func _apply_splash_damage(impact_position: Vector2) -> void:
	# Get all entities in splash radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = WIZARD_STATS.splash_radius
	query.shape = shape
	query.transform = Transform2D(0, impact_position)
	query.collision_mask = 0xFFFFFFFF  # Check all layers

	var results = space_state.intersect_shape(query)

	# Apply damage to all valid targets in radius
	for result in results:
		var body = result.collider
		if body is Entity and body != self:
			var body_team = body.get_component("TeamComponent") as TeamComponent
			if team_component and body_team and team_component.is_enemy(body):
				var health_comp = body.get_component("HealthComponent") as HealthComponent
				if health_comp:
					health_comp.take_damage(attack_component.damage if attack_component else WIZARD_STATS.damage, self)


## Create explosion effect at impact
func _create_explosion_effect(position: Vector2) -> void:
	var explosion = CPUParticles2D.new()
	explosion.position = position
	explosion.emitting = true
	explosion.amount = 35
	explosion.lifetime = 0.6
	explosion.one_shot = true
	explosion.speed_scale = 3.5
	explosion.explosiveness = 0.9
	explosion.spread = 180.0
	explosion.initial_velocity_min = 120.0
	explosion.initial_velocity_max = 220.0
	explosion.scale_amount_min = 0.5
	explosion.scale_amount_max = 1.5
	explosion.color = Color(1.0, 0.3, 0.8)  # Pink-purple magical explosion
	get_parent().add_child(explosion)

	# Auto-remove explosion after emission
	await get_tree().create_timer(explosion.lifetime).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()


## Return projectile to pool
func _return_projectile_to_pool(projectile: Node2D) -> void:
	if not projectile:
		return

	projectile.visible = false
	projectile.position = Vector2.ZERO
	projectile.rotation = 0.0

	if projectile_pool.size() < max_pool_size:
		projectile_pool.append(projectile)
	else:
		projectile.queue_free()


## Play casting animation
func _play_cast_animation() -> void:
	if not sprite:
		return

	# Raise staff and cast
	var original_pos = position
	var original_scale = scale

	var tween = get_tree().create_tween()

	# Wind up (raise staff)
	tween.tween_property(self, "position", original_pos + Vector2(0, -5), 0.15)
	tween.tween_property(self, "scale", original_scale * 1.05, 0.15)

	# Cast (push forward)
	tween.tween_property(self, "position", original_pos + Vector2(0, 3), 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)

	# Return to normal
	tween.tween_property(self, "position", original_pos, 0.15)


## Wizard prioritizes grouped enemies for maximum splash value
func _find_nearest_target() -> bool:
	var enemies = []

	# Get all potential targets in range
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Entity and body != self:
				var body_team = body.get_component("TeamComponent") as TeamComponent
				if team_component and body_team and team_component.is_enemy(body):
					enemies.append(body)

	if enemies.is_empty():
		return false

	# Find the enemy with the most other enemies nearby (splash optimization)
	var best_target = null
	var best_score = 0

	for target in enemies:
		var nearby_count = 0
		for other in enemies:
			if other != target:
				var distance = target.global_position.distance_to(other.global_position)
				if distance < WIZARD_STATS.splash_radius * 1.5:
					nearby_count += 1

		# Score is higher when more enemies can be hit
		if nearby_count > best_score:
			best_score = nearby_count
			best_target = target

	# If no grouping detected, just get closest
	if not best_target and enemies.size() > 0:
		var closest_distance = INF
		for target in enemies:
			var distance = global_position.distance_to(target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				best_target = target

	if best_target:
		current_target = best_target
		return true

	return false


## Clean up on death
func _on_unit_died() -> void:
	super._on_unit_died()

	# Clear projectile pool
	for projectile in projectile_pool:
		if is_instance_valid(projectile):
			projectile.queue_free()
	projectile_pool.clear()


## Wizard is fragile but powerful
func _on_damage_taken(amount: int, source: Entity) -> void:
	super._on_damage_taken(amount, source)

	# Visual feedback for damage
	if sprite:
		_flash_damage()


## Visual feedback when taking damage
func _flash_damage() -> void:
	if not sprite:
		return

	var original_modulate = sprite.modulate
	sprite.modulate = Color(1.5, 1.5, 1.5)  # Flash white

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(self) and sprite:
		sprite.modulate = original_modulate


## Get unit description for UI
func get_description() -> String:
	return "The Wizard hurls fireballs at his enemies, dealing area damage. He's also got a mean mustache."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Wizard",
		"hp": health_component.max_health if health_component else WIZARD_STATS.hp,
		"damage": attack_component.damage if attack_component else WIZARD_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else WIZARD_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else WIZARD_STATS.movement_speed,
		"range": attack_component.range if attack_component else WIZARD_STATS.attack_range,
		"elixir_cost": WIZARD_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Rare",
		"special": "Ranged splash damage fireballs"
	}
