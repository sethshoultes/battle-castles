## Individual Minion unit class
## Level 1 Stats: 200 HP, 90 damage, 1.0s attack speed
## Fast flying units deployed in groups of 3
class_name Minion
extends BaseUnit

## Minion-specific constants
const MINION_STATS = {
	"hp": 200,
	"damage": 90,
	"attack_speed": 1.0,
	"movement_speed": 80.0,  # Fast movement
	"attack_range": 128.0,  # 2.0 tiles ranged attack
	"elixir_cost": 3,  # Total for group of 3
	"projectile_speed": 450.0
}

## Projectile scene
@export var projectile_scene: PackedScene

## Reference to the swarm this minion belongs to
var swarm: Array[Minion] = []

## Swarm position index
var swarm_index: int = 0

## Projectile pool for performance
var projectile_pool: Array[Node2D] = []
var max_pool_size: int = 8


func _ready() -> void:
	super._ready()
	_setup_minion()
	_initialize_projectile_pool()


## Setup minion-specific properties
func _setup_minion() -> void:
	# Initialize base stats
	initialize(
		MINION_STATS.hp,
		MINION_STATS.damage,
		MINION_STATS.attack_speed,
		MINION_STATS.movement_speed,
		MINION_STATS.attack_range,
		MINION_STATS.elixir_cost / 3,  # Individual cost
		"Minion",
		team_component.team_id if team_component else 0
	)

	# Set minion-specific stats
	if stats_component:
		stats_component.rarity = "Common"
		stats_component.flies = true

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Minion is a flying unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup minion visuals
func _setup_visuals() -> void:
	# Set minion color based on team (dark, flying creature)
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.3, 0.2, 0.3)  # Dark purple for player 1
		else:
			modulate = Color(0.3, 0.2, 0.2)  # Dark red for player 2

	# Minions are small flying units
	scale = Vector2(0.7, 0.7)


## Initialize projectile pool for performance
func _initialize_projectile_pool() -> void:
	# Pre-create projectiles for pooling
	pass


## Deploy a swarm of 3 minions
static func deploy_swarm(scene: PackedScene, position: Vector2, team_id: int, parent: Node) -> Array[Minion]:
	var minions: Array[Minion] = []

	# Formation pattern (triangle)
	var offsets = [
		Vector2(0, -20),      # Front
		Vector2(-20, 10),     # Left back
		Vector2(20, 10)       # Right back
	]

	# Create all minions
	for i in range(3):
		var minion = scene.instantiate() as Minion
		if minion:
			minion.position = position + offsets[i]
			minion.swarm_index = i
			if minion.team_component:
				minion.team_component.team_id = team_id
			parent.add_child(minion)
			minions.append(minion)

	# Link the swarm
	for minion in minions:
		minion.swarm = minions

	return minions


## Override attack to shoot projectiles
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Create and launch projectile
	_launch_projectile(target)

	# Play attack animation
	if sprite:
		_play_attack_animation()


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
			health_comp.take_damage(attack_component.damage if attack_component else MINION_STATS.damage, self)
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
		var sprite_node = Sprite2D.new()
		sprite_node.texture = preload("res://icon.svg") if ResourceLoader.exists("res://icon.svg") else null
		sprite_node.scale = Vector2(0.08, 0.08)
		sprite_node.modulate = Color(0.4, 0.2, 0.4)  # Dark projectile
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
	var travel_time = distance / MINION_STATS.projectile_speed

	# Create tween for projectile movement
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "position", target.global_position, travel_time)

	# Handle projectile hit
	await tween.finished

	# Apply damage if target still valid
	if is_instance_valid(target) and target.has_component("HealthComponent"):
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		health_comp.take_damage(attack_component.damage if attack_component else MINION_STATS.damage, self)

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


## Play attack animation
func _play_attack_animation() -> void:
	if not sprite:
		return

	# Quick forward dash for attack
	var original_pos = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(0, -5), 0.05)
	tween.tween_property(self, "position", original_pos, 0.1)


## Minions prioritize weak targets they can quickly eliminate
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

	# Prioritize low-HP targets (minions like easy kills)
	var best_target = null
	var lowest_hp = INF

	for target in enemies:
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		if health_comp and health_comp.current_health < lowest_hp:
			lowest_hp = health_comp.current_health
			best_target = target

	# If all targets high HP, just get closest
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


## Override to add flying movement pattern
func _process(delta: float) -> void:
	super._process(delta)

	# Add gentle hovering motion for flying units
	if is_active and sprite:
		var hover_offset = sin(Time.get_ticks_msec() * 0.003 + swarm_index) * 3.0
		sprite.offset.y = hover_offset


## Clean up on death
func _on_unit_died() -> void:
	super._on_unit_died()

	# Clear projectile pool
	for projectile in projectile_pool:
		if is_instance_valid(projectile):
			projectile.queue_free()
	projectile_pool.clear()

	# Remove self from swarm
	if swarm:
		var index = swarm.find(self)
		if index != -1:
			swarm.remove_at(index)


## Get unit description for UI
func get_description() -> String:
	return "Three small flying creatures. Fast, weak, and easily distracted by dangling objects."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Minion",
		"hp": health_component.max_health if health_component else MINION_STATS.hp,
		"damage": attack_component.damage if attack_component else MINION_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else MINION_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else MINION_STATS.movement_speed,
		"range": attack_component.range if attack_component else MINION_STATS.attack_range,
		"elixir_cost": MINION_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Common",
		"special": "Flying units, deployed in groups of 3"
	}
