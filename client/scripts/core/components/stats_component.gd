## Component that stores unit stats and level information
class_name StatsComponent
extends Component

## Unit name/type
@export var unit_name: String = "Unit"

## Elixir cost to deploy
@export var elixir_cost: int = 3

## Unit level (1-14)
@export var level: int = 1

## Unit rarity (Common, Rare, Epic, Legendary)
@export_enum("Common", "Rare", "Epic", "Legendary") var rarity: String = "Common"

## Whether this is a building unit
@export var is_building: bool = false

## Whether this unit targets only buildings
@export var targets_buildings_only: bool = false

## Number of units spawned (for squad units)
@export var spawn_count: int = 1

## Special abilities flags
@export var has_shield: bool = false
@export var has_rage: bool = false
@export var has_spawn: bool = false

## Damage reduction percentages
@export var damage_reduction: float = 0.0
@export var building_damage_reduction: float = 0.0
@export var first_hit_reduction: float = 0.0

## Has taken first hit (for knights)
var has_taken_first_hit: bool = false


func get_component_class() -> String:
	return "StatsComponent"


## Applies level scaling to unit stats
func apply_level_scaling(health_comp: HealthComponent, attack_comp: AttackComponent) -> void:
	if not health_comp or not attack_comp:
		return

	# Level scaling percentages per level (approximation from Clash Royale)
	var level_multiplier = 1.0 + (level - 1) * 0.1

	# Scale health
	health_comp.max_health = int(health_comp.max_health * level_multiplier)
	health_comp.current_health = health_comp.max_health

	# Scale damage
	attack_comp.damage = int(attack_comp.damage * level_multiplier)


## Calculates damage reduction for incoming damage
func calculate_damage_reduction(damage: int, from_building: bool = false) -> int:
	var reduction = damage_reduction

	# Apply building-specific reduction
	if from_building and building_damage_reduction > 0:
		reduction = max(reduction, building_damage_reduction)

	# Apply first hit reduction (knights)
	if not has_taken_first_hit and first_hit_reduction > 0:
		reduction = max(reduction, first_hit_reduction)
		has_taken_first_hit = true

	# Calculate final damage
	var final_damage = int(damage * (1.0 - reduction))
	return max(1, final_damage)  # Minimum 1 damage


## Gets the upgrade cost for the next level
func get_upgrade_cost() -> int:
	if level >= 14:
		return 0  # Max level

	# Cost scaling based on rarity
	var base_cost = 0
	match rarity:
		"Common":
			base_cost = [0, 5, 20, 50, 150, 400, 800, 1500, 2500, 4000, 6000, 8000, 12000, 20000][level]
		"Rare":
			base_cost = [0, 50, 150, 400, 800, 1500, 2500, 4000, 6000, 8000, 12000, 20000, 35000, 50000][level]
		"Epic":
			base_cost = [0, 400, 1000, 2000, 4000, 6000, 10000, 15000, 20000, 30000, 40000, 60000, 80000, 100000][level]
		"Legendary":
			base_cost = [0, 5000, 10000, 20000, 30000, 50000, 75000, 100000, 150000, 200000, 300000, 400000, 500000, 600000][level]

	return base_cost


## Gets the cards needed for the next level
func get_cards_needed() -> int:
	if level >= 14:
		return 0  # Max level

	# Cards needed based on rarity
	var cards_needed = 0
	match rarity:
		"Common":
			cards_needed = [0, 2, 4, 10, 20, 50, 100, 200, 400, 800, 1000, 2000, 5000][level - 1]
		"Rare":
			cards_needed = [0, 2, 4, 10, 20, 50, 100, 200, 400, 800, 1000, 2000][level - 1]
		"Epic":
			cards_needed = [0, 2, 4, 10, 20, 50, 100, 200, 400, 800][level - 1]
		"Legendary":
			cards_needed = [0, 2, 4, 10, 20, 50, 100, 200][level - 1]

	return cards_needed


## Resets the component state
func reset() -> void:
	has_taken_first_hit = false


func serialize() -> Dictionary:
	var data = super.serialize()
	data["unit_name"] = unit_name
	data["elixir_cost"] = elixir_cost
	data["level"] = level
	data["rarity"] = rarity
	data["is_building"] = is_building
	data["targets_buildings_only"] = targets_buildings_only
	data["spawn_count"] = spawn_count
	data["has_shield"] = has_shield
	data["has_rage"] = has_rage
	data["has_spawn"] = has_spawn
	data["damage_reduction"] = damage_reduction
	data["building_damage_reduction"] = building_damage_reduction
	data["first_hit_reduction"] = first_hit_reduction
	data["has_taken_first_hit"] = has_taken_first_hit
	return data


func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("unit_name"):
		unit_name = data["unit_name"]
	if data.has("elixir_cost"):
		elixir_cost = data["elixir_cost"]
	if data.has("level"):
		level = data["level"]
	if data.has("rarity"):
		rarity = data["rarity"]
	if data.has("is_building"):
		is_building = data["is_building"]
	if data.has("targets_buildings_only"):
		targets_buildings_only = data["targets_buildings_only"]
	if data.has("spawn_count"):
		spawn_count = data["spawn_count"]
	if data.has("has_shield"):
		has_shield = data["has_shield"]
	if data.has("has_rage"):
		has_rage = data["has_rage"]
	if data.has("has_spawn"):
		has_spawn = data["has_spawn"]
	if data.has("damage_reduction"):
		damage_reduction = data["damage_reduction"]
	if data.has("building_damage_reduction"):
		building_damage_reduction = data["building_damage_reduction"]
	if data.has("first_hit_reduction"):
		first_hit_reduction = data["first_hit_reduction"]
	if data.has("has_taken_first_hit"):
		has_taken_first_hit = data["has_taken_first_hit"]