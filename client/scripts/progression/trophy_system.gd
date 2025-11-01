extends Node
class_name TrophySystem

# Trophy and arena progression system
# Manages trophy calculations, arena unlocks, and seasonal resets

signal trophies_changed(new_count: int, change: int)
signal arena_changed(new_arena: int, arena_name: String)
signal season_reset(trophies_before: int, trophies_after: int, rewards: Dictionary)
signal leaderboard_position_changed(new_position: int)
signal milestone_reached(milestone: Dictionary)

const SAVE_PATH = "user://trophy_data.json"
const SEASON_DURATION = 2592000  # 30 days in seconds
const RESET_THRESHOLD = 4000  # Trophies above this get reset
const RESET_PERCENTAGE = 0.5  # Reset to 50% of trophies above threshold

# Arena definitions
var arena_definitions = [
	{"name": "Training Camp", "min_trophies": 0, "max_trophies": 299, "chest_bonus": 1.0},
	{"name": "Goblin Stadium", "min_trophies": 300, "max_trophies": 599, "chest_bonus": 1.1},
	{"name": "Bone Pit", "min_trophies": 600, "max_trophies": 999, "chest_bonus": 1.2},
	{"name": "Barbarian Bowl", "min_trophies": 1000, "max_trophies": 1299, "chest_bonus": 1.3},
	{"name": "Spell Valley", "min_trophies": 1300, "max_trophies": 1599, "chest_bonus": 1.4},
	{"name": "Builder's Workshop", "min_trophies": 1600, "max_trophies": 1999, "chest_bonus": 1.5},
	{"name": "Royal Arena", "min_trophies": 2000, "max_trophies": 2299, "chest_bonus": 1.6},
	{"name": "Frozen Peak", "min_trophies": 2300, "max_trophies": 2599, "chest_bonus": 1.7},
	{"name": "Jungle Arena", "min_trophies": 2600, "max_trophies": 2999, "chest_bonus": 1.8},
	{"name": "Legendary Arena", "min_trophies": 3000, "max_trophies": 999999, "chest_bonus": 2.0}
]

# Trophy milestones
var trophy_milestones = [
	{"trophies": 100, "reward_gold": 100, "reward_gems": 5},
	{"trophies": 300, "reward_gold": 200, "reward_gems": 10},
	{"trophies": 600, "reward_gold": 300, "reward_gems": 15},
	{"trophies": 1000, "reward_gold": 500, "reward_gems": 20},
	{"trophies": 1500, "reward_gold": 750, "reward_gems": 25},
	{"trophies": 2000, "reward_gold": 1000, "reward_gems": 30},
	{"trophies": 2500, "reward_gold": 1500, "reward_gems": 40},
	{"trophies": 3000, "reward_gold": 2000, "reward_gems": 50},
	{"trophies": 4000, "reward_gold": 3000, "reward_gems": 75},
	{"trophies": 5000, "reward_gold": 5000, "reward_gems": 100}
]

# Trophy data
var trophy_data: Dictionary = {
	"current_trophies": 0,
	"highest_trophies": 0,
	"current_arena": 0,
	"season_highest": 0,
	"previous_seasons": [],
	"current_season_start": 0,
	"total_trophies_earned": 0,
	"total_trophies_lost": 0,
	"milestones_claimed": [],
	"leaderboard_position": 0,
	"win_streak": 0,
	"loss_streak": 0,
	"best_win_streak": 0,
	"version": "1.0.0"
}

func _ready() -> void:
	load_trophy_data()
	_check_season_reset()

func calculate_trophy_change(player_trophies: int, opponent_trophies: int, result: String) -> int:
	# ELO-like trophy calculation
	var trophy_difference = opponent_trophies - player_trophies
	var base_change = 30  # Base trophy change

	# Calculate expected win probability
	var expected_score = 1.0 / (1.0 + pow(10, trophy_difference / 400.0))

	var actual_score = 0.0
	match result.to_lower():
		"win":
			actual_score = 1.0
		"loss":
			actual_score = 0.0
		"draw":
			actual_score = 0.5

	# Calculate trophy change
	var trophy_change = int(base_change * (actual_score - expected_score))

	# Apply arena-based modifiers
	var arena_modifier = _get_arena_modifier(player_trophies)
	trophy_change = int(trophy_change * arena_modifier)

	# Minimum changes
	if result == "win":
		trophy_change = max(trophy_change, 8)  # Minimum 8 trophies for win
	elif result == "loss":
		trophy_change = min(trophy_change, -8)  # Maximum 8 trophies lost

	# Protection for low trophy players
	if player_trophies < 1000:
		if result == "loss":
			trophy_change = max(trophy_change, -5)  # Less harsh losses early on

	return trophy_change

