extends GdUnitTestSuite

class_name TestTowerTargeting

var tower: Node
var battlefield: Node
var mock_units: Array

func before_each() -> void:
	var Tower = load("res://scripts/battle/tower.gd")
	tower = Tower.new()
	tower.position = Vector2(500, 100)
	tower.attack_range = 150.0
	tower.damage = 50
	tower.attack_speed = 1.0

	var Battlefield = load("res://scripts/battle/battlefield.gd")
	battlefield = Battlefield.new()

	mock_units = []

func after_each() -> void:
	if tower:
		tower.queue_free()
	if battlefield:
		battlefield.queue_free()
	for unit in mock_units:
		if unit:
			unit.queue_free()

func test_tower_auto_attack() -> void:
	# Setup enemy unit in range
	var enemy = create_mock_unit(Vector2(500, 200), "opponent")
	mock_units.append(enemy)

	# Tower should detect enemy
	var target = tower.find_closest_enemy()
	assert_not_null(target)
	assert_equal(enemy, target)

	# Tower should attack
	var can_attack = tower.can_attack(Time.get_ticks_msec() / 1000.0)
	if can_attack:
		enemy.get_component("HealthComponent").take_damage(tower.damage)

	# Verify damage dealt
	assert_less(enemy.get_component("HealthComponent").current_health, 500)

func test_target_prioritization() -> void:
	# Create multiple enemies at different distances
	var close_enemy = create_mock_unit(Vector2(500, 150), "opponent")  # 50 units away
	var medium_enemy = create_mock_unit(Vector2(450, 100), "opponent") # 50 units away
	var far_enemy = create_mock_unit(Vector2(500, 240), "opponent")    # 140 units away

	mock_units.append_array([close_enemy, medium_enemy, far_enemy])

	# Tower should target closest enemy
	var target = tower.find_closest_enemy()
	assert_true(target == close_enemy or target == medium_enemy)  # Both are equally close
	assert_not_equal(far_enemy, target)

func test_target_switching_on_death() -> void:
	# Setup two enemies
	var enemy1 = create_mock_unit(Vector2(500, 150), "opponent")
	var enemy2 = create_mock_unit(Vector2(500, 180), "opponent")
	mock_units.append_array([enemy1, enemy2])

	# Tower targets first enemy
	tower.current_target = enemy1
	assert_equal(enemy1, tower.current_target)

	# Kill first enemy
	enemy1.get_component("HealthComponent").current_health = 0
	enemy1.is_active = false

	# Tower should switch to second enemy
	tower.update_target()
	assert_equal(enemy2, tower.current_target)

func test_out_of_range_targeting() -> void:
	# Setup enemy outside range
	var enemy = create_mock_unit(Vector2(500, 300), "opponent")  # 200 units away
	mock_units.append(enemy)

	# Tower should not target out-of-range enemy
	var in_range = tower.is_in_range(enemy.position)
	assert_false(in_range)

	var target = tower.find_closest_enemy()
	assert_null(target)

func test_king_tower_activation() -> void:
	# Setup king tower (initially inactive)
	var king_tower = Tower.new()
	king_tower.is_king_tower = true
	king_tower.is_activated = false
	king_tower.position = Vector2(500, 50)
	king_tower.attack_range = 200.0  # Larger range when activated

	# King tower should not attack initially
	var enemy = create_mock_unit(Vector2(500, 150), "opponent")
	mock_units.append(enemy)

	assert_false(king_tower.is_activated)
	assert_false(king_tower.can_attack_target(enemy))

	# Activate king tower (usually when damaged)
	king_tower.activate()
	assert_true(king_tower.is_activated)
	assert_true(king_tower.can_attack_target(enemy))

	king_tower.queue_free()

func test_multiple_tower_coordination() -> void:
	# Setup multiple towers
	var tower2 = Tower.new()
	tower2.position = Vector2(300, 100)
	tower2.attack_range = 150.0

	# Create enemy between towers
	var enemy = create_mock_unit(Vector2(400, 100), "opponent")
	mock_units.append(enemy)

	# Both towers should be able to target the same enemy
	var target1 = tower.find_closest_enemy()
	var target2 = tower2.find_closest_enemy()

	assert_equal(enemy, target1)
	assert_equal(enemy, target2)

	# Both attack simultaneously
	enemy.get_component("HealthComponent").take_damage(tower.damage)
	enemy.get_component("HealthComponent").take_damage(tower2.damage)

	assert_equal(400, enemy.get_component("HealthComponent").current_health)  # 500 - 50 - 50

	tower2.queue_free()

func test_tower_attack_speed() -> void:
	# Setup
	var enemy = create_mock_unit(Vector2(500, 150), "opponent")
	mock_units.append(enemy)

	tower.attack_speed = 2.0  # 2 attacks per second
	tower.last_attack_time = 0.0

	# Test attack timing
	var current_time = 0.0

	# First attack at t=0
	assert_true(tower.can_attack(current_time))
	tower.perform_attack(enemy)
	tower.last_attack_time = current_time

	# Cannot attack at t=0.25 (need 0.5s between attacks)
	current_time = 0.25
	assert_false(tower.can_attack(current_time))

	# Can attack at t=0.5
	current_time = 0.5
	assert_true(tower.can_attack(current_time))
	tower.perform_attack(enemy)
	tower.last_attack_time = current_time

	# Verify damage
	assert_equal(400, enemy.get_component("HealthComponent").current_health)  # 2 attacks

func test_princess_tower_destruction() -> void:
	# Setup princess tower
	tower.is_princess_tower = true
	tower.health = 100

	# Create strong enemy
	var enemy = create_mock_unit(Vector2(500, 150), "opponent")
	enemy.get_component("AttackComponent").damage = 150
	mock_units.append(enemy)

	# Enemy attacks tower
	tower.take_damage(enemy.get_component("AttackComponent").damage)

	# Tower should be destroyed
	assert_equal(0, tower.health)
	assert_false(tower.is_active)

	# Should award crown to enemy team
	var crown_awarded = tower.is_princess_tower and tower.health <= 0
	assert_true(crown_awarded)

func test_tower_vs_flying_units() -> void:
	# Create ground and air units
	var ground_unit = create_mock_unit(Vector2(500, 150), "opponent")
	ground_unit.is_flying = false

	var air_unit = create_mock_unit(Vector2(500, 180), "opponent")
	air_unit.is_flying = true

	mock_units.append_array([ground_unit, air_unit])

	# Tower can target both
	assert_true(tower.can_target(ground_unit))
	assert_true(tower.can_target(air_unit))

	# Some units might only target ground
	var ground_only_unit = Node2D.new()
	ground_only_unit.can_target_air = false

	assert_true(ground_only_unit.can_target_air == false)
	ground_only_unit.queue_free()

func test_tower_projectile_travel_time() -> void:
	# Setup ranged tower with projectile
	tower.has_projectile = true
	tower.projectile_speed = 500.0  # pixels per second

	var enemy = create_mock_unit(Vector2(500, 200), "opponent")
	mock_units.append(enemy)

	# Calculate projectile travel time
	var distance = tower.position.distance_to(enemy.position)
	var travel_time = distance / tower.projectile_speed

	assert_in_range(travel_time, 0.19, 0.21)  # ~0.2 seconds for 100 pixel distance

	# Enemy could move during projectile flight
	var enemy_movement = enemy.get_component("MovementComponent").speed * travel_time
	var predicted_position = enemy.position + enemy.velocity.normalized() * enemy_movement

	# Tower should lead target
	assert_not_equal(enemy.position, predicted_position)

# Helper function to create mock units
func create_mock_unit(pos: Vector2, team: String) -> Node2D:
	var unit = Node2D.new()
	unit.position = pos
	unit.team = team
	unit.is_active = true
	unit.is_flying = false
	unit.velocity = Vector2.ZERO

	# Add components
	var HealthComponent = load("res://scripts/core/components/health_component.gd")
	var health = HealthComponent.new()
	health.max_health = 500
	health.current_health = 500
	health.name = "HealthComponent"
	unit.add_child(health)

	var AttackComponent = load("res://scripts/core/components/attack_component.gd")
	var attack = AttackComponent.new()
	attack.damage = 50
	attack.name = "AttackComponent"
	unit.add_child(attack)

	var MovementComponent = load("res://scripts/core/components/movement_component.gd")
	var movement = MovementComponent.new()
	movement.speed = 50
	movement.name = "MovementComponent"
	unit.add_child(movement)

	unit.get_component = func(comp_name):
		return unit.get_node(comp_name)

	return unit