## Component that manages an entity's attack properties and behaviors
class_name AttackComponent
extends Component

## Signal emitted when an attack is performed
signal attack_performed(target: Entity, damage: int)

## Signal emitted when attack cooldown starts
signal attack_cooldown_started(duration: float)

## Signal emitted when attack cooldown ends
signal attack_cooldown_ended()

## Base damage dealt by attacks
@export var damage: int = 10

## Time between attacks in seconds
@export var attack_speed: float = 1.0

## Attack range in units
@export var range: float = 100.0

## Whether this entity can only target buildings
@export var targets_buildings_only: bool = false

## Whether this entity prefers to target buildings
@export var prefers_buildings: bool = false

## Damage multiplier against buildings
@export var building_damage_multiplier: float = 1.0

## Whether area of effect damage is enabled
@export var has_area_damage: bool = false

## Radius of area damage effect
@export var area_damage_radius: float = 50.0

## Percentage of damage dealt to area targets (0.0 to 1.0)
@export var area_damage_percentage: float = 0.5

## Current attack cooldown timer
var attack_cooldown: float = 0.0

## Reference to current target
var current_target: Entity = null

## Whether the entity can currently attack
var can_attack: bool = true


## Returns the component class name for identification
func get_class() -> String:
	return "AttackComponent"


## Called when the component is attached to an entity
func on_attached() -> void:
	attack_cooldown = 0.0
	can_attack = true


## Updates the attack component
func update(delta: float) -> void:
	if not enabled or not is_valid():
		return

	# Update attack cooldown
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			attack_cooldown = 0.0
			can_attack = true
			attack_cooldown_ended.emit()


## Performs an attack on the specified target
## Returns true if the attack was successful
func perform_attack(target: Entity) -> bool:
	if not can_perform_attack(target):
		return false

	var final_damage: int = calculate_damage(target)

	# Apply damage to primary target
	var target_health: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if target_health:
		target_health.take_damage(final_damage, entity)

	# Handle area damage if enabled
	if has_area_damage:
		_apply_area_damage(target, final_damage)

	# Set attack cooldown
	_start_attack_cooldown()

	current_target = target
	attack_performed.emit(target, final_damage)

	return true


## Checks if the entity can attack the specified target
func can_perform_attack(target: Entity) -> bool:
	if not enabled or not is_valid() or not can_attack:
		return false

	if attack_cooldown > 0.0:
		return false

	if target == null or not target.is_active:
		return false

	if not is_target_valid(target):
		return false

	if not is_in_range(target):
		return false

	return true


## Checks if the target is valid based on targeting rules
func is_target_valid(target: Entity) -> bool:
	if target == null or target == entity:
		return false

	# Check team
	var self_team: TeamComponent = entity.get_component("TeamComponent") as TeamComponent
	var target_team: TeamComponent = target.get_component("TeamComponent") as TeamComponent

	if self_team and target_team:
		# Don't attack same team
		if self_team.team_id == target_team.team_id:
			return false

	# Check if target has health
	var target_health: HealthComponent = target.get_component("HealthComponent") as HealthComponent
	if not target_health or target_health.is_dead:
		return false

	# Check building targeting restrictions
	if targets_buildings_only:
		# You would check if target is a building here
		# For now, we'll assume entities have a way to identify as buildings
		pass

	return true


## Checks if the target is within attack range
func is_in_range(target: Entity) -> bool:
	if not entity or not target:
		return false

	var distance: float = entity.global_position.distance_to(target.global_position)
	return distance <= range


## Calculates the damage to deal to a target
func calculate_damage(target: Entity) -> int:
	var final_damage: int = damage

	# Apply building damage multiplier if applicable
	# You would check if target is a building here
	# For demonstration, we'll check for a hypothetical BuildingComponent
	if target.has_component("BuildingComponent"):
		final_damage = int(final_damage * building_damage_multiplier)

	return max(1, final_damage)


## Gets the current attack speed (attacks per second)
func get_attacks_per_second() -> float:
	if attack_speed <= 0.0:
		return 0.0
	return 1.0 / attack_speed


## Sets a new attack speed
func set_attack_speed(new_speed: float) -> void:
	attack_speed = max(0.1, new_speed)  # Minimum 0.1 seconds between attacks


## Modifies damage by a percentage
func modify_damage(percentage: float) -> void:
	damage = int(damage * (1.0 + percentage))
	damage = max(1, damage)


## Starts the attack cooldown
func _start_attack_cooldown() -> void:
	attack_cooldown = attack_speed
	can_attack = false
	attack_cooldown_started.emit(attack_speed)


## Applies area damage around the target
func _apply_area_damage(center_target: Entity, base_damage: int) -> void:
	if not has_area_damage or area_damage_radius <= 0.0:
		return

	var area_damage_amount: int = int(base_damage * area_damage_percentage)
	if area_damage_amount <= 0:
		return

	# Get all entities from GameManager (will be implemented in game_manager.gd)
	# For now, we'll use a placeholder
	# var game_manager = get_node("/root/GameManager")
	# var all_entities = game_manager.get_all_entities()

	# Apply damage to entities in radius
	# This would be implemented when GameManager is available


## Resets the attack cooldown
func reset_cooldown() -> void:
	attack_cooldown = 0.0
	can_attack = true


## Resets the component to its default state
func reset() -> void:
	attack_cooldown = 0.0
	can_attack = true
	current_target = null


## Returns a dictionary representation of the component's data
func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["damage"] = damage
	data["attack_speed"] = attack_speed
	data["range"] = range
	data["targets_buildings_only"] = targets_buildings_only
	data["prefers_buildings"] = prefers_buildings
	data["building_damage_multiplier"] = building_damage_multiplier
	data["has_area_damage"] = has_area_damage
	data["area_damage_radius"] = area_damage_radius
	data["area_damage_percentage"] = area_damage_percentage
	return data


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("damage"):
		damage = data["damage"]
	if data.has("attack_speed"):
		attack_speed = data["attack_speed"]
	if data.has("range"):
		range = data["range"]
	if data.has("targets_buildings_only"):
		targets_buildings_only = data["targets_buildings_only"]
	if data.has("prefers_buildings"):
		prefers_buildings = data["prefers_buildings"]
	if data.has("building_damage_multiplier"):
		building_damage_multiplier = data["building_damage_multiplier"]
	if data.has("has_area_damage"):
		has_area_damage = data["has_area_damage"]
	if data.has("area_damage_radius"):
		area_damage_radius = data["area_damage_radius"]
	if data.has("area_damage_percentage"):
		area_damage_percentage = data["area_damage_percentage"]