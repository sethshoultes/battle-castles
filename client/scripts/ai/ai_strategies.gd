extends Node
class_name AIStrategies

# AI Strategies - Defines different play styles and strategic approaches
# Each strategy influences unit selection, timing, and positioning decisions

signal strategy_selected(strategy: StrategyType)

enum StrategyType {
	AGGRESSIVE,      # Constant pressure, offensive plays
	DEFENSIVE,       # React and counter, focus on defense
	BALANCED,        # Mix of offense and defense
	RUSH,            # Early game aggression
	CONTROL,         # Slow, methodical play
	CYCLE,           # Fast cycling, chip damage
	BEATDOWN,        # Build massive pushes
	SIEGE,           # Spell/building focused
	BRIDGE_SPAM,     # Constant bridge pressure
	COUNTER_PUSH,    # Defend then attack
	DUAL_LANE,       # Split push tactics
	BAIT             # Bait out counters
}

# Strategy complexity level (set by difficulty)
var complexity_level: float = 0.7  # 0-1, affects strategy sophistication

# Strategy weights for different situations
var strategy_weights: Dictionary = {}

# Current strategy state
var current_strategy: StrategyType = StrategyType.BALANCED
var strategy_timer: float = 0.0
var strategy_duration: float = 30.0  # How long to stick with a strategy
var can_switch: bool = true

func _ready() -> void:
	_initialize_strategy_weights()

func _initialize_strategy_weights() -> void:
	# Initialize base weights for each strategy
	strategy_weights = {
		StrategyType.AGGRESSIVE: 1.0,
		StrategyType.DEFENSIVE: 1.0,
		StrategyType.BALANCED: 1.5,  # Slightly prefer balanced
		StrategyType.RUSH: 0.8,
		StrategyType.CONTROL: 0.9,
		StrategyType.CYCLE: 0.7,
		StrategyType.BEATDOWN: 0.6,
		StrategyType.SIEGE: 0.5,
		StrategyType.BRIDGE_SPAM: 0.8,
		StrategyType.COUNTER_PUSH: 1.0,
		StrategyType.DUAL_LANE: 0.4,
		StrategyType.BAIT: 0.6
	}

func set_complexity(level: float) -> void:
	complexity_level = clamp(level, 0.0, 1.0)
	_adjust_strategy_availability()

func _adjust_strategy_availability() -> void:
	# Disable complex strategies for lower complexity levels
	if complexity_level < 0.3:
		# Easy - Only basic strategies
		strategy_weights[StrategyType.DUAL_LANE] = 0.0
		strategy_weights[StrategyType.BAIT] = 0.0
		strategy_weights[StrategyType.SIEGE] = 0.0
		strategy_weights[StrategyType.BEATDOWN] = 0.0
		strategy_weights[StrategyType.CYCLE] = 0.0
	elif complexity_level < 0.7:
		# Medium - Some advanced strategies
		strategy_weights[StrategyType.DUAL_LANE] = 0.2
		strategy_weights[StrategyType.BAIT] = 0.3
		strategy_weights[StrategyType.SIEGE] = 0.4
	else:
		# Hard - All strategies available
		_initialize_strategy_weights()

func select_strategy(evaluation: Dictionary, difficulty: AIDifficulty.Level, personality_seed: int) -> StrategyType:
	# Check if we should stick with current strategy
	if not _should_switch_strategy(evaluation):
		return current_strategy

	# Generate personality traits for consistency
	var personality_traits = AIDifficulty.generate_personality(difficulty, personality_seed)

	# Calculate strategy scores based on situation
	var strategy_scores = _calculate_strategy_scores(evaluation, personality_traits)

	# Select best strategy
	var selected = _select_best_strategy(strategy_scores)

	if selected != current_strategy:
		current_strategy = selected
		strategy_timer = 0.0
		emit_signal("strategy_selected", selected)
		print("[AI Strategy] Switched to: ", get_strategy_name(selected))

	return current_strategy

func _should_switch_strategy(evaluation: Dictionary) -> bool:
	# Don't switch too frequently
	if strategy_timer < 10.0:
		return false

	# Force switch in critical situations
	if evaluation.immediate_threat > 0.8:
		return true  # Need defensive strategy

	if evaluation.overall_advantage > 0.5:
		return true  # Press advantage

	if evaluation.overall_advantage < -0.5:
		return true  # Need to recover

	# Random chance to switch based on complexity
	return randf() < (complexity_level * 0.1)

