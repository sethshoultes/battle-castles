## System that processes combat between entities
class_name CombatSystem
extends Node

## Signal emitted when combat occurs
signal combat_occurred(attacker: Entity, defender: Entity, damage: int)

## Signal emitted when an entity is destroyed in combat
signal entity_destroyed(entity: Entity, killer: Entity)

## Reference to the game manager
var game_manager: GameManager = null

## Combat statistics tracking
var total_damage_dealt: int = 0
var total_entities_destroyed: int = 0
var combat_events_processed: int = 0


func _init() -> void:
	name = "CombatSystem"


## Initializes the combat system with a game manager reference
func initialize(manager: GameManager) -> void:
	game_manager = manager


## Processes combat for all entities
func process_combat(entities: Array, delta: float) -> void:
	if entities.is_empty():
		return

	for entity in entities:
		if not _is_combat_ready(entity):
			continue

		_process_entity_combat(entity, entities, delta)

	combat_events_processed += 1


## Processes combat for a single entity
func _process_entity_combat(attacker: Entity, all_entities: Array, delta: float) -> void:
	var attack_comp: AttackComponent = attacker.get_component("AttackComponent") as AttackComponent
	if not attack_comp or not attack_comp.enabled:
		return

	# Update attack cooldown
	attack_comp.update(delta)

	# Check if entity can attack
	if not attack_comp.can_attack:
		return

	# Find a target
	var target: Entity = find_best_target(attacker, all_entities, attack_comp)
	if not target:
		return

	# Perform the attack
	if attack_comp.perform_attack(target):
		var damage: int = attack_comp.calculate_damage(target)
		combat_occurred.emit(attacker, target, damage)
		total_damage_dealt += damage

		# Check if target was destroyed
		var target_health: HealthComponent = target.get_component("HealthComponent") as HealthComponent
		if target_health and target_health.is_dead:
			entity_destroyed.emit(target, attacker)
			total_entities_destroyed += 1


## Finds the best target for an attacker
func find_best_target(attacker: Entity, all_entities: Array, attack_comp: AttackComponent) -> Entity:
	var best_target: Entity = null
	var best_priority: float = -1.0

	var attacker_team: TeamComponent = attacker.get_component("TeamComponent") as TeamComponent

	for entity in all_entities:
		if entity == attacker or not entity.is_active:
			continue

		# Check if it's a valid target
		if not attack_comp.is_target_valid(entity):
			continue

		# Check if it's in range
		if not attack_comp.is_in_range(entity):
			continue

		# Calculate target priority
		var priority: float = _calculate_target_priority(attacker, entity, attack_comp)

		if priority > best_priority:
			best_priority = priority
			best_target = entity

	return best_target


## Calculates the priority of a target
func _calculate_target_priority(attacker: Entity, target: Entity, attack_comp: AttackComponent) -> float:
	var priority: float = 100.0

	# Distance factor - closer targets have higher priority
	var distance: float = attacker.global_position.distance_to(target.global_position)
	priority -= distance * 0.1

	# Health factor - prefer lower health targets
	var target_health: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if target_health:
		var health_percentage: float = target_health.get_health_percentage()
		priority += (1.0 - health_percentage) * 20.0

	# Building preference
	if attack_comp.prefers_buildings and target.has_component("BuildingComponent"):
		priority += 50.0

	# Threat level - prioritize targets that can attack back
	if target.has_component("AttackComponent"):
		priority += 30.0

	return priority


## Calculates damage with all modifiers applied
func calculate_damage(attacker: Entity, defender: Entity, base_damage: int) -> int:
	var final_damage: float = float(base_damage)

	# Get components
	var attack_comp: AttackComponent = attacker.get_component("AttackComponent") as AttackComponent
	var defender_health: HealthComponent = defender.get_component("HealthComponent") as HealthComponent

	if not attack_comp or not defender_health:
		return base_damage

	# Apply building damage multiplier if applicable
	if defender.has_component("BuildingComponent"):
		final_damage *= attack_comp.building_damage_multiplier

	# Apply armor reduction
	if defender_health.armor > 0:
		var damage_reduction: float = defender_health.armor / (100.0 + defender_health.armor)
		final_damage *= (1.0 - damage_reduction)

	# Ensure minimum damage
	final_damage = max(1.0, final_damage)

	return int(final_damage)


