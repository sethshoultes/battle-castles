## Giant unit class
## Level 1 Stats: 3400 HP, 120 damage, 2.4s attack speed, 5 elixir
## ONLY targets buildings, 35% damage reduction from buildings, slow movement
class_name Giant
extends BaseUnit

## Giant-specific constants
const GIANT_STATS = {
	"hp": 3400,
	"damage": 120,
	"attack_speed": 2.4,
	"movement_speed": 60.0,  # Very slow
	"attack_range": 64.0,  # 1 tile melee range
	"elixir_cost": 5,
	"building_damage_reduction": 0.35  # 35% damage reduction from buildings
}

## Screen shake intensity when giant attacks
const SCREEN_SHAKE_INTENSITY = 10.0
const SCREEN_SHAKE_DURATION = 0.2

## Ground impact effect on attack
var impact_particles: CPUParticles2D


func _ready() -> void:
	super._ready()
	_setup_giant()
	_create_impact_effects()


## Setup giant-specific properties
func _setup_giant() -> void:
	# Initialize base stats
	initialize(
		GIANT_STATS.hp,
		GIANT_STATS.damage,
		GIANT_STATS.attack_speed,
		GIANT_STATS.movement_speed,
		GIANT_STATS.attack_range,
		GIANT_STATS.elixir_cost,
		"Giant",
		team_component.team_id if team_component else 0
	)

	# Set giant-specific stats
	if stats_component:
		stats_component.rarity = "Rare"
		stats_component.building_damage_reduction = GIANT_STATS.building_damage_reduction
		stats_component.targets_buildings_only = true
		stats_component.is_building = false  # Giant is not a building

		# Apply level scaling if not level 1
		if stats_component.level > 1:
			stats_component.apply_level_scaling(health_component, attack_component)

	# Giant ONLY targets buildings
	if attack_component:
		attack_component.targets_buildings_only = true
		attack_component.can_attack_air = false  # Can't attack air units
		attack_component.can_attack_ground = true

	# Set visual properties
	_setup_visuals()


## Setup giant visuals
func _setup_visuals() -> void:
	# Set giant color based on team
	if sprite and team_component:
		if team_component.team_id == 0:
			modulate = Color(0.3, 0.3, 0.8)  # Dark blue for player 1
		else:
			modulate = Color(0.8, 0.3, 0.3)  # Dark red for player 2

	# Giants are much larger
	scale = Vector2(1.5, 1.5)

	# Add shadow effect for giant
	if sprite:
		var shadow = Sprite2D.new()
		shadow.texture = sprite.texture if sprite.texture else null
		shadow.modulate = Color(0, 0, 0, 0.3)
		shadow.position = Vector2(5, 5)
		shadow.z_index = -1
		sprite.add_child(shadow)


## Create impact particle effects
func _create_impact_effects() -> void:
	impact_particles = CPUParticles2D.new()
	impact_particles.emitting = false
	impact_particles.amount = 20
	impact_particles.lifetime = 0.5
	impact_particles.one_shot = true
	impact_particles.speed_scale = 2.0
	impact_particles.spread = 45.0
	impact_particles.initial_velocity_min = 100.0
	impact_particles.initial_velocity_max = 200.0
	impact_particles.scale_amount_min = 0.5
	impact_particles.scale_amount_max = 1.5
	impact_particles.color = Color(0.6, 0.4, 0.2)  # Brown dust color
	add_child(impact_particles)


