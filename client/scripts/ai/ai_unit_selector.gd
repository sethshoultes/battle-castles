extends Node
class_name AIUnitSelector

# AI Unit Selector - Handles card selection logic, counter-picking, and synergy detection
# Uses optimization level to determine how well it selects units

signal unit_selected(unit: Dictionary)

# Selection parameters
var optimization_level: float = 0.7  # How well AI selects units (0-1)
var synergy_weight: float = 0.3  # How much to consider synergies
var counter_weight: float = 0.5  # How much to consider counters
var elixir_efficiency_weight: float = 0.2  # How much to consider elixir value

# Unit type matchups (what counters what)
const COUNTER_MATRIX = {
	"tank": ["swarm", "inferno", "high_damage"],
	"swarm": ["splash", "spell", "area_damage"],
	"flying": ["anti_air", "ranged", "spell"],
	"building": ["siege", "spell", "ranged"],
	"ranged": ["tank", "shield", "fast"],
	"splash": ["tank", "single_target", "high_health"],
	"win_condition": ["building", "swarm", "distraction"],
	"spell": ["nothing_direct"],  # Spells don't have direct counters
	"support": ["spell", "ranged", "assassin"],
	"siege": ["fast", "flying", "spell"]
}

# Synergy combinations
const SYNERGY_COMBOS = {
	"tank_support": ["tank", "ranged"],
	"tank_splash": ["tank", "splash"],
	"bait": ["swarm", "swarm"],
	"siege_spell": ["siege", "spell"],
	"dual_win_condition": ["win_condition", "win_condition"],
	"air_ground": ["flying", "tank"],
	"cycle": ["cheap", "cheap"],
	"beatdown": ["tank", "support", "support"],
	"bridge_spam": ["fast", "fast"],
	"control": ["building", "spell"]
}

# Card memory (tracks recently played cards)
var card_history: Array = []
var max_history: int = 10
var opponent_card_tracker: Dictionary = {}  # Track opponent's cards

func _ready() -> void:
	pass

func set_optimization_level(level: float) -> void:
	optimization_level = clamp(level, 0.0, 1.0)
	# Adjust weights based on optimization level
	synergy_weight = optimization_level * 0.4
	counter_weight = optimization_level * 0.6
	elixir_efficiency_weight = 0.2 + (optimization_level * 0.2)

func select_unit(
	available_cards: Array,
	evaluation: Dictionary,
	current_elixir: float,
	strategy: AIStrategies.StrategyType
) -> Dictionary:

	if available_cards.is_empty():
		return {}

	# Get strategy parameters
	var strategy_params = AIStrategies.new().get_strategy_params(strategy)

	# Filter cards by elixir cost
	var affordable_cards = _filter_affordable_cards(available_cards, current_elixir)
	if affordable_cards.is_empty():
		return {}

	# Score each card
	var card_scores = []
	for card in affordable_cards:
		var score = _calculate_card_score(card, evaluation, strategy_params)
		card_scores.append({"card": card, "score": score})

	# Sort by score
	card_scores.sort_custom(func(a, b): return a.score > b.score)

	# Apply optimization level (lower optimization = more random)
	var selection_index = _apply_optimization_randomness(card_scores.size())
	var selected = card_scores[selection_index]

	# Track selection
	_track_card_selection(selected.card)

	emit_signal("unit_selected", selected.card)
	return {
		"unit": selected.card,
		"cost": selected.card.get("elixir_cost", 3),
		"score": selected.score
	}

func _filter_affordable_cards(cards: Array, elixir: float) -> Array:
	var affordable = []
	for card in cards:
		if card.get("elixir_cost", 3) <= elixir:
			affordable.append(card)
	return affordable

func _calculate_card_score(
	card: Dictionary,
	evaluation: Dictionary,
	strategy_params: Dictionary
) -> float:

	var score = 0.0

	# Base score from card strength
	score += _get_card_base_score(card) * 0.2

	# Counter score - how well this counters enemy units
	score += _calculate_counter_score(card, evaluation) * counter_weight

	# Synergy score - how well this works with friendly units
	score += _calculate_synergy_score(card, evaluation) * synergy_weight

	# Elixir efficiency score
	score += _calculate_elixir_efficiency(card, evaluation) * elixir_efficiency_weight

	# Strategy alignment score
	score += _calculate_strategy_alignment(card, strategy_params) * 0.3

	# Situation-specific adjustments
	score += _calculate_situational_score(card, evaluation) * 0.2

	# Cycle bonus (avoid playing same card repeatedly)
	score += _calculate_cycle_bonus(card) * 0.1

	return score

