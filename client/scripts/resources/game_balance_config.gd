## GameBalanceConfig resource for storing gameplay balance values
## Eliminates hardcoded balance values and enables data-driven tuning
class_name GameBalanceConfig
extends Resource

## Elixir system
@export_group("Elixir System")
@export var starting_elixir: float = 5.0  ## Starting elixir for both players
@export var max_elixir: float = 10.0  ## Maximum elixir capacity
@export var elixir_generation_rate: float = 0.357  ## Elixir per second (1 per 2.8s)
@export var double_elixir_start_time: float = 120.0  ## When double elixir starts (seconds)

## Battle timing
@export_group("Battle Timing")
@export var match_duration: float = 180.0  ## Battle duration in seconds (3 minutes)
@export var overtime_duration: float = 60.0  ## Overtime duration if tied

## AI configuration
@export_group("AI Settings")
@export var ai_starting_elixir: float = 5.0  ## AI starting elixir
@export var ai_max_elixir: float = 10.0  ## AI maximum elixir
@export var ai_elixir_reserve: float = 1.5  ## AI keeps this much elixir in reserve
@export var ai_decision_interval: float = 1.0  ## AI checks for actions every N seconds

## AI difficulty modifiers
@export_subgroup("AI Difficulty")
@export var ai_easy_reaction_delay: float = 2.0  ## Easy AI delay before responding
@export var ai_medium_reaction_delay: float = 1.0  ## Medium AI delay
@export var ai_hard_reaction_delay: float = 0.5  ## Hard AI delay
@export var ai_easy_elixir_reserve: float = 2.0  ## Easy AI saves more elixir
@export var ai_medium_elixir_reserve: float = 1.5  ## Medium AI reserve
@export var ai_hard_elixir_reserve: float = 0.5  ## Hard AI is more aggressive

## Unit physics
@export_group("Unit Physics")
@export var unit_collision_radius: float = 12.0  ## Unit collision radius for physics
@export var unit_separation_force: float = 50.0  ## Force pushing units apart
@export var unit_max_speed: float = 100.0  ## Maximum unit movement speed
@export var unit_acceleration: float = 200.0  ## Unit acceleration

## Combat settings
@export_group("Combat Settings")
@export var tower_threat_radius: float = 400.0  ## Range for AI to consider tower threatened
@export var aggro_range_multiplier: float = 1.2  ## Multiplier for unit aggro range
@export var attack_cooldown_variance: float = 0.1  ## Random variance in attack timing (0-1)

## Visual and UI settings
@export_group("Visual Settings")
@export var health_bar_width: float = 60.0  ## Width of unit health bars
@export var health_bar_height: float = 6.0  ## Height of unit health bars
@export var health_bar_offset_y: float = -1.0  ## Offset above unit head
@export var unit_sprite_scale_multiplier: float = 3.0  ## Sprite scale multiplier

## Deployment settings
@export_group("Deployment")
@export var deployment_zone_margin: float = 100.0  ## Margin from deployment zone edges
@export var min_deployment_spacing: float = 32.0  ## Minimum space between unit spawns

## Camera settings
@export_group("Camera")
@export var default_camera_zoom: Vector2 = Vector2(1.0, 1.0)  ## Default camera zoom level
@export var camera_smoothing: float = 5.0  ## Camera movement smoothing

## Performance settings
@export_group("Performance")
@export var max_projectiles: int = 100  ## Maximum active projectiles
@export var max_effects: int = 50  ## Maximum active visual effects
@export var particle_quality: float = 1.0  ## Particle quality multiplier (0.5-1.0)


## Get AI settings for specific difficulty level
func get_ai_settings_for_difficulty(difficulty: int) -> Dictionary:
	match difficulty:
		0:  # Easy
			return {
				"elixir_reserve": ai_easy_elixir_reserve,
				"reaction_delay": ai_easy_reaction_delay,
				"decision_interval": ai_decision_interval * 1.5
			}
		1:  # Medium
			return {
				"elixir_reserve": ai_medium_elixir_reserve,
				"reaction_delay": ai_medium_reaction_delay,
				"decision_interval": ai_decision_interval
			}
		2:  # Hard
			return {
				"elixir_reserve": ai_hard_elixir_reserve,
				"reaction_delay": ai_hard_reaction_delay,
				"decision_interval": ai_decision_interval * 0.75
			}
		_:  # Default to medium
			return {
				"elixir_reserve": ai_medium_elixir_reserve,
				"reaction_delay": ai_medium_reaction_delay,
				"decision_interval": ai_decision_interval
			}


## Calculate elixir generation rate (for display purposes)
func get_elixir_per_second(double_elixir: bool = false) -> float:
	if double_elixir:
		return elixir_generation_rate * 2.0
	return elixir_generation_rate


## Get time until double elixir starts
func get_time_until_double_elixir(current_time: float) -> float:
	return max(0.0, double_elixir_start_time - current_time)


## Check if double elixir should be active
func is_double_elixir_time(current_time: float) -> bool:
	return current_time >= double_elixir_start_time