func _get_arena_modifier(trophies: int) -> float:
	# Modifier based on current arena
	if trophies < 1000:
		return 1.2  # Easier progression in early arenas
	elif trophies < 2000:
		return 1.0  # Normal progression
	elif trophies < 3000:
		return 0.9  # Slightly harder
	else:
		return 0.8  # Harder progression at high levels

func update_trophies(change: int) -> void:
	var old_trophies = trophy_data.current_trophies
	trophy_data.current_trophies = max(0, trophy_data.current_trophies + change)

	# Update statistics
	if change > 0:
		trophy_data.total_trophies_earned += change
	else:
		trophy_data.total_trophies_lost += abs(change)

	# Update highest trophies
	if trophy_data.current_trophies > trophy_data.highest_trophies:
		trophy_data.highest_trophies = trophy_data.current_trophies

	# Update season highest
	if trophy_data.current_trophies > trophy_data.season_highest:
		trophy_data.season_highest = trophy_data.current_trophies

	# Check for arena change
	var old_arena = trophy_data.current_arena
	var new_arena = get_arena_for_trophies(trophy_data.current_trophies)

	if new_arena != old_arena:
		trophy_data.current_arena = new_arena
		arena_changed.emit(new_arena, arena_definitions[new_arena].name)

	# Check milestones
	_check_milestones()

	save_trophy_data()
	trophies_changed.emit(trophy_data.current_trophies, change)

func record_battle_result(result: String, opponent_trophies: int) -> int:
	var trophy_change = calculate_trophy_change(
		trophy_data.current_trophies,
		opponent_trophies,
		result
	)

	# Update streaks
	match result.to_lower():
		"win":
			trophy_data.win_streak += 1
			trophy_data.loss_streak = 0

			if trophy_data.win_streak > trophy_data.best_win_streak:
				trophy_data.best_win_streak = trophy_data.win_streak

		"loss":
			trophy_data.loss_streak += 1
			trophy_data.win_streak = 0

		"draw":
			# Draws don't affect streaks
			pass

	# Apply streak bonuses
	if trophy_data.win_streak >= 3:
		var streak_bonus = min(trophy_data.win_streak - 2, 5)  # Max 5 bonus trophies
		trophy_change += streak_bonus

	update_trophies(trophy_change)
	return trophy_change

func get_arena_for_trophies(trophies: int) -> int:
	for i in range(arena_definitions.size() - 1, -1, -1):
		if trophies >= arena_definitions[i].min_trophies:
			return i
	return 0

func get_current_arena() -> Dictionary:
	return arena_definitions[trophy_data.current_arena].duplicate()

func get_next_arena() -> Dictionary:
	if trophy_data.current_arena < arena_definitions.size() - 1:
		return arena_definitions[trophy_data.current_arena + 1].duplicate()
	return {}

func get_trophies_to_next_arena() -> int:
	if trophy_data.current_arena < arena_definitions.size() - 1:
		var next_arena = arena_definitions[trophy_data.current_arena + 1]
		return max(0, next_arena.min_trophies - trophy_data.current_trophies)
	return 0

func get_trophies_to_previous_arena() -> int:
	if trophy_data.current_arena > 0:
		var current_arena = arena_definitions[trophy_data.current_arena]
		return max(0, trophy_data.current_trophies - current_arena.min_trophies)
	return trophy_data.current_trophies

func _check_season_reset() -> void:
	var current_time = Time.get_unix_time_from_system()

	# Initialize season if needed
	if trophy_data.current_season_start == 0:
		trophy_data.current_season_start = current_time
		save_trophy_data()
		return

	# Check if season should reset
	if current_time - trophy_data.current_season_start >= SEASON_DURATION:
		perform_season_reset()

func perform_season_reset() -> void:
	var trophies_before = trophy_data.current_trophies
	var reset_rewards = {}

	# Save season data
	trophy_data.previous_seasons.append({
		"end_trophies": trophy_data.current_trophies,
		"highest_trophies": trophy_data.season_highest,
		"end_date": Time.get_datetime_string_from_system()
	})

	# Keep only last 12 seasons
	if trophy_data.previous_seasons.size() > 12:
		trophy_data.previous_seasons.pop_front()

	# Reset trophies if above threshold
	if trophy_data.current_trophies > RESET_THRESHOLD:
		var excess = trophy_data.current_trophies - RESET_THRESHOLD
		var trophies_to_remove = int(excess * RESET_PERCENTAGE)
		trophy_data.current_trophies = RESET_THRESHOLD + (excess - trophies_to_remove)

		# Calculate reset rewards based on trophies removed
		reset_rewards = {
			"gold": trophies_to_remove * 10,
			"gems": int(trophies_to_remove / 100)
		}

	# Reset season data
	trophy_data.season_highest = trophy_data.current_trophies
	trophy_data.current_season_start = Time.get_unix_time_from_system()

	# Update arena
	trophy_data.current_arena = get_arena_for_trophies(trophy_data.current_trophies)

	save_trophy_data()
	season_reset.emit(trophies_before, trophy_data.current_trophies, reset_rewards)

