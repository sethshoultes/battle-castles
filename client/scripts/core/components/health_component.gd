## Component that manages an entity's health, armor, and damage handling
class_name HealthComponent
extends Component

## Signal emitted when health changes
signal health_changed(new_health: int, max_health: int)

## Signal emitted when the entity takes damage
signal damage_taken(amount: int, source: Entity)

## Signal emitted when the entity is healed
signal healed(amount: int)

## Signal emitted when the entity dies
signal died()

## Current health points
@export var current_health: int = 100

## Maximum health points
@export var max_health: int = 100

## Armor value that reduces incoming damage
@export var armor: int = 0

## Whether this entity is currently invulnerable
var is_invulnerable: bool = false

## Whether this entity is dead
var is_dead: bool = false


func _init() -> void:
	current_health = max_health


## Returns the component class name for identification
func get_component_class() -> String:
	return "HealthComponent"


## Called when the component is attached to an entity
func on_attached() -> void:
	if current_health > max_health:
		current_health = max_health
	is_dead = current_health <= 0


## Takes damage and applies armor reduction
## Returns the actual damage dealt after armor reduction
func take_damage(amount: int, source: Entity = null) -> int:
	if is_invulnerable or is_dead or amount <= 0:
		return 0

	# Calculate damage after armor reduction
	var damage_reduction: float = armor / (100.0 + armor)
	var final_damage: int = int(amount * (1.0 - damage_reduction))
	final_damage = max(1, final_damage)  # Minimum 1 damage

	var old_health: int = current_health
	current_health = max(0, current_health - final_damage)

	var actual_damage: int = old_health - current_health

	damage_taken.emit(actual_damage, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0 and not is_dead:
		_die()

	return actual_damage


## Heals the entity by the specified amount
## Returns the actual amount healed
func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0

	var old_health: int = current_health
	current_health = min(max_health, current_health + amount)

	var actual_heal: int = current_health - old_health

	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)

	return actual_heal


## Sets the maximum health and optionally heals to full
func set_max_health(new_max: int, heal_to_full: bool = false) -> void:
	if new_max <= 0:
		push_error("Max health must be greater than 0")
		return

	max_health = new_max

	if heal_to_full:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0 and not is_dead:
		_die()


## Revives the entity with the specified health percentage
func revive(health_percentage: float = 1.0) -> void:
	if not is_dead:
		return

	is_dead = false
	current_health = int(max_health * clamp(health_percentage, 0.0, 1.0))
	current_health = max(1, current_health)

	health_changed.emit(current_health, max_health)


## Gets the current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


## Checks if the entity is at full health
func is_full_health() -> bool:
	return current_health >= max_health


## Makes the entity invulnerable for a duration
func set_invulnerable(duration: float) -> void:
	if duration <= 0.0:
		is_invulnerable = false
		return

	is_invulnerable = true

	if entity and entity.is_inside_tree():
		await entity.get_tree().create_timer(duration).timeout
		is_invulnerable = false


## Handles entity death
func _die() -> void:
	is_dead = true
	current_health = 0
	died.emit()

	if entity:
		entity.is_active = false


## Resets the component to its default state
func reset() -> void:
	current_health = max_health
	is_dead = false
	is_invulnerable = false
	health_changed.emit(current_health, max_health)


## Returns a dictionary representation of the component's data
func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["current_health"] = current_health
	data["max_health"] = max_health
	data["armor"] = armor
	data["is_invulnerable"] = is_invulnerable
	data["is_dead"] = is_dead
	return data


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("max_health"):
		max_health = data["max_health"]
	if data.has("current_health"):
		current_health = data["current_health"]
	if data.has("armor"):
		armor = data["armor"]
	if data.has("is_invulnerable"):
		is_invulnerable = data["is_invulnerable"]
	if data.has("is_dead"):
		is_dead = data["is_dead"]