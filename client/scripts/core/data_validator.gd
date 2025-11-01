## Data validation and integrity system
## Validates game data, handles corrupted saves, and manages data migration
## Add to Project Settings -> Autoload as "DataValidator"
extends Node

## Signals
signal validation_started()
signal validation_completed(success: bool, errors: Array)
signal backup_created(backup_path: String)
signal data_migrated(from_version: String, to_version: String)
signal corrupted_data_detected(file_path: String, error: String)

## Data version management
const CURRENT_DATA_VERSION: String = "1.0.0"
const MIN_COMPATIBLE_VERSION: String = "1.0.0"

## Validation settings
var auto_backup: bool = true
var auto_migrate: bool = true
var max_backups: int = 5
var validation_enabled: bool = true

## Paths
var save_directory: String = "user://saves/"
var backup_directory: String = "user://backups/"
var config_directory: String = "user://config/"

## Validation results
var last_validation_errors: Array = []
var validation_in_progress: bool = false

## Data schemas for validation
var schemas: Dictionary = {
	"player_profile": {
		"required": ["player_id", "player_name", "level", "experience", "trophies"],
		"types": {
			"player_id": TYPE_STRING,
			"player_name": TYPE_STRING,
			"level": TYPE_INT,
			"experience": TYPE_INT,
			"trophies": TYPE_INT
		}
	},
	"card_collection": {
		"required": ["cards"],
		"types": {
			"cards": TYPE_ARRAY
		}
	},
	"deck": {
		"required": ["deck_id", "name", "cards"],
		"types": {
			"deck_id": TYPE_INT,
			"name": TYPE_STRING,
			"cards": TYPE_ARRAY
		}
	},
	"settings": {
		"required": ["music_volume", "sfx_volume", "master_volume"],
		"types": {
			"music_volume": TYPE_FLOAT,
			"sfx_volume": TYPE_FLOAT,
			"master_volume": TYPE_FLOAT
		}
	}
}


func _ready() -> void:
	# Ensure directories exist
	_create_directories()

	# Run initial validation
	if validation_enabled:
		validate_all_data()

	print("DataValidator initialized")


## Creates necessary directories
func _create_directories() -> void:
	for dir_path in [save_directory, backup_directory, config_directory]:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
			print("Created directory: ", dir_path)


## Validates all game data
func validate_all_data() -> bool:
	if validation_in_progress:
		push_warning("Validation already in progress")
		return false

	validation_in_progress = true
	validation_started.emit()
	last_validation_errors.clear()

	print("Starting data validation...")

	# Validate save files
	var save_valid := _validate_saves()

	# Validate config files
	var config_valid := _validate_config()

	# Check for data corruption
	var corruption_check := _check_for_corruption()

	var success := save_valid and config_valid and corruption_check

	validation_in_progress = false
	validation_completed.emit(success, last_validation_errors)

	if success:
		print("Data validation completed successfully")
	else:
		push_warning("Data validation found errors: ", last_validation_errors.size())

	return success


## Validates save files
func _validate_saves() -> bool:
	var all_valid := true

	# Check player profile
	var profile_path := save_directory + "player_profile.json"
	if FileAccess.file_exists(profile_path):
		if not validate_file(profile_path, "player_profile"):
			all_valid = false

	# Check card collection
	var collection_path := save_directory + "card_collection.json"
	if FileAccess.file_exists(collection_path):
		if not validate_file(collection_path, "card_collection"):
			all_valid = false

	# Check decks
	var deck_dir := DirAccess.open(save_directory)
	if deck_dir:
		deck_dir.list_dir_begin()
		var file_name := deck_dir.get_next()
		while file_name != "":
			if file_name.begins_with("deck_") and file_name.ends_with(".json"):
				var deck_path := save_directory + file_name
				if not validate_file(deck_path, "deck"):
					all_valid = false
			file_name = deck_dir.get_next()
		deck_dir.list_dir_end()

	return all_valid


## Validates config files
func _validate_config() -> bool:
	var settings_path := config_directory + "settings.json"
	if FileAccess.file_exists(settings_path):
		return validate_file(settings_path, "settings")
	return true


## Validates a specific file against a schema
func validate_file(file_path: String, schema_name: String) -> bool:
	if not schemas.has(schema_name):
		push_error("Unknown schema: " + schema_name)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		var error := "Failed to open file: " + file_path
		last_validation_errors.append(error)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)

	if parse_result != OK:
		var error := "JSON parse error in " + file_path + ": " + json.get_error_message()
		last_validation_errors.append(error)
		corrupted_data_detected.emit(file_path, error)
		return false

	var data: Dictionary = json.data

	# Check version
	if data.has("version"):
		if not _is_version_compatible(data["version"]):
			if auto_migrate:
				migrate_data(file_path, data["version"], CURRENT_DATA_VERSION)
			else:
				var error := "Incompatible data version in " + file_path
				last_validation_errors.append(error)
				return false

	# Validate against schema
	var schema: Dictionary = schemas[schema_name]

	# Check required fields
	for field in schema["required"]:
		if not data.has(field):
			var error := "Missing required field '" + field + "' in " + file_path
			last_validation_errors.append(error)
			return false

	# Check field types
	if schema.has("types"):
		for field in schema["types"]:
			if data.has(field):
				var expected_type: int = schema["types"][field]
				var actual_type: int = typeof(data[field])
				if actual_type != expected_type:
					var error := "Type mismatch for field '" + field + "' in " + file_path
					last_validation_errors.append(error)
					return false

	return true


