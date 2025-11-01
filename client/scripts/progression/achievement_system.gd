extends Node
class_name AchievementSystem

# Achievement system with progress tracking and rewards
# Manages various achievement types and completion tracking

signal achievement_unlocked(achievement_id: String)
signal achievement_progress(achievement_id: String, current: int, target: int)
signal reward_claimed(achievement_id: String, rewards: Dictionary)
signal achievement_completed(achievement_id: String)
signal tier_completed(tier: int)

const SAVE_PATH = "user://achievement_data.json"
const NOTIFICATION_QUEUE_PATH = "user://achievement_notifications.json"

# Achievement categories
enum Category {
	BATTLE,
	COLLECTION,
	SOCIAL,
	PROGRESSION,
	SPECIAL
}

# Achievement tiers
enum Tier {
	BRONZE,
	SILVER,
	GOLD,
	PLATINUM,
	DIAMOND
}

# Achievement definitions
var achievement_definitions = {
	# Battle achievements
	"first_win": {
		"name": "First Victory",
		"description": "Win your first battle",
		"category": Category.BATTLE,
		"tier": Tier.BRONZE,
		"target": 1,
		"rewards": {"gold": 100, "gems": 5},
		"track_stat": "battles_won"
	},
	"win_streak_3": {
		"name": "Hot Streak",
		"description": "Win 3 battles in a row",
		"category": Category.BATTLE,
		"tier": Tier.BRONZE,
		"target": 3,
		"rewards": {"gold": 200, "gems": 10},
		"track_stat": "win_streak"
	},
	"win_streak_10": {
		"name": "Unstoppable",
		"description": "Win 10 battles in a row",
		"category": Category.BATTLE,
		"tier": Tier.SILVER,
		"target": 10,
		"rewards": {"gold": 500, "gems": 25},
		"track_stat": "win_streak"
	},
	"battles_100": {
		"name": "Battle Veteran",
		"description": "Play 100 battles",
		"category": Category.BATTLE,
		"tier": Tier.SILVER,
		"target": 100,
		"rewards": {"gold": 1000, "gems": 50},
		"track_stat": "total_battles"
	},
	"three_crown_10": {
		"name": "Crown Collector",
		"description": "Win 10 battles with 3 crowns",
		"category": Category.BATTLE,
		"tier": Tier.SILVER,
		"target": 10,
		"rewards": {"gold": 750, "gems": 30},
		"track_stat": "three_crown_wins"
	},
	"perfect_defense": {
		"name": "Perfect Defense",
		"description": "Win a battle without losing any towers",
		"category": Category.BATTLE,
		"tier": Tier.GOLD,
		"target": 1,
		"rewards": {"gold": 500, "gems": 20},
		"track_stat": "perfect_wins"
	},

	# Collection achievements
	"collect_10_cards": {
		"name": "Card Collector",
		"description": "Unlock 10 different cards",
		"category": Category.COLLECTION,
		"tier": Tier.BRONZE,
		"target": 10,
		"rewards": {"gold": 300, "gems": 15},
		"track_stat": "unique_cards"
	},
	"collect_all_commons": {
		"name": "Common Knowledge",
		"description": "Unlock all common cards",
		"category": Category.COLLECTION,
		"tier": Tier.SILVER,
		"target": 15,  # Assuming 15 common cards
		"rewards": {"gold": 1000, "gems": 40},
		"track_stat": "common_cards"
	},
	"first_legendary": {
		"name": "Legendary Find",
		"description": "Unlock your first legendary card",
		"category": Category.COLLECTION,
		"tier": Tier.GOLD,
		"target": 1,
		"rewards": {"gold": 2000, "gems": 100},
		"track_stat": "legendary_cards"
	},
	"max_level_card": {
		"name": "Maxed Out",
		"description": "Upgrade any card to max level",
		"category": Category.COLLECTION,
		"tier": Tier.PLATINUM,
		"target": 1,
		"rewards": {"gold": 5000, "gems": 200},
		"track_stat": "max_level_cards"
	},

	# Progression achievements
	"reach_arena_3": {
		"name": "Arena Fighter",
		"description": "Reach Barbarian Bowl (Arena 3)",
		"category": Category.PROGRESSION,
		"tier": Tier.BRONZE,
		"target": 3,
		"rewards": {"gold": 500, "gems": 25},
		"track_stat": "highest_arena"
	},
	"reach_arena_6": {
		"name": "Royal Champion",
		"description": "Reach Royal Arena (Arena 6)",
		"category": Category.PROGRESSION,
		"tier": Tier.SILVER,
		"target": 6,
		"rewards": {"gold": 1500, "gems": 75},
		"track_stat": "highest_arena"
	},
	"reach_arena_9": {
		"name": "Legendary Player",
		"description": "Reach Legendary Arena (Arena 9)",
		"category": Category.PROGRESSION,
		"tier": Tier.GOLD,
		"target": 9,
		"rewards": {"gold": 3000, "gems": 150},
		"track_stat": "highest_arena"
	},
	"level_10": {
		"name": "Experienced",
		"description": "Reach player level 10",
		"category": Category.PROGRESSION,
		"tier": Tier.BRONZE,
		"target": 10,
		"rewards": {"gold": 1000, "gems": 50},
		"track_stat": "player_level"
	},
	"level_25": {
		"name": "Veteran",
		"description": "Reach player level 25",
		"category": Category.PROGRESSION,
		"tier": Tier.SILVER,
		"target": 25,
		"rewards": {"gold": 2500, "gems": 125},
		"track_stat": "player_level"
	},
	"trophies_1000": {
		"name": "Trophy Hunter",
		"description": "Reach 1000 trophies",
		"category": Category.PROGRESSION,
		"tier": Tier.SILVER,
		"target": 1000,
		"rewards": {"gold": 1000, "gems": 50},
		"track_stat": "highest_trophies"
	},
	"trophies_3000": {
		"name": "Trophy Master",
		"description": "Reach 3000 trophies",
		"category": Category.PROGRESSION,
		"tier": Tier.GOLD,
		"target": 3000,
		"rewards": {"gold": 3000, "gems": 150},
		"track_stat": "highest_trophies"
	},

	# Social achievements
	"donate_100": {
		"name": "Generous Soul",
		"description": "Donate 100 cards to clan members",
		"category": Category.SOCIAL,
		"tier": Tier.BRONZE,
		"target": 100,
		"rewards": {"gold": 500, "gems": 25},
		"track_stat": "cards_donated"
	},
	"clan_wars_10": {
		"name": "Clan Warrior",
		"description": "Participate in 10 clan wars",
		"category": Category.SOCIAL,
		"tier": Tier.SILVER,
		"target": 10,
		"rewards": {"gold": 1500, "gems": 75},
		"track_stat": "clan_wars_participated"
	},

	# Special achievements
	"open_100_chests": {
		"name": "Chest Master",
		"description": "Open 100 chests",
		"category": Category.SPECIAL,
		"tier": Tier.SILVER,
		"target": 100,
		"rewards": {"gold": 2000, "gems": 100},
		"track_stat": "chests_opened"
	},
	"spend_10000_gold": {
		"name": "Big Spender",
		"description": "Spend 10000 gold total",
		"category": Category.SPECIAL,
		"tier": Tier.BRONZE,
		"target": 10000,
		"rewards": {"gold": 500, "gems": 25},
		"track_stat": "gold_spent"
	}
}

