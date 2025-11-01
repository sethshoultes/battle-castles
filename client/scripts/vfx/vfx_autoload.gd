extends Node
class_name VFXAutoload

# Autoload script for VFX system
# Add this to Project Settings -> Autoload as "VFX"
# This provides global access to all VFX systems

# VFX subsystems
var manager: VFXManager
var screen: ScreenEffects
var arena: ArenaEffects
var particles: ParticleEffects

# Configuration
var default_quality: VFXManager.QualityLevel = VFXManager.QualityLevel.MEDIUM
var effects_enabled: bool = true

# Performance monitoring
var effect_count: int = 0
var max_effects: int = 100

func _ready() -> void:
	# Initialize VFX subsystems
	_setup_vfx_manager()
	_setup_screen_effects()
	_setup_arena_effects()
	_setup_particle_system()

	# Load user preferences
	_load_settings()

	# Connect to game signals if available
	_connect_game_signals()

	print("VFX System initialized successfully")

func _setup_vfx_manager() -> void:
	manager = VFXManager.new()
	manager.name = "VFXManager"
	add_child(manager)

func _setup_screen_effects() -> void:
	screen = ScreenEffects.new()
	screen.name = "ScreenEffects"
	add_child(screen)

func _setup_arena_effects() -> void:
	arena = ArenaEffects.new()
	arena.name = "ArenaEffects"
	add_child(arena)

func _setup_particle_system() -> void:
	particles = ParticleEffects.new()
	particles.name = "ParticleEffects"
	add_child(particles)

func _connect_game_signals() -> void:
	# Connect to battle manager if it exists
	if has_node("/root/BattleManager"):
		var battle_manager = get_node("/root/BattleManager")

		# Connect battle events to VFX
		if battle_manager.has_signal("unit_deployed"):
			battle_manager.unit_deployed.connect(_on_unit_deployed)
		if battle_manager.has_signal("unit_attacked"):
			battle_manager.unit_attacked.connect(_on_unit_attacked)
		if battle_manager.has_signal("unit_died"):
			battle_manager.unit_died.connect(_on_unit_died)
		if battle_manager.has_signal("tower_destroyed"):
			battle_manager.tower_destroyed.connect(_on_tower_destroyed)
		if battle_manager.has_signal("battle_won"):
			battle_manager.battle_won.connect(_on_battle_won)
		if battle_manager.has_signal("battle_lost"):
			battle_manager.battle_lost.connect(_on_battle_lost)

# Quick access methods (global shortcuts)

func shake(intensity: float = 0.5, duration: float = 0.5) -> void:
	if not effects_enabled:
		return
	if screen:
		screen.shake(intensity, duration)

func flash(color: Color = Color.WHITE, duration: float = 0.1, intensity: float = 0.8) -> void:
	if not effects_enabled:
		return
	if screen:
		screen.flash(color, duration, intensity)

func explosion(position: Vector2, size: float = 1.0) -> void:
	if not effects_enabled:
		return
	if manager:
		manager.spawn_explosion_effect(position, size)

func impact(position: Vector2, strength: float = 0.5) -> void:
	if not effects_enabled:
		return
	if manager:
		manager.spawn_impact_effect(position, strength)

func deploy(position: Vector2) -> void:
	if not effects_enabled:
		return
	if manager:
		manager.spawn_deploy_effect(position)

func heal(position: Vector2) -> void:
	if not effects_enabled:
		return
	if manager:
		manager.spawn_heal_effect(position)

func confetti(position: Vector2) -> void:
	if not effects_enabled:
		return
	if manager:
		manager.spawn_victory_confetti(position)

func slow_motion(time_scale: float = 0.3, duration: float = 1.0) -> void:
	if not effects_enabled:
		return
	if screen:
		screen.slow_motion(time_scale, duration)

func freeze_frame(duration: float = 0.05) -> void:
	if not effects_enabled:
		return
	if screen:
		screen.freeze_frame(duration)

func set_weather(weather: ArenaEffects.WeatherType, transition_time: float = 2.0) -> void:
	if not effects_enabled:
		return
	if arena:
		arena.set_weather(weather, transition_time)

func set_time_of_day(time: ArenaEffects.TimeOfDay, transition_time: float = 3.0) -> void:
	if not effects_enabled:
		return
	if arena:
		arena.set_time_of_day(time, transition_time)

