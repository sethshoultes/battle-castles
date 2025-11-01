extends RefCounted

class_name GdUnitMock

var _class_type
var _mock_calls: Dictionary = {}
var _return_values: Dictionary = {}
var _call_counts: Dictionary = {}

func _init(clazz) -> void:
	_class_type = clazz

func when_called(method_name: String) -> GdUnitMock:
	if not _mock_calls.has(method_name):
		_mock_calls[method_name] = []
		_call_counts[method_name] = 0
	return self

func then_return(value: Variant) -> GdUnitMock:
	var last_method = _mock_calls.keys().back()
	_return_values[last_method] = value
	return self

func verify_called(method_name: String, times: int = -1) -> void:
	if not _call_counts.has(method_name):
		push_error("Method %s was never called" % method_name)
		assert(false)
		return

	var actual_calls = _call_counts[method_name]
	if times >= 0 and actual_calls != times:
		push_error("Expected %s to be called %d times but was called %d times" % [method_name, times, actual_calls])
		assert(false)

func verify_never_called(method_name: String) -> void:
	if _call_counts.has(method_name) and _call_counts[method_name] > 0:
		push_error("Expected %s to never be called but was called %d times" % [method_name, _call_counts[method_name]])
		assert(false)

func reset() -> void:
	_mock_calls.clear()
	_return_values.clear()
	_call_counts.clear()

func _call(method_name: String, args: Array = []) -> Variant:
	if not _call_counts.has(method_name):
		_call_counts[method_name] = 0
	_call_counts[method_name] += 1

	if not _mock_calls.has(method_name):
		_mock_calls[method_name] = []
	_mock_calls[method_name].append(args)

	if _return_values.has(method_name):
		return _return_values[method_name]

	return null

func get_call_count(method_name: String) -> int:
	return _call_counts.get(method_name, 0)

func get_call_args(method_name: String, call_index: int = 0) -> Array:
	if not _mock_calls.has(method_name):
		return []
	if call_index >= _mock_calls[method_name].size():
		return []
	return _mock_calls[method_name][call_index]