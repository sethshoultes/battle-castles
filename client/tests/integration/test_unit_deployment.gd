extends GdUnitTestSuite

class_name TestUnitDeployment

var battle_scene: Node
var elixir_manager: Node
var battlefield: Node

func before_all() -> void:
	# Load the battle scene
	var BattleScene = load("res://scenes/battle/battle.tscn")
	if BattleScene:
		battle_scene = BattleScene.instantiate()

func before_each() -> void:
	# Setup managers
	var ElixirManager = load("res://scripts/battle/elixir_manager.gd")
	elixir_manager = ElixirManager.new()
	elixir_manager.current_elixir = 10.0

	var Battlefield = load("res://scripts/battle/battlefield.gd")
	battlefield = Battlefield.new()

func after_each() -> void:
	if elixir_manager:
		elixir_manager.queue_free()
	if battlefield:
		battlefield.queue_free()

func after_all() -> void:
	if battle_scene:
		battle_scene.queue_free()

func test_full_unit_spawn_flow() -> void:
	# Setup
	var unit_data = {
		"name": "knight",
		"cost": 3,
		"health": 1000,
		"damage": 100,
		"speed": 50,
		"range": 1.5
	}
	var spawn_position = Vector2(500, 400)

	# Check elixir
	assert_true(elixir_manager.can_spend(unit_data.cost))

	# Spend elixir
	elixir_manager.spend(unit_data.cost)
	assert_equal(7.0, elixir_manager.current_elixir)

	# Spawn unit
	var unit = battlefield.spawn_unit(unit_data, spawn_position)
	assert_not_null(unit)

	# Verify unit properties
	assert_equal(spawn_position, unit.position)
	assert_equal(unit_data.health, unit.get_component("HealthComponent").max_health)
	assert_equal(unit_data.damage, unit.get_component("AttackComponent").damage)

	# Verify unit is active
	assert_true(unit.is_active)

	# Start movement
	unit.get_component("MovementComponent").set_target(Vector2(500, 100))
	assert_equal("moving", unit.state)

	# Simulate finding enemy
	var enemy = battlefield.spawn_unit(unit_data, Vector2(500, 200))
	enemy.team = "opponent"

	# Check combat engagement
	var distance = unit.position.distance_to(enemy.position)
	if distance <= unit_data.range:
		unit.state = "attacking"
		assert_equal("attacking", unit.state)

	# Cleanup
	unit.queue_free()
	enemy.queue_free()

func test_deployment_validation() -> void:
	# Test invalid deployment positions
	var invalid_positions = [
		Vector2(-100, 200),    # Out of bounds
		Vector2(1100, 200),    # Out of bounds
		Vector2(500, -50),     # Out of bounds
		Vector2(500, 100)      # Enemy territory (assuming top half)
	]

	for pos in invalid_positions:
		var is_valid = battlefield.is_valid_deployment_position(pos, "player")
		assert_false(is_valid, "Position %s should be invalid" % pos)

	# Test valid positions
	var valid_positions = [
		Vector2(500, 400),     # Player territory
		Vector2(300, 350),     # Player territory
		Vector2(700, 350)      # Player territory
	]

	for pos in valid_positions:
		var is_valid = battlefield.is_valid_deployment_position(pos, "player")
		assert_true(is_valid, "Position %s should be valid" % pos)

func test_unit_deck_cycling() -> void:
	# Setup deck
	var deck = [
		{"name": "knight", "cost": 3},
		{"name": "archer", "cost": 3},
		{"name": "giant", "cost": 5},
		{"name": "wizard", "cost": 5},
		{"name": "skeleton", "cost": 1},
		{"name": "goblin", "cost": 2},
		{"name": "minion", "cost": 3},
		{"name": "valkyrie", "cost": 4}
	]

	var hand = []
	var next_card_index = 0

	# Draw initial hand (4 cards)
	for i in 4:
		hand.append(deck[next_card_index])
		next_card_index = (next_card_index + 1) % deck.size()

	assert_equal(4, hand.size())

	# Deploy a card
	var deployed_card = hand[0]
	hand.remove_at(0)

	# Draw next card
	hand.append(deck[next_card_index])
	next_card_index = (next_card_index + 1) % deck.size()

	assert_equal(4, hand.size())
	assert_not_equal(deployed_card, hand[3])  # New card should be different

func test_simultaneous_unit_spawning() -> void:
	# Test spawning multiple units at once
	var spawn_positions = [
		Vector2(400, 400),
		Vector2(500, 400),
		Vector2(600, 400)
	]

	var units = []
	for pos in spawn_positions:
		var unit_data = {"name": "skeleton", "cost": 1, "health": 100}
		var unit = battlefield.spawn_unit(unit_data, pos)
		units.append(unit)

	# Verify all units spawned
	assert_equal(3, units.size())

	# Verify positions don't overlap too much
	for i in range(units.size()):
		for j in range(i + 1, units.size()):
			var distance = units[i].position.distance_to(units[j].position)
			assert_greater(distance, 50)  # Minimum separation

	# Cleanup
	for unit in units:
		unit.queue_free()

func test_elixir_refund_on_invalid_deployment() -> void:
	# Setup
	var initial_elixir = elixir_manager.current_elixir
	var unit_cost = 4

	# Try to deploy in invalid position
	var invalid_pos = Vector2(-100, -100)

	# Attempt deployment
	if battlefield.is_valid_deployment_position(invalid_pos, "player"):
		elixir_manager.spend(unit_cost)
		battlefield.spawn_unit({"cost": unit_cost}, invalid_pos)
	else:
		# Deployment failed, elixir should not be spent
		pass

	# Assert elixir wasn't spent
	assert_equal(initial_elixir, elixir_manager.current_elixir)

func test_unit_death_and_cleanup() -> void:
	# Setup
	var unit_data = {"name": "skeleton", "health": 100}
	var unit = battlefield.spawn_unit(unit_data, Vector2(500, 400))
	var initial_unit_count = battlefield.get_unit_count()

	# Deal lethal damage
	unit.get_component("HealthComponent").take_damage(150)

	# Check death state
	assert_equal(0, unit.get_component("HealthComponent").current_health)
	assert_false(unit.is_active)

	# Unit should be removed from battlefield
	battlefield.remove_unit(unit)
	assert_equal(initial_unit_count - 1, battlefield.get_unit_count())

	# Cleanup
	unit.queue_free()

func test_spell_deployment() -> void:
	# Setup spell
	var spell_data = {
		"name": "fireball",
		"cost": 4,
		"damage": 300,
		"radius": 100,
		"type": "area"
	}

	# Check elixir
	assert_true(elixir_manager.can_spend(spell_data.cost))

	# Deploy spell
	var target_pos = Vector2(500, 200)
	elixir_manager.spend(spell_data.cost)

	# Create spell effect
	var spell = battlefield.cast_spell(spell_data, target_pos)
	assert_not_null(spell)

	# Find units in radius
	var affected_units = battlefield.get_units_in_radius(target_pos, spell_data.radius)

	# Apply damage to affected units
	for unit in affected_units:
		unit.get_component("HealthComponent").take_damage(spell_data.damage)

	# Cleanup
	if spell:
		spell.queue_free()