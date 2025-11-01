@tool
extends EditorPlugin

const GDUNIT_SETTINGS_PREFIX = "gdunit4/"

func _enter_tree() -> void:
	print("GdUnit4 Test Framework - Activated")
	_init_settings()
	add_autoload_singleton("GdUnitRunner", "res://addons/gdUnit4/src/core/GdUnitRunner.gd")

func _exit_tree() -> void:
	print("GdUnit4 Test Framework - Deactivated")
	remove_autoload_singleton("GdUnitRunner")

func _init_settings() -> void:
	_add_setting(GDUNIT_SETTINGS_PREFIX + "test_timeout", 5000, TYPE_INT)
	_add_setting(GDUNIT_SETTINGS_PREFIX + "test_root_folder", "res://tests", TYPE_STRING)
	_add_setting(GDUNIT_SETTINGS_PREFIX + "verbose_logging", false, TYPE_BOOL)
	_add_setting(GDUNIT_SETTINGS_PREFIX + "fail_fast", false, TYPE_BOOL)

func _add_setting(name: String, default_value: Variant, type: int) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
		var property_info = {
			"name": name,
			"type": type
		}
		ProjectSettings.add_property_info(property_info)