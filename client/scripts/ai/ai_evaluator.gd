extends Node
class_name AIEvaluator

# AI Evaluator - Analyzes board state and provides scoring/assessment
# Used by AI Controller to make informed decisions

signal evaluation_complete(evaluation: Dictionary)

# Evaluation weights (adjusted by difficulty)
var accuracy: float = 0.8  # How accurate the evaluation is (0-1)
var noise_factor: float = 0.1  # Random noise added to evaluations

# Tower health thresholds
const TOWER_CRITICAL_HEALTH = 0.3
const TOWER_LOW_HEALTH = 0.5
const TOWER_DAMAGED = 0.8

# Unit threat levels
const TANK_THREAT = 0.7
const SWARM_THREAT = 0.5
const RANGED_THREAT = 0.6
const BUILDING_THREAT = 0.4
const SPELL_THREAT = 0.8

# Position importance
const BRIDGE_ZONE_IMPORTANCE = 1.5
const TOWER_ZONE_IMPORTANCE = 2.0
const BACK_LINE_IMPORTANCE = 0.5

func _ready() -> void:
	pass

func set_accuracy(new_accuracy: float) -> void:
	accuracy = clamp(new_accuracy, 0.0, 1.0)
	noise_factor = (1.0 - accuracy) * 0.3  # More noise with lower accuracy

func evaluate_board(board_state: Dictionary) -> Dictionary:
	var evaluation = {
		"overall_advantage": 0.0,
		"tower_advantage": 0.0,
		"unit_advantage": 0.0,
		"elixir_advantage": 0.0,
		"position_advantage": 0.0,
		"immediate_threat": 0.0,
		"enemy_push_strength": 0.0,
		"friendly_push_strength": 0.0,
		"defensive_capability": 0.0,
		"offensive_potential": 0.0,
		"weakest_lane": "",
		"strongest_lane": "",
		"recommended_action": "",
		"threat_units": [],
		"opportunity_targets": []
	}

	# Perform evaluations
	evaluation.tower_advantage = _evaluate_towers(board_state)
	evaluation.unit_advantage = _evaluate_units(board_state)
	evaluation.elixir_advantage = _evaluate_elixir(board_state)
	evaluation.position_advantage = _evaluate_positions(board_state)

	# Assess threats and opportunities
	evaluation.immediate_threat = _assess_immediate_threat(board_state)
	evaluation.enemy_push_strength = _calculate_push_strength(board_state.enemy_units)
	evaluation.friendly_push_strength = _calculate_push_strength(board_state.friendly_units)

	# Evaluate capabilities
	evaluation.defensive_capability = _evaluate_defensive_capability(board_state)
	evaluation.offensive_potential = _evaluate_offensive_potential(board_state)

	# Identify lanes
	var lane_eval = _evaluate_lanes(board_state)
	evaluation.weakest_lane = lane_eval.weakest
	evaluation.strongest_lane = lane_eval.strongest

	# Identify specific threats and opportunities
	evaluation.threat_units = _identify_threat_units(board_state.enemy_units)
	evaluation.opportunity_targets = _identify_opportunities(board_state)

	# Calculate overall advantage
	evaluation.overall_advantage = _calculate_overall_advantage(evaluation)

	# Recommend action
	evaluation.recommended_action = _recommend_action(evaluation)

	# Add noise based on accuracy
	evaluation = _add_evaluation_noise(evaluation)

	emit_signal("evaluation_complete", evaluation)
	return evaluation

func _evaluate_towers(board_state: Dictionary) -> float:
	var friendly_tower_health = _calculate_total_tower_health(board_state.friendly_towers)
	var enemy_tower_health = _calculate_total_tower_health(board_state.enemy_towers)

	if enemy_tower_health == 0:
		return 1.0  # We're winning
	elif friendly_tower_health == 0:
		return -1.0  # We're losing

	# Calculate advantage (-1 to 1)
	var advantage = (friendly_tower_health - enemy_tower_health) / (friendly_tower_health + enemy_tower_health)

	# Weight by tower count
	var friendly_count = board_state.friendly_towers.size()
	var enemy_count = board_state.enemy_towers.size()
	if friendly_count > enemy_count:
		advantage += 0.3
	elif enemy_count > friendly_count:
		advantage -= 0.3

	return clamp(advantage, -1.0, 1.0)

func _calculate_total_tower_health(towers: Array) -> float:
	var total = 0.0
	for tower in towers:
		if tower.has("health") and tower.has("max_health"):
			var health_percent = float(tower.health) / float(tower.max_health)
			# King tower worth more
			var multiplier = 1.5 if tower.get("is_king_tower", false) else 1.0
			total += health_percent * multiplier
	return total

