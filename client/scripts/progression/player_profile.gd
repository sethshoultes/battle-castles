extends Node
class_name PlayerProfile

# Player profile data management
# Handles player stats, level, experience, and battle statistics

signal level_up(new_level: int, rewards: Dictionary)
signal profile_updated()
signal stats_changed()

const SAVE_PATH = "user://player_profile.json"
const MAX_LEVEL = 50
const BACKUP_COUNT = 3

# Player data
var player_data: Dictionary = {
	"player_id": "",
	"username": "",
	"level": 1,
	"experience": 0,
	"experience_to_next": 100,
	"total_experience": 0,
	"trophies": 0,
	"highest_trophies": 0,
	"current_arena": 0,
	"stats": {
		"battles_played": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"three_crown_wins": 0,
		"cards_collected": 0,
		"donations": 0,
		"clan_wars_participated": 0
	},
	"created_at": "",
	"last_login": "",
	"version": "1.0.0"
}

# Experience requirements per level
var experience_table: Array = []

func _ready() -> void:
	_initialize_experience_table()
	load_profile()

func _initialize_experience_table() -> void:
	# Generate experience requirements for each level
	experience_table.clear()
	experience_table.append(0) # Level 1 starts at 0 exp

	for level in range(2, MAX_LEVEL + 1):
		var base_exp = 100
		var multiplier = pow(1.15, level - 1)
		var exp_required = int(base_exp * multiplier)
		experience_table.append(exp_required)

func create_new_profile(username: String) -> void:
	player_data.player_id = _generate_player_id()
	player_data.username = username
	player_data.created_at = Time.get_datetime_string_from_system()
	player_data.last_login = Time.get_datetime_string_from_system()

	save_profile()
	profile_updated.emit()

func _generate_player_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "PLAYER_%d_%04d" % [timestamp, random_suffix]

func add_experience(amount: int) -> Dictionary:
	var rewards = {}
	player_data.experience += amount
	player_data.total_experience += amount

	# Check for level up
	while player_data.level < MAX_LEVEL and player_data.experience >= player_data.experience_to_next:
		player_data.experience -= player_data.experience_to_next
		player_data.level += 1

		if player_data.level < MAX_LEVEL:
			player_data.experience_to_next = experience_table[player_data.level - 1]
		else:
			player_data.experience_to_next = 0
			player_data.experience = 0

		# Generate level up rewards
		rewards = _generate_level_rewards(player_data.level)
		level_up.emit(player_data.level, rewards)

	save_profile()
	profile_updated.emit()
	return rewards

func _generate_level_rewards(level: int) -> Dictionary:
	var rewards = {
		"gold": level * 100,
		"gems": 0,
		"cards": []
	}

	# Bonus gems every 5 levels
	if level % 5 == 0:
		rewards.gems = level * 2

	# Special rewards at milestone levels
	if level == 10:
		rewards.chest_type = "golden"
	elif level == 20:
		rewards.chest_type = "giant"
	elif level == 30:
		rewards.chest_type = "magical"
	elif level == 40:
		rewards.chest_type = "super_magical"
	elif level == MAX_LEVEL:
		rewards.chest_type = "legendary"
		rewards.gems = 500

	return rewards

func update_trophies(amount: int) -> void:
	player_data.trophies = max(0, player_data.trophies + amount)

	if player_data.trophies > player_data.highest_trophies:
		player_data.highest_trophies = player_data.trophies

	# Update arena based on trophy count
	player_data.current_arena = _calculate_arena(player_data.trophies)

	save_profile()
	profile_updated.emit()

func _calculate_arena(trophy_count: int) -> int:
	# Arena thresholds
	var arenas = [
		0,     # Arena 0: Training Camp
		300,   # Arena 1: Goblin Stadium
		600,   # Arena 2: Bone Pit
		1000,  # Arena 3: Barbarian Bowl
		1300,  # Arena 4: Spell Valley
		1600,  # Arena 5: Builder's Workshop
		2000,  # Arena 6: Royal Arena
		2300,  # Arena 7: Frozen Peak
		2600,  # Arena 8: Jungle Arena
		3000,  # Arena 9: Hog Mountain
	]

	for i in range(arenas.size() - 1, -1, -1):
		if trophy_count >= arenas[i]:
			return i

	return 0

func record_battle_result(result: String, crowns_won: int = 0, crowns_lost: int = 0) -> void:
	player_data.stats.battles_played += 1

	match result.to_lower():
		"win":
			player_data.stats.wins += 1
			if crowns_won == 3:
				player_data.stats.three_crown_wins += 1
		"loss":
			player_data.stats.losses += 1
		"draw":
			player_data.stats.draws += 1

	save_profile()
	stats_changed.emit()

func get_win_rate() -> float:
	if player_data.stats.battles_played == 0:
		return 0.0
	return float(player_data.stats.wins) / float(player_data.stats.battles_played) * 100.0

