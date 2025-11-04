## Musketeer unit class
## Level 1 Stats: 600 HP, 100 damage, 1.1s attack speed, 4 elixir
## Long-range single-target unit effective against air and ground
class_name Musketeer
extends BaseUnit

## Musketeer-specific constants
const MUSKETEER_STATS = {
	"hp": 600,
	"damage": 100,
	"attack_speed": 1.1,
	"movement_speed": 60.0,  # Slow movement
	"attack_range": 288.0,  # 4.5 tiles (4.5 * 64 pixels)
	"elixir_cost": 4,
	"projectile_speed": 500.0
}

## Projectile scene
@export var projectile_scene: PackedScene

## Projectile pool for performance
var projectile_pool: Array[Node2D] = []
var max_pool_size: int = 10


func _ready() -> void:
	super._ready()
	_setup_musketeer()
	_initialize_projectile_pool()


## Setup musketeer-specific properties
func _setup_musketeer() -> void:
	# Initialize base stats
	initialize(
		MUSKETEER_STATS.hp,
		MUSKETEER_STATS.damage,
		MUSKETEER_STATS.attack_speed,
		MUSKETEER_STATS.movement_speed,
		MUSKETEER_STATS.attack_range,
		MUSKETEER_STATS.elixir_cost,
		"Musketeer",
		team_component.team_id if team_component else 0
	)

	# Set musketeer-specific stats
	if stats_component:
		stats_component.rarity = "Rare"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Musketeer is a ground unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup musketeer visuals
func _setup_visuals() -> void:
	# Set musketeer color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.3, 0.5, 0.9)  # Blue uniform for player 1
		else:
			modulate = Color(0.9, 0.5, 0.3)  # Orange-red for player 2

	# Musketeer is normal size
	scale = Vector2(1.0, 1.0)


## Initialize projectile pool for performance
func _initialize_projectile_pool() -> void:
	# Pre-create projectiles for pooling
	pass


## Override attack to shoot projectiles
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Create and launch projectile
	_launch_projectile(target)

	# Play shooting animation
	if sprite:
		_play_shoot_animation()


## Launch a projectile at the target
func _launch_projectile(target: Entity) -> void:
	var projectile: Node2D

	# Get from pool or create new
	if projectile_pool.is_empty():
		projectile = _create_projectile()
	else:
		projectile = projectile_pool.pop_back()

	if not projectile:
		# Fallback: instant damage if no projectile
		if target and target.has_component("HealthComponent"):
			var health_comp = target.get_component("HealthComponent") as HealthComponent
			health_comp.take_damage(attack_component.damage if attack_component else MUSKETEER_STATS.damage, self)
		return

	# Setup projectile
	projectile.position = global_position
	projectile.visible = true

	# Calculate direction and launch
	var direction = (target.global_position - global_position).normalized()
	_move_projectile(projectile, target, direction)


## Create a new projectile
func _create_projectile() -> Node2D:
	var projectile: Node2D

	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		# Create simple bullet projectile if no scene
		projectile = Node2D.new()
		var sprite_node = Sprite2D.new()
		sprite_node.texture = preload("res://icon.svg") if ResourceLoader.exists("res://icon.svg") else null
		sprite_node.scale = Vector2(0.12, 0.12)
		sprite_node.modulate = Color(0.9, 0.9, 0.2)  # Yellow bullet
		projectile.add_child(sprite_node)

	if projectile and not projectile.is_inside_tree():
		get_parent().add_child(projectile)

	return projectile


## Move projectile to target
func _move_projectile(projectile: Node2D, target: Entity, direction: Vector2) -> void:
	if not projectile or not is_instance_valid(target):
		_return_projectile_to_pool(projectile)
		return

	var distance = global_position.distance_to(target.global_position)
	var travel_time = distance / MUSKETEER_STATS.projectile_speed

	# Create tween for projectile movement
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "position", target.global_position, travel_time)

	# Rotate projectile to face direction
	projectile.rotation = direction.angle()

	# Handle projectile hit
	await tween.finished

	# Apply damage if target still valid
	if is_instance_valid(target) and target.has_component("HealthComponent"):
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		health_comp.take_damage(attack_component.damage if attack_component else MUSKETEER_STATS.damage, self)

	# Create hit effect
	_create_hit_effect(projectile.position)

	# Return projectile to pool
	_return_projectile_to_pool(projectile)


## Create hit effect
func _create_hit_effect(position: Vector2) -> void:
	var hit = CPUParticles2D.new()
	hit.position = position
	hit.emitting = true
	hit.amount = 8
	hit.lifetime = 0.2
	hit.one_shot = true
	hit.speed_scale = 2.0
	hit.spread = 180.0
	hit.initial_velocity_min = 50.0
	hit.initial_velocity_max = 100.0
	hit.scale_amount_min = 0.3
	hit.scale_amount_max = 0.6
	hit.color = Color(0.9, 0.8, 0.3)
	get_parent().add_child(hit)

	# Auto-remove hit effect
	await get_tree().create_timer(hit.lifetime).timeout
	if is_instance_valid(hit):
		hit.queue_free()


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


## Play shooting animation
func _play_shoot_animation() -> void:
	if not sprite:
		return

	# Recoil animation
	var original_pos = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_pos - Vector2(8, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.15)


## Musketeer prioritizes air units, then closest target
func _find_nearest_target() -> bool:
	var air_units = []
	var ground_units = []

	# Get all potential targets in range
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Entity and body != self:
				var body_team = body.get_component("TeamComponent") as TeamComponent
				if team_component and body_team and team_component.is_enemy(body):
					var body_stats = body.get_component("StatsComponent") as StatsComponent
					# Check if air or ground unit
					if body_stats and body_stats.flies:
						air_units.append(body)
					else:
						ground_units.append(body)

	# Prioritize air units, then ground units
	var potential_targets = air_units if air_units.size() > 0 else ground_units

	if potential_targets.is_empty():
		return false

	# Find closest target
	var closest_target = null
	var closest_distance = INF

	for target in potential_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target

	if closest_target:
		current_target = closest_target
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
	return "A sharp-eyed riflewoman with great range. Effective against air and ground troops."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Musketeer",
		"hp": health_component.max_health if health_component else MUSKETEER_STATS.hp,
		"damage": attack_component.damage if attack_component else MUSKETEER_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else MUSKETEER_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else MUSKETEER_STATS.movement_speed,
		"range": attack_component.range if attack_component else MUSKETEER_STATS.attack_range,
		"elixir_cost": MUSKETEER_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Rare",
		"special": "Long range, prioritizes air units"
	}