func _evaluate_units(board_state: Dictionary) -> float:
	var friendly_strength = _calculate_unit_strength(board_state.friendly_units)
	var enemy_strength = _calculate_unit_strength(board_state.enemy_units)

	if friendly_strength + enemy_strength == 0:
		return 0.0

	return (friendly_strength - enemy_strength) / (friendly_strength + enemy_strength)

func _calculate_unit_strength(units: Array) -> float:
	var total_strength = 0.0

	for unit in units:
		var base_strength = _get_unit_base_strength(unit)
		var position_modifier = _get_position_modifier(unit)
		var health_modifier = _get_health_modifier(unit)

		total_strength += base_strength * position_modifier * health_modifier

	return total_strength

func _get_unit_base_strength(unit: Dictionary) -> float:
	# Calculate base strength based on unit type and cost
	var strength = unit.get("elixir_cost", 3.0)  # Use cost as base

	# Modify by unit type
	var unit_type = unit.get("type", "")
	match unit_type:
		"tank":
			strength *= 1.5
		"swarm":
			strength *= 0.8
		"ranged":
			strength *= 1.2
		"building":
			strength *= 0.9
		"spell":
			strength *= 1.3
		_:
			strength *= 1.0

	# Consider special abilities
	if unit.get("has_splash", false):
		strength *= 1.3
	if unit.get("targets_air", false):
		strength *= 1.2
	if unit.get("is_flying", false):
		strength *= 1.1

	return strength

func _get_position_modifier(unit: Dictionary) -> float:
	if not unit.has("position"):
		return 1.0

	var pos = unit.position
	var modifier = 1.0

	# Check if unit is in important zones
	if _is_in_bridge_zone(pos):
		modifier *= BRIDGE_ZONE_IMPORTANCE
	elif _is_in_tower_zone(pos):
		modifier *= TOWER_ZONE_IMPORTANCE
	elif _is_in_back_line(pos):
		modifier *= BACK_LINE_IMPORTANCE

	return modifier

func _get_health_modifier(unit: Dictionary) -> float:
	if unit.has("health") and unit.has("max_health"):
		return float(unit.health) / float(unit.max_health)
	return 1.0

func _evaluate_elixir(board_state: Dictionary) -> float:
	# Simple elixir advantage calculation
	var friendly_elixir = board_state.get("current_elixir", 0.0)

	# Estimate enemy elixir (would need tracking in real implementation)
	var enemy_elixir_estimate = 5.0  # Default estimate

	var advantage = (friendly_elixir - enemy_elixir_estimate) / 10.0
	return clamp(advantage, -1.0, 1.0)

func _evaluate_positions(board_state: Dictionary) -> float:
	var friendly_position_value = _calculate_position_value(board_state.friendly_units, true)
	var enemy_position_value = _calculate_position_value(board_state.enemy_units, false)

	if friendly_position_value + enemy_position_value == 0:
		return 0.0

	return (friendly_position_value - enemy_position_value) / (friendly_position_value + enemy_position_value)

func _calculate_position_value(units: Array, is_friendly: bool) -> float:
	var value = 0.0

	for unit in units:
		if not unit.has("position"):
			continue

		var pos = unit.position
		var distance_to_enemy_tower = _get_distance_to_nearest_enemy_tower(pos, is_friendly)

		# Closer to enemy tower = higher value for offensive units
		if distance_to_enemy_tower > 0:
			value += (1000 - distance_to_enemy_tower) / 1000.0

	return value

func _assess_immediate_threat(board_state: Dictionary) -> float:
	var max_threat = 0.0

	for unit in board_state.enemy_units:
		var threat_level = _calculate_unit_threat(unit, board_state)
		max_threat = max(max_threat, threat_level)

	return clamp(max_threat, 0.0, 1.0)

func _calculate_unit_threat(unit: Dictionary, board_state: Dictionary) -> float:
	var threat = 0.0

	# Base threat from unit strength
	threat = _get_unit_base_strength(unit) / 10.0  # Normalize

	# Increase threat based on proximity to our towers
	if unit.has("position"):
		var distance = _get_distance_to_nearest_friendly_tower(unit.position)
		if distance < 300:
			threat *= 2.0  # Double threat when very close
		elif distance < 600:
			threat *= 1.5

	# Increase threat if no defenders nearby
	if not _has_defenders_nearby(unit.position, board_state.friendly_units):
		threat *= 1.3

	return threat