func _calculate_strategy_scores(evaluation: Dictionary, personality_traits: Array) -> Dictionary:
	var scores = {}

	for strategy in StrategyType.values():
		var score = strategy_weights[strategy]

		# Adjust score based on game state
		score *= _get_situation_modifier(strategy, evaluation)

		# Adjust for personality
		score *= _get_personality_modifier(strategy, personality_traits)

		# Apply complexity factor
		score *= _get_complexity_modifier(strategy)

		scores[strategy] = score

	return scores

func _get_situation_modifier(strategy: StrategyType, evaluation: Dictionary) -> float:
	var modifier = 1.0

	match strategy:
		StrategyType.AGGRESSIVE:
			# Good when ahead or enemy is weak
			if evaluation.overall_advantage > 0.2:
				modifier *= 1.5
			if evaluation.enemy_push_strength < 0.3:
				modifier *= 1.3
			if evaluation.tower_advantage > 0.3:
				modifier *= 1.2

		StrategyType.DEFENSIVE:
			# Good when behind or under threat
			if evaluation.immediate_threat > 0.5:
				modifier *= 2.0
			if evaluation.overall_advantage < -0.2:
				modifier *= 1.5
			if evaluation.defensive_capability < 0.5:
				modifier *= 1.3

		StrategyType.BALANCED:
			# Always decent, better when game is even
			if abs(evaluation.overall_advantage) < 0.2:
				modifier *= 1.3

		StrategyType.RUSH:
			# Good early game or when enemy is unprepared
			if evaluation.get("time_elapsed", 0) < 60:
				modifier *= 1.5
			if evaluation.enemy_push_strength < 0.2:
				modifier *= 1.3

		StrategyType.CONTROL:
			# Good with elixir advantage
			if evaluation.elixir_advantage > 0.3:
				modifier *= 1.4
			if evaluation.defensive_capability > 0.6:
				modifier *= 1.2

		StrategyType.CYCLE:
			# Good with cheap deck and elixir advantage
			if evaluation.elixir_advantage > 0.2:
				modifier *= 1.3

		StrategyType.BEATDOWN:
			# Good with elixir and position advantage
			if evaluation.elixir_advantage > 0.4:
				modifier *= 1.5
			if evaluation.position_advantage > 0.3:
				modifier *= 1.3
			if evaluation.friendly_push_strength > 0.5:
				modifier *= 1.4

		StrategyType.SIEGE:
			# Good when towers are damaged
			if evaluation.tower_advantage < -0.2:
				modifier *= 0.5  # Don't siege when losing towers
			else:
				modifier *= 1.2

		StrategyType.BRIDGE_SPAM:
			# Good with elixir advantage and low enemy defense
			if evaluation.elixir_advantage > 0.3:
				modifier *= 1.4
			if evaluation.defensive_capability < 0.4:
				modifier *= 1.3

		StrategyType.COUNTER_PUSH:
			# Good after successful defense
			if evaluation.defensive_capability > 0.6:
				modifier *= 1.5
			if evaluation.enemy_push_strength < 0.3:
				modifier *= 1.3

		StrategyType.DUAL_LANE:
			# Good when enemy is focused on one lane
			if evaluation.position_advantage > 0.3:
				modifier *= 1.4
			if evaluation.offensive_potential > 0.6:
				modifier *= 1.3

		StrategyType.BAIT:
			# Good with varied unit types
			if evaluation.elixir_advantage > 0.2:
				modifier *= 1.2

	return modifier

