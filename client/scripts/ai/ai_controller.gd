extends Node
class_name AIController

# AI Controller manages the AI opponent's decision-making and actions
# Uses behavior tree pattern for modular decision logic

signal ai_decision_made(action: Dictionary)
signal ai_state_changed(new_state: String)

# Core properties
var difficulty: AIDifficulty.Level = AIDifficulty.Level.MEDIUM
var current_elixir: float = 0.0
var max_elixir: float = 10.0
var elixir_generation_rate: float = 2.8  # Elixir per second

# AI Components
var evaluator: AIEvaluator
var strategies: AIStrategies
var unit_selector: AIUnitSelector

# Decision making
var decision_timer: Timer
var reaction_delay: float = 1.0  # Seconds before AI reacts
var last_decision_time: float = 0.0
var is_active: bool = false

# Board state
var friendly_towers: Array = []
var enemy_towers: Array = []
var friendly_units: Array = []
var enemy_units: Array = []
var available_cards: Array = []
var cards_in_hand: Array = []

# Personality and behavior
var personality_seed: int = 0
var current_strategy: AIStrategies.StrategyType
var mistake_probability: float = 0.1  # Chance to make suboptimal play

# Performance tracking
var decisions_made: int = 0
var elixir_spent: float = 0.0
var units_deployed: int = 0

func _ready() -> void:
	_initialize_components()
	_setup_decision_timer()
	_configure_difficulty(difficulty)

	# Generate random personality seed for variation
	personality_seed = randi() % 1000

func _initialize_components() -> void:
	# Create AI subsystems
	evaluator = AIEvaluator.new()
	strategies = AIStrategies.new()
	unit_selector = AIUnitSelector.new()

	add_child(evaluator)
	add_child(strategies)
	add_child(unit_selector)

func _setup_decision_timer() -> void:
	decision_timer = Timer.new()
	decision_timer.wait_time = 0.5  # Base evaluation frequency
	decision_timer.timeout.connect(_on_decision_timer_timeout)
	add_child(decision_timer)

func start_ai() -> void:
	is_active = true
	decision_timer.start()
	emit_signal("ai_state_changed", "active")
	print("[AI] Started with difficulty: ", AIDifficulty.get_difficulty_name(difficulty))

func stop_ai() -> void:
	is_active = false
	decision_timer.stop()
	emit_signal("ai_state_changed", "inactive")
	print("[AI] Stopped")

func set_difficulty(level: AIDifficulty.Level) -> void:
	difficulty = level
	_configure_difficulty(level)
	print("[AI] Difficulty changed to: ", AIDifficulty.get_difficulty_name(level))

func _configure_difficulty(level: AIDifficulty.Level) -> void:
	var config = AIDifficulty.get_difficulty_config(level)

	reaction_delay = config.reaction_time
	mistake_probability = config.mistake_chance
	decision_timer.wait_time = config.decision_interval

	# Configure components with difficulty settings
	evaluator.set_accuracy(config.evaluation_accuracy)
	strategies.set_complexity(config.strategy_complexity)
	unit_selector.set_optimization_level(config.unit_selection_accuracy)

func _on_decision_timer_timeout() -> void:
	if not is_active:
		return

	# Check if enough time has passed since last decision
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_decision_time < reaction_delay:
		return

	# Make decision
	_evaluate_and_decide()
	last_decision_time = current_time

func _evaluate_and_decide() -> void:
	# Step 1: Evaluate current board state
	var board_state = _get_board_state()
	var evaluation = evaluator.evaluate_board(board_state)

	# Step 2: Determine strategy based on evaluation
	current_strategy = strategies.select_strategy(
		evaluation,
		difficulty,
		personality_seed
	)

	# Step 3: Should we make a mistake? (for lower difficulties)
	if randf() < mistake_probability:
		_make_intentional_mistake()
		return

	# Step 4: Select action based on strategy
	var action = _select_action(evaluation, current_strategy)

	# Step 5: Execute action if possible
	if action and _can_afford_action(action):
		_execute_action(action)

func _get_board_state() -> Dictionary:
	return {
		"friendly_towers": friendly_towers,
		"enemy_towers": enemy_towers,
		"friendly_units": friendly_units,
		"enemy_units": enemy_units,
		"current_elixir": current_elixir,
		"time_elapsed": Time.get_ticks_msec() / 1000.0
	}

func _select_action(evaluation: Dictionary, strategy: AIStrategies.StrategyType) -> Dictionary:
	# Determine action type based on strategy and evaluation
	var action_type = _determine_action_type(evaluation, strategy)

	if action_type == "deploy_unit":
		return _select_deployment_action(evaluation)
	elif action_type == "wait":
		return {"type": "wait", "duration": 1.0}
	else:
		return null

func _determine_action_type(evaluation: Dictionary, strategy: AIStrategies.StrategyType) -> String:
	# Priority checks
	if evaluation.immediate_threat > 0.7:
		return "deploy_unit"  # Defend immediately

	if current_elixir >= max_elixir * 0.95:
		return "deploy_unit"  # Don't waste elixir

	# Strategy-based decisions
	match strategy:
		AIStrategies.StrategyType.AGGRESSIVE:
			if current_elixir >= 4.0:
				return "deploy_unit"
		AIStrategies.StrategyType.DEFENSIVE:
			if evaluation.enemy_push_strength > 0.5:
				return "deploy_unit"
		AIStrategies.StrategyType.BALANCED:
			if current_elixir >= 6.0 or evaluation.advantage > 0.3:
				return "deploy_unit"

	return "wait"