func _calculate_push_strength(units: Array) -> float:
	var strength = 0.0
	var synergy_bonus = 0.0

	# Group units by lane
	var lanes = {"left": [], "center": [], "right": []}
	for unit in units:
		var lane = _get_unit_lane(unit)
		if lane in lanes:
			lanes[lane].append(unit)

	# Calculate strength for each lane
	for lane in lanes:
		var lane_units = lanes[lane]
		if lane_units.size() > 0:
			var lane_strength = 0.0
			for unit in lane_units:
				lane_strength += _get_unit_base_strength(unit)

			# Add synergy bonus for unit combinations
			if _has_tank_support_combo(lane_units):
				synergy_bonus += 0.3
			if _has_air_ground_combo(lane_units):
				synergy_bonus += 0.2

			strength = max(strength, lane_strength)

	return (strength / 20.0) + synergy_bonus  # Normalize and add synergy

func _has_tank_support_combo(units: Array) -> bool:
	var has_tank = false
	var has_support = false

	for unit in units:
		if unit.get("type", "") == "tank":
			has_tank = true
		elif unit.get("type", "") in ["ranged", "swarm"]:
			has_support = true

	return has_tank and has_support

func _has_air_ground_combo(units: Array) -> bool:
	var has_air = false
	var has_ground = false

	for unit in units:
		if unit.get("is_flying", false):
			has_air = true
		else:
			has_ground = true

	return has_air and has_ground

func _evaluate_defensive_capability(board_state: Dictionary) -> float:
	var capability = 0.0

	# Check for defensive units
	for unit in board_state.friendly_units:
		if _is_defensive_unit(unit):
			capability += 0.2
		if _is_in_defensive_position(unit):
			capability += 0.1

	# Check available elixir for defense
	var elixir = board_state.get("current_elixir", 0.0)
	capability += elixir / 20.0  # Normalize elixir contribution

	return clamp(capability, 0.0, 1.0)

func _evaluate_offensive_potential(board_state: Dictionary) -> float:
	var potential = 0.0

	# Check for offensive units
	for unit in board_state.friendly_units:
		if _is_offensive_unit(unit):
			potential += 0.2
		if _is_in_offensive_position(unit):
			potential += 0.15

	# Check elixir advantage
	var elixir = board_state.get("current_elixir", 0.0)
	if elixir > 7:
		potential += 0.3

	return clamp(potential, 0.0, 1.0)

func _evaluate_lanes(board_state: Dictionary) -> Dictionary:
	var lanes = {
		"left": {"strength": 0.0, "vulnerability": 0.0},
		"center": {"strength": 0.0, "vulnerability": 0.0},
		"right": {"strength": 0.0, "vulnerability": 0.0}
	}

	# Evaluate each lane
	for lane_name in lanes:
		var lane_data = lanes[lane_name]

		# Check tower health
		lane_data.vulnerability = _get_lane_tower_vulnerability(lane_name, board_state)

		# Check unit presence
		lane_data.strength = _get_lane_unit_strength(lane_name, board_state)

	# Find weakest and strongest
	var weakest = ""
	var strongest = ""
	var min_score = INF
	var max_score = -INF

	for lane_name in lanes:
		var score = lanes[lane_name].strength - lanes[lane_name].vulnerability
		if score < min_score:
			min_score = score
			weakest = lane_name
		if score > max_score:
			max_score = score
			strongest = lane_name

	return {"weakest": weakest, "strongest": strongest}

func _identify_threat_units(enemy_units: Array) -> Array:
	var threats = []

	for unit in enemy_units:
		var threat_info = {
			"unit": unit,
			"threat_level": _calculate_unit_threat(unit, {}),
			"counter_needed": _get_recommended_counter(unit)
		}

		if threat_info.threat_level > 0.5:
			threats.append(threat_info)

	# Sort by threat level
	threats.sort_custom(func(a, b): return a.threat_level > b.threat_level)

	return threats

func _identify_opportunities(board_state: Dictionary) -> Array:
	var opportunities = []

	# Check for undefended towers
	for tower in board_state.enemy_towers:
		if _is_tower_undefended(tower, board_state.enemy_units):
			opportunities.append({
				"type": "undefended_tower",
				"target": tower,
				"priority": 0.8
			})

	# Check for elixir advantage
	if board_state.get("current_elixir", 0) > 8:
		opportunities.append({
			"type": "elixir_advantage",
			"priority": 0.6
		})

	# Check for counter-push opportunity
	if board_state.friendly_units.size() > 2:
		opportunities.append({
			"type": "counter_push",
			"priority": 0.7
		})

	return opportunities

