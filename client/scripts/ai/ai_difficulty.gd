extends Resource
class_name AIDifficulty

# AI Difficulty configurations and enumerations
# Defines behavior parameters for each difficulty level

enum Level {
	EASY,
	MEDIUM,
	HARD
}

# Difficulty configuration structure
class DifficultyConfig:
	var reaction_time: float  # Seconds before AI reacts to threats
	var decision_interval: float  # How often AI evaluates the board
	var mistake_chance: float  # Probability of making intentional mistakes
	var evaluation_accuracy: float  # How well AI evaluates board state (0-1)
	var strategy_complexity: float  # Complexity of strategic decisions (0-1)
	var unit_selection_accuracy: float  # How well AI selects counters (0-1)
	var elixir_management: float  # How efficiently AI manages elixir (0-1)
	var prediction_depth: int  # How many moves ahead AI thinks
	var personality_variation: float  # How much personality affects decisions
	var aggression_level: float  # Base aggression tendency (0-1)
	var max_apm: int  # Maximum actions per minute

	func _init(
		p_reaction: float = 1.0,
		p_interval: float = 0.5,
		p_mistake: float = 0.1,
		p_eval_acc: float = 0.8,
		p_strat_complex: float = 0.8,
		p_unit_acc: float = 0.8,
		p_elixir: float = 0.8,
		p_prediction: int = 1,
		p_personality: float = 0.2,
		p_aggression: float = 0.5,
		p_apm: int = 60
	):
		reaction_time = p_reaction
		decision_interval = p_interval
		mistake_chance = p_mistake
		evaluation_accuracy = p_eval_acc
		strategy_complexity = p_strat_complex
		unit_selection_accuracy = p_unit_acc
		elixir_management = p_elixir
		prediction_depth = p_prediction
		personality_variation = p_personality
		aggression_level = p_aggression
		max_apm = p_apm

# Static difficulty configurations
static var configs = {
	Level.EASY: DifficultyConfig.new(
		2.5,   # reaction_time - Very slow reactions
		1.5,   # decision_interval - Infrequent decisions
		0.4,   # mistake_chance - Makes many mistakes
		0.4,   # evaluation_accuracy - Poor board evaluation
		0.3,   # strategy_complexity - Simple strategies only
		0.3,   # unit_selection_accuracy - Often picks wrong units
		0.4,   # elixir_management - Wastes elixir frequently
		0,     # prediction_depth - No prediction
		0.5,   # personality_variation - High variation for fun
		0.6,   # aggression_level - Tends to be aggressive (predictable)
		30     # max_apm - Slow actions
	),
	Level.MEDIUM: DifficultyConfig.new(
		1.0,   # reaction_time - Normal human-like reactions
		0.75,  # decision_interval - Regular decision making
		0.15,  # mistake_chance - Occasional mistakes
		0.7,   # evaluation_accuracy - Good board evaluation
		0.7,   # strategy_complexity - Can execute complex strategies
		0.7,   # unit_selection_accuracy - Usually picks good counters
		0.7,   # elixir_management - Decent elixir management
		1,     # prediction_depth - Thinks one move ahead
		0.3,   # personality_variation - Moderate variation
		0.5,   # aggression_level - Balanced approach
		60     # max_apm - Normal action speed
	),
	Level.HARD: DifficultyConfig.new(
		0.5,   # reaction_time - Fast reactions
		0.5,   # decision_interval - Frequent evaluations
		0.02,  # mistake_chance - Rarely makes mistakes
		0.95,  # evaluation_accuracy - Near-perfect evaluation
		0.95,  # strategy_complexity - Advanced strategies
		0.95,  # unit_selection_accuracy - Optimal unit selection
		0.95,  # elixir_management - Excellent elixir management
		3,     # prediction_depth - Thinks multiple moves ahead
		0.1,   # personality_variation - Consistent optimal play
		0.5,   # aggression_level - Adapts perfectly
		120    # max_apm - Very fast actions
	)
}

# Personality traits that add variation to AI behavior
enum PersonalityTrait {
	AGGRESSIVE,    # Prefers offensive plays
	DEFENSIVE,     # Prefers defensive plays
	RUSHER,        # Likes to rush early
	CONTROLLER,    # Likes to control the pace
	PUNISHER,      # Capitalizes on mistakes
	CYCLER,        # Focuses on card cycling
	BEATDOWN,      # Builds big pushes
	SIEGE,         # Focuses on spell damage
	BRIDGE_SPAM,   # Constant pressure at bridge
	COUNTER_PUSH   # Defends then counter attacks
}

# Get configuration for a difficulty level
static func get_difficulty_config(level: Level) -> DifficultyConfig:
	if configs.has(level):
		return configs[level]
	return configs[Level.MEDIUM]

