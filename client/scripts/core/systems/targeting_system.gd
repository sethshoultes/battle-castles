## System that handles target acquisition and prioritization for entities
class_name TargetingSystem
extends Node

## Enum for targeting strategies
enum TargetingStrategy {
	NEAREST,           # Target nearest enemy
	LOWEST_HEALTH,     # Target enemy with lowest health
	HIGHEST_HEALTH,    # Target enemy with highest health
	HIGHEST_DAMAGE,    # Target enemy with highest damage
	BUILDINGS_FIRST,   # Prioritize buildings
	UNITS_FIRST,       # Prioritize units
	MOST_THREATENING,  # Target based on threat level
	RANDOM            # Random valid target
}

## Signal emitted when a new target is acquired
signal target_acquired(entity: Entity, target: Entity)

## Signal emitted when a target is lost
signal target_lost(entity: Entity, previous_target: Entity)

## Reference to the game manager
var game_manager: GameManager = null

## Target acquisition statistics
var targets_acquired: int = 0
var targets_lost: int = 0


func _init() -> void:
	name = "TargetingSystem"


## Initializes the targeting system with a game manager reference
func initialize(manager: GameManager) -> void:
	game_manager = manager


## Finds a target for an entity based on its attack component settings
func find_target(entity: Entity, all_entities: Array) -> Entity:
	if not entity or not entity.is_active:
		return null

	var attack_comp: AttackComponent = entity.get_component("AttackComponent") as AttackComponent
	if not attack_comp:
		return null

	# Determine targeting strategy
	var strategy: TargetingStrategy = _determine_strategy(attack_comp)

	# Get valid targets
	var valid_targets: Array[Entity] = _get_valid_targets(entity, all_entities, attack_comp)

	if valid_targets.is_empty():
		return null

	# Select target based on strategy
	var target: Entity = _select_target_by_strategy(entity, valid_targets, strategy, attack_comp)

	if target:
		targets_acquired += 1
		target_acquired.emit(entity, target)

	return target


## Gets all valid targets for an entity
func _get_valid_targets(entity: Entity, all_entities: Array, attack_comp: AttackComponent) -> Array[Entity]:
	var valid_targets: Array[Entity] = []
	var entity_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent

	for potential_target in all_entities:
		if potential_target == entity or not potential_target.is_active:
			continue

		# Check if target is valid
		if not attack_comp.is_target_valid(potential_target):
			continue

		# Check if target is in range
		if not attack_comp.is_in_range(potential_target):
			continue

		# Check team
		if entity_team:
			var target_team: TeamComponent = potential_target.get_component("TeamComponent") as TeamComponent
			if target_team and not entity_team.is_enemy(potential_target):
				continue

		# Check if target has health
		var target_health: HealthComponent = potential_target.get_component("HealthComponent") as HealthComponent
		if not target_health or target_health.is_dead:
			continue

		# Check building targeting restrictions
		if attack_comp.targets_buildings_only:
			if not potential_target.has_component("BuildingComponent"):
				continue

		valid_targets.append(potential_target)

	return valid_targets


## Determines the targeting strategy based on attack component settings
func _determine_strategy(attack_comp: AttackComponent) -> TargetingStrategy:
	if attack_comp.targets_buildings_only:
		return TargetingStrategy.BUILDINGS_FIRST
	elif attack_comp.prefers_buildings:
		return TargetingStrategy.BUILDINGS_FIRST
	else:
		# Default to nearest target
		return TargetingStrategy.NEAREST


## Selects a target based on the specified strategy
func _select_target_by_strategy(entity: Entity, valid_targets: Array[Entity], strategy: TargetingStrategy, attack_comp: AttackComponent) -> Entity:
	match strategy:
		TargetingStrategy.NEAREST:
			return _get_nearest_target(entity, valid_targets)

		TargetingStrategy.LOWEST_HEALTH:
			return _get_lowest_health_target(valid_targets)

		TargetingStrategy.HIGHEST_HEALTH:
			return _get_highest_health_target(valid_targets)

		TargetingStrategy.HIGHEST_DAMAGE:
			return _get_highest_damage_target(valid_targets)

		TargetingStrategy.BUILDINGS_FIRST:
			return _get_building_priority_target(entity, valid_targets)

		TargetingStrategy.UNITS_FIRST:
			return _get_unit_priority_target(entity, valid_targets)

		TargetingStrategy.MOST_THREATENING:
			return _get_most_threatening_target(entity, valid_targets)

		TargetingStrategy.RANDOM:
			return _get_random_target(valid_targets)

		_:
			return _get_nearest_target(entity, valid_targets)


## Gets the nearest valid target
func _get_nearest_target(entity: Entity, targets: Array[Entity]) -> Entity:
	var nearest_target: Entity = null
	var nearest_distance: float = INF

	for target in targets:
		var distance: float = entity.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target

	return nearest_target


## Gets the target with the lowest health
func _get_lowest_health_target(targets: Array[Entity]) -> Entity:
	var lowest_health_target: Entity = null
	var lowest_health: int = INF

	for target in targets:
		var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
		if health_comp and health_comp.current_health < lowest_health:
			lowest_health = health_comp.current_health
			lowest_health_target = target

	return lowest_health_target


## Gets the target with the highest health
func _get_highest_health_target(targets: Array[Entity]) -> Entity:
	var highest_health_target: Entity = null
	var highest_health: int = 0

	for target in targets:
		var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
		if health_comp and health_comp.current_health > highest_health:
			highest_health = health_comp.current_health
			highest_health_target = target

	return highest_health_target