func _get_card_base_score(card: Dictionary) -> float:
	# Base score based on card stats
	var score = 0.5  # Default

	# Consider card rarity/power level
	var cost = card.get("elixir_cost", 3)
	score += (cost / 10.0) * 0.3  # Higher cost = generally stronger

	# Consider card type value
	var card_type = card.get("type", "")
	match card_type:
		"win_condition":
			score += 0.3
		"tank":
			score += 0.2
		"splash":
			score += 0.2
		"spell":
			score += 0.1
		_:
			score += 0.0

	return clamp(score, 0.0, 1.0)

func _calculate_counter_score(card: Dictionary, evaluation: Dictionary) -> float:
	var score = 0.0
	var threat_units = evaluation.get("threat_units", [])

	if threat_units.is_empty():
		return 0.5  # Neutral score if no threats

	# Check how well this card counters current threats
	for threat_info in threat_units:
		var threat_unit = threat_info.get("unit", {})
		var threat_type = threat_unit.get("type", "")

		if _is_counter(card.get("type", ""), threat_type):
			score += threat_info.get("threat_level", 0.5)

	# Normalize score
	return clamp(score / max(threat_units.size(), 1), 0.0, 1.0)

func _is_counter(card_type: String, enemy_type: String) -> bool:
	if not COUNTER_MATRIX.has(enemy_type):
		return false

	var counters = COUNTER_MATRIX[enemy_type]
	return card_type in counters

func _calculate_synergy_score(card: Dictionary, evaluation: Dictionary) -> float:
	var score = 0.0
	var friendly_units = evaluation.get("friendly_units", [])

	if friendly_units.is_empty():
		return 0.3  # Low synergy if no units on board

	# Check for synergy combinations
	for unit in friendly_units:
		var combo_score = _get_synergy_combo_score(card, unit)
		score += combo_score

	# Check for deck synergies (cards in hand)
	score += _calculate_deck_synergy(card) * 0.3

	return clamp(score / max(friendly_units.size(), 1), 0.0, 1.0)

func _get_synergy_combo_score(card1: Dictionary, card2: Dictionary) -> float:
	var type1 = card1.get("type", "")
	var type2 = card2.get("type", "")

	# Check all synergy combos
	for combo_name in SYNERGY_COMBOS:
		var combo = SYNERGY_COMBOS[combo_name]
		if (type1 in combo and type2 in combo) or \
		   (type1 == combo[0] and type2 == combo[1]) or \
		   (type2 == combo[0] and type1 == combo[1]):
			return 0.5

	return 0.0

func _calculate_deck_synergy(card: Dictionary) -> float:
	# Check if this card synergizes with recently played cards
	var synergy = 0.0
	for recent_card in card_history:
		if _get_synergy_combo_score(card, recent_card) > 0:
			synergy += 0.2

	return clamp(synergy, 0.0, 1.0)

func _calculate_elixir_efficiency(card: Dictionary, evaluation: Dictionary) -> float:
	var cost = card.get("elixir_cost", 3)
	var efficiency = 0.0

	# Lower cost is generally more efficient
	efficiency += (10 - cost) / 10.0 * 0.5

	# Adjust based on game state
	if evaluation.get("elixir_advantage", 0) > 0.3:
		# Can afford expensive cards
		efficiency += 0.2
	elif evaluation.get("elixir_advantage", 0) < -0.3:
		# Need cheap cards
		efficiency += (5 - cost) / 5.0 * 0.3

	# Consider value trades
	var threat_level = evaluation.get("immediate_threat", 0)
	if threat_level > 0.5 and cost <= 4:
		efficiency += 0.3  # Cheap defense is efficient

	return clamp(efficiency, 0.0, 1.0)

func _calculate_strategy_alignment(card: Dictionary, strategy_params: Dictionary) -> float:
	var score = 0.0
	var unit_pref = strategy_params.get("unit_preference", "mixed")
	var card_type = card.get("type", "")

	# Match card type to strategy preference
	match unit_pref:
		"offensive":
			if card_type in ["win_condition", "tank", "fast"]:
				score += 0.7
		"defensive":
			if card_type in ["building", "swarm", "spell"]:
				score += 0.7
		"fast":
			if card.get("speed", "medium") == "fast":
				score += 0.6
			if card.get("elixir_cost", 3) <= 3:
				score += 0.3
		"cheap":
			var cost = card.get("elixir_cost", 3)
			score += (5 - cost) / 5.0
		"tank_support":
			if card_type in ["tank", "support", "ranged"]:
				score += 0.7
		"buildings_spells":
			if card_type in ["building", "spell"]:
				score += 0.8
		"bridge_spam":
			if card.get("speed", "medium") in ["fast", "very_fast"]:
				score += 0.7
		"counter":
			if card_type in ["swarm", "building", "high_damage"]:
				score += 0.6
		"bait":
			if card_type == "swarm" or card.get("is_bait", false):
				score += 0.8
		_:
			score += 0.5  # Neutral

	return clamp(score, 0.0, 1.0)