## Applies damage to a target
func apply_damage(target: Entity, damage: int, attacker: Entity = null) -> int:
	var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if not health_comp:
		push_error("Cannot apply damage to entity without HealthComponent")
		return 0

	return health_comp.take_damage(damage, attacker)


## Applies area damage around a position
func apply_area_damage(center: Vector2, radius: float, damage: int, attacker: Entity = null, friendly_fire: bool = false) -> Array[Entity]:
	var damaged_entities: Array[Entity] = []

	if not game_manager:
		push_error("CombatSystem requires GameManager reference")
		return damaged_entities

	var attacker_team: TeamComponent = null
	if attacker:
		attacker_team = attacker.get_component("TeamComponent") as TeamComponent

	var all_entities: Array = game_manager.get_all_entities()

	for entity in all_entities:
		if not entity.is_active:
			continue

		# Skip the attacker
		if entity == attacker:
			continue

		# Check distance
		var distance: float = entity.global_position.distance_to(center)
		if distance > radius:
			continue

		# Check friendly fire
		if not friendly_fire and attacker_team:
			var entity_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent
			if entity_team and not attacker_team.is_enemy(entity):
				continue

		# Apply damage with falloff based on distance
		var damage_falloff: float = 1.0 - (distance / radius) * 0.5
		var final_damage: int = int(damage * damage_falloff)

		if apply_damage(entity, final_damage, attacker) > 0:
			damaged_entities.append(entity)

	return damaged_entities


## Applies a damage over time effect
func apply_damage_over_time(target: Entity, damage_per_tick: int, duration: float, tick_rate: float = 1.0, attacker: Entity = null) -> void:
	if not target or not target.is_active:
		return

	var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if not health_comp:
		return

	var ticks: int = int(duration / tick_rate)
	var current_tick: int = 0

	while current_tick < ticks and target.is_active and not health_comp.is_dead:
		apply_damage(target, damage_per_tick, attacker)
		current_tick += 1

		if target.is_inside_tree():
			await target.get_tree().create_timer(tick_rate).timeout
		else:
			break


## Heals a target
func heal_target(target: Entity, amount: int) -> int:
	var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if not health_comp:
		push_error("Cannot heal entity without HealthComponent")
		return 0

	return health_comp.heal(amount)


## Applies area healing around a position
func apply_area_healing(center: Vector2, radius: float, amount: int, healer: Entity = null, heal_enemies: bool = false) -> Array[Entity]:
	var healed_entities: Array[Entity] = []

	if not game_manager:
		push_error("CombatSystem requires GameManager reference")
		return healed_entities

	var healer_team: TeamComponent = null
	if healer:
		healer_team = healer.get_component("TeamComponent") as TeamComponent

	var all_entities: Array = game_manager.get_all_entities()

	for entity in all_entities:
		if not entity.is_active:
			continue

		# Check distance
		var distance: float = entity.global_position.distance_to(center)
		if distance > radius:
			continue

		# Check team
		if not heal_enemies and healer_team:
			var entity_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent
			if entity_team and healer_team.is_enemy(entity):
				continue

		if heal_target(entity, amount) > 0:
			healed_entities.append(entity)

	return healed_entities


## Checks if an entity is ready for combat
func _is_combat_ready(entity: Entity) -> bool:
	if not entity or not entity.is_active:
		return false

	# Check for required components
	if not entity.has_component("AttackComponent"):
		return false

	if not entity.has_component("TeamComponent"):
		return false

	var health_comp: HealthComponent = entity.get_component("HealthComponent") as HealthComponent
	if health_comp and health_comp.is_dead:
		return false

	return true


## Gets combat statistics
func get_statistics() -> Dictionary:
	return {
		"total_damage_dealt": total_damage_dealt,
		"total_entities_destroyed": total_entities_destroyed,
		"combat_events_processed": combat_events_processed
	}


## Resets combat statistics
func reset_statistics() -> void:
	total_damage_dealt = 0
	total_entities_destroyed = 0
	combat_events_processed = 0