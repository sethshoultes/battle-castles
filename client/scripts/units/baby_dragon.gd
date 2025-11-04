## Baby Dragon unit class
## Level 1 Stats: 900 HP, 100 damage, 1.6s attack speed, 4 elixir
## Flying unit that deals splash damage with area fireballs
class_name BabyDragon
extends BaseUnit

## Baby Dragon-specific constants
const BABY_DRAGON_STATS = {
	"hp": 900,
	"damage": 100,
	"attack_speed": 1.6,
	"movement_speed": 70.0,  # Medium speed
	"attack_range": 224.0,  # 3.5 tiles (3.5 * 64 pixels)
	"elixir_cost": 4,
	"splash_radius": 96.0,  # 1.5 tiles splash radius
	"projectile_speed": 350.0
}

## Projectile scene
@export var projectile_scene: PackedScene

## Projectile pool for performance
var projectile_pool: Array[Node2D] = []
var max_pool_size: int = 10


func _ready() -> void:
	super._ready()
	_setup_baby_dragon()
	_initialize_projectile_pool()


## Setup baby dragon-specific properties
func _setup_baby_dragon() -> void:
	# Initialize base stats
	initialize(
		BABY_DRAGON_STATS.hp,
		BABY_DRAGON_STATS.damage,
		BABY_DRAGON_STATS.attack_speed,
		BABY_DRAGON_STATS.movement_speed,
		BABY_DRAGON_STATS.attack_range,
		BABY_DRAGON_STATS.elixir_cost,
		"Baby Dragon",
		team_component.team_id if team_component else 0
	)

	# Set baby dragon-specific stats
	if stats_component:
		stats_component.rarity = "Epic"
		stats_component.flies = true
		stats_component.splash_damage = true
		stats_component.splash_radius = BABY_DRAGON_STATS.splash_radius

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Baby Dragon is a flying unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true
		attack_component.splash_damage = true
		attack_component.splash_radius = BABY_DRAGON_STATS.splash_radius

	# Set visual properties
	_setup_visuals()


## Setup baby dragon visuals
func _setup_visuals() -> void:
	# Set baby dragon color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.7, 0.3, 0.7)  # Purple for player 1
		else:
			modulate = Color(0.7, 0.3, 0.3)  # Dark red for player 2

	# Baby Dragon is slightly larger
	scale = Vector2(1.2, 1.2)


## Initialize projectile pool for performance
func _initialize_projectile_pool() -> void:
	# Pre-create projectiles for pooling
	# This would be done with actual projectile scenes in production
	pass


## Override attack to shoot splash damage fireballs
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Create and launch projectile
	_launch_fireball(target)

	# Play fire breathing animation
	if sprite:
		_play_fire_animation()


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
		sprite_node.scale = Vector2(0.15, 0.15)
		sprite_node.modulate = Color(1.0, 0.4, 0.1)  # Orange fireball
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
	var travel_time = distance / BABY_DRAGON_STATS.projectile_speed

	# Create tween for projectile movement
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "position", target_pos, travel_time)

	# Add slight rotation to projectile
	var rotation_tween = get_tree().create_tween()
	rotation_tween.tween_property(projectile, "rotation", randf_range(-PI, PI), travel_time)

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
	shape.radius = BABY_DRAGON_STATS.splash_radius
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
					health_comp.take_damage(attack_component.damage if attack_component else BABY_DRAGON_STATS.damage, self)


## Create explosion effect at impact
func _create_explosion_effect(position: Vector2) -> void:
	var explosion = CPUParticles2D.new()
	explosion.position = position
	explosion.emitting = true
	explosion.amount = 30
	explosion.lifetime = 0.5
	explosion.one_shot = true
	explosion.speed_scale = 3.0
	explosion.explosiveness = 0.8
	explosion.spread = 180.0
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 200.0
	explosion.scale_amount_min = 0.5
	explosion.scale_amount_max = 1.5
	explosion.color = Color(1.0, 0.5, 0.1)  # Orange fire color
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


## Play fire breathing animation
func _play_fire_animation() -> void:
	if not sprite:
		return

	# Simple scale pulse for fire breathing
	var original_scale = scale
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", original_scale * 1.1, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.2)


## Baby Dragon prioritizes damaged units
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

	# Prioritize damaged units, then closest
	var best_target = null
	var best_score = -INF

	for target in enemies:
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		var distance = global_position.distance_to(target.global_position)

		# Higher score for damaged and closer units
		var health_ratio = health_comp.current_health / float(health_comp.max_health) if health_comp else 1.0
		var score = (1.0 - health_ratio) * 100 - distance * 0.1

		if score > best_score:
			best_score = score
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


## Get unit description for UI
func get_description() -> String:
	return "Burps fireballs from the sky that deal area damage. Baby dragons are good at everything."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Baby Dragon",
		"hp": health_component.max_health if health_component else BABY_DRAGON_STATS.hp,
		"damage": attack_component.damage if attack_component else BABY_DRAGON_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else BABY_DRAGON_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else BABY_DRAGON_STATS.movement_speed,
		"range": attack_component.range if attack_component else BABY_DRAGON_STATS.attack_range,
		"elixir_cost": BABY_DRAGON_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Epic",
		"special": "Flying unit with splash damage"
	}