## Gets the target with the highest damage potential
func _get_highest_damage_target(targets: Array[Entity]) -> Entity:
	var highest_damage_target: Entity = null
	var highest_damage: int = 0

	for target in targets:
		var attack_comp: AttackComponent = target.get_component("AttackComponent") as AttackComponent
		if attack_comp and attack_comp.damage > highest_damage:
			highest_damage = attack_comp.damage
			highest_damage_target = target

	return highest_damage_target


## Gets a target prioritizing buildings
func _get_building_priority_target(entity: Entity, targets: Array[Entity]) -> Entity:
	var building_targets: Array[Entity] = []
	var unit_targets: Array[Entity] = []

	for target in targets:
		if target.has_component("BuildingComponent"):
			building_targets.append(target)
		else:
			unit_targets.append(target)

	# Prioritize buildings if available
	if not building_targets.is_empty():
		return _get_nearest_target(entity, building_targets)
	elif not unit_targets.is_empty():
		return _get_nearest_target(entity, unit_targets)
	else:
		return null


## Gets a target prioritizing units over buildings
func _get_unit_priority_target(entity: Entity, targets: Array[Entity]) -> Entity:
	var building_targets: Array[Entity] = []
	var unit_targets: Array[Entity] = []

	for target in targets:
		if target.has_component("BuildingComponent"):
			building_targets.append(target)
		else:
			unit_targets.append(target)

	# Prioritize units if available
	if not unit_targets.is_empty():
		return _get_nearest_target(entity, unit_targets)
	elif not building_targets.is_empty():
		return _get_nearest_target(entity, building_targets)
	else:
		return null


## Gets the most threatening target based on multiple factors
func _get_most_threatening_target(entity: Entity, targets: Array[Entity]) -> Entity:
	var most_threatening_target: Entity = null
	var highest_threat_level: float = 0.0

	for target in targets:
		var threat_level: float = _calculate_threat_level(entity, target)
		if threat_level > highest_threat_level:
			highest_threat_level = threat_level
			most_threatening_target = target

	return most_threatening_target


## Calculates the threat level of a target
func _calculate_threat_level(entity: Entity, target: Entity) -> float:
	var threat_level: float = 0.0

	# Distance factor - closer enemies are more threatening
	var distance: float = entity.global_position.distance_to(target.global_position)
	threat_level += (1000.0 / max(distance, 1.0)) * 10.0

	# Damage factor
	var attack_comp: AttackComponent = target.get_component("AttackComponent") as AttackComponent
	if attack_comp:
		threat_level += attack_comp.damage * 2.0

		# Can this target attack us?
		if attack_comp.is_in_range(entity):
			threat_level += 50.0

	# Health factor - healthier enemies are more threatening
	var health_comp: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if health_comp:
		threat_level += health_comp.current_health * 0.1

	# Speed factor - faster enemies are more threatening
	var movement_comp: MovementComponent = target.get_component("MovementComponent") as MovementComponent
	if movement_comp:
		threat_level += movement_comp.speed * 0.5

	# Building targets are less threatening
	if target.has_component("BuildingComponent"):
		threat_level *= 0.5

	return threat_level


## Gets a random target from the list
func _get_random_target(targets: Array[Entity]) -> Entity:
	if targets.is_empty():
		return null

	var index: int = randi() % targets.size()
	return targets[index]


## Updates target validity for an entity
func update_target_validity(entity: Entity, current_target: Entity) -> Entity:
	if not current_target or not current_target.is_active:
		targets_lost += 1
		target_lost.emit(entity, current_target)
		return null

	var attack_comp: AttackComponent = entity.get_component("AttackComponent") as AttackComponent
	if not attack_comp:
		return null

	# Check if target is still valid
	if not attack_comp.is_target_valid(current_target):
		targets_lost += 1
		target_lost.emit(entity, current_target)
		return null

	# Check if target is still in range
	if not attack_comp.is_in_range(current_target):
		targets_lost += 1
		target_lost.emit(entity, current_target)
		return null

	# Target is still valid
	return current_target


## Gets all enemies within a radius
func get_enemies_in_radius(entity: Entity, radius: float, all_entities: Array) -> Array[Entity]:
	var enemies: Array[Entity] = []
	var entity_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent

	if not entity_team:
		return enemies

	for other_entity in all_entities:
		if other_entity == entity or not other_entity.is_active:
			continue

		var distance: float = entity.global_position.distance_to(other_entity.global_position)
		if distance > radius:
			continue

		if entity_team.is_enemy(other_entity):
			enemies.append(other_entity)

	return enemies


## Gets all allies within a radius
func get_allies_in_radius(entity: Entity, radius: float, all_entities: Array, include_self: bool = false) -> Array[Entity]:
	var allies: Array[Entity] = []
	var entity_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent

	if not entity_team:
		return allies

	for other_entity in all_entities:
		if not include_self and other_entity == entity:
			continue

		if not other_entity.is_active:
			continue

		var distance: float = entity.global_position.distance_to(other_entity.global_position)
		if distance > radius:
			continue

		if entity_team.is_ally(other_entity) or (include_self and other_entity == entity):
			allies.append(other_entity)

	return allies


## Gets targeting statistics
func get_statistics() -> Dictionary:
	return {
		"targets_acquired": targets_acquired,
		"targets_lost": targets_lost
	}


## Resets targeting statistics
func reset_statistics() -> void:
	targets_acquired = 0
	targets_lost = 0