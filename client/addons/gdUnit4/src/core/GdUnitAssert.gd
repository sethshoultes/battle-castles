extends RefCounted

class_name GdUnitAssert

var _value: Variant

func _init(value: Variant) -> void:
	_value = value

func is_equal(expected: Variant) -> GdUnitAssert:
	if _value != expected:
		push_error("Expected %s but was %s" % [expected, _value])
		assert(false)
	return self

func is_not_equal(expected: Variant) -> GdUnitAssert:
	if _value == expected:
		push_error("Expected values to be different but both were %s" % [expected])
		assert(false)
	return self

func is_null() -> GdUnitAssert:
	if _value != null:
		push_error("Expected null but was %s" % [_value])
		assert(false)
	return self

func is_not_null() -> GdUnitAssert:
	if _value == null:
		push_error("Expected non-null value")
		assert(false)
	return self

func is_true() -> GdUnitAssert:
	if not _value:
		push_error("Expected true but was %s" % [_value])
		assert(false)
	return self

func is_false() -> GdUnitAssert:
	if _value:
		push_error("Expected false but was %s" % [_value])
		assert(false)
	return self

func is_greater(than: Variant) -> GdUnitAssert:
	if _value <= than:
		push_error("Expected %s to be greater than %s" % [_value, than])
		assert(false)
	return self

func is_less(than: Variant) -> GdUnitAssert:
	if _value >= than:
		push_error("Expected %s to be less than %s" % [_value, than])
		assert(false)
	return self

func is_between(min_val: Variant, max_val: Variant) -> GdUnitAssert:
	if _value < min_val or _value > max_val:
		push_error("Expected %s to be between %s and %s" % [_value, min_val, max_val])
		assert(false)
	return self

func has_size(expected: int) -> GdUnitAssert:
	var size = 0
	if _value is Array:
		size = _value.size()
	elif _value is String:
		size = _value.length()
	elif _value is Dictionary:
		size = _value.size()
	else:
		push_error("Cannot get size of %s" % [_value])
		assert(false)
		return self

	if size != expected:
		push_error("Expected size %d but was %d" % [expected, size])
		assert(false)
	return self

func contains(item: Variant) -> GdUnitAssert:
	var found = false
	if _value is Array:
		found = item in _value
	elif _value is String:
		found = item in _value
	elif _value is Dictionary:
		found = _value.has(item)
	else:
		push_error("Cannot check containment for %s" % [_value])
		assert(false)
		return self

	if not found:
		push_error("Expected %s to contain %s" % [_value, item])
		assert(false)
	return self

func is_instance_of(clazz) -> GdUnitAssert:
	if not _value is clazz:
		push_error("Expected instance of %s but was %s" % [clazz, _value.get_class()])
		assert(false)
	return self