# Event handlers

func _on_unit_deployed(unit: Node, position: Vector2) -> void:
	deploy(position)
	shake(0.2, 0.3)

func _on_unit_attacked(attacker: Node, target: Node, damage: float) -> void:
	if target:
		impact(target.global_position, clamp(damage / 100.0, 0.1, 1.0))

func _on_unit_died(unit: Node) -> void:
	if unit:
		explosion(unit.global_position, 1.0)

func _on_tower_destroyed(tower: Node) -> void:
	if tower:
		explosion(tower.global_position, 3.0)
		shake(1.0, 1.0)
		flash(Color(1.0, 0.5, 0.0), 0.3, 0.8)

func _on_battle_won() -> void:
	# Victory sequence
	slow_motion(0.5, 2.0)
	var viewport_center = get_viewport().size / 2
	confetti(viewport_center)
	if screen:
		screen.victory_effect()

func _on_battle_lost() -> void:
	# Defeat sequence
	if screen:
		screen.death_effect()

# Settings management

func set_quality(level: VFXManager.QualityLevel) -> void:
	default_quality = level
	if manager:
		manager.set_quality(level)
	if screen:
		screen.set_quality(level)
	if arena:
		arena.set_quality(level)
	_save_settings()

func toggle_effects(enabled: bool) -> void:
	effects_enabled = enabled
	_save_settings()

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		default_quality = config.get_value("graphics", "vfx_quality", VFXManager.QualityLevel.MEDIUM)
		effects_enabled = config.get_value("graphics", "vfx_enabled", true)

		# Apply loaded settings
		set_quality(default_quality)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")  # Load existing settings
	config.set_value("graphics", "vfx_quality", default_quality)
	config.set_value("graphics", "vfx_enabled", effects_enabled)
	config.save("user://settings.cfg")

# Performance monitoring

func get_active_effect_count() -> int:
	if not manager:
		return 0

	var count = 0
	for effect_type in manager._effect_pools:
		for effect_data in manager._effect_pools[effect_type]:
			if effect_data["in_use"]:
				count += 1
	return count

func is_performance_limited() -> bool:
	return get_active_effect_count() >= max_effects

# Utility functions

func create_custom_particle_effect(config: Dictionary) -> GPUParticles2D:
	if particles:
		return ParticleEffects.create_custom(config)
	return null

func create_preset_particle_effect(preset_name: String, overrides: Dictionary = {}) -> GPUParticles2D:
	if particles:
		return ParticleEffects.create_from_preset(preset_name, overrides)
	return null

# Debug functions

func debug_test_all_effects() -> void:
	print("Testing all VFX effects...")

	var test_position = get_viewport().size / 2

	# Test each effect type with delay
	var effects_to_test = [
		{"method": "deploy", "args": [test_position], "name": "Deploy"},
		{"method": "impact", "args": [test_position, 0.5], "name": "Impact"},
		{"method": "explosion", "args": [test_position, 1.0], "name": "Explosion"},
		{"method": "heal", "args": [test_position], "name": "Heal"},
		{"method": "shake", "args": [0.5, 0.5], "name": "Screen Shake"},
		{"method": "flash", "args": [Color.WHITE, 0.2, 0.5], "name": "Flash"},
		{"method": "slow_motion", "args": [0.3, 1.0], "name": "Slow Motion"},
		{"method": "confetti", "args": [test_position], "name": "Confetti"}
	]

	for i in range(effects_to_test.size()):
		var effect = effects_to_test[i]
		var timer = Timer.new()
		timer.wait_time = i * 1.5
		timer.one_shot = true
		timer.timeout.connect(func():
			print("Testing effect: " + effect["name"])
			callv(effect["method"], effect["args"])
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

func debug_stress_test() -> void:
	print("Starting VFX stress test...")

	# Spawn many effects to test performance
	var positions = []
	for i in range(10):
		for j in range(10):
			positions.append(Vector2(i * 100 + 100, j * 60 + 100))

	for pos in positions:
		explosion(pos, randf_range(0.5, 1.5))
		await get_tree().create_timer(0.05).timeout

	print("Stress test complete. Active effects: ", get_active_effect_count())