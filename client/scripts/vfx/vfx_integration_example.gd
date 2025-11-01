extends Node
class_name VFXIntegrationExample

# Example script showing how to integrate the VFX system with game units and battles
# This demonstrates best practices for using the VFX Manager and effects

# References to VFX systems (assuming they're autoloaded as singletons)
var vfx_manager: VFXManager
var screen_effects: ScreenEffects
var arena_effects: ArenaEffects

func _ready() -> void:
	# Get references to VFX singletons
	# These would typically be autoloaded in project settings
	if has_node("/root/VFXManager"):
		vfx_manager = get_node("/root/VFXManager")
	if has_node("/root/ScreenEffects"):
		screen_effects = get_node("/root/ScreenEffects")
	if has_node("/root/ArenaEffects"):
		arena_effects = get_node("/root/ArenaEffects")

# Unit deployment effect
func on_unit_deployed(unit_position: Vector2, unit_type: String = "normal") -> void:
	if not vfx_manager:
		return

	# Spawn deploy sparkles
	vfx_manager.spawn_deploy_effect(unit_position)

	# Add screen shake for impact
	if screen_effects:
		screen_effects.shake(0.2, 0.3)

	# Special effects for different unit types
	match unit_type:
		"legendary":
			# Extra flashy deploy for legendary units
			vfx_manager.spawn_effect("magic", unit_position, {
				"scale": Vector2(1.5, 1.5),
				"color": Color(1.0, 0.8, 0.0, 1.0)
			})
			if screen_effects:
				screen_effects.flash(Color(1.0, 0.9, 0.0), 0.2, 0.5)

		"spell":
			# Magical deploy effect
			vfx_manager.spawn_effect("magic", unit_position, {
				"scale": Vector2(1.2, 1.2)
			})

# Unit attack effect
func on_unit_attack(attacker_pos: Vector2, target_pos: Vector2, damage: float, attack_type: String = "physical") -> void:
	if not vfx_manager:
		return

	# Spawn impact at target
	var damage_percent = clamp(damage / 100.0, 0.1, 1.0)
	vfx_manager.spawn_impact_effect(target_pos, damage_percent)

	# Different effects for attack types
	match attack_type:
		"ranged":
			# Create arrow trail from attacker to target
			_create_projectile_trail(attacker_pos, target_pos, "arrow")

		"magic":
			# Magic bolt effect
			_create_projectile_trail(attacker_pos, target_pos, "magic")
			vfx_manager.spawn_effect("electric", target_pos)

		"area":
			# Area damage explosion
			vfx_manager.spawn_explosion_effect(target_pos, 1.5)

	# Critical hit effects
	if damage > 50:
		if screen_effects:
			screen_effects.critical_hit_effect()

# Unit death effect
func on_unit_death(unit_position: Vector2, unit_type: String = "normal", killer_team: String = "") -> void:
	if not vfx_manager:
		return

	# Death explosion
	var explosion_size = 1.0
	if unit_type == "boss":
		explosion_size = 2.0
	elif unit_type == "building":
		explosion_size = 2.5

	vfx_manager.spawn_explosion_effect(unit_position, explosion_size)

	# Screen effects for important deaths
	if unit_type in ["boss", "building"]:
		if screen_effects:
			screen_effects.death_effect()

