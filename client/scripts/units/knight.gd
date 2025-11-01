## Knight unit class
## Level 1 Stats: 1400 HP, 75 damage, 1.2s attack speed, 3 elixir
## Special: 5% damage reduction on first hit
class_name Knight
extends BaseUnit

## Knight-specific constants
const KNIGHT_STATS = {
	"hp": 1400,
	"damage": 75,
	"attack_speed": 1.2,
	"movement_speed": 90.0,  # Medium speed
	"attack_range": 64.0,  # 1 tile melee range
	"elixir_cost": 3,
	"first_hit_reduction": 0.05  # 5% damage reduction
}


func _ready() -> void:
	super._ready()
	_setup_knight()


## Setup knight-specific properties
func _setup_knight() -> void:
	# Initialize base stats
	initialize(
		KNIGHT_STATS.hp,
		KNIGHT_STATS.damage,
		KNIGHT_STATS.attack_speed,
		KNIGHT_STATS.movement_speed,
		KNIGHT_STATS.attack_range,
		KNIGHT_STATS.elixir_cost,
		"Knight",
		team_component.team_id if team_component else 0
	)

	# Set knight-specific stats
	if stats_component:
		stats_component.rarity = "Common"
		stats_component.first_hit_reduction = KNIGHT_STATS.first_hit_reduction
		stats_component.has_taken_first_hit = false

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Knight is a ground unit that can attack both ground and air
	if attack_component:
		attack_component.can_attack_air = true
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup knight visuals
func _setup_visuals() -> void:
	# Set knight color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.2, 0.4, 1.0)  # Blue for player 1
		else:
			modulate = Color(1.0, 0.2, 0.2)  # Red for player 2

	# Set sprite animations if available
	if sprite and sprite.sprite_frames:
		if not sprite.sprite_frames.has_animation("idle"):
			# Create placeholder animations
			# In production, these would be loaded from resources
			pass


## Override damage taken to handle first hit reduction
func _on_damage_taken(amount: int, source: Entity) -> void:
	# First hit reduction is handled in stats_component.calculate_damage_reduction
	# which is called by the parent class
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


## Override attack performed for knight-specific effects
func _on_attack_performed(target: Entity, damage: int) -> void:
	super._on_attack_performed(target, damage)

	# Knight has a strong melee attack with slight knockback
	# This could be implemented with physics impulse
	if target and target.has_method("apply_knockback"):
		var knockback_direction = (target.global_position - global_position).normalized()
		#target.apply_knockback(knockback_direction * 50)


## Find the nearest target (prioritize units over buildings)
func _find_nearest_target() -> bool:
	var enemies = []
	var buildings = []

	# Get all potential targets in range
	# In a full implementation, this would query the game manager
	# For now, we'll use the attack area if available
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

	# Prioritize units over buildings
	var potential_targets = enemies if enemies.size() > 0 else buildings

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


## Get unit description for UI
func get_description() -> String:
	return "A tough melee fighter with good stats all around. Takes reduced damage from the first hit."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Knight",
		"hp": health_component.max_health if health_component else KNIGHT_STATS.hp,
		"damage": attack_component.damage if attack_component else KNIGHT_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else KNIGHT_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else KNIGHT_STATS.movement_speed,
		"range": attack_component.range if attack_component else KNIGHT_STATS.attack_range,
		"elixir_cost": stats_component.elixir_cost if stats_component else KNIGHT_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Common",
		"special": "5% damage reduction on first hit"
	}