func get_average_crowns() -> float:
	if player_data.stats.battles_played == 0:
		return 0.0
	# This would need to track total crowns earned
	return 0.0

func increment_stat(stat_name: String, amount: int = 1) -> void:
	if stat_name in player_data.stats:
		player_data.stats[stat_name] += amount
		save_profile()
		stats_changed.emit()

func save_profile() -> void:
	player_data.last_login = Time.get_datetime_string_from_system()

	# Create backup of existing save
	_create_backup()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data)
		file.store_string(json_string)
		file.close()
		print("Profile saved successfully")
	else:
		push_error("Failed to save player profile")

func _create_backup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		for i in range(BACKUP_COUNT - 1, 0, -1):
			var old_backup = "%s.backup%d" % [SAVE_PATH, i]
			var new_backup = "%s.backup%d" % [SAVE_PATH, i + 1]

			if FileAccess.file_exists(old_backup):
				DirAccess.rename_absolute(old_backup, new_backup)

		# Create the first backup
		DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".backup1")

func load_profile() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, using default profile")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var loaded_data = json.data

			# Migrate data if needed
			loaded_data = _migrate_profile_data(loaded_data)

			# Validate data
			if _validate_profile_data(loaded_data):
				player_data = loaded_data
				profile_updated.emit()
				print("Profile loaded successfully")
				return true
			else:
				push_error("Profile data validation failed")
				return _try_load_backup()
		else:
			push_error("Failed to parse profile JSON")
			return _try_load_backup()
	else:
		push_error("Failed to open profile file")
		return false

func _try_load_backup() -> bool:
	for i in range(1, BACKUP_COUNT + 1):
		var backup_path = "%s.backup%d" % [SAVE_PATH, i]
		if FileAccess.file_exists(backup_path):
			print("Attempting to load backup %d" % i)

			var file = FileAccess.open(backup_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()

				var json = JSON.new()
				var parse_result = json.parse(json_string)

				if parse_result == OK:
					var loaded_data = json.data
					loaded_data = _migrate_profile_data(loaded_data)

					if _validate_profile_data(loaded_data):
						player_data = loaded_data
						save_profile() # Save the recovered data
						profile_updated.emit()
						print("Profile recovered from backup %d" % i)
						return true

	push_error("All backup recovery attempts failed")
	return false

func _migrate_profile_data(data: Dictionary) -> Dictionary:
	# Check version and migrate if needed
	if not data.has("version"):
		data.version = "1.0.0"

	# Add any missing fields with default values
	var default_stats = {
		"battles_played": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"three_crown_wins": 0,
		"cards_collected": 0,
		"donations": 0,
		"clan_wars_participated": 0
	}

	if not data.has("stats"):
		data.stats = default_stats
	else:
		for key in default_stats:
			if not data.stats.has(key):
				data.stats[key] = default_stats[key]

	# Add other missing fields
	if not data.has("highest_trophies"):
		data.highest_trophies = data.get("trophies", 0)

	if not data.has("current_arena"):
		data.current_arena = _calculate_arena(data.get("trophies", 0))

	return data

func _validate_profile_data(data: Dictionary) -> bool:
	# Check required fields
	var required_fields = ["player_id", "username", "level", "experience", "trophies"]
	for field in required_fields:
		if not data.has(field):
			push_error("Missing required field: " + field)
			return false

	# Validate data types and ranges
	if not is_instance_of(data.level, TYPE_INT) or data.level < 1 or data.level > MAX_LEVEL:
		push_error("Invalid level: " + str(data.level))
		return false

	if not is_instance_of(data.experience, TYPE_INT) or data.experience < 0:
		push_error("Invalid experience: " + str(data.experience))
		return false

	if not is_instance_of(data.trophies, TYPE_INT) or data.trophies < 0:
		push_error("Invalid trophies: " + str(data.trophies))
		return false

	return true

func reset_profile() -> void:
	# Reset to default values but keep player_id and username
	var player_id = player_data.player_id
	var username = player_data.username

	player_data = {
		"player_id": player_id,
		"username": username,
		"level": 1,
		"experience": 0,
		"experience_to_next": 100,
		"total_experience": 0,
		"trophies": 0,
		"highest_trophies": 0,
		"current_arena": 0,
		"stats": {
			"battles_played": 0,
			"wins": 0,
			"losses": 0,
			"draws": 0,
			"three_crown_wins": 0,
			"cards_collected": 0,
			"donations": 0,
			"clan_wars_participated": 0
		},
		"created_at": Time.get_datetime_string_from_system(),
		"last_login": Time.get_datetime_string_from_system(),
		"version": "1.0.0"
	}

	save_profile()
	profile_updated.emit()

func export_profile() -> String:
	return JSON.stringify(player_data)

func import_profile(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		var imported_data = json.data
		imported_data = _migrate_profile_data(imported_data)

		if _validate_profile_data(imported_data):
			player_data = imported_data
			save_profile()
			profile_updated.emit()
			return true

	return false