# Tower destruction effect
func on_tower_destroyed(tower_position: Vector2, team: String) -> void:
	if not vfx_manager:
		return

	# Big explosion
	vfx_manager.spawn_explosion_effect(tower_position, 3.0)

	# Multiple debris explosions
	for i in range(3):
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var delay = i * 0.1

		# Use timer for delayed explosions
		var timer = Timer.new()
		timer.wait_time = delay
		timer.one_shot = true
		timer.timeout.connect(func():
			vfx_manager.spawn_explosion_effect(tower_position + offset, randf_range(0.8, 1.5))
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

	# Major screen shake
	if screen_effects:
		screen_effects.explosion_effect(1.0)

# Spell casting effects
func on_spell_cast(spell_name: String, position: Vector2, area_radius: float = 0.0) -> void:
	if not vfx_manager:
		return

	match spell_name:
		"fireball":
			vfx_manager.spawn_effect("fire", position, {
				"scale": Vector2(2.0, 2.0)
			})
			if screen_effects:
				screen_effects.flash(Color(1.0, 0.5, 0.0), 0.2)

		"heal":
			vfx_manager.spawn_heal_effect(position)

		"freeze":
			vfx_manager.spawn_effect("ice", position)
			if screen_effects:
				screen_effects.flash(Color(0.5, 0.8, 1.0), 0.3)

		"lightning":
			vfx_manager.spawn_effect("electric", position, {
				"scale": Vector2(3.0, 3.0)
			})
			if screen_effects:
				screen_effects.flash(Color.WHITE, 0.1, 1.0)
				screen_effects.shake(0.5, 0.5)

		"poison_cloud":
			for i in range(5):
				var offset = Vector2(
					randf_range(-area_radius, area_radius),
					randf_range(-area_radius, area_radius)
				)
				vfx_manager.spawn_effect("poison", position + offset)

# Battle end effects
func on_battle_victory(winning_team: String) -> void:
	if not vfx_manager:
		return

	# Victory confetti at multiple positions
	var viewport_size = get_viewport().size
	var positions = [
		Vector2(viewport_size.x * 0.25, viewport_size.y * 0.3),
		Vector2(viewport_size.x * 0.5, viewport_size.y * 0.3),
		Vector2(viewport_size.x * 0.75, viewport_size.y * 0.3)
	]

	for pos in positions:
		vfx_manager.spawn_victory_confetti(pos)

	# Screen effects
	if screen_effects:
		screen_effects.victory_effect()

	# Set celebratory weather
	if arena_effects:
		arena_effects.set_weather(ArenaEffects.WeatherType.CLEAR)

func on_battle_defeat() -> void:
	if screen_effects:
		screen_effects.fade_to_black(2.0)

	# Set gloomy weather
	if arena_effects:
		arena_effects.set_weather(ArenaEffects.WeatherType.RAIN)

# Environmental effects
func set_battle_environment(map_name: String) -> void:
	if not arena_effects:
		return

	match map_name:
		"forest":
			arena_effects.set_weather(ArenaEffects.WeatherType.CLEAR)
			arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.DAY)

		"mountain":
			arena_effects.set_weather(ArenaEffects.WeatherType.SNOW)
			arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.DUSK)

		"desert":
			arena_effects.set_weather(ArenaEffects.WeatherType.WINDY)
			arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.DAY)

		"swamp":
			arena_effects.set_weather(ArenaEffects.WeatherType.FOG)
			arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.DAWN)

		"castle_siege":
			arena_effects.set_weather(ArenaEffects.WeatherType.STORM)
			arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.NIGHT)

# Overtime/sudden death effects
func on_overtime_start() -> void:
	if screen_effects:
		# Add dramatic slow motion
		screen_effects.slow_motion(0.7, 1.0)

		# Flash and vignette for drama
		screen_effects.flash(Color(1.0, 0.0, 0.0), 0.5, 0.5)
		screen_effects.vignette_fade(0.4, 1.0)

	if arena_effects:
		# Storm weather for dramatic effect
		arena_effects.set_weather(ArenaEffects.WeatherType.STORM)

# Helper functions

func _create_projectile_trail(from: Vector2, to: Vector2, projectile_type: String) -> void:
	# Create a moving particle trail from one position to another
	var trail = vfx_manager.spawn_effect("arrow_trail", from)
	if not trail:
		return

	# Animate movement to target
	var tween = create_tween()
	tween.tween_property(trail, "global_position", to, 0.3)
	tween.tween_callback(func():
		# Impact effect at destination
		vfx_manager.spawn_impact_effect(to, 0.5)
	)

# Quality settings management
func set_vfx_quality(quality: VFXManager.QualityLevel) -> void:
	if vfx_manager:
		vfx_manager.set_quality(quality)
	if screen_effects:
		screen_effects.set_quality(quality)
	if arena_effects:
		arena_effects.set_quality(quality)

# Cleanup
func cleanup_battle_effects() -> void:
	# Reset all effects when leaving battle
	if screen_effects:
		Engine.time_scale = 1.0
		screen_effects.shake_trauma = 0.0
		screen_effects.fade_from_black(0.5)

	if arena_effects:
		arena_effects.set_weather(ArenaEffects.WeatherType.CLEAR)
		arena_effects.set_time_of_day(ArenaEffects.TimeOfDay.DAY)