# Achievement progress data
var achievement_data: Dictionary = {
	"progress": {},  # achievement_id: {current, completed, claimed}
	"stats": {},     # Various tracked statistics
	"completed_count": 0,
	"total_rewards_claimed": {"gold": 0, "gems": 0},
	"version": "1.0.0"
}

# Notification queue
var notification_queue: Array = []

func _ready() -> void:
	load_achievements()
	_initialize_achievement_progress()

func _initialize_achievement_progress() -> void:
	for achievement_id in achievement_definitions:
		if not achievement_data.progress.has(achievement_id):
			achievement_data.progress[achievement_id] = {
				"current": 0,
				"completed": false,
				"claimed": false,
				"completed_at": ""
			}

func track_stat(stat_name: String, value: int) -> void:
	if not achievement_data.stats.has(stat_name):
		achievement_data.stats[stat_name] = 0

	var old_value = achievement_data.stats[stat_name]
	achievement_data.stats[stat_name] = value

	# Check all achievements that track this stat
	for achievement_id in achievement_definitions:
		var achievement = achievement_definitions[achievement_id]
		if achievement.track_stat == stat_name:
			_update_achievement_progress(achievement_id, value)

func increment_stat(stat_name: String, amount: int = 1) -> void:
	if not achievement_data.stats.has(stat_name):
		achievement_data.stats[stat_name] = 0

	achievement_data.stats[stat_name] += amount

	# Check all achievements that track this stat
	for achievement_id in achievement_definitions:
		var achievement = achievement_definitions[achievement_id]
		if achievement.track_stat == stat_name:
			_update_achievement_progress(achievement_id, achievement_data.stats[stat_name])