## Checks if a version is compatible
func _is_version_compatible(version: String) -> bool:
	# Simple version comparison (you can make this more sophisticated)
	var current_parts := CURRENT_DATA_VERSION.split(".")
	var check_parts := version.split(".")
	var min_parts := MIN_COMPATIBLE_VERSION.split(".")

	# Check if version is at least minimum compatible
	for i in range(min(min_parts.size(), check_parts.size())):
		var min_part := min_parts[i].to_int()
		var check_part := check_parts[i].to_int()
		if check_part < min_part:
			return false
		elif check_part > min_part:
			return true

	return true


## Checks for data corruption
func _check_for_corruption() -> bool:
	var all_clean := true

	# Check file sizes (detect empty or suspiciously small files)
	var files_to_check := [
		save_directory + "player_profile.json",
		save_directory + "card_collection.json",
		config_directory + "settings.json"
	]

	for file_path in files_to_check:
		if FileAccess.file_exists(file_path):
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file:
				var size := file.get_length()
				file.close()

				if size < 10:  # Suspiciously small
					var error := "Potentially corrupted file (too small): " + file_path
					last_validation_errors.append(error)
					corrupted_data_detected.emit(file_path, error)
					all_clean = false

	return all_clean


## Creates a backup of all save data
func create_backup() -> String:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var backup_path := backup_directory + "backup_" + timestamp + "/"

	DirAccess.make_dir_recursive_absolute(backup_path)

	# Copy save directory
	_copy_directory(save_directory, backup_path + "saves/")

	# Copy config directory
	_copy_directory(config_directory, backup_path + "config/")

	# Clean old backups
	_clean_old_backups()

	backup_created.emit(backup_path)
	print("Backup created: ", backup_path)

	return backup_path


## Copies a directory recursively
func _copy_directory(from_dir: String, to_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(to_dir)

	var dir := DirAccess.open(from_dir)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var from_path := from_dir + file_name
		var to_path := to_dir + file_name

		if dir.current_is_dir():
			_copy_directory(from_path + "/", to_path + "/")
		else:
			_copy_file(from_path, to_path)

		file_name = dir.get_next()
	dir.list_dir_end()


## Copies a single file
func _copy_file(from_path: String, to_path: String) -> void:
	var source := FileAccess.open(from_path, FileAccess.READ)
	if not source:
		return

	var content := source.get_buffer(source.get_length())
	source.close()

	var dest := FileAccess.open(to_path, FileAccess.WRITE)
	if dest:
		dest.store_buffer(content)
		dest.close()


## Cleans up old backups
func _clean_old_backups() -> void:
	var dir := DirAccess.open(backup_directory)
	if not dir:
		return

	# Get all backup folders
	var backups: Array = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and file_name.begins_with("backup_"):
			backups.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by name (timestamp-based)
	backups.sort()

	# Remove oldest if exceeding max
	while backups.size() > max_backups:
		var oldest := backups.pop_front()
		_delete_directory_recursive(backup_directory + oldest)
		print("Deleted old backup: ", oldest)


## Deletes a directory recursively
func _delete_directory_recursive(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var path := dir_path + "/" + file_name
		if dir.current_is_dir():
			_delete_directory_recursive(path)
		else:
			DirAccess.remove_absolute(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	DirAccess.remove_absolute(dir_path)


## Migrates data from one version to another
func migrate_data(file_path: String, from_version: String, to_version: String) -> bool:
	print("Migrating data: ", file_path, " from v", from_version, " to v", to_version)

	# Create backup before migration
	if auto_backup:
		create_backup()

	# Load current data
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		return false

	var data: Dictionary = json.data

	# Apply migrations based on version
	# Add migration logic here for different versions
	# Example:
	# if from_version == "0.9.0" and to_version == "1.0.0":
	#     data = _migrate_0_9_to_1_0(data)

	# Update version
	data["version"] = to_version

	# Save migrated data
	var save_file := FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(data, "\t"))
		save_file.close()

	data_migrated.emit(from_version, to_version)
	print("Migration completed successfully")

	return true


## Restores from a backup
func restore_backup(backup_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(backup_path):
		push_error("Backup not found: " + backup_path)
		return false

	# Copy backup saves
	_copy_directory(backup_path + "saves/", save_directory)

	# Copy backup config
	_copy_directory(backup_path + "config/", config_directory)

	print("Backup restored from: ", backup_path)
	return true


## Repairs corrupted data (attempts to fix common issues)
func repair_corrupted_data(file_path: String) -> bool:
	print("Attempting to repair: ", file_path)

	# Try to load and fix JSON
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var content := file.get_as_text()
	file.close()

	# Attempt to fix common JSON issues
	content = content.strip_edges()
	content = content.replace("\r\n", "\n")

	# Try to parse
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("Cannot repair: Invalid JSON")
		return false

	# Re-save with proper formatting
	var save_file := FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(json.data, "\t"))
		save_file.close()
		print("File repaired: ", file_path)
		return true

	return false


## Gets validation errors
func get_last_errors() -> Array:
	return last_validation_errors


## Checks if data is valid
func is_data_valid() -> bool:
	return last_validation_errors.is_empty()
