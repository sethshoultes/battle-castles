## Individual Barbarian unit class
## Level 1 Stats: 500 HP, 75 damage, 1.5s attack speed
## Deployed in packs of 4, strong melee warriors
class_name Barbarian
extends BaseUnit

## Barbarian-specific constants
const BARBARIAN_STATS = {
	"hp": 500,
	"damage": 75,
	"attack_speed": 1.5,
	"movement_speed": 65.0,  # Slow movement
	"attack_range": 32.0,  # 0.5 tiles melee range
	"elixir_cost": 5  # Total for pack of 4
}

## Reference to the pack this barbarian belongs to
var pack: Array[Barbarian] = []

## Pack position index
var pack_index: int = 0


func _ready() -> void:
	super._ready()
	_setup_barbarian()


## Setup barbarian-specific properties
func _setup_barbarian() -> void:
	# Initialize base stats
	initialize(
		BARBARIAN_STATS.hp,
		BARBARIAN_STATS.damage,
		BARBARIAN_STATS.attack_speed,
		BARBARIAN_STATS.movement_speed,
		BARBARIAN_STATS.attack_range,
		BARBARIAN_STATS.elixir_cost / 4,  # Individual cost
		"Barbarian",
		team_component.team_id if team_component else 0
	)

	# Set barbarian-specific stats
	if stats_component:
		stats_component.rarity = "Common"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Barbarian is a ground unit that can only attack ground
	if attack_component:
		attack_component.can_attack_air = false
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup barbarian visuals
func _setup_visuals() -> void:
	# Set barbarian color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(1.0, 0.7, 0.4)  # Orange for player 1
		else:
			modulate = Color(0.7, 0.3, 0.2)  # Dark orange-red for player 2

	# Barbarians are slightly larger than normal units
	scale = Vector2(1.1, 1.1)


## Deploy a pack of 4 barbarians
static func deploy_pack(scene: PackedScene, position: Vector2, team_id: int, parent: Node) -> Array[Barbarian]:
	var barbarians: Array[Barbarian] = []

	# Formation pattern (diamond shape)
	var offsets = [
		Vector2(0, -30),      # Front
		Vector2(-25, 0),      # Left
		Vector2(25, 0),       # Right
		Vector2(0, 30)        # Back
	]

	# Create all barbarians
	for i in range(4):
		var barbarian = scene.instantiate() as Barbarian
		if barbarian:
			barbarian.position = position + offsets[i]
			barbarian.pack_index = i
			if barbarian.team_component:
				barbarian.team_component.team_id = team_id
			parent.add_child(barbarian)
			barbarians.append(barbarian)

	# Link the pack
	for barbarian in barbarians:
		barbarian.pack = barbarians

	return barbarians


## Barbarians prioritize nearby enemies aggressively
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

	# Prioritize units over buildings (barbarians are anti-unit)
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


## Barbarians attack with powerful swings
func _on_attack_performed(target: Entity, damage: int) -> void:
	super._on_attack_performed(target, damage)

	# Play swing animation
	if sprite:
		_play_swing_animation()


## Play sword swing animation
func _play_swing_animation() -> void:
	if not sprite:
		return

	# Create swing effect with rotation and position
	var original_rotation = rotation
	var original_pos = position

	var tween = get_tree().create_tween()
	tween.set_parallel(true)

	# Swing rotation
	tween.tween_property(self, "rotation", original_rotation - 0.3, 0.15)
	tween.tween_property(self, "position", original_pos + Vector2(10, 0), 0.15)

	tween.chain()
	tween.set_parallel(true)

	# Return to normal
	tween.tween_property(self, "rotation", original_rotation, 0.15)
	tween.tween_property(self, "position", original_pos, 0.15)


## Override to notify pack on death
func _on_unit_died() -> void:
	super._on_unit_died()

	# Remove self from pack
	if pack:
		var index = pack.find(self)
		if index != -1:
			pack.remove_at(index)


## Barbarians are aggressive and durable
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
	return "A pack of angry warriors with long swords. They do massive damage and have lots of hitpoints."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Barbarian",
		"hp": health_component.max_health if health_component else BARBARIAN_STATS.hp,
		"damage": attack_component.damage if attack_component else BARBARIAN_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else BARBARIAN_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else BARBARIAN_STATS.movement_speed,
		"range": attack_component.range if attack_component else BARBARIAN_STATS.attack_range,
		"elixir_cost": BARBARIAN_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Common",
		"special": "Deployed in packs of 4"
	}
