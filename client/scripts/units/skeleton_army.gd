## Individual Skeleton unit class
## Level 1 Stats: 60 HP, 60 damage, 1.0s attack speed
## Very weak but deployed in massive numbers (15 skeletons)
class_name Skeleton
extends BaseUnit

## Skeleton-specific constants
const SKELETON_STATS = {
	"hp": 60,
	"damage": 60,
	"attack_speed": 1.0,
	"movement_speed": 85.0,  # Fast movement
	"attack_range": 32.0,  # 0.5 tiles melee range
	"elixir_cost": 3  # Total for army of 15
}

## Reference to the army this skeleton belongs to
var army: Array[Skeleton] = []

## Army position index
var army_index: int = 0


func _ready() -> void:
	super._ready()
	_setup_skeleton()


## Setup skeleton-specific properties
func _setup_skeleton() -> void:
	# Initialize base stats
	initialize(
		SKELETON_STATS.hp,
		SKELETON_STATS.damage,
		SKELETON_STATS.attack_speed,
		SKELETON_STATS.movement_speed,
		SKELETON_STATS.attack_range,
		SKELETON_STATS.elixir_cost / 15,  # Individual cost
		"Skeleton",
		team_component.team_id if team_component else 0
	)

	# Set skeleton-specific stats
	if stats_component:
		stats_component.rarity = "Epic"

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Skeleton is a ground unit that can only attack ground
	if attack_component:
		attack_component.can_attack_air = false
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup skeleton visuals
func _setup_visuals() -> void:
	# Set skeleton color based on team (bony white appearance)
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.9, 0.9, 0.9)  # White-grey for player 1
		else:
			modulate = Color(0.8, 0.7, 0.7)  # Slight red tint for player 2

	# Skeletons are very small
	scale = Vector2(0.6, 0.6)


## Deploy an army of 15 skeletons
static func deploy_army(scene: PackedScene, position: Vector2, team_id: int, parent: Node) -> Array[Skeleton]:
	var skeletons: Array[Skeleton] = []

	# Formation pattern (circular spread)
	var circle_radius = 40.0
	var angle_step = TAU / 15  # Divide circle into 15 parts

	# Create all skeletons
	for i in range(15):
		var skeleton = scene.instantiate() as Skeleton
		if skeleton:
			# Calculate position in circle
			var angle = i * angle_step
			var offset = Vector2(cos(angle), sin(angle)) * circle_radius
			skeleton.position = position + offset
			skeleton.army_index = i
			if skeleton.team_component:
				skeleton.team_component.team_id = team_id
			parent.add_child(skeleton)
			skeletons.append(skeleton)

	# Link the army
	for skeleton in skeletons:
		skeleton.army = skeletons

	return skeletons


## Skeletons are extremely aggressive and fast
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

	# Find closest target (skeletons swarm whatever is nearest)
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


## Skeletons attack with quick slashes
func _on_attack_performed(target: Entity, damage: int) -> void:
	super._on_attack_performed(target, damage)

	# Play quick attack animation
	if sprite:
		_play_quick_attack()


## Play quick attack animation
func _play_quick_attack() -> void:
	if not sprite:
		return

	# Very quick jab animation
	var original_pos = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)


## Override target acquisition for very aggressive behavior
func _update_target_acquisition(delta: float) -> void:
	# Skeletons check for targets very frequently
	target_check_timer += delta
	if target_check_timer >= target_check_interval * 0.5:  # 50% faster checking
		target_check_timer = 0.0

		# Validate current target
		if current_target and is_instance_valid(current_target):
			var target_health = current_target.get_component("HealthComponent") as HealthComponent
			if target_health and target_health.is_dead:
				current_target = null

		# Always look for closer targets (swarm behavior)
		_find_nearest_target()


## Override to notify army on death
func _on_unit_died() -> void:
	super._on_unit_died()

	# Remove self from army
	if army:
		var index = army.find(self)
		if index != -1:
			army.remove_at(index)

	# Create bone scatter effect on death
	_create_death_effect()


## Create bone scatter effect
func _create_death_effect() -> void:
	var bones = CPUParticles2D.new()
	bones.position = global_position
	bones.emitting = true
	bones.amount = 8
	bones.lifetime = 0.4
	bones.one_shot = true
	bones.speed_scale = 2.0
	bones.spread = 180.0
	bones.initial_velocity_min = 80.0
	bones.initial_velocity_max = 150.0
	bones.scale_amount_min = 0.2
	bones.scale_amount_max = 0.5
	bones.color = Color(0.95, 0.95, 0.95)
	get_parent().add_child(bones)

	# Auto-remove effect
	await get_tree().create_timer(bones.lifetime).timeout
	if is_instance_valid(bones):
		bones.queue_free()


## Skeletons are very fragile
func _on_damage_taken(amount: int, source: Entity) -> void:
	super._on_damage_taken(amount, source)

	# Slight visual feedback (they die so fast it's barely visible)
	if sprite:
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.2), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)


## Add jittery movement to skeletons
func _process(delta: float) -> void:
	super._process(delta)

	# Add slight jitter to make them look more chaotic
	if is_active and current_state == State.MOVING:
		var jitter = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		position += jitter * delta * 10.0


## Get unit description for UI
func get_description() -> String:
	return "Spawns a horde of skeletons. Meet Larry and his friends - a bunch of fast, unarmored fighters."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Skeleton",
		"hp": health_component.max_health if health_component else SKELETON_STATS.hp,
		"damage": attack_component.damage if attack_component else SKELETON_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else SKELETON_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else SKELETON_STATS.movement_speed,
		"range": attack_component.range if attack_component else SKELETON_STATS.attack_range,
		"elixir_cost": SKELETON_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Epic",
		"special": "Deployed in massive army of 15"
	}
