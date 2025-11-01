extends GdUnitTestSuite

class_name TestMatchFlow

var battle_manager: Node
var battlefield: Node
var player_deck: Array
var opponent_deck: Array

func before_each() -> void:
	var BattleManager = load("res://scripts/battle/battle_manager.gd")
	battle_manager = BattleManager.new()

	var Battlefield = load("res://scripts/battle/battlefield.gd")
	battlefield = Battlefield.new()

	# Setup test decks
	player_deck = create_test_deck()
	opponent_deck = create_test_deck()

func after_each() -> void:
	if battle_manager:
		battle_manager.queue_free()
	if battlefield:
		battlefield.queue_free()

func test_complete_battle_flow() -> void:
	# 1. Match initialization
	battle_manager.start_match(player_deck, opponent_deck)
	assert_equal(180, battle_manager.match_time)
	assert_equal(0, battle_manager.player_crowns)
	assert_equal(0, battle_manager.opponent_crowns)
	assert_false(battle_manager.is_double_elixir)

	# 2. Early game (first minute)
	await simulate_time_passage(60)
	assert_equal(120, battle_manager.match_time)
	assert_false(battle_manager.is_double_elixir)

	# 3. Deploy some units
	var knight = deploy_unit("knight", Vector2(500, 400), "player")
	assert_not_null(knight)

	# 4. Simulate combat
	var enemy_archer = deploy_unit("archer", Vector2(500, 200), "opponent")
	await simulate_combat(knight, enemy_archer, 5.0)

	# 5. Destroy a tower
	destroy_tower("opponent_left")
	battle_manager.player_crowns = 1
	assert_equal(1, battle_manager.player_crowns)

	# 6. Enter double elixir phase (last minute)
	await simulate_time_passage(60)
	assert_equal(60, battle_manager.match_time)
	assert_true(battle_manager.is_double_elixir)

	# 7. More intense combat in double elixir
	var giant = deploy_unit("giant", Vector2(400, 400), "player")
	var wizard = deploy_unit("wizard", Vector2(450, 400), "player")
	assert_not_null(giant)
	assert_not_null(wizard)

	# 8. End of regular time
	await simulate_time_passage(60)
	assert_equal(0, battle_manager.match_time)

	# 9. Check victory condition
	if battle_manager.player_crowns > battle_manager.opponent_crowns:
		assert_equal("victory", battle_manager.check_victory_condition())
	elif battle_manager.player_crowns < battle_manager.opponent_crowns:
		assert_equal("defeat", battle_manager.check_victory_condition())
	else:
		# Overtime triggered
		assert_true(battle_manager.is_overtime)
		assert_equal(60, battle_manager.overtime_remaining)

func test_three_crown_victory() -> void:
	# Start match
	battle_manager.start_match(player_deck, opponent_deck)

	# Quickly destroy all opponent towers
	destroy_tower("opponent_left")
	destroy_tower("opponent_right")
	destroy_tower("opponent_king")

	battle_manager.player_crowns = 3

	# Check immediate victory
	var result = battle_manager.check_victory_condition()
	assert_equal("victory", result)
	assert_true(battle_manager.is_match_over())

	# Match should end even with time remaining
	assert_greater(battle_manager.match_time, 0)

func test_overtime_flow() -> void:
	# Setup tied match at end of regular time
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0

	# Trigger overtime
	battle_manager.check_overtime_condition()
	assert_true(battle_manager.is_overtime)
	assert_equal(60, battle_manager.overtime_remaining)
	assert_true(battle_manager.is_double_elixir)  # Always double elixir in overtime

	# Simulate overtime
	await simulate_time_passage(30)
	assert_equal(30, battle_manager.overtime_remaining)

	# Score a crown in overtime
	destroy_tower("opponent_left")
	battle_manager.player_crowns = 2

	# Check victory in overtime
	var result = battle_manager.check_victory_condition()
	assert_equal("victory", result)

func test_sudden_death_flow() -> void:
	# Setup for sudden death
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.match_time = 0
	battle_manager.overtime_remaining = 0
	battle_manager.is_overtime = true

	# Trigger sudden death
	battle_manager.check_sudden_death_condition()
	assert_true(battle_manager.is_sudden_death)

	# Any tower damage wins in sudden death
	battle_manager.player_tower_damage = 100
	battle_manager.opponent_tower_damage = 99

	var result = battle_manager.check_victory_condition()
	assert_equal("victory", result)

