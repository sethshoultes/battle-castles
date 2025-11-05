## Mini P.E.K.K.A unit class
## Level 1 Stats: 1100 HP, 340 damage, 1.8s attack speed, 4 elixir
## High-damage single-target melee unit with devastating attacks
class_name MiniPekka
extends BaseUnit

## Mini P.E.K.K.A-specific constants
const MINI_PEKKA_STATS = {
	"hp": 1100,
	"damage": 340,
	"attack_speed": 1.8,
	"movement_speed": 70.0,  # Medium speed
	"attack_range": 32.0,  # 0.5 tiles melee range
	"elixir_cost": 4
}

## Ground slam effect on attack
var impact_particles: CPUParticles2D


func _ready() -> void:
	super._ready()
	_setup_mini_pekka()
	_create_impact_effects()


## Setup mini pekka-specific properties
func _setup_mini_pekka() -> void:
	# Initialize base stats
	initialize(
		MINI_PEKKA_STATS.hp,
		MINI_PEKKA_STATS.damage,
		MINI_PEKKA_STATS.attack_speed,
		MINI_PEKKA_STATS.movement_speed,
		MINI_PEKKA_STATS.attack_range,
		MINI_PEKKA_STATS.elixir_cost,
		"Mini P.E.K.K.A",
		team_component.team_id if team_component else 0
	)

	# Set mini pekka-specific stats
	if stats_component:
		stats_component.rarity = "Rare"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Mini P.E.K.K.A is a ground unit that can only attack ground
	if attack_component:
		attack_component.can_attack_air = false
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup mini pekka visuals
func _setup_visuals() -> void:
	# Set mini pekka color based on team (darker, armored appearance)
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.3, 0.3, 0.5)  # Dark blue-grey for player 1
		else:
			modulate = Color(0.5, 0.3, 0.3)  # Dark red-grey for player 2

	# Mini P.E.K.K.A is larger than normal units
	scale = Vector2(1.3, 1.3)


## Create impact particle effects
func _create_impact_effects() -> void:
	impact_particles = CPUParticles2D.new()
	impact_particles.emitting = false
	impact_particles.amount = 15
	impact_particles.lifetime = 0.4
	impact_particles.one_shot = true
	impact_particles.speed_scale = 2.5
	impact_particles.spread = 45.0
	impact_particles.initial_velocity_min = 120.0
	impact_particles.initial_velocity_max = 180.0
	impact_particles.scale_amount_min = 0.3
	impact_particles.scale_amount_max = 1.0
	impact_particles.color = Color(0.8, 0.8, 0.9)  # Metallic grey
	add_child(impact_particles)


## Mini P.E.K.K.A prioritizes high-value targets (high HP units and buildings)
func _find_nearest_target() -> bool:
	var enemies = []
	var buildings = []

	# Get all potential targets in range
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Entity and body != self:
				var body_team = body.get_component("TeamComponent") as TeamComponent
				if team_component and body_team and team_component.is_enemy(body):
					var body_stats = body.get_component("StatsComponent") as StatsComponent
					if body_stats and body_stats.is_building:
						buildings.append(body)
					else:
						enemies.append(body)

	# Prioritize high-HP enemies, then buildings
	var potential_targets = enemies + buildings

	if potential_targets.is_empty():
		return false

	# Find target with highest HP (mini pekka likes to fight big things)
	var best_target = null
	var best_hp = 0

	for target in potential_targets:
		var health_comp = target.get_component("HealthComponent") as HealthComponent
		if health_comp and health_comp.max_health > best_hp:
			best_hp = health_comp.max_health
			best_target = target

	# If no high-HP target, just get closest
	if not best_target and potential_targets.size() > 0:
		var closest_distance = INF
		for target in potential_targets:
			var distance = global_position.distance_to(target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				best_target = target

	if best_target:
		current_target = best_target
		return true

	return false


## Override attack for devastating strikes
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Apply damage (base class handles this)
	super._on_attack_performed(target, damage)

	# Create powerful strike effect
	_create_strike_effect()

	# Play powerful attack animation
	if sprite:
		_play_strike_animation()


## Create strike visual effect
func _create_strike_effect() -> void:
	if impact_particles:
		impact_particles.restart()

	# Create impact flash
	var flash = Sprite2D.new()
	flash.modulate = Color(1.5, 1.5, 1.5, 0.8)
	flash.scale = Vector2(1.5, 1.5)
	add_child(flash)

	# Fade out flash
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)


## Play strike animation
func _play_strike_animation() -> void:
	if not sprite:
		return

	# Wind up and strike
	var original_pos = position
	var original_scale = scale

	var tween = get_tree().create_tween()

	# Wind up (pull back)
	tween.tween_property(self, "position", original_pos - Vector2(15, 0), 0.15)
	tween.tween_property(self, "scale", original_scale * 1.1, 0.15)

	# Strike forward with force
	tween.tween_property(self, "position", original_pos + Vector2(10, 0), 0.1)
	tween.tween_property(self, "scale", original_scale * 0.95, 0.1)

	# Return to position
	tween.tween_property(self, "position", original_pos, 0.15)
	tween.tween_property(self, "scale", original_scale, 0.15)


## Mini P.E.K.K.A is heavily armored
func _on_damage_taken(amount: int, source: Entity) -> void:
	super._on_damage_taken(amount, source)

	# Visual feedback for armor
	if sprite:
		_show_armor_effect()


## Show visual feedback for armor
func _show_armor_effect() -> void:
	if not sprite:
		return

	# Create metallic shield effect
	var shield = Sprite2D.new()
	shield.modulate = Color(0.8, 0.8, 1.0, 0.6)
	shield.scale = Vector2(1.3, 1.3)
	add_child(shield)

	# Fade out shield
	var tween = get_tree().create_tween()
	tween.tween_property(shield, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shield.queue_free)


## Mini P.E.K.K.A has heavy footsteps
func _on_movement_started(destination: Vector2) -> void:
	super._on_movement_started(destination)

	# Create footstep sound effects (visual representation)
	if movement_component and movement_component.is_moving:
		_create_footstep_effects()


## Create footstep effects
func _create_footstep_effects() -> void:
	while movement_component and movement_component.is_moving and current_state == State.MOVING:
		# Create dust at feet
		var dust = CPUParticles2D.new()
		dust.position = position + Vector2(0, 15)
		dust.emitting = true
		dust.amount = 3
		dust.lifetime = 0.2
		dust.speed_scale = 1.0
		dust.spread = 15.0
		dust.initial_velocity_min = 15.0
		dust.initial_velocity_max = 30.0
		dust.color = Color(0.5, 0.5, 0.5, 0.4)
		get_parent().add_child(dust)

		# Auto-remove dust after emission
		dust.emitting = false
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(dust):
			dust.queue_free()

		# Wait between footsteps
		await get_tree().create_timer(0.4).timeout


## Get unit description for UI
func get_description() -> String:
	return "The Arena is a certified P.E.K.K.A. mini. Deals devastating damage to anything in its path."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Mini P.E.K.K.A",
		"hp": health_component.max_health if health_component else MINI_PEKKA_STATS.hp,
		"damage": attack_component.damage if attack_component else MINI_PEKKA_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else MINI_PEKKA_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else MINI_PEKKA_STATS.movement_speed,
		"range": attack_component.range if attack_component else MINI_PEKKA_STATS.attack_range,
		"elixir_cost": MINI_PEKKA_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Rare",
		"special": "Devastating single-target damage"
	}