func get_season_time_remaining() -> int:
	var current_time = Time.get_unix_time_from_system()
	var season_end = trophy_data.current_season_start + SEASON_DURATION
	return max(0, season_end - current_time)

func get_season_progress() -> float:
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - trophy_data.current_season_start
	return min(1.0, float(elapsed) / float(SEASON_DURATION))

func _check_milestones() -> void:
	for milestone in trophy_milestones:
		if trophy_data.current_trophies >= milestone.trophies:
			if not milestone.trophies in trophy_data.milestones_claimed:
				trophy_data.milestones_claimed.append(milestone.trophies)
				milestone_reached.emit(milestone)

func claim_milestone(milestone_trophies: int, currency_manager: Node) -> bool:
	if milestone_trophies in trophy_data.milestones_claimed:
		return false  # Already claimed

	# Find the milestone
	var milestone_data = null
	for milestone in trophy_milestones:
		if milestone.trophies == milestone_trophies:
			milestone_data = milestone
			break

	if milestone_data == null:
		return false

	if trophy_data.current_trophies < milestone_trophies:
		return false  # Not reached yet

	# Grant rewards
	if milestone_data.has("reward_gold"):
		currency_manager.add_gold(
			milestone_data.reward_gold,
			CurrencyManager.TransactionType.ACHIEVEMENT_REWARD,
			"Trophy milestone: %d" % milestone_trophies
		)

	if milestone_data.has("reward_gems"):
		currency_manager.add_gems(
			milestone_data.reward_gems,
			CurrencyManager.TransactionType.ACHIEVEMENT_REWARD,
			"Trophy milestone: %d" % milestone_trophies
		)

	trophy_data.milestones_claimed.append(milestone_trophies)
	save_trophy_data()
	return true

func get_unclaimed_milestones() -> Array:
	var unclaimed = []
	for milestone in trophy_milestones:
		if trophy_data.current_trophies >= milestone.trophies:
			if not milestone.trophies in trophy_data.milestones_claimed:
				unclaimed.append(milestone)
	return unclaimed

func update_leaderboard_position(position: int) -> void:
	var old_position = trophy_data.leaderboard_position
	trophy_data.leaderboard_position = position

	if old_position != position:
		leaderboard_position_changed.emit(position)
		save_trophy_data()

func get_statistics() -> Dictionary:
	var win_rate = 0.0
	var total_battles = trophy_data.total_trophies_earned + trophy_data.total_trophies_lost

	if total_battles > 0:
		win_rate = float(trophy_data.total_trophies_earned) / float(total_battles) * 100.0

	return {
		"current_trophies": trophy_data.current_trophies,
		"highest_trophies": trophy_data.highest_trophies,
		"season_highest": trophy_data.season_highest,
		"current_arena": arena_definitions[trophy_data.current_arena].name,
		"total_earned": trophy_data.total_trophies_earned,
		"total_lost": trophy_data.total_trophies_lost,
		"win_streak": trophy_data.win_streak,
		"best_win_streak": trophy_data.best_win_streak,
		"leaderboard_position": trophy_data.leaderboard_position,
		"seasons_played": trophy_data.previous_seasons.size() + 1
	}

func get_arena_rewards_multiplier() -> float:
	return arena_definitions[trophy_data.current_arena].chest_bonus

func save_trophy_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(trophy_data)
		file.store_string(json_string)
		file.close()
		print("Trophy data saved successfully")
	else:
		push_error("Failed to save trophy data")

func load_trophy_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No trophy save found, starting fresh")
		trophy_data.current_season_start = Time.get_unix_time_from_system()
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			trophy_data = json.data
			print("Trophy data loaded successfully")
			return true

	return false

func reset_trophy_data() -> void:
	trophy_data = {
		"current_trophies": 0,
		"highest_trophies": 0,
		"current_arena": 0,
		"season_highest": 0,
		"previous_seasons": [],
		"current_season_start": Time.get_unix_time_from_system(),
		"total_trophies_earned": 0,
		"total_trophies_lost": 0,
		"milestones_claimed": [],
		"leaderboard_position": 0,
		"win_streak": 0,
		"loss_streak": 0,
		"best_win_streak": 0,
		"version": "1.0.0"
	}
	save_trophy_data()

func export_trophy_data() -> String:
	return JSON.stringify(trophy_data)

func import_trophy_data(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		trophy_data = json.data
		save_trophy_data()
		return true

	return false