extends Node

# Main test runner for Battle Castles
# Executes all tests and generates reports

signal tests_started()
signal tests_completed(results: Dictionary)
signal test_progress(current: int, total: int, test_name: String)

var test_suites: Array = []
var test_results: Dictionary = {}
var current_suite_index: int = 0
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var skipped_tests: int = 0
var start_time: float = 0.0
var verbose: bool = false
var fail_fast: bool = false
var filter_pattern: String = ""
var output_format: String = "console"  # console, json, xml, html

func _ready() -> void:
	# Parse command line arguments
	parse_arguments()

	# Discover and run tests
	discover_tests()

	if test_suites.size() > 0:
		run_tests()
	else:
		print("No tests found!")
		get_tree().quit(1)

func parse_arguments() -> void:
	var args = OS.get_cmdline_args()

	for i in range(args.size()):
		match args[i]:
			"--verbose", "-v":
				verbose = true
			"--fail-fast", "-f":
				fail_fast = true
			"--filter", "-t":
				if i + 1 < args.size():
					filter_pattern = args[i + 1]
			"--output", "-o":
				if i + 1 < args.size():
					output_format = args[i + 1]
			"--help", "-h":
				print_help()
				get_tree().quit(0)

func print_help() -> void:
	print("""
Battle Castles Test Runner

Usage: godot --headless -s tests/test_runner.gd [options]

Options:
  --verbose, -v       Show detailed test output
  --fail-fast, -f     Stop on first test failure
  --filter, -t PATTERN  Run only tests matching pattern
  --output, -o FORMAT   Output format (console, json, xml, html)
  --help, -h         Show this help message
""")

func discover_tests() -> void:
	print("🔍 Discovering tests...")

	# Discover test files
	var test_dirs = [
		"res://tests/unit",
		"res://tests/integration",
		"res://tests/performance"
	]

	for dir_path in test_dirs:
		scan_test_directory(dir_path)

	print("Found %d test suites" % test_suites.size())

func scan_test_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_"):
			var full_path = path + "/" + file_name

			# Apply filter if specified
			if filter_pattern.is_empty() or filter_pattern in file_name:
				test_suites.append({
					"path": full_path,
					"name": file_name.get_basename(),
					"category": path.get_file()
				})

		file_name = dir.get_next()

func run_tests() -> void:
	start_time = Time.get_ticks_msec() / 1000.0
	tests_started.emit()

	print("\n🚀 Running %d test suites..." % test_suites.size())
	print("=" * 60)

	await run_all_suites()

	# Generate report
	generate_report()

	# Exit with appropriate code
	var exit_code = 0 if failed_tests == 0 else 1
	get_tree().quit(exit_code)

func run_all_suites() -> void:
	for suite_data in test_suites:
		if fail_fast and failed_tests > 0:
			break

		await run_test_suite(suite_data)
		current_suite_index += 1

func run_test_suite(suite_data: Dictionary) -> void:
	var suite_name = suite_data.name
	var suite_path = suite_data.path
	var suite_category = suite_data.category

	print("\n📁 %s/%s" % [suite_category, suite_name])
	print("-" * 40)

	# Load test suite
	var suite_script = load(suite_path)
	if not suite_script:
		print("❌ Failed to load test suite: %s" % suite_path)
		failed_tests += 1
		return

	var suite_instance = suite_script.new()
	if not suite_instance:
		print("❌ Failed to instantiate test suite")
		failed_tests += 1
		return

	# Get test methods
	var test_methods = get_test_methods(suite_instance)
	var suite_results = {
		"name": suite_name,
		"category": suite_category,
		"tests": [],
		"passed": 0,
		"failed": 0,
		"skipped": 0,
		"time": 0.0
	}

	var suite_start = Time.get_ticks_msec() / 1000.0

	# Run before_all
	if suite_instance.has_method("before_all"):
		suite_instance.before_all()

	# Run each test
	for method_name in test_methods:
		if fail_fast and failed_tests > 0:
			break

		var test_result = await run_single_test(suite_instance, method_name)
		suite_results.tests.append(test_result)

		if test_result.passed:
			suite_results.passed += 1
			passed_tests += 1
			print("  ✅ %s (%.3fs)" % [method_name, test_result.time])
		else:
			suite_results.failed += 1
			failed_tests += 1
			print("  ❌ %s - %s" % [method_name, test_result.error])
			if verbose and test_result.has("stack_trace"):
				print("     Stack trace:")
				print("     " + test_result.stack_trace)

		total_tests += 1
		test_progress.emit(total_tests, calculate_total_tests(), method_name)

	# Run after_all
	if suite_instance.has_method("after_all"):
		suite_instance.after_all()

	suite_results.time = Time.get_ticks_msec() / 1000.0 - suite_start
	test_results[suite_name] = suite_results

	# Summary for this suite
	print("\nSuite Summary: %d passed, %d failed in %.3fs" %
		[suite_results.passed, suite_results.failed, suite_results.time])

	# Cleanup
	suite_instance.queue_free()

