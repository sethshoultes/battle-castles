extends GdUnitTestSuite

class_name TestBattleManager

var battle_manager: Node
var mock_player: GdUnitMock
var mock_opponent: GdUnitMock

func before_each() -> void:
	var BattleManager = load("res://scripts/battle/battle_manager.gd")
	battle_manager = BattleManager.new()
	mock_player = mock(Node)
	mock_opponent = mock(Node)

	# Initialize battle state
	battle_manager.player_crowns = 0
	battle_manager.opponent_crowns = 0
	battle_manager.match_time = 180  # 3 minutes

func after_each() -> void:
	if battle_manager:
		battle_manager.queue_free()

func test_victory_by_three_crowns() -> void:
	# Setup
	battle_manager.player_crowns = 3
	battle_manager.opponent_crowns = 1

	# Act
	var result = battle_manager.check_victory_condition()

	# Assert
	assert_equal("victory", result)
	assert_true(battle_manager.is_match_over())

func test_defeat_by_three_crowns() -> void:
	# Setup
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 3

	# Act
	var result = battle_manager.check_victory_condition()

	# Assert
	assert_equal("defeat", result)
	assert_true(battle_manager.is_match_over())

func test_victory_by_more_crowns_at_timeout() -> void:
	# Setup
	battle_manager.player_crowns = 2
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0  # Time's up

	# Act
	var result = battle_manager.check_victory_condition()

	# Assert
	assert_equal("victory", result)

func test_draw_at_timeout() -> void:
	# Setup
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0

	# Act
	var result = battle_manager.check_victory_condition()

	# Assert
	assert_equal("draw", result)

func test_overtime_trigger() -> void:
	# Setup - Tied at regular time end
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0
	battle_manager.is_overtime = false

	# Act
	battle_manager.check_overtime_condition()

	# Assert
	assert_true(battle_manager.is_overtime)
	assert_equal(60, battle_manager.overtime_remaining)  # 1 minute overtime

func test_sudden_death_trigger() -> void:
	# Setup - Still tied after overtime
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0
	battle_manager.overtime_remaining = 0
	battle_manager.is_overtime = true
	battle_manager.is_sudden_death = false

	# Act
	battle_manager.check_sudden_death_condition()

	# Assert
	assert_true(battle_manager.is_sudden_death)

func test_sudden_death_instant_victory() -> void:
	# Setup
	battle_manager.is_sudden_death = true
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 0
	battle_manager.player_tower_damage = 500
	battle_manager.opponent_tower_damage = 400

	# Act - Any tower damage in sudden death
	battle_manager.player_tower_damage += 1

	var result = battle_manager.check_victory_condition()

	# Assert
	assert_equal("victory", result)

func test_crown_calculation() -> void:
	# Setup tower healths
	var towers = {
		"player_left": 100,
		"player_right": 0,    # Destroyed
		"player_king": 500,
		"opponent_left": 0,    # Destroyed
		"opponent_right": 0,   # Destroyed
		"opponent_king": 200
	}

	# Act
	var player_crowns = battle_manager.calculate_crowns(towers, "player")
	var opponent_crowns = battle_manager.calculate_crowns(towers, "opponent")

	# Assert
	assert_equal(2, opponent_crowns)  # Opponent destroyed 2 player towers
	assert_equal(1, player_crowns)     # Player destroyed 1 opponent tower

func test_king_tower_activation() -> void:
	# Setup
	battle_manager.player_king_activated = false
	battle_manager.opponent_king_activated = false

	# Act - Damage king tower
	battle_manager.damage_king_tower("player", 1)

	# Assert
	assert_true(battle_manager.player_king_activated)
	assert_false(battle_manager.opponent_king_activated)

func test_timer_countdown() -> void:
	# Setup
	battle_manager.match_time = 180.0
	var delta = 1.0  # 1 second

	# Act
	battle_manager.update_timer(delta)

	# Assert
	assert_equal(179.0, battle_manager.match_time)

	# Test overtime timer
	battle_manager.match_time = 0
	battle_manager.is_overtime = true
	battle_manager.overtime_remaining = 60.0

	battle_manager.update_timer(delta)
	assert_equal(59.0, battle_manager.overtime_remaining)

func test_double_elixir_mode_timing() -> void:
	# Setup - Last minute triggers double elixir
	battle_manager.match_time = 61.0  # Just over 1 minute
	battle_manager.is_double_elixir = false

	# Act
	battle_manager.update_timer(1.5)  # Cross the 60-second threshold

	# Assert
	assert_true(battle_manager.is_double_elixir)

func test_match_result_calculation() -> void:
	# Test various match outcomes
	var scenarios = [
		{"player": 3, "opponent": 0, "expected": "victory"},
		{"player": 0, "opponent": 3, "expected": "defeat"},
		{"player": 2, "opponent": 1, "expected": "victory"},
		{"player": 1, "opponent": 2, "expected": "defeat"},
		{"player": 1, "opponent": 1, "expected": "draw"}
	]

	for scenario in scenarios:
		battle_manager.player_crowns = scenario.player
		battle_manager.opponent_crowns = scenario.opponent
		battle_manager.match_time = 0  # End of match

		var result = battle_manager.check_victory_condition()
		assert_equal(scenario.expected, result)

func test_tower_destruction_order() -> void:
	# Setup
	battle_manager.player_left_tower_health = 0
	battle_manager.player_right_tower_health = 100
	battle_manager.player_king_tower_health = 500

	# Act - Try to damage king tower before both princess towers are down
	var can_damage_king = battle_manager.can_target_king_tower("player")

	# Assert
	assert_false(can_damage_king)  # Still has one princess tower

	# Destroy second princess tower
	battle_manager.player_right_tower_health = 0
	can_damage_king = battle_manager.can_target_king_tower("player")

	assert_true(can_damage_king)  # Both princess towers down

func test_replay_data_recording() -> void:
	# Setup
	battle_manager.replay_data = []

	# Act - Record some actions
	var actions = [
		{"time": 0.0, "type": "deploy", "unit": "knight", "position": Vector2(100, 100)},
		{"time": 1.5, "type": "deploy", "unit": "archer", "position": Vector2(150, 150)},
		{"time": 3.0, "type": "spell", "spell": "fireball", "position": Vector2(200, 200)}
	]

	for action in actions:
		battle_manager.record_action(action)

	# Assert
	assert_equal(3, battle_manager.replay_data.size())
	assert_equal("deploy", battle_manager.replay_data[0].type)
	assert_equal("fireball", battle_manager.replay_data[2].spell)