func _update_achievement_progress(achievement_id: String, value: int) -> void:
	if not achievement_definitions.has(achievement_id):
		return

	var achievement = achievement_definitions[achievement_id]
	var progress = achievement_data.progress[achievement_id]

	if progress.completed:
		return  # Already completed

	var old_value = progress.current
	progress.current = min(value, achievement.target)

	if progress.current >= achievement.target and not progress.completed:
		progress.completed = true
		progress.completed_at = Time.get_datetime_string_from_system()
		achievement_data.completed_count += 1

		# Add to notification queue
		_queue_notification(achievement_id)

		achievement_completed.emit(achievement_id)
		achievement_unlocked.emit(achievement_id)

		# Check tier completion
		_check_tier_completion(achievement.tier)
	elif old_value != progress.current:
		achievement_progress.emit(achievement_id, progress.current, achievement.target)

	save_achievements()

func _queue_notification(achievement_id: String) -> void:
	notification_queue.append({
		"achievement_id": achievement_id,
		"timestamp": Time.get_unix_time_from_system(),
		"shown": false
	})
	_save_notifications()

func get_pending_notifications() -> Array:
	var pending = []
	for notification in notification_queue:
		if not notification.shown:
			pending.append(notification)
	return pending

func mark_notification_shown(achievement_id: String) -> void:
	for notification in notification_queue:
		if notification.achievement_id == achievement_id:
			notification.shown = true
			break
	_save_notifications()

func claim_reward(achievement_id: String, currency_manager: Node) -> bool:
	if not achievement_definitions.has(achievement_id):
		return false

	var achievement = achievement_definitions[achievement_id]
	var progress = achievement_data.progress[achievement_id]

	if not progress.completed:
		return false  # Not completed yet

	if progress.claimed:
		return false  # Already claimed

	# Grant rewards
	var rewards = achievement.rewards.duplicate()

	if rewards.has("gold") and rewards.gold > 0:
		currency_manager.add_gold(
			rewards.gold,
			CurrencyManager.TransactionType.ACHIEVEMENT_REWARD,
			"Achievement: " + achievement.name
		)
		achievement_data.total_rewards_claimed.gold += rewards.gold

	if rewards.has("gems") and rewards.gems > 0:
		currency_manager.add_gems(
			rewards.gems,
			CurrencyManager.TransactionType.ACHIEVEMENT_REWARD,
			"Achievement: " + achievement.name
		)
		achievement_data.total_rewards_claimed.gems += rewards.gems

	progress.claimed = true
	save_achievements()
	reward_claimed.emit(achievement_id, rewards)
	return true

func get_achievement_progress(achievement_id: String) -> Dictionary:
	if not achievement_definitions.has(achievement_id):
		return {}

	var achievement = achievement_definitions[achievement_id]
	var progress = achievement_data.progress[achievement_id]

	return {
		"name": achievement.name,
		"description": achievement.description,
		"category": achievement.category,
		"tier": achievement.tier,
		"current": progress.current,
		"target": achievement.target,
		"percentage": float(progress.current) / float(achievement.target) * 100.0,
		"completed": progress.completed,
		"claimed": progress.claimed,
		"rewards": achievement.rewards
	}

func get_achievements_by_category(category: int) -> Array:
	var achievements = []
	for achievement_id in achievement_definitions:
		if achievement_definitions[achievement_id].category == category:
			achievements.append(get_achievement_progress(achievement_id))
	return achievements

func get_achievements_by_tier(tier: int) -> Array:
	var achievements = []
	for achievement_id in achievement_definitions:
		if achievement_definitions[achievement_id].tier == tier:
			achievements.append(get_achievement_progress(achievement_id))
	return achievements