func test_draw_condition() -> void:
	# Setup equal match
	battle_manager.player_crowns = 1
	battle_manager.opponent_crowns = 1
	battle_manager.player_tower_damage = 500
	battle_manager.opponent_tower_damage = 500
	battle_manager.match_time = 0
	battle_manager.overtime_remaining = 0
	battle_manager.is_overtime = true

	# Even in sudden death with equal damage
	battle_manager.is_sudden_death = true

	var result = battle_manager.check_victory_condition()
	assert_equal("draw", result)

func test_match_abandonment() -> void:
	# Start match
	battle_manager.start_match(player_deck, opponent_deck)

	# Simulate player leaving
	battle_manager.player_disconnected = true

	# After disconnect timeout, opponent wins
	await simulate_time_passage(5.0)  # 5 second disconnect timer
	battle_manager.check_disconnect_condition()

	assert_equal("defeat", battle_manager.check_victory_condition())

func test_replay_recording() -> void:
	# Start recording
	battle_manager.start_match(player_deck, opponent_deck)
	battle_manager.is_recording = true
	battle_manager.replay_data = []

	# Record some actions
	var actions = [
		{"time": 0.5, "player": "player", "action": "deploy", "card": "knight", "position": Vector2(500, 400)},
		{"time": 2.0, "player": "opponent", "action": "deploy", "card": "archer", "position": Vector2(500, 200)},
		{"time": 5.0, "player": "player", "action": "spell", "card": "fireball", "position": Vector2(500, 200)},
		{"time": 10.0, "player": "player", "action": "deploy", "card": "giant", "position": Vector2(400, 400)}
	]

	for action in actions:
		battle_manager.record_action(action)

	# Verify recording
	assert_equal(4, battle_manager.replay_data.size())
	assert_equal("knight", battle_manager.replay_data[0].card)
	assert_equal("fireball", battle_manager.replay_data[2].card)

	# Save replay at match end
	battle_manager.save_replay("test_replay_001")

func test_spectator_mode() -> void:
	# Initialize as spectator
	battle_manager.is_spectator = true
	battle_manager.start_match(player_deck, opponent_deck)

	# Spectator cannot deploy units
	var can_deploy = battle_manager.can_player_deploy()
	assert_false(can_deploy)

	# Spectator sees both hands
	assert_true(battle_manager.show_player_hand)
	assert_true(battle_manager.show_opponent_hand)

	# Spectator sees real-time updates
	assert_equal(0, battle_manager.spectator_delay)

# Helper functions
func create_test_deck() -> Array:
	return [
		{"name": "knight", "cost": 3, "level": 9},
		{"name": "archer", "cost": 3, "level": 9},
		{"name": "giant", "cost": 5, "level": 9},
		{"name": "wizard", "cost": 5, "level": 9},
		{"name": "fireball", "cost": 4, "level": 9},
		{"name": "skeleton", "cost": 1, "level": 9},
		{"name": "goblin", "cost": 2, "level": 9},
		{"name": "valkyrie", "cost": 4, "level": 9}
	]

func deploy_unit(unit_name: String, position: Vector2, team: String) -> Node:
	var unit_data = {"name": unit_name, "team": team}
	return battlefield.spawn_unit(unit_data, position)

func destroy_tower(tower_name: String) -> void:
	match tower_name:
		"opponent_left":
			battle_manager.opponent_left_tower_health = 0
		"opponent_right":
			battle_manager.opponent_right_tower_health = 0
		"opponent_king":
			battle_manager.opponent_king_tower_health = 0
		"player_left":
			battle_manager.player_left_tower_health = 0
		"player_right":
			battle_manager.player_right_tower_health = 0
		"player_king":
			battle_manager.player_king_tower_health = 0

func simulate_time_passage(seconds: float) -> void:
	battle_manager.update_timer(seconds)
	await get_tree().create_timer(0.01).timeout

func simulate_combat(unit1: Node, unit2: Node, duration: float) -> void:
	var elapsed = 0.0
	while elapsed < duration and unit1.is_active and unit2.is_active:
		# Simulate attacks
		if unit1.can_attack():
			unit2.take_damage(unit1.damage)
		if unit2.can_attack():
			unit1.take_damage(unit2.damage)

		elapsed += 0.1
		await get_tree().create_timer(0.1).timeout