func _get_personality_modifier(strategy: StrategyType, traits: Array) -> float:
	var modifier = 1.0

	for trait in traits:
		match trait:
			AIDifficulty.PersonalityTrait.AGGRESSIVE:
				if strategy in [StrategyType.AGGRESSIVE, StrategyType.RUSH, StrategyType.BRIDGE_SPAM]:
					modifier *= 1.4
			AIDifficulty.PersonalityTrait.DEFENSIVE:
				if strategy in [StrategyType.DEFENSIVE, StrategyType.CONTROL, StrategyType.COUNTER_PUSH]:
					modifier *= 1.4
			AIDifficulty.PersonalityTrait.RUSHER:
				if strategy == StrategyType.RUSH:
					modifier *= 1.6
			AIDifficulty.PersonalityTrait.CONTROLLER:
				if strategy == StrategyType.CONTROL:
					modifier *= 1.5
			AIDifficulty.PersonalityTrait.BEATDOWN:
				if strategy == StrategyType.BEATDOWN:
					modifier *= 1.5
			AIDifficulty.PersonalityTrait.SIEGE:
				if strategy == StrategyType.SIEGE:
					modifier *= 1.5
			AIDifficulty.PersonalityTrait.BRIDGE_SPAM:
				if strategy == StrategyType.BRIDGE_SPAM:
					modifier *= 1.5
			AIDifficulty.PersonalityTrait.COUNTER_PUSH:
				if strategy == StrategyType.COUNTER_PUSH:
					modifier *= 1.5

	return modifier

func _get_complexity_modifier(strategy: StrategyType) -> float:
	# Simple strategies are always available
	var simple_strategies = [
		StrategyType.AGGRESSIVE,
		StrategyType.DEFENSIVE,
		StrategyType.BALANCED
	]

	if strategy in simple_strategies:
		return 1.0

	# Complex strategies scale with complexity level
	return complexity_level

func _select_best_strategy(scores: Dictionary) -> StrategyType:
	# Add some randomization for variety
	var best_strategy = StrategyType.BALANCED
	var best_score = 0.0

	for strategy in scores:
		var score = scores[strategy]
		# Add small random factor for variety
		score += randf() * 0.2

		if score > best_score:
			best_score = score
			best_strategy = strategy

	return best_strategy

func get_strategy_params(strategy: StrategyType) -> Dictionary:
	# Return parameters that influence AI behavior for each strategy
	match strategy:
		StrategyType.AGGRESSIVE:
			return {
				"deployment_threshold": 4.0,  # Deploy at 4 elixir
				"preferred_lane": "strongest",
				"unit_preference": "offensive",
				"reaction_speed_modifier": 0.8,
				"risk_tolerance": 0.8,
				"elixir_reserve": 2.0
			}

		StrategyType.DEFENSIVE:
			return {
				"deployment_threshold": 6.0,  # Wait for more elixir
				"preferred_lane": "threatened",
				"unit_preference": "defensive",
				"reaction_speed_modifier": 0.6,  # React faster
				"risk_tolerance": 0.2,
				"elixir_reserve": 4.0
			}

		StrategyType.BALANCED:
			return {
				"deployment_threshold": 5.0,
				"preferred_lane": "adaptive",
				"unit_preference": "mixed",
				"reaction_speed_modifier": 1.0,
				"risk_tolerance": 0.5,
				"elixir_reserve": 3.0
			}

		StrategyType.RUSH:
			return {
				"deployment_threshold": 3.0,  # Deploy ASAP
				"preferred_lane": "random",
				"unit_preference": "fast",
				"reaction_speed_modifier": 0.5,  # Very fast
				"risk_tolerance": 0.9,
				"elixir_reserve": 0.0
			}

		StrategyType.CONTROL:
			return {
				"deployment_threshold": 7.0,  # Wait for advantage
				"preferred_lane": "safest",
				"unit_preference": "value",
				"reaction_speed_modifier": 1.2,  # Slower, methodical
				"risk_tolerance": 0.3,
				"elixir_reserve": 5.0
			}

		StrategyType.CYCLE:
			return {
				"deployment_threshold": 3.0,
				"preferred_lane": "alternating",
				"unit_preference": "cheap",
				"reaction_speed_modifier": 0.7,
				"risk_tolerance": 0.6,
				"elixir_reserve": 2.0
			}

		StrategyType.BEATDOWN:
			return {
				"deployment_threshold": 8.0,  # Build big pushes
				"preferred_lane": "single",
				"unit_preference": "tank_support",
				"reaction_speed_modifier": 1.3,
				"risk_tolerance": 0.4,
				"elixir_reserve": 1.0
			}

		StrategyType.SIEGE:
			return {
				"deployment_threshold": 5.0,
				"preferred_lane": "safest",
				"unit_preference": "buildings_spells",
				"reaction_speed_modifier": 1.0,
				"risk_tolerance": 0.3,
				"elixir_reserve": 4.0
			}

		StrategyType.BRIDGE_SPAM:
			return {
				"deployment_threshold": 4.0,
				"preferred_lane": "bridge",
				"unit_preference": "bridge_spam",
				"reaction_speed_modifier": 0.6,
				"risk_tolerance": 0.7,
				"elixir_reserve": 2.0
			}

		StrategyType.COUNTER_PUSH:
			return {
				"deployment_threshold": 5.0,
				"preferred_lane": "defended",
				"unit_preference": "counter",
				"reaction_speed_modifier": 0.8,
				"risk_tolerance": 0.4,
				"elixir_reserve": 3.0
			}

		StrategyType.DUAL_LANE:
			return {
				"deployment_threshold": 6.0,
				"preferred_lane": "split",
				"unit_preference": "mixed",
				"reaction_speed_modifier": 0.9,
				"risk_tolerance": 0.6,
				"elixir_reserve": 2.0
			}

		StrategyType.BAIT:
			return {
				"deployment_threshold": 4.0,
				"preferred_lane": "baiting",
				"unit_preference": "bait",
				"reaction_speed_modifier": 0.8,
				"risk_tolerance": 0.5,
				"elixir_reserve": 3.0
			}

		_:
			return get_strategy_params(StrategyType.BALANCED)

