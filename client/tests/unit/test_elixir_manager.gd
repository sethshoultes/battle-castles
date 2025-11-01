extends GdUnitTestSuite

class_name TestElixirManager

var elixir_manager: Node

func before_each() -> void:
	var ElixirManager = load("res://scripts/battle/elixir_manager.gd")
	elixir_manager = ElixirManager.new()
	elixir_manager.max_elixir = 10.0
	elixir_manager.current_elixir = 5.0
	elixir_manager.regen_rate = 2.8  # Normal regen rate

func after_each() -> void:
	if elixir_manager:
		elixir_manager.queue_free()

func test_elixir_regeneration() -> void:
	# Setup
	var initial_elixir = elixir_manager.current_elixir
	var delta = 1.0  # 1 second

	# Act
	elixir_manager.regenerate(delta)

	# Assert
	var expected = initial_elixir + (elixir_manager.regen_rate * delta)
	assert_that(elixir_manager.current_elixir).is_equal(expected)

func test_elixir_max_cap() -> void:
	# Setup
	elixir_manager.current_elixir = 9.0
	var delta = 1.0  # Should generate 2.8 elixir, but cap at 10

	# Act
	elixir_manager.regenerate(delta)

	# Assert
	assert_equal(10.0, elixir_manager.current_elixir)
	assert_that(elixir_manager.current_elixir).is_not_equal(11.8)

func test_elixir_spending() -> void:
	# Setup
	elixir_manager.current_elixir = 7.0
	var cost = 4.0

	# Act
	var can_spend = elixir_manager.can_spend(cost)
	if can_spend:
		elixir_manager.spend(cost)

	# Assert
	assert_true(can_spend)
	assert_equal(3.0, elixir_manager.current_elixir)

func test_insufficient_elixir() -> void:
	# Setup
	elixir_manager.current_elixir = 3.0
	var cost = 5.0

	# Act
	var can_spend = elixir_manager.can_spend(cost)

	# Assert
	assert_false(can_spend)
	assert_equal(3.0, elixir_manager.current_elixir)  # Should not change

func test_double_elixir_mode() -> void:
	# Setup
	elixir_manager.current_elixir = 0.0
	elixir_manager.is_double_elixir = true
	var delta = 1.0

	# Act
	var expected_regen = elixir_manager.regen_rate * 2.0 * delta
	elixir_manager.regenerate(delta)

	# Assert
	assert_equal(expected_regen, elixir_manager.current_elixir)

func test_elixir_overflow_prevention() -> void:
	# Setup
	elixir_manager.current_elixir = 10.0  # Already at max
	elixir_manager.leak_rate = 1.0  # 1 elixir per second leak when full

	# Act
	var delta = 1.0
	elixir_manager.update_overflow(delta)

	# Assert - Should leak 1 elixir but regenerate normally
	var expected = 10.0  # Stay at cap
	assert_equal(expected, elixir_manager.current_elixir)

func test_elixir_generation_timing() -> void:
	# Setup - Track elixir over time
	elixir_manager.current_elixir = 0.0
	var time_to_full = elixir_manager.max_elixir / elixir_manager.regen_rate

	# Act - Simulate full regeneration
	elixir_manager.regenerate(time_to_full)

	# Assert
	assert_in_range(elixir_manager.current_elixir, 9.9, 10.0)  # Allow small float precision error

func test_elixir_cost_validation() -> void:
	# Test various card costs
	var card_costs = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
	elixir_manager.current_elixir = 5.0

	for cost in card_costs:
		var can_afford = elixir_manager.can_spend(cost)
		if cost <= 5.0:
			assert_true(can_afford, "Should afford %d elixir" % cost)
		else:
			assert_false(can_afford, "Should not afford %d elixir" % cost)

func test_elixir_sudden_death_mode() -> void:
	# Setup - Sudden death has faster regen
	elixir_manager.is_sudden_death = true
	elixir_manager.sudden_death_multiplier = 3.0
	elixir_manager.current_elixir = 0.0

	# Act
	var delta = 1.0
	var expected = elixir_manager.regen_rate * elixir_manager.sudden_death_multiplier * delta
	elixir_manager.regenerate(delta)

	# Assert
	assert_equal(expected, elixir_manager.current_elixir)

func test_elixir_collector_bonus() -> void:
	# Setup - Elixir collector provides bonus generation
	elixir_manager.collector_bonus = 0.5  # +0.5 elixir/second
	elixir_manager.current_elixir = 0.0

	# Act
	var delta = 2.0
	var base_regen = elixir_manager.regen_rate * delta
	var collector_regen = elixir_manager.collector_bonus * delta
	elixir_manager.regenerate_with_collector(delta)

	# Assert
	var expected_total = base_regen + collector_regen
	assert_equal(expected_total, elixir_manager.current_elixir)

func test_elixir_reset() -> void:
	# Setup
	elixir_manager.current_elixir = 7.5
	elixir_manager.is_double_elixir = true

	# Act
	elixir_manager.reset()

	# Assert
	assert_equal(5.0, elixir_manager.current_elixir)  # Default starting elixir
	assert_false(elixir_manager.is_double_elixir)