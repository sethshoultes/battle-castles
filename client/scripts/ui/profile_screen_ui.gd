extends Control

# Profile Screen UI
# Displays detailed player profile information and statistics

signal back_pressed

# UI References
@onready var player_name_label: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/PlayerNameLabel
@onready var player_id_label: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/PlayerIDLabel
@onready var level_number: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/LevelSection/LevelRow/LevelBadge/LevelNumber
@onready var level_label: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/LevelSection/LevelRow/LevelLabel
@onready var xp_progress_bar: ProgressBar = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/LevelSection/XPProgressBar
@onready var xp_label: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ProfileCard/VBox/LevelSection/XPLabel

@onready var arena_name: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ArenaSection/VBox/ArenaInfo/ArenaName
@onready var current_trophies: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ArenaSection/VBox/TrophyInfo/CurrentTrophies
@onready var highest_trophies: Label = $MainContainer/ContentContainer/MainContent/LeftColumn/ArenaSection/VBox/TrophyInfo/HighestTrophies

@onready var total_battles_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/TotalBattlesValue
@onready var wins_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/WinsValue
@onready var losses_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/LossesValue
@onready var draws_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/DrawsValue
@onready var win_rate_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/WinRateValue
@onready var three_crowns_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/BattleStatsCard/VBox/StatsGrid/ThreeCrownsValue

@onready var cards_collected_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/CollectionStatsCard/VBox/StatsRow/CardsContainer/Value
@onready var donations_value: Label = $MainContainer/ContentContainer/MainContent/RightColumn/CollectionStatsCard/VBox/StatsRow/DonationsContainer/Value

# Arena names mapping
const ARENA_NAMES = [
	"Training Camp",
	"Goblin Stadium",
	"Bone Pit",
	"Barbarian Bowl",
	"Spell Valley",
	"Builder's Workshop",
	"Royal Arena",
	"Frozen Peak",
	"Jungle Arena",
	"Hog Mountain"
]

func _ready() -> void:
	_load_profile_data()

func _load_profile_data() -> void:
	# Get player profile from GameManager
	if not GameManager:
		push_warning("GameManager not found, using default values")
		return

	if not GameManager.player_profile:
		push_warning("PlayerProfile not found in GameManager, using default values")
		return

	var profile = GameManager.player_profile
	var player_data = profile.player_data

	# Update player information
	_update_player_info(player_data)
	_update_level_info(player_data)
	_update_arena_info(player_data)
	_update_battle_stats(player_data)
	_update_collection_stats(player_data)

func _update_player_info(player_data: Dictionary) -> void:
	# Player name and ID
	player_name_label.text = player_data.get("username", "Player")
	player_id_label.text = "ID: " + player_data.get("player_id", "UNKNOWN")

func _update_level_info(player_data: Dictionary) -> void:
	var level = player_data.get("level", 1)
	var experience = player_data.get("experience", 0)
	var experience_to_next = player_data.get("experience_to_next", 100)

	# Update level display
	level_number.text = str(level)
	level_label.text = "Level " + str(level)

	# Update XP progress bar
	if experience_to_next > 0:
		var progress = (float(experience) / float(experience_to_next)) * 100.0
		xp_progress_bar.value = progress
		xp_label.text = "%d / %d XP" % [experience, experience_to_next]
	else:
		# Max level reached
		xp_progress_bar.value = 100.0
		xp_label.text = "MAX LEVEL"

func _update_arena_info(player_data: Dictionary) -> void:
	var current_arena = player_data.get("current_arena", 0)
	var trophies = player_data.get("trophies", 0)
	var highest = player_data.get("highest_trophies", 0)

	# Update arena name
	if current_arena >= 0 and current_arena < ARENA_NAMES.size():
		arena_name.text = ARENA_NAMES[current_arena]
	else:
		arena_name.text = "Unknown Arena"

	# Update trophy counts
	current_trophies.text = str(trophies)
	highest_trophies.text = str(highest)

func _update_battle_stats(player_data: Dictionary) -> void:
	var stats = player_data.get("stats", {})

	var battles_played = stats.get("battles_played", 0)
	var wins = stats.get("wins", 0)
	var losses = stats.get("losses", 0)
	var draws = stats.get("draws", 0)
	var three_crown_wins = stats.get("three_crown_wins", 0)

	# Update battle statistics
	total_battles_value.text = str(battles_played)
	wins_value.text = str(wins)
	losses_value.text = str(losses)
	draws_value.text = str(draws)
	three_crowns_value.text = str(three_crown_wins)

	# Calculate and display win rate
	var win_rate = 0.0
	if battles_played > 0:
		win_rate = (float(wins) / float(battles_played)) * 100.0

	win_rate_value.text = "%.1f%%" % win_rate

func _update_collection_stats(player_data: Dictionary) -> void:
	var stats = player_data.get("stats", {})

	var cards_collected = stats.get("cards_collected", 0)
	var donations = stats.get("donations", 0)

	cards_collected_value.text = str(cards_collected)
	donations_value.text = str(donations)

func _on_back_button_pressed() -> void:
	back_pressed.emit()

	# Return to main menu
	if SceneManager:
		SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		push_error("SceneManager not found")
