## Valkyrie unit class
## Level 1 Stats: 1500 HP, 120 damage, 1.5s attack speed, 4 elixir
## Tough melee warrior that deals area damage in a 360-degree spin
class_name Valkyrie
extends BaseUnit

## Valkyrie-specific constants
const VALKYRIE_STATS = {
	"hp": 1500,
	"damage": 120,
	"attack_speed": 1.5,
	"movement_speed": 70.0,  # Medium speed
	"attack_range": 32.0,  # 0.5 tiles melee range
	"elixir_cost": 4,
	"splash_radius": 64.0  # 1 tile splash radius around her
}

## Spin attack visual effect
var spin_particles: CPUParticles2D


func _ready() -> void:
	super._ready()
	_setup_valkyrie()
	_create_spin_effects()


## Setup valkyrie-specific properties
func _setup_valkyrie() -> void:
	# Initialize base stats
	initialize(
		VALKYRIE_STATS.hp,
		VALKYRIE_STATS.damage,
		VALKYRIE_STATS.attack_speed,
		VALKYRIE_STATS.movement_speed,
		VALKYRIE_STATS.attack_range,
		VALKYRIE_STATS.elixir_cost,
		"Valkyrie",
		team_component.team_id if team_component else 0
	)

	# Set valkyrie-specific stats
	if stats_component:
		stats_component.rarity = "Rare"
		stats_component.splash_damage = true
		stats_component.splash_radius = VALKYRIE_STATS.splash_radius

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Valkyrie is a ground unit that can only attack ground (but with AOE)
	if attack_component:
		attack_component.can_attack_air = false
		attack_component.can_attack_ground = true
		attack_component.splash_damage = true
		attack_component.splash_radius = VALKYRIE_STATS.splash_radius

	# Set visual properties
	_setup_visuals()


## Setup valkyrie visuals
func _setup_visuals() -> void:
	# Set valkyrie color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.9, 0.5, 0.3)  # Orange warrior for player 1
		else:
			modulate = Color(0.7, 0.3, 0.2)  # Dark red for player 2

	# Valkyrie is slightly larger than normal units
	scale = Vector2(1.15, 1.15)


## Create spin attack particle effects
func _create_spin_effects() -> void:
	spin_particles = CPUParticles2D.new()
	spin_particles.emitting = false
	spin_particles.amount = 20
	spin_particles.lifetime = 0.5
	spin_particles.one_shot = true
	spin_particles.speed_scale = 2.0
	spin_particles.spread = 180.0
	spin_particles.initial_velocity_min = 100.0
	spin_particles.initial_velocity_max = 150.0
	spin_particles.scale_amount_min = 0.4
	spin_particles.scale_amount_max = 0.8
	spin_particles.color = Color(1.0, 0.7, 0.4)  # Orange slash effect
	add_child(spin_particles)


## Valkyrie prioritizes swarms (multiple nearby enemies)
func _find_nearest_target() -> bool:
	var enemies = []

	# Get all potential targets in range
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Entity and body != self:
				var body_team = body.get_component("TeamComponent") as TeamComponent
				if team_component and body_team and team_component.is_enemy(body):
					var body_stats = body.get_component("StatsComponent") as StatsComponent
					# Only target ground units (can't hit air)
					if body_stats and not body_stats.flies:
						enemies.append(body)

	if enemies.is_empty():
		return false

	# Find the enemy with the most other enemies nearby (swarm detection)
	var best_target = null
	var best_score = 0

	for target in enemies:
		var nearby_count = 0
		for other in enemies:
			if other != target:
				var distance = target.global_position.distance_to(other.global_position)
				if distance < VALKYRIE_STATS.splash_radius * 1.5:
					nearby_count += 1

		# Score is higher when more enemies are grouped
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


## Override attack to perform 360-degree spin attack
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Don't just damage the target - damage ALL enemies in splash radius
	_perform_spin_attack()

	# Play spin animation
	if sprite:
		_play_spin_animation()


## Perform 360-degree spin attack hitting all nearby enemies
func _perform_spin_attack() -> void:
	# Create spin effect
	if spin_particles:
		spin_particles.restart()

	# Get all entities in splash radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = VALKYRIE_STATS.splash_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFFFFFF  # Check all layers

	var results = space_state.intersect_shape(query)

	# Apply damage to all valid targets in radius
	for result in results:
		var body = result.collider
		if body is Entity and body != self:
			var body_team = body.get_component("TeamComponent") as TeamComponent
			var body_stats = body.get_component("StatsComponent") as StatsComponent

			# Only hit ground units
			if team_component and body_team and team_component.is_enemy(body):
				if not body_stats or not body_stats.flies:
					var health_comp = body.get_component("HealthComponent") as HealthComponent
					if health_comp:
						health_comp.take_damage(attack_component.damage if attack_component else VALKYRIE_STATS.damage, self)


## Play spin attack animation
func _play_spin_animation() -> void:
	if not sprite:
		return

	# Rapid 360-degree spin
	var original_rotation = rotation
	var tween = get_tree().create_tween()

	# Spin attack (full rotation)
	tween.tween_property(self, "rotation", original_rotation + TAU, 0.4)

	# Return to normal rotation
	tween.tween_callback(func():
		rotation = original_rotation
	)


## Valkyrie is very durable
func _on_damage_taken(amount: int, source: Entity) -> void:
	super._on_damage_taken(amount, source)

	# Visual feedback for taking damage
	if sprite:
		_flash_damage()


## Visual feedback when taking damage
func _flash_damage() -> void:
	if not sprite:
		return

	var original_modulate = sprite.modulate
	sprite.modulate = Color(1.3, 1.3, 1.3)  # Flash bright

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(self) and sprite:
		sprite.modulate = original_modulate


## Valkyrie charges into battle
func _on_movement_started(destination: Vector2) -> void:
	super._on_movement_started(destination)

	# Add battle cry effect (visual representation)
	if sprite:
		_create_charge_effect()


## Create charge effect
func _create_charge_effect() -> void:
	# Create dust trail while charging
	var dust = CPUParticles2D.new()
	dust.position = position
	dust.emitting = true
	dust.amount = 5
	dust.lifetime = 0.3
	dust.speed_scale = 1.5
	dust.spread = 30.0
	dust.initial_velocity_min = 30.0
	dust.initial_velocity_max = 60.0
	dust.color = Color(0.7, 0.5, 0.3, 0.5)
	get_parent().add_child(dust)

	# Auto-remove dust
	dust.emitting = false
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(dust):
		dust.queue_free()


## Get unit description for UI
func get_description() -> String:
	return "Tough warrior woman with a mean swing. Deals area damage around her."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Valkyrie",
		"hp": health_component.max_health if health_component else VALKYRIE_STATS.hp,
		"damage": attack_component.damage if attack_component else VALKYRIE_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else VALKYRIE_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else VALKYRIE_STATS.movement_speed,
		"range": attack_component.range if attack_component else VALKYRIE_STATS.attack_range,
		"elixir_cost": VALKYRIE_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Rare",
		"special": "360-degree area damage attack"
	}
