extends Node

class_name GdUnitRunner

signal test_started(test_name: String)
signal test_finished(test_name: String, passed: bool, time: float)
signal suite_started(suite_name: String)
signal suite_finished(suite_name: String, passed: int, failed: int)
signal all_tests_finished(total_passed: int, total_failed: int, time: float)

var test_suites: Array = []
var current_suite: GdUnitTestSuite
var total_passed: int = 0
var total_failed: int = 0
var start_time: float = 0.0

func _ready() -> void:
	set_process(false)

func discover_tests(path: String = "res://tests") -> Array:
	test_suites.clear()
	_scan_directory(path)
	return test_suites

func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path + "/" + file_name

		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(full_path)
		elif file_name.ends_with(".gd") and file_name.begins_with("test_"):
			var script = load(full_path)
			if script and script.has_method("_init"):
				test_suites.append(full_path)

		file_name = dir.get_next()

func run_all_tests() -> void:
	start_time = Time.get_ticks_msec() / 1000.0
	total_passed = 0
	total_failed = 0

	for suite_path in test_suites:
		await run_test_suite(suite_path)

	var total_time = Time.get_ticks_msec() / 1000.0 - start_time
	all_tests_finished.emit(total_passed, total_failed, total_time)

func run_test_suite(suite_path: String) -> void:
	var suite = load(suite_path).new()
	if not suite is GdUnitTestSuite:
		push_error("Invalid test suite: " + suite_path)
		return

	current_suite = suite
	var suite_name = suite_path.get_file().get_basename()
	suite_started.emit(suite_name)

	var passed = 0
	var failed = 0

	# Run before_all
	if suite.has_method("before_all"):
		suite.before_all()

	# Get all test methods
	var methods = []
	for method in suite.get_method_list():
		if method.name.begins_with("test_"):
			methods.append(method.name)

	# Run each test
	for test_method in methods:
		var test_passed = await run_test(suite, test_method)
		if test_passed:
			passed += 1
			total_passed += 1
		else:
			failed += 1
			total_failed += 1

	# Run after_all
	if suite.has_method("after_all"):
		suite.after_all()

	suite_finished.emit(suite_name, passed, failed)
	current_suite.queue_free()

func run_test(suite: GdUnitTestSuite, test_name: String) -> bool:
	test_started.emit(test_name)
	var test_start = Time.get_ticks_msec() / 1000.0

	# Run before_each
	if suite.has_method("before_each"):
		suite.before_each()

	# Run the test
	var passed = true
	try:
		await suite.call(test_name)
	except:
		passed = false

	# Run after_each
	if suite.has_method("after_each"):
		suite.after_each()

	var test_time = Time.get_ticks_msec() / 1000.0 - test_start
	test_finished.emit(test_name, passed, test_time)

	return passed

func try(callable: Callable) -> void:
	callable.call()

func except() -> void:
	pass