func _calculate_overall_advantage(evaluation: Dictionary) -> float:
	# Weighted sum of different advantages
	var weights = {
		"tower": 0.35,
		"unit": 0.25,
		"elixir": 0.15,
		"position": 0.25
	}

	var advantage = 0.0
	advantage += evaluation.tower_advantage * weights.tower
	advantage += evaluation.unit_advantage * weights.unit
	advantage += evaluation.elixir_advantage * weights.elixir
	advantage += evaluation.position_advantage * weights.position

	return clamp(advantage, -1.0, 1.0)

func _recommend_action(evaluation: Dictionary) -> String:
	# Recommend action based on evaluation
	if evaluation.immediate_threat > 0.7:
		return "defend_immediately"
	elif evaluation.overall_advantage > 0.3:
		return "push_advantage"
	elif evaluation.overall_advantage < -0.3:
		return "defend_and_recover"
	elif evaluation.enemy_push_strength > 0.6:
		return "prepare_defense"
	elif evaluation.offensive_potential > 0.6:
		return "build_push"
	else:
		return "maintain_pressure"

func _add_evaluation_noise(evaluation: Dictionary) -> Dictionary:
	if noise_factor == 0.0:
		return evaluation

	# Add noise to numeric values
	for key in evaluation:
		var value = evaluation[key]
		if value is float:
			var noise = randf_range(-noise_factor, noise_factor)
			evaluation[key] = clamp(value + noise, -1.0, 1.0)

	return evaluation

# Helper functions
func _is_in_bridge_zone(position: Vector2) -> bool:
	# Check if position is near bridge
	return position.y > 350 and position.y < 450

func _is_in_tower_zone(position: Vector2) -> bool:
	# Check if position is near a tower
	return position.y < 200 or position.y > 600

func _is_in_back_line(position: Vector2) -> bool:
	# Check if position is in back line
	return position.y > 650

func _get_distance_to_nearest_enemy_tower(position: Vector2, is_friendly_unit: bool) -> float:
	# Simplified distance calculation
	if is_friendly_unit:
		return position.distance_to(Vector2(400, 100))  # Enemy king tower
	else:
		return position.distance_to(Vector2(400, 700))  # Friendly king tower

func _get_distance_to_nearest_friendly_tower(position: Vector2) -> float:
	return position.distance_to(Vector2(400, 700))  # Friendly king tower

func _has_defenders_nearby(position: Vector2, friendly_units: Array) -> bool:
	for unit in friendly_units:
		if unit.has("position"):
			if unit.position.distance_to(position) < 200:
				return true
	return false

func _get_unit_lane(unit: Dictionary) -> String:
	if not unit.has("position"):
		return "center"

	var x = unit.position.x
	if x < 300:
		return "left"
	elif x > 500:
		return "right"
	else:
		return "center"

func _is_defensive_unit(unit: Dictionary) -> bool:
	var type = unit.get("type", "")
	return type in ["building", "tank"] or unit.get("is_defensive", false)

func _is_offensive_unit(unit: Dictionary) -> bool:
	var type = unit.get("type", "")
	return type in ["win_condition", "siege"] or unit.get("is_offensive", false)

func _is_in_defensive_position(unit: Dictionary) -> bool:
	if not unit.has("position"):
		return false
	return unit.position.y > 500

func _is_in_offensive_position(unit: Dictionary) -> bool:
	if not unit.has("position"):
		return false
	return unit.position.y < 400

func _get_lane_tower_vulnerability(lane: String, board_state: Dictionary) -> float:
	# Check tower health in lane
	for tower in board_state.friendly_towers:
		if tower.get("lane", "") == lane:
			var health_percent = float(tower.health) / float(tower.max_health)
			return 1.0 - health_percent
	return 0.5  # Default if no tower found

func _get_lane_unit_strength(lane: String, board_state: Dictionary) -> float:
	var strength = 0.0
	for unit in board_state.friendly_units:
		if _get_unit_lane(unit) == lane:
			strength += _get_unit_base_strength(unit)
	return strength / 20.0  # Normalize

func _is_tower_undefended(tower: Dictionary, enemy_units: Array) -> bool:
	if not tower.has("position"):
		return true

	for unit in enemy_units:
		if unit.has("position"):
			if unit.position.distance_to(tower.position) < 300:
				return false
	return true

func _get_recommended_counter(unit: Dictionary) -> String:
	var unit_type = unit.get("type", "")
	match unit_type:
		"tank":
			return "swarm"
		"swarm":
			return "splash"
		"flying":
			return "anti_air"
		"building":
			return "siege"
		_:
			return "balanced"