func get_unclaimed_rewards() -> Array:
	var unclaimed = []
	for achievement_id in achievement_data.progress:
		var progress = achievement_data.progress[achievement_id]
		if progress.completed and not progress.claimed:
			unclaimed.append(achievement_id)
	return unclaimed

func claim_all_rewards(currency_manager: Node) -> Dictionary:
	var total_rewards = {"gold": 0, "gems": 0}
	var unclaimed = get_unclaimed_rewards()

	for achievement_id in unclaimed:
		if claim_reward(achievement_id, currency_manager):
			var rewards = achievement_definitions[achievement_id].rewards
			if rewards.has("gold"):
				total_rewards.gold += rewards.gold
			if rewards.has("gems"):
				total_rewards.gems += rewards.gems

	return total_rewards

func _check_tier_completion(tier: int) -> void:
	var tier_achievements = get_achievements_by_tier(tier)
	var completed_count = 0
	var total_count = tier_achievements.size()

	for achievement in tier_achievements:
		if achievement.completed:
			completed_count += 1

	if completed_count == total_count:
		tier_completed.emit(tier)

func get_statistics() -> Dictionary:
	var total_achievements = achievement_definitions.size()
	var completed = 0
	var claimed = 0

	for progress in achievement_data.progress.values():
		if progress.completed:
			completed += 1
		if progress.claimed:
			claimed += 1

	var category_stats = {}
	for i in range(Category.size()):
		var cat_achievements = get_achievements_by_category(i)
		var cat_completed = 0
		for achievement in cat_achievements:
			if achievement.completed:
				cat_completed += 1
		category_stats[i] = {
			"total": cat_achievements.size(),
			"completed": cat_completed,
			"percentage": float(cat_completed) / float(cat_achievements.size()) * 100.0 if cat_achievements.size() > 0 else 0.0
		}

	return {
		"total_achievements": total_achievements,
		"completed": completed,
		"claimed": claimed,
		"completion_percentage": float(completed) / float(total_achievements) * 100.0,
		"total_gold_earned": achievement_data.total_rewards_claimed.gold,
		"total_gems_earned": achievement_data.total_rewards_claimed.gems,
		"category_stats": category_stats
	}

func get_next_achievements(limit: int = 3) -> Array:
	var next_achievements = []

	for achievement_id in achievement_definitions:
		var progress = achievement_data.progress[achievement_id]
		if not progress.completed:
			var achievement_info = get_achievement_progress(achievement_id)
			if achievement_info.percentage > 0:  # Has some progress
				next_achievements.append(achievement_info)

	# Sort by completion percentage (highest first)
	next_achievements.sort_custom(func(a, b): return a.percentage > b.percentage)

	return next_achievements.slice(0, min(limit, next_achievements.size()))

func reset_achievement(achievement_id: String) -> void:
	if achievement_data.progress.has(achievement_id):
		achievement_data.progress[achievement_id] = {
			"current": 0,
			"completed": false,
			"claimed": false,
			"completed_at": ""
		}
		save_achievements()

func save_achievements() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(achievement_data)
		file.store_string(json_string)
		file.close()
		print("Achievements saved successfully")
	else:
		push_error("Failed to save achievement data")

func load_achievements() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No achievement save found, starting fresh")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			achievement_data = json.data
			_initialize_achievement_progress()
			print("Achievements loaded successfully")
			return true

	return false

func _save_notifications() -> void:
	var file = FileAccess.open(NOTIFICATION_QUEUE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(notification_queue)
		file.store_string(json_string)
		file.close()

func _load_notifications() -> void:
	if not FileAccess.file_exists(NOTIFICATION_QUEUE_PATH):
		return

	var file = FileAccess.open(NOTIFICATION_QUEUE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			notification_queue = json.data

func reset_all_achievements() -> void:
	achievement_data = {
		"progress": {},
		"stats": {},
		"completed_count": 0,
		"total_rewards_claimed": {"gold": 0, "gems": 0},
		"version": "1.0.0"
	}
	notification_queue.clear()
	_initialize_achievement_progress()
	save_achievements()
	_save_notifications()

func export_achievement_data() -> String:
	return JSON.stringify(achievement_data)

func import_achievement_data(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		achievement_data = json.data
		save_achievements()
		return true

	return false