# Get human-readable difficulty name
static func get_difficulty_name(level: Level) -> String:
	match level:
		Level.EASY:
			return "Easy"
		Level.MEDIUM:
			return "Medium"
		Level.HARD:
			return "Hard"
		_:
			return "Unknown"

# Get difficulty description for UI
static func get_difficulty_description(level: Level) -> String:
	match level:
		Level.EASY:
			return "Perfect for beginners! The AI makes frequent mistakes and reacts slowly."
		Level.MEDIUM:
			return "A balanced challenge. The AI plays like an average human player."
		Level.HARD:
			return "Expert level AI with fast reactions and optimal play. Good luck!"
		_:
			return ""

# Generate a random personality based on difficulty
static func generate_personality(level: Level, seed: int = 0) -> Array:
	var rng = RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed

	var traits: Array = []
	var num_traits = 1

	match level:
		Level.EASY:
			# Easy AI has 1-2 simple traits
			num_traits = rng.randi_range(1, 2)
			var easy_traits = [
				PersonalityTrait.AGGRESSIVE,
				PersonalityTrait.DEFENSIVE,
				PersonalityTrait.RUSHER
			]
			for i in num_traits:
				traits.append(easy_traits[rng.randi() % easy_traits.size()])

		Level.MEDIUM:
			# Medium AI has 2-3 traits
			num_traits = rng.randi_range(2, 3)
			var medium_traits = [
				PersonalityTrait.AGGRESSIVE,
				PersonalityTrait.DEFENSIVE,
				PersonalityTrait.CONTROLLER,
				PersonalityTrait.PUNISHER,
				PersonalityTrait.COUNTER_PUSH
			]
			for i in num_traits:
				var trait = medium_traits[rng.randi() % medium_traits.size()]
				if trait not in traits:
					traits.append(trait)

		Level.HARD:
			# Hard AI has 2-4 complex traits
			num_traits = rng.randi_range(2, 4)
			var all_traits = PersonalityTrait.values()
			for i in num_traits:
				var trait = all_traits[rng.randi() % all_traits.size()]
				if trait not in traits:
					traits.append(trait)

	return traits

# Calculate reaction time modifier based on situation
static func get_reaction_modifier(level: Level, situation: String) -> float:
	var base_config = get_difficulty_config(level)
	var modifier = 1.0

	match situation:
		"immediate_threat":
			# React faster to immediate threats
			modifier = 0.5 if level == Level.HARD else 0.7
		"opportunity":
			# React to opportunities based on difficulty
			modifier = 1.5 if level == Level.EASY else 1.0
		"elixir_leak":
			# React to full elixir
			modifier = 0.3  # Always react fast to avoid wasting elixir
		"overtime":
			# Speed up in overtime
			modifier = 0.7
		_:
			modifier = 1.0

	return base_config.reaction_time * modifier

# Get mistake type based on difficulty
static func get_mistake_type(level: Level) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	match level:
		Level.EASY:
			# Easy makes all types of mistakes
			var mistakes = [
				"wrong_unit",      # 30% - Deploys wrong counter
				"wrong_timing",    # 30% - Bad timing
				"wrong_position",  # 20% - Bad placement
				"over_commit",     # 10% - Uses too much elixir
				"no_action",       # 10% - Freezes up
			]
			var weights = [30, 30, 20, 10, 10]
			return _weighted_random(mistakes, weights, rng)

		Level.MEDIUM:
			# Medium makes fewer critical mistakes
			var mistakes = [
				"slight_misplay",  # 40% - Minor positioning error
				"wrong_timing",    # 30% - Slightly off timing
				"over_commit",     # 20% - Occasional over-commitment
				"wrong_unit",      # 10% - Rare wrong counter
			]
			var weights = [40, 30, 20, 10]
			return _weighted_random(mistakes, weights, rng)

		Level.HARD:
			# Hard almost never makes mistakes
			var mistakes = [
				"slight_misplay",  # 70% - Very minor errors only
				"calculated_risk", # 30% - Takes risks that might fail
			]
			var weights = [70, 30]
			return _weighted_random(mistakes, weights, rng)

		_:
			return "no_action"

# Helper function for weighted random selection
static func _weighted_random(options: Array, weights: Array, rng: RandomNumberGenerator) -> String:
	var total_weight = 0
	for weight in weights:
		total_weight += weight

	var random_value = rng.randf() * total_weight
	var cumulative_weight = 0

	for i in range(options.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return options[i]

	return options[0]  # Fallback

# Check if AI should make a play based on APM limit
static func can_make_action(level: Level, actions_this_minute: int) -> bool:
	var config = get_difficulty_config(level)
	return actions_this_minute < config.max_apm