func _process(delta: float) -> void:
	strategy_timer += delta

func should_defend(strategy: StrategyType, threat_level: float) -> bool:
	# Determine if AI should defend based on strategy and threat
	match strategy:
		StrategyType.DEFENSIVE:
			return threat_level > 0.2  # Very defensive
		StrategyType.AGGRESSIVE:
			return threat_level > 0.7  # Only defend major threats
		StrategyType.RUSH:
			return threat_level > 0.8  # Almost ignore defense
		StrategyType.CONTROL:
			return threat_level > 0.3  # Defensive minded
		_:
			return threat_level > 0.5  # Normal threshold

func should_push(strategy: StrategyType, advantage: float) -> bool:
	# Determine if AI should push based on strategy and advantage
	match strategy:
		StrategyType.AGGRESSIVE:
			return advantage > -0.2  # Push even when slightly behind
		StrategyType.DEFENSIVE:
			return advantage > 0.5  # Only push with clear advantage
		StrategyType.RUSH:
			return true  # Always push
		StrategyType.BEATDOWN:
			return advantage > 0.2 or strategy_timer > 15.0  # Build up first
		_:
			return advantage > 0.0

func get_deployment_style(strategy: StrategyType) -> String:
	# Return deployment style for positioning
	match strategy:
		StrategyType.AGGRESSIVE, StrategyType.RUSH:
			return "bridge"  # Deploy at bridge
		StrategyType.DEFENSIVE, StrategyType.CONTROL:
			return "back"  # Deploy behind towers
		StrategyType.BRIDGE_SPAM:
			return "bridge_corners"  # Specific bridge positions
		StrategyType.BEATDOWN:
			return "king_tower"  # Start from way back
		StrategyType.SIEGE:
			return "center"  # Center placement for buildings
		_:
			return "mixed"

static func get_strategy_name(strategy: StrategyType) -> String:
	match strategy:
		StrategyType.AGGRESSIVE:
			return "Aggressive"
		StrategyType.DEFENSIVE:
			return "Defensive"
		StrategyType.BALANCED:
			return "Balanced"
		StrategyType.RUSH:
			return "Rush"
		StrategyType.CONTROL:
			return "Control"
		StrategyType.CYCLE:
			return "Cycle"
		StrategyType.BEATDOWN:
			return "Beatdown"
		StrategyType.SIEGE:
			return "Siege"
		StrategyType.BRIDGE_SPAM:
			return "Bridge Spam"
		StrategyType.COUNTER_PUSH:
			return "Counter Push"
		StrategyType.DUAL_LANE:
			return "Dual Lane"
		StrategyType.BAIT:
			return "Bait"
		_:
			return "Unknown"