func _select_deployment_action(evaluation: Dictionary) -> Dictionary:
	# Get best unit and position from unit selector
	var selection = unit_selector.select_unit(
		cards_in_hand,
		evaluation,
		current_elixir,
		current_strategy
	)

	if not selection:
		return null

	# Determine deployment position
	var position = _calculate_deployment_position(selection.unit, evaluation)

	return {
		"type": "deploy_unit",
		"unit": selection.unit,
		"position": position,
		"cost": selection.cost
	}

func _calculate_deployment_position(unit: Dictionary, evaluation: Dictionary) -> Vector2:
	# Calculate optimal deployment position based on unit type and board state
	var base_position = Vector2()

	# Determine lane (left, center, right)
	var lane = _select_lane(evaluation)

	# Adjust position based on unit type
	if unit.has("type"):
		match unit.type:
			"tank":
				base_position = _get_bridge_position(lane)
			"ranged":
				base_position = _get_backline_position(lane)
			"swarm":
				base_position = _get_center_position(lane)
			_:
				base_position = _get_safe_position(lane)

	# Add slight randomization for variety
	base_position.x += randf_range(-50, 50)
	base_position.y += randf_range(-50, 50)

	return base_position

func _select_lane(evaluation: Dictionary) -> String:
	# Select lane based on evaluation
	if evaluation.has("weakest_lane"):
		return evaluation.weakest_lane

	# Default to random lane
	var lanes = ["left", "center", "right"]
	return lanes[randi() % lanes.size()]

func _get_bridge_position(lane: String) -> Vector2:
	# Return position at the bridge for the specified lane
	match lane:
		"left":
			return Vector2(200, 400)
		"right":
			return Vector2(600, 400)
		_:
			return Vector2(400, 400)

func _get_backline_position(lane: String) -> Vector2:
	# Return position behind towers for the specified lane
	match lane:
		"left":
			return Vector2(200, 600)
		"right":
			return Vector2(600, 600)
		_:
			return Vector2(400, 650)

func _get_center_position(lane: String) -> Vector2:
	# Return center position for the specified lane
	return Vector2(400, 500)

func _get_safe_position(lane: String) -> Vector2:
	# Return a safe deployment position
	return Vector2(400, 550)

func _can_afford_action(action: Dictionary) -> bool:
	if action.type == "deploy_unit":
		return current_elixir >= action.cost
	return true

func _execute_action(action: Dictionary) -> void:
	match action.type:
		"deploy_unit":
			_deploy_unit(action.unit, action.position)
			current_elixir -= action.cost
			elixir_spent += action.cost
			units_deployed += 1
		"wait":
			pass  # Do nothing this cycle

	decisions_made += 1
	emit_signal("ai_decision_made", action)

func _deploy_unit(unit: Dictionary, position: Vector2) -> void:
	# This would interface with the game's unit spawning system
	print("[AI] Deploying ", unit.name, " at position ", position)
	# Game.spawn_unit(unit, position, "ai_player")

func _make_intentional_mistake() -> void:
	# Make a suboptimal play for lower difficulties
	var mistake_types = ["wrong_timing", "wrong_position", "wrong_unit", "no_action"]
	var mistake = mistake_types[randi() % mistake_types.size()]

	match mistake:
		"wrong_timing":
			# Deploy too early or too late
			await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
		"wrong_position":
			# Deploy in suboptimal location
			if cards_in_hand.size() > 0:
				var random_unit = cards_in_hand[randi() % cards_in_hand.size()]
				var random_pos = Vector2(randf_range(100, 700), randf_range(300, 600))
				_deploy_unit(random_unit, random_pos)
		"wrong_unit":
			# Deploy wrong counter
			if cards_in_hand.size() > 0:
				var random_unit = cards_in_hand[randi() % cards_in_hand.size()]
				var position = _calculate_deployment_position(random_unit, {})
				_deploy_unit(random_unit, position)
		"no_action":
			# Skip this decision cycle
			pass

func update_board_state(state: Dictionary) -> void:
	# Update AI's knowledge of the board
	if state.has("friendly_towers"):
		friendly_towers = state.friendly_towers
	if state.has("enemy_towers"):
		enemy_towers = state.enemy_towers
	if state.has("friendly_units"):
		friendly_units = state.friendly_units
	if state.has("enemy_units"):
		enemy_units = state.enemy_units

func update_cards(cards: Array) -> void:
	cards_in_hand = cards

func add_elixir(amount: float) -> void:
	current_elixir = min(current_elixir + amount, max_elixir)

func _process(delta: float) -> void:
	if is_active:
		# Generate elixir over time
		add_elixir(elixir_generation_rate * delta)

func get_stats() -> Dictionary:
	return {
		"decisions_made": decisions_made,
		"elixir_spent": elixir_spent,
		"units_deployed": units_deployed,
		"current_strategy": AIStrategies.get_strategy_name(current_strategy),
		"difficulty": AIDifficulty.get_difficulty_name(difficulty)
	}