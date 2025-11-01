extends GdUnitTestSuite

class_name TestCombatSystem

var attack_component: Node
var health_component: Node
var mock_target: GdUnitMock

func before_each() -> void:
	# Create test components
	var AttackComponent = load("res://scripts/core/components/attack_component.gd")
	var HealthComponent = load("res://scripts/core/components/health_component.gd")

	attack_component = AttackComponent.new()
	health_component = HealthComponent.new()
	mock_target = mock(Node2D)

func after_each() -> void:
	if attack_component:
		attack_component.queue_free()
	if health_component:
		health_component.queue_free()

func test_damage_calculation() -> void:
	# Setup
	attack_component.damage = 100
	health_component.max_health = 500
	health_component.current_health = 500

	# Act
	health_component.take_damage(attack_component.damage)

	# Assert
	assert_equal(400, health_component.current_health)

func test_damage_with_armor() -> void:
	# Setup
	attack_component.damage = 100
	health_component.max_health = 500
	health_component.current_health = 500
	health_component.armor = 20  # 20% reduction

	# Act
	var actual_damage = attack_component.damage * (1.0 - health_component.armor / 100.0)
	health_component.take_damage(actual_damage)

	# Assert
	assert_equal(420, health_component.current_health)

func test_critical_hit() -> void:
	# Setup
	attack_component.damage = 100
	attack_component.crit_chance = 1.0  # 100% crit chance for testing
	attack_component.crit_multiplier = 2.0

	# Act
	var damage = attack_component.calculate_damage()

	# Assert
	assert_equal(200, damage)

func test_attack_speed() -> void:
	# Setup
	attack_component.attack_speed = 2.0  # 2 attacks per second
	attack_component.last_attack_time = 0.0

	# Act - simulate time passing
	var can_attack_at_0_5 = attack_component.can_attack(0.5)
	var can_attack_at_0_25 = attack_component.can_attack(0.25)

	# Assert
	assert_true(can_attack_at_0_5)  # 0.5 seconds passed, can attack
	assert_false(can_attack_at_0_25)  # Only 0.25 seconds passed

func test_range_detection() -> void:
	# Setup
	attack_component.attack_range = 5.0
	attack_component.global_position = Vector2(0, 0)

	# Act
	var in_range_target = Vector2(3, 4)  # Distance = 5
	var out_of_range_target = Vector2(6, 0)  # Distance = 6

	var is_in_range = attack_component.is_in_range(in_range_target)
	var is_out_of_range = attack_component.is_in_range(out_of_range_target)

	# Assert
	assert_true(is_in_range)
	assert_false(is_out_of_range)

func test_melee_vs_ranged() -> void:
	# Setup melee unit
	var melee_attack = attack_component
	melee_attack.attack_range = 1.5
	melee_attack.is_ranged = false

	# Setup ranged unit
	var RangedAttack = load("res://scripts/core/components/attack_component.gd")
	var ranged_attack = RangedAttack.new()
	ranged_attack.attack_range = 6.0
	ranged_attack.is_ranged = true

	# Assert
	assert_less(melee_attack.attack_range, 2.0)
	assert_greater(ranged_attack.attack_range, 5.0)
	assert_false(melee_attack.is_ranged)
	assert_true(ranged_attack.is_ranged)

	ranged_attack.queue_free()

func test_damage_over_time() -> void:
	# Setup
	health_component.max_health = 500
	health_component.current_health = 500

	# Apply poison/burn effect
	var dot_damage = 10
	var dot_duration = 3.0
	var dot_tick_rate = 0.5  # Damage every 0.5 seconds

	# Simulate DOT effect
	var total_ticks = int(dot_duration / dot_tick_rate)
	for i in total_ticks:
		health_component.take_damage(dot_damage)

	# Assert
	var expected_health = 500 - (dot_damage * total_ticks)
	assert_equal(expected_health, health_component.current_health)

func test_area_damage() -> void:
	# Setup
	var targets = []
	for i in 3:
		var target = HealthComponent.new()
		target.max_health = 100
		target.current_health = 100
		targets.append(target)

	# Apply area damage
	var area_damage = 30
	for target in targets:
		target.take_damage(area_damage)

	# Assert
	for target in targets:
		assert_equal(70, target.current_health)
		target.queue_free()

func test_target_prioritization() -> void:
	# Setup mock targets
	var tank = {"health": 1000, "priority": 1}
	var dps = {"health": 500, "priority": 2}
	var support = {"health": 300, "priority": 3}

	var targets = [tank, dps, support]

	# Sort by priority (higher priority first)
	targets.sort_custom(func(a, b): return a.priority > b.priority)

	# Assert
	assert_equal(support, targets[0])  # Highest priority
	assert_equal(dps, targets[1])
	assert_equal(tank, targets[2])  # Lowest priority

func test_damage_mitigation_stacking() -> void:
	# Setup
	health_component.max_health = 1000
	health_component.current_health = 1000
	health_component.armor = 20  # 20% reduction
	health_component.magic_resist = 15  # 15% reduction

	# Calculate stacked mitigation (multiplicative)
	var physical_damage = 100
	var magic_damage = 100

	var mitigated_physical = physical_damage * (1.0 - health_component.armor / 100.0)
	var mitigated_magic = magic_damage * (1.0 - health_component.magic_resist / 100.0)

	# Assert
	assert_equal(80, mitigated_physical)
	assert_equal(85, mitigated_magic)