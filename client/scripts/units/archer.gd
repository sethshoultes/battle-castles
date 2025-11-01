## Archer unit class (deployed as pair)
## Level 1 Stats: 252 HP, 60 damage, 1.1s attack speed
## Ranged attack with 5.5 tiles range
class_name Archer
extends BaseUnit

## Archer-specific constants
const ARCHER_STATS = {
	"hp": 252,
	"damage": 60,
	"attack_speed": 1.1,
	"movement_speed": 80.0,  # Slow movement
	"attack_range": 352.0,  # 5.5 tiles (5.5 * 64 pixels)
	"elixir_cost": 3,  # Total for pair
	"projectile_speed": 400.0
}

## Projectile scene
@export var projectile_scene: PackedScene

## Reference to paired archer if deployed as pair
var paired_archer: Archer = null

## Projectile pool for performance
var projectile_pool: Array[Node2D] = []
var max_pool_size: int = 10

## Offset for pair deployment
var pair_offset: Vector2 = Vector2(50, 0)


func _ready() -> void:
	super._ready()
	_setup_archer()
	_initialize_projectile_pool()


## Setup archer-specific properties
func _setup_archer() -> void:
	# Initialize base stats
	initialize(
		ARCHER_STATS.hp,
		ARCHER_STATS.damage,
		ARCHER_STATS.attack_speed,
		ARCHER_STATS.movement_speed,
		ARCHER_STATS.attack_range,
		ARCHER_STATS.elixir_cost / 2,  # Individual cost
		"Archer",
		team_component.team_id if team_component else 0
	)

	# Set archer-specific stats
	if stats_component:
		stats_component.rarity = "Common"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Archer is a ground unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup archer visuals
func _setup_visuals() -> void:
	# Set archer color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.4, 0.6, 1.0)  # Light blue for player 1
		else:
			modulate = Color(1.0, 0.6, 0.4)  # Light red for player 2

	# Archers are slightly smaller than knights
	scale = Vector2(0.9, 0.9)


## Initialize projectile pool for performance
func _initialize_projectile_pool() -> void:
	# Pre-create projectiles for pooling
	# This would be done with actual projectile scenes in production
	pass


## Deploy as a pair of archers
static func deploy_pair(scene: PackedScene, position: Vector2, team_id: int, parent: Node) -> Array[Archer]:
	var archers: Array[Archer] = []

	# Create first archer
	var archer1 = scene.instantiate() as Archer
	if archer1:
		archer1.position = position - Vector2(25, 0)
		if archer1.team_component:
			archer1.team_component.team_id = team_id
		parent.add_child(archer1)
		archers.append(archer1)

	# Create second archer
	var archer2 = scene.instantiate() as Archer
	if archer2:
		archer2.position = position + Vector2(25, 0)
		if archer2.team_component:
			archer2.team_component.team_id = team_id
		parent.add_child(archer2)
		archers.append(archer2)

	# Link the pair
	if archers.size() == 2:
		archer1.paired_archer = archer2
		archer2.paired_archer = archer1

	return archers


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
			health_comp.take_damage(attack_component.damage if attack_component else ARCHER_STATS.damage, self)
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
		# Create simple projectile if no scene
		projectile = Node2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://icon.svg") if ResourceLoader.exists("res://icon.svg") else null
		sprite.scale = Vector2(0.1, 0.1)
		projectile.add_child(sprite)

	if projectile and not projectile.is_inside_tree():
		get_parent().add_child(projectile)

	return projectile


## Move projectile to target
func _move_projectile(projectile: Node2D, target: Entity, direction: Vector2) -> void:
	if not projectile or not is_instance_valid(target):
		_return_projectile_to_pool(projectile)
		return

	var distance = global_position.distance_to(target.global_position)
	var travel_time = distance / ARCHER_STATS.projectile_speed

	# Create tween for projectile movement
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "position", target.global_position, travel_time)

	# Handle projectile hit
	await tween.finished

	# Apply damage if target still valid
	if is_instance_valid(target) and target.has_component("HealthComponent"):
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		health_comp.take_damage(attack_component.damage if attack_component else ARCHER_STATS.damage, self)

	# Return projectile to pool
	_return_projectile_to_pool(projectile)


## Return projectile to pool
func _return_projectile_to_pool(projectile: Node2D) -> void:
	if not projectile:
		return

	projectile.visible = false
	projectile.position = Vector2.ZERO

	if projectile_pool.size() < max_pool_size:
		projectile_pool.append(projectile)
	else:
		projectile.queue_free()


## Play shooting animation
func _play_shoot_animation() -> void:
	if not sprite:
		return

	# Simple recoil animation
	var original_pos = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_pos - Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.1)


## Archers prioritize air units
func _find_nearest_target() -> bool:
	var air_units = []
	var ground_units = []

	# Get all potential targets in range
	# In production, this would query the game manager
	# For now, we'll check a circular area
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 0xFFFFFFFF  # Check all layers

	# Simplified target finding
	var bodies_in_range = []
	if attack_area:
		bodies_in_range = attack_area.get_overlapping_bodies()

	for body in bodies_in_range:
		if body is Entity and body != self:
			var body_team = body.get_component("TeamComponent") as TeamComponent
			if team_component and body_team and team_component.is_enemy(body):
				# Check if air or ground unit
				# This would check actual unit type in production
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

	# Notify paired archer
	if paired_archer:
		paired_archer.paired_archer = null


## Get unit description for UI
func get_description() -> String:
	return "Long-range attackers that can target air and ground units. Deployed in pairs."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Archer",
		"hp": health_component.max_health if health_component else ARCHER_STATS.hp,
		"damage": attack_component.damage if attack_component else ARCHER_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else ARCHER_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else ARCHER_STATS.movement_speed,
		"range": attack_component.range if attack_component else ARCHER_STATS.attack_range,
		"elixir_cost": ARCHER_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Common",
		"special": "Ranged attacks, deployed in pairs"
	}