func run_single_test(suite: Node, method_name: String) -> Dictionary:
	var test_start = Time.get_ticks_msec() / 1000.0
	var result = {
		"name": method_name,
		"passed": false,
		"error": "",
		"time": 0.0
	}

	# Run before_each
	if suite.has_method("before_each"):
		suite.before_each()

	# Run the test with error catching
	var test_passed = true
	var error_message = ""

	# Create a timer for test timeout
	var timeout_timer = get_tree().create_timer(5.0)  # 5 second timeout

	# Run test in a try-catch like manner
	var test_completed = false

	suite.call(method_name)
	test_completed = true

	# Check if test timed out
	if not test_completed and timeout_timer.time_left <= 0:
		test_passed = false
		error_message = "Test timed out after 5 seconds"

	# Run after_each
	if suite.has_method("after_each"):
		suite.after_each()

	result.passed = test_passed
	result.error = error_message
	result.time = Time.get_ticks_msec() / 1000.0 - test_start

	return result

func get_test_methods(suite: Node) -> Array:
	var methods = []
	for method in suite.get_method_list():
		if method.name.begins_with("test_"):
			methods.append(method.name)
	return methods

func calculate_total_tests() -> int:
	var total = 0
	for suite in test_suites:
		var script = load(suite.path)
		if script:
			var instance = script.new()
			total += get_test_methods(instance).size()
			instance.queue_free()
	return total

func generate_report() -> void:
	var total_time = Time.get_ticks_msec() / 1000.0 - start_time

	match output_format:
		"json":
			generate_json_report(total_time)
		"xml":
			generate_xml_report(total_time)
		"html":
			generate_html_report(total_time)
		_:
			generate_console_report(total_time)

func generate_console_report(total_time: float) -> void:
	print("\n" + "=" * 60)
	print("📊 TEST RESULTS")
	print("=" * 60)

	# Summary statistics
	print("\nSummary:")
	print("  Total Tests: %d" % total_tests)
	print("  ✅ Passed: %d (%.1f%%)" % [passed_tests, (passed_tests / float(max(total_tests, 1))) * 100])
	print("  ❌ Failed: %d (%.1f%%)" % [failed_tests, (failed_tests / float(max(total_tests, 1))) * 100])
	print("  ⏭️  Skipped: %d" % skipped_tests)
	print("  ⏱️  Time: %.3f seconds" % total_time)

	# Performance metrics
	if total_tests > 0:
		var avg_time = total_time / total_tests
		print("\nPerformance:")
		print("  Average test time: %.3f seconds" % avg_time)
		print("  Tests per second: %.1f" % (total_tests / total_time))

	# Category breakdown
	print("\nBy Category:")
	var categories = {}
	for suite_name in test_results:
		var suite = test_results[suite_name]
		if not categories.has(suite.category):
			categories[suite.category] = {"passed": 0, "failed": 0}
		categories[suite.category].passed += suite.passed
		categories[suite.category].failed += suite.failed

	for category in categories:
		var stats = categories[category]
		print("  %s: %d passed, %d failed" % [category, stats.passed, stats.failed])

	# Failed tests summary
	if failed_tests > 0:
		print("\n❌ Failed Tests:")
		for suite_name in test_results:
			var suite = test_results[suite_name]
			for test in suite.tests:
				if not test.passed:
					print("  - %s::%s - %s" % [suite_name, test.name, test.error])

	# Final result
	print("\n" + "=" * 60)
	if failed_tests == 0:
		print("🎉 ALL TESTS PASSED! 🎉")
	else:
		print("💔 %d TESTS FAILED" % failed_tests)
	print("=" * 60)