func _calculate_situational_score(card: Dictionary, evaluation: Dictionary) -> float:
	var score = 0.0

	# Immediate threat response
	if evaluation.get("immediate_threat", 0) > 0.7:
		if card.get("type", "") in ["swarm", "building", "high_damage"]:
			score += 0.5

	# Push support
	if evaluation.get("friendly_push_strength", 0) > 0.5:
		if card.get("type", "") in ["support", "spell"]:
			score += 0.4

	# Tower damage opportunity
	var weakest_lane = evaluation.get("weakest_lane", "")
	if weakest_lane != "" and evaluation.get("offensive_potential", 0) > 0.6:
		if card.get("type", "") == "win_condition":
			score += 0.5

	# Overtime adjustments
	var time_elapsed = evaluation.get("time_elapsed", 0)
	if time_elapsed > 180:  # Overtime
		if card.get("type", "") in ["spell", "win_condition"]:
			score += 0.3

	return clamp(score, 0.0, 1.0)

func _calculate_cycle_bonus(card: Dictionary) -> float:
	# Avoid playing the same card repeatedly
	for i in range(min(3, card_history.size())):
		if card_history[-(i+1)].get("name", "") == card.get("name", ""):
			return -0.5  # Penalty for repetition

	return 0.2  # Bonus for variety

func _apply_optimization_randomness(num_cards: int) -> int:
	if num_cards == 0:
		return 0

	# Higher optimization = more likely to pick best card
	if optimization_level > 0.9:
		# Almost always pick best
		return 0 if randf() < 0.95 else min(1, num_cards - 1)
	elif optimization_level > 0.7:
		# Usually pick from top 2
		return min(randi() % 2, num_cards - 1)
	elif optimization_level > 0.5:
		# Pick from top 3
		return min(randi() % 3, num_cards - 1)
	else:
		# Pick from top half
		var top_half = max(1, num_cards / 2)
		return min(randi() % int(top_half), num_cards - 1)

func _track_card_selection(card: Dictionary) -> void:
	card_history.append(card)
	if card_history.size() > max_history:
		card_history.pop_front()

func track_opponent_card(card: Dictionary) -> void:
	# Track opponent's cards for better counter-picking
	var card_name = card.get("name", "unknown")
	if not opponent_card_tracker.has(card_name):
		opponent_card_tracker[card_name] = 0
	opponent_card_tracker[card_name] += 1

func predict_opponent_cycle() -> Array:
	# Predict what cards opponent might play next
	# (Simplified - would need more sophisticated tracking in real game)
	var predictions = []

	# Sort opponent cards by usage frequency
	var sorted_cards = []
	for card_name in opponent_card_tracker:
		sorted_cards.append({
			"name": card_name,
			"count": opponent_card_tracker[card_name]
		})

	sorted_cards.sort_custom(func(a, b): return a.count < b.count)

	# Return least recently used cards (likely to come up in cycle)
	for i in range(min(4, sorted_cards.size())):
		predictions.append(sorted_cards[i].name)

	return predictions

func get_optimal_counter_hand(threat_types: Array) -> Array:
	# Suggest optimal cards to have in hand for given threats
	var optimal_cards = []

	for threat_type in threat_types:
		if COUNTER_MATRIX.has(threat_type):
			var counters = COUNTER_MATRIX[threat_type]
			for counter in counters:
				if counter not in optimal_cards:
					optimal_cards.append(counter)

	return optimal_cards

func calculate_card_value(card: Dictionary, board_state: Dictionary) -> float:
	# Calculate overall value of playing a card in current state
	var mock_evaluation = {
		"immediate_threat": board_state.get("threat_level", 0),
		"friendly_units": board_state.get("friendly_units", []),
		"threat_units": board_state.get("enemy_units", [])
	}

	return _calculate_card_score(
		card,
		mock_evaluation,
		{"unit_preference": "mixed"}
	)

func reset_tracking() -> void:
	# Reset tracking for new game
	card_history.clear()
	opponent_card_tracker.clear()