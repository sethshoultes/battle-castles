## CardData resource for storing unit card information
## Used for deck building and battle deployment
class_name CardData
extends Resource

## Display information
@export var card_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var rarity: String = "Common" # Common, Rare, Epic, Legendary

## Game mechanics
@export var elixir_cost: int = 3
@export var unit_type: String = "" # "knight", "goblin", "archer", "giant"
@export var deploy_count: int = 1 # How many units spawn (e.g., 3 for goblins)
@export var deploy_time: float = 1.0

## Unit stats (Level 1 base values)
@export var hitpoints: int = 1000
@export var damage: int = 50
@export var attack_speed: float = 1.0 # Seconds between attacks
@export var movement_speed: float = 60.0 # Units per second
@export var attack_range: float = 0.5 # Tiles
@export var target_type: String = "Ground" # "Ground", "Air", "Both"

## AI behavior
@export var targets_buildings_only: bool = false
@export var flies: bool = false
@export var splash_damage: bool = false

## Level progression (multipliers per level)
@export var hp_growth: float = 1.1 # 10% per level
@export var damage_growth: float = 1.1 # 10% per level

## Visual/Audio
@export var color_modulate: Color = Color.WHITE


## Get stats for a specific card level
func get_stats_for_level(level: int) -> Dictionary:
	var level_multiplier: float = pow(1.1, level - 1)

	return {
		"hitpoints": int(hitpoints * level_multiplier),
		"damage": int(damage * level_multiplier),
		"dps": float(damage * level_multiplier) / attack_speed,
		"attack_speed": attack_speed,
		"movement_speed": movement_speed,
		"attack_range": attack_range
	}


## Get calculated DPS
func get_dps() -> float:
	if attack_speed > 0:
		return float(damage) / attack_speed
	return 0.0


## Check if card can be played with given elixir
func can_afford(current_elixir: float) -> bool:
	return current_elixir >= float(elixir_cost)


## Get elixir efficiency (HP per elixir)
func get_hp_efficiency() -> float:
	if elixir_cost > 0:
		return float(hitpoints * deploy_count) / float(elixir_cost)
	return 0.0


## Get DPS efficiency (DPS per elixir)
func get_dps_efficiency() -> float:
	if elixir_cost > 0:
		return get_dps() * deploy_count / float(elixir_cost)
	return 0.0


## Returns formatted description with stats
func get_full_description() -> String:
	var stats_text: String = "\n\nHP: %d\nDamage: %d\nDPS: %.1f\nSpeed: %s" % [
		hitpoints,
		damage,
		get_dps(),
		_get_speed_name()
	]
	return description + stats_text


func _get_speed_name() -> String:
	if movement_speed >= 90:
		return "Very Fast"
	elif movement_speed >= 60:
		return "Medium"
	elif movement_speed >= 40:
		return "Slow"
	else:
		return "Very Slow"