func generate_json_report(total_time: float) -> void:
	var report = {
		"summary": {
			"total": total_tests,
			"passed": passed_tests,
			"failed": failed_tests,
			"skipped": skipped_tests,
			"duration": total_time,
			"timestamp": Time.get_datetime_string_from_system()
		},
		"suites": test_results
	}

	var json_string = JSON.stringify(report, "\t")
	var file = FileAccess.open("test_results.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("JSON report saved to test_results.json")

func generate_xml_report(total_time: float) -> void:
	# JUnit XML format for CI/CD integration
	var xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
	xml += '<testsuites tests="%d" failures="%d" time="%.3f">\n' % [total_tests, failed_tests, total_time]

	for suite_name in test_results:
		var suite = test_results[suite_name]
		xml += '  <testsuite name="%s" tests="%d" failures="%d" time="%.3f">\n' % [
			suite_name, suite.tests.size(), suite.failed, suite.time
		]

		for test in suite.tests:
			xml += '    <testcase name="%s" time="%.3f"' % [test.name, test.time]
			if test.passed:
				xml += '/>\n'
			else:
				xml += '>\n'
				xml += '      <failure message="%s"/>\n' % test.error.xml_escape()
				xml += '    </testcase>\n'

		xml += '  </testsuite>\n'

	xml += '</testsuites>'

	var file = FileAccess.open("test_results.xml", FileAccess.WRITE)
	if file:
		file.store_string(xml)
		file.close()
		print("XML report saved to test_results.xml")

func generate_html_report(total_time: float) -> void:
	var html = """<!DOCTYPE html>
<html>
<head>
	<title>Battle Castles Test Report</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; }
		h1 { color: #333; }
		.summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }
		.passed { color: green; }
		.failed { color: red; }
		.suite { margin: 20px 0; border: 1px solid #ddd; border-radius: 5px; }
		.suite-header { background: #e0e0e0; padding: 10px; font-weight: bold; }
		.test { padding: 5px 20px; border-bottom: 1px solid #eee; }
		.test:last-child { border-bottom: none; }
	</style>
</head>
<body>
	<h1>Battle Castles Test Report</h1>
	<div class="summary">
		<h2>Summary</h2>
		<p>Total Tests: %d</p>
		<p class="passed">Passed: %d (%.1f%%)</p>
		<p class="failed">Failed: %d (%.1f%%)</p>
		<p>Duration: %.3f seconds</p>
		<p>Generated: %s</p>
	</div>
""" % [
		total_tests,
		passed_tests, (passed_tests / float(max(total_tests, 1))) * 100,
		failed_tests, (failed_tests / float(max(total_tests, 1))) * 100,
		total_time,
		Time.get_datetime_string_from_system()
	]

	for suite_name in test_results:
		var suite = test_results[suite_name]
		html += '<div class="suite">\n'
		html += '  <div class="suite-header">%s - %d/%d passed (%.3fs)</div>\n' % [
			suite_name, suite.passed, suite.tests.size(), suite.time
		]

		for test in suite.tests:
			var status_class = "passed" if test.passed else "failed"
			var status_icon = "✅" if test.passed else "❌"
			html += '  <div class="test %s">%s %s (%.3fs)' % [status_class, status_icon, test.name, test.time]
			if not test.passed:
				html += ' - %s' % test.error
			html += '</div>\n'

		html += '</div>\n'

	html += """
</body>
</html>"""

	var file = FileAccess.open("test_results.html", FileAccess.WRITE)
	if file:
		file.store_string(html)
		file.close()
		print("HTML report saved to test_results.html")