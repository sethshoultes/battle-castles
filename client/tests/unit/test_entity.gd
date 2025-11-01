extends GdUnitTestSuite

class_name TestEntity

var entity: Node
var mock_component: GdUnitMock

func before_each() -> void:
	var Entity = load("res://scripts/core/entity.gd")
	entity = Entity.new()
	mock_component = mock(Node)

func after_each() -> void:
	if entity:
		entity.queue_free()

func test_component_addition() -> void:
	# Setup
	var Component = load("res://scripts/core/component.gd")
	var component = Component.new()
	component.name = "TestComponent"

	# Act
	entity.add_component(component)

	# Assert
	assert_true(entity.has_component("TestComponent"))
	assert_not_null(entity.get_component("TestComponent"))

func test_component_removal() -> void:
	# Setup
	var Component = load("res://scripts/core/component.gd")
	var component = Component.new()
	component.name = "TestComponent"
	entity.add_component(component)

	# Act
	entity.remove_component("TestComponent")

	# Assert
	assert_false(entity.has_component("TestComponent"))
	assert_null(entity.get_component("TestComponent"))

func test_multiple_components() -> void:
	# Setup
	var components = []
	for i in 3:
		var Component = load("res://scripts/core/component.gd")
		var comp = Component.new()
		comp.name = "Component%d" % i
		components.append(comp)
		entity.add_component(comp)

	# Assert
	assert_equal(3, entity.get_component_count())
	for i in 3:
		assert_true(entity.has_component("Component%d" % i))

func test_component_lifecycle() -> void:
	# Setup
	var Component = load("res://scripts/core/component.gd")
	var component = Component.new()
	component.name = "LifecycleComponent"

	# Act - Component lifecycle
	entity.add_component(component)
	assert_true(component.is_enabled)

	component.disable()
	assert_false(component.is_enabled)

	component.enable()
	assert_true(component.is_enabled)

	entity.remove_component("LifecycleComponent")
	assert_false(entity.has_component("LifecycleComponent"))

func test_entity_initialization() -> void:
	# Assert default state
	assert_not_null(entity)
	assert_true(entity.is_active)
	assert_equal(0, entity.get_component_count())

func test_entity_activation_state() -> void:
	# Setup
	entity.is_active = true

	# Act
	entity.deactivate()
	assert_false(entity.is_active)

	entity.activate()
	assert_true(entity.is_active)

func test_component_communication() -> void:
	# Setup components that need to interact
	var HealthComponent = load("res://scripts/core/components/health_component.gd")
	var AttackComponent = load("res://scripts/core/components/attack_component.gd")

	var health = HealthComponent.new()
	var attack = AttackComponent.new()

	health.name = "HealthComponent"
	attack.name = "AttackComponent"

	entity.add_component(health)
	entity.add_component(attack)

	# Components should be able to find each other
	var found_health = entity.get_component("HealthComponent")
	var found_attack = entity.get_component("AttackComponent")

	assert_not_null(found_health)
	assert_not_null(found_attack)
	assert_equal(health, found_health)
	assert_equal(attack, found_attack)

func test_entity_pooling() -> void:
	# Setup entity pool
	var pool = []
	var pool_size = 10

	for i in pool_size:
		var Entity = load("res://scripts/core/entity.gd")
		var pooled_entity = Entity.new()
		pooled_entity.is_active = false
		pool.append(pooled_entity)

	# Act - Get entity from pool
	var borrowed_entity = pool.pop_front()
	borrowed_entity.is_active = true

	# Assert
	assert_equal(pool_size - 1, pool.size())
	assert_true(borrowed_entity.is_active)

	# Return to pool
	borrowed_entity.is_active = false
	borrowed_entity.reset()
	pool.append(borrowed_entity)

	assert_equal(pool_size, pool.size())

	# Cleanup
	for pooled_entity in pool:
		pooled_entity.queue_free()

func test_entity_tagging() -> void:
	# Setup
	entity.tags = []

	# Act
	entity.add_tag("unit")
	entity.add_tag("ground")
	entity.add_tag("melee")

	# Assert
	assert_true(entity.has_tag("unit"))
	assert_true(entity.has_tag("ground"))
	assert_true(entity.has_tag("melee"))
	assert_false(entity.has_tag("air"))

	# Remove tag
	entity.remove_tag("ground")
	assert_false(entity.has_tag("ground"))

func test_entity_hierarchy() -> void:
	# Setup parent-child relationship
	var Entity = load("res://scripts/core/entity.gd")
	var parent_entity = Entity.new()
	var child_entity = Entity.new()

	# Act
	parent_entity.add_child(child_entity)

	# Assert
	assert_equal(parent_entity, child_entity.get_parent())
	assert_true(parent_entity.has_node(child_entity.get_path()))

	parent_entity.queue_free()

func test_entity_destruction() -> void:
	# Setup
	var Component = load("res://scripts/core/component.gd")
	var component = Component.new()
	component.name = "TestComponent"
	entity.add_component(component)

	# Act
	entity.destroy()

	# Assert
	assert_false(entity.is_active)
	assert_equal(0, entity.get_component_count())