## Override to only target buildings
func _find_nearest_target() -> bool:
	var buildings = []

	# Get all potential building targets in range
	# In production, this would query the game manager for buildings
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Entity and body != self:
				var body_team = body.get_component("TeamComponent") as TeamComponent
				var body_stats = body.get_component("StatsComponent") as StatsComponent

				if team_component and body_team and team_component.is_enemy(body):
					# Check if it's a building
					if body_stats and body_stats.is_building:
						buildings.append(body)

	if buildings.is_empty():
		return false

	# Find closest building
	var closest_building = null
	var closest_distance = INF

	for building in buildings:
		var distance = global_position.distance_to(building.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_building = building

	if closest_building:
		current_target = closest_building
		return true

	return false


## Override attack for giant's powerful slam
func _on_attack_performed(target: Entity, damage: int) -> void:
	if not target:
		return

	# Apply damage (base class handles this)
	super._on_attack_performed(target, damage)

	# Create impact effects
	_create_slam_effect()

	# Play slam animation
	if sprite:
		_play_slam_animation()

	# Screen shake effect (if camera available)
	_apply_screen_shake()


## Create slam visual effect
func _create_slam_effect() -> void:
	if impact_particles:
		impact_particles.restart()

	# Create ground crack effect
	var crack = Sprite2D.new()
	crack.modulate = Color(0.2, 0.2, 0.2, 0.5)
	crack.scale = Vector2(2, 2)
	crack.z_index = -1
	add_child(crack)

	# Fade out crack
	var tween = get_tree().create_tween()
	tween.tween_property(crack, "modulate:a", 0.0, 1.0)
	tween.tween_callback(crack.queue_free)


## Play slam animation
func _play_slam_animation() -> void:
	if not sprite:
		return

	# Raise and slam down
	var original_pos = position
	var tween = get_tree().create_tween()

	# Raise up
	tween.tween_property(self, "position", original_pos + Vector2(0, -20), 0.2)
	# Slam down
	tween.tween_property(self, "position", original_pos + Vector2(0, 5), 0.1)
	# Return to position
	tween.tween_property(self, "position", original_pos, 0.1)


## Apply screen shake effect
func _apply_screen_shake() -> void:
	# Get camera if available
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	# Simple screen shake
	var original_offset = camera.offset
	var shake_timer = 0.0

	while shake_timer < SCREEN_SHAKE_DURATION:
		var shake_offset = Vector2(
			randf_range(-SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_INTENSITY),
			randf_range(-SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_INTENSITY)
		)
		camera.offset = original_offset + shake_offset
		await get_tree().process_frame
		shake_timer += get_process_delta_time()

	camera.offset = original_offset


## Override damage taken to apply building damage reduction
func _on_damage_taken(amount: int, source: Entity) -> void:
	# Check if damage is from a building
	var from_building = false
	if source and source.has_component("StatsComponent"):
		var source_stats = source.get_component("StatsComponent") as StatsComponent
		from_building = source_stats.is_building

	# Apply building damage reduction
	if from_building and stats_component:
		var reduced_damage = stats_component.calculate_damage_reduction(amount, true)
		# Visual feedback for reduced damage
		if sprite:
			_show_damage_reduction()

	super._on_damage_taken(amount, source)


## Show visual feedback for damage reduction
func _show_damage_reduction() -> void:
	if not sprite:
		return

	# Create shield effect
	var shield = Sprite2D.new()
	shield.modulate = Color(1, 1, 1, 0.5)
	shield.scale = Vector2(1.2, 1.2)
	add_child(shield)

	# Fade out shield
	var tween = get_tree().create_tween()
	tween.tween_property(shield, "modulate:a", 0.0, 0.3)
	tween.tween_callback(shield.queue_free)


## Giants make the ground shake when walking
func _on_movement_started(destination: Vector2) -> void:
	super._on_movement_started(destination)

	# Create footstep effects
	if movement_component and movement_component.is_moving:
		_create_footstep_effects()


## Create footstep effects
func _create_footstep_effects() -> void:
	while movement_component and movement_component.is_moving:
		# Create dust cloud at feet
		var dust = CPUParticles2D.new()
		dust.position = position + Vector2(0, 20)
		dust.emitting = true
		dust.amount = 5
		dust.lifetime = 0.3
		dust.speed_scale = 1.0
		dust.spread = 20.0
		dust.initial_velocity_min = 20.0
		dust.initial_velocity_max = 40.0
		dust.color = Color(0.6, 0.5, 0.4, 0.5)
		get_parent().add_child(dust)

		# Auto-remove dust after emission
		dust.emitting = false
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(dust):
			dust.queue_free()

		# Wait between footsteps
		await get_tree().create_timer(0.3).timeout


## Get unit description for UI
func get_description() -> String:
	return "Tanky unit that only attacks buildings. Takes reduced damage from defensive structures."


## Get detailed stats for UI
func get_detailed_stats() -> Dictionary:
	return {
		"name": "Giant",
		"hp": health_component.max_health if health_component else GIANT_STATS.hp,
		"damage": attack_component.damage if attack_component else GIANT_STATS.damage,
		"attack_speed": attack_component.attack_speed if attack_component else GIANT_STATS.attack_speed,
		"movement_speed": movement_component.movement_speed if movement_component else GIANT_STATS.movement_speed,
		"range": attack_component.range if attack_component else GIANT_STATS.attack_range,
		"elixir_cost": GIANT_STATS.elixir_cost,
		"level": stats_component.level if stats_component else 1,
		"rarity": stats_component.rarity if stats_component else "Rare",
		"special": "Only targets buildings, 35% damage reduction from buildings"
	}