## Individual Goblin unit class
## Level 1 Stats: 160 HP, 50 damage, 0.8s attack speed
## Fast movement speed, part of squad deployment
class_name Goblin
extends BaseUnit

## Goblin-specific constants
const GOBLIN_STATS = {
	"hp": 160,
	"damage": 50,
	"attack_speed": 0.8,
	"movement_speed": 120.0,  # Fast speed
	"attack_range": 64.0,  # 1 tile melee range
	"elixir_cost": 0  # Individual goblins don't have cost, squad does
}

## Reference to the squad this goblin belongs to
var squad: GoblinSquad = null

## Squad position offset for formation
var squad_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	_setup_goblin()


## Setup goblin-specific properties
func _setup_goblin() -> void:
	# Initialize base stats
	initialize(
		GOBLIN_STATS.hp,
		GOBLIN_STATS.damage,
		GOBLIN_STATS.attack_speed,
		GOBLIN_STATS.movement_speed,
		GOBLIN_STATS.attack_range,
		GOBLIN_STATS.elixir_cost,
		"Goblin",
		team_component.team_id if team_component else 0
	)

	# Set goblin-specific stats
	if stats_component:
		stats_component.rarity = "Common"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Goblin is a ground unit that can only attack ground
	if attack_component:
		attack_component.can_attack_air = false
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup goblin visuals
func _setup_visuals() -> void:
	# Set goblin color based on team (smaller, greener tint)
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.2, 0.8, 0.4)  # Greenish-blue for player 1
		else:
			modulate = Color(0.8, 0.4, 0.2)  # Orange-red for player 2

	# Make goblins slightly smaller
	scale = Vector2(0.8, 0.8)


## Set the squad this goblin belongs to
func set_squad(new_squad: GoblinSquad, offset: Vector2) -> void:
	squad = new_squad
	squad_offset = offset


## Override movement to maintain formation when moving as squad
func _state_moving(delta: float) -> void:
	if squad and squad.maintain_formation:
		# Move in formation
		var target_pos = squad.global_position + squad_offset
		if movement_component:
			movement_component.move_to(target_pos)
	else:
		# Move independently
		super._state_moving(delta)


## Override to handle goblin death (notify squad)
func _on_unit_died() -> void:
	super._on_unit_died()

	# Notify squad of goblin death
	if squad:
		squad.on_goblin_died(self)


## Goblins are aggressive and fast
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

	# Find closest target (goblins are aggressive, no preference)
	var closest_target = null
	var closest_distance = INF

	for target in enemies:
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target

	if closest_target:
		current_target = closest_target
		return true

	return false


## Goblins attack quickly with less damage
func _on_attack_performed(target: Entity, damage: int) -> void:
	super._on_attack_performed(target, damage)

	# Quick slash animation
	if sprite:
		_quick_attack_animation()


## Quick attack animation for goblin
func _quick_attack_animation() -> void:
	if not sprite:
		return

	# Quick scale bounce for attack
	var original_scale = scale
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)


## Override to make goblins more aggressive in target acquisition
func _update_target_acquisition(delta: float) -> void:
	# Goblins check for targets more frequently
	target_check_timer += delta
	if target_check_timer >= target_check_interval * 0.7:  # 30% faster checking
		target_check_timer = 0.0

		# Validate current target
		if current_target and is_instance_valid(current_target):
			var target_health = current_target.get_component("HealthComponent") as HealthComponent
			if target_health and target_health.is_dead:
				current_target = null

		# Always look for closer targets (aggressive behavior)
		_find_nearest_target()


## Get unit description for UI
func get_description() -> String:
	return "Fast, cheap, and weak melee attackers. Deploy in groups of 3 for swarm tactics."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Goblin",
		"hp": health_component.max_health if health_component else GOBLIN_STATS.hp,
		"damage": attack_component.damage if attack_component else GOBLIN_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else GOBLIN_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else GOBLIN_STATS.movement_speed,
		"range": attack_component.range if attack_component else GOBLIN_STATS.attack_range,
		"elixir_cost": "2 (for squad of 3)",
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Common",
		"special": "Deployed in squads of 3"
	}