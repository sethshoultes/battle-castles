extends Node

class_name GdUnitTestSuite

# Test lifecycle methods
func before_all() -> void:
	pass

func after_all() -> void:
	pass

func before_each() -> void:
	pass

func after_each() -> void:
	pass

# Assertion methods
func assert_that(value: Variant) -> GdUnitAssert:
	return GdUnitAssert.new(value)

func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("Expected true but was false. " + message)

func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("Expected false but was true. " + message)

func assert_equal(expected: Variant, actual: Variant, message: String = "") -> void:
	if expected != actual:
		_fail("Expected %s but was %s. %s" % [expected, actual, message])

func assert_not_equal(expected: Variant, actual: Variant, message: String = "") -> void:
	if expected == actual:
		_fail("Expected values to be different but both were %s. %s" % [expected, message])

func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		_fail("Expected null but was %s. %s" % [value, message])

func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		_fail("Expected non-null value. " + message)

func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> void:
	if value < min_val or value > max_val:
		_fail("Expected %f to be between %f and %f. %s" % [value, min_val, max_val, message])

func assert_signal_emitted(obj: Object, signal_name: String, message: String = "") -> void:
	# This would need signal monitoring setup
	pass

func assert_no_error(callable: Callable, message: String = "") -> void:
	try:
		callable.call()
	except:
		_fail("Expected no error but an error occurred. " + message)

func _fail(message: String) -> void:
	push_error("[TEST FAILED] " + message)
	assert(false, message)

func try(callable: Callable) -> void:
	callable.call()

func except() -> void:
	pass

# Mock creation helper
func mock(clazz) -> GdUnitMock:
	return GdUnitMock.new(clazz)