extends Node

# Test script to demonstrate and verify all progression systems
# This can be attached to a test scene or run independently

var player_profile: PlayerProfile
var card_collection: CardCollection
var deck_manager: DeckManager
var currency_manager: CurrencyManager
var chest_system: ChestSystem
var trophy_system: TrophySystem
var achievement_system: AchievementSystem

func _ready() -> void:
	print("=== Initializing Battle Castles Progression Systems ===")
	_initialize_systems()
	_run_tests()

func _initialize_systems() -> void:
	# Create system instances
	player_profile = PlayerProfile.new()
	card_collection = CardCollection.new()
	deck_manager = DeckManager.new()
	currency_manager = CurrencyManager.new()
	chest_system = ChestSystem.new()
	trophy_system = TrophySystem.new()
	achievement_system = AchievementSystem.new()

	# Add as children for proper initialization
	add_child(player_profile)
	add_child(card_collection)
	add_child(deck_manager)
	add_child(currency_manager)
	add_child(chest_system)
	add_child(trophy_system)
	add_child(achievement_system)

	# Link systems
	deck_manager.set_card_definitions(card_collection.card_definitions)

	# Connect signals for testing
	_connect_signals()

	print("All systems initialized")

func _connect_signals() -> void:
	# Player profile signals
	player_profile.level_up.connect(_on_level_up)
	player_profile.profile_updated.connect(_on_profile_updated)

	# Card collection signals
	card_collection.card_unlocked.connect(_on_card_unlocked)
	card_collection.card_upgraded.connect(_on_card_upgraded)

	# Currency signals
	currency_manager.currency_changed.connect(_on_currency_changed)

	# Chest signals
	chest_system.chest_received.connect(_on_chest_received)
	chest_system.chest_opened.connect(_on_chest_opened)

	# Trophy signals
	trophy_system.arena_changed.connect(_on_arena_changed)
	trophy_system.milestone_reached.connect(_on_milestone_reached)

	# Achievement signals
	achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
	achievement_system.achievement_completed.connect(_on_achievement_completed)

func _run_tests() -> void:
	print("\n=== Running System Tests ===\n")

	# Test 1: Create player profile
	print("TEST 1: Creating player profile")
	player_profile.create_new_profile("TestPlayer")
	print("Player ID: " + player_profile.player_data.player_id)
	print("Username: " + player_profile.player_data.username)

	# Test 2: Add starting currency
	print("\nTEST 2: Currency system")
	print("Starting gold: %d" % currency_manager.get_gold())
	print("Starting gems: %d" % currency_manager.get_gems())
	currency_manager.add_gold(500, CurrencyManager.TransactionType.ADMIN_GRANT, "Test grant")
	print("After adding 500 gold: %d" % currency_manager.get_gold())

	# Test 3: Card collection
	print("\nTEST 3: Card collection")
	card_collection.add_cards("knight", 10)
	card_collection.add_cards("archer", 5)
	card_collection.add_cards("fireball", 2)
	var unlocked = card_collection.get_unlocked_cards()
	print("Unlocked cards: ", unlocked)
	print("Knight level: %d" % card_collection.get_card_level("knight"))
	print("Knight count: %d" % card_collection.get_card_count("knight"))

	# Test 4: Create and validate deck
	print("\nTEST 4: Deck management")
	var test_deck = ["knight", "archer", "goblin", "giant", "fireball", "arrows", "cannon", "musketeer"]
	var deck_created = deck_manager.create_deck(0, "Test Deck", test_deck)
	if deck_created:
		print("Deck created successfully!")
		var deck = deck_manager.get_deck(0)
		print("Deck name: " + deck.name)
		print("Average elixir: %.2f" % deck.average_elixir)
		print("Cards: ", deck.cards)

		# Export deck code
		var deck_code = deck_manager.export_deck(0)
		print("Deck code: " + deck_code)

	# Test 5: Battle simulation and trophy system
	print("\nTEST 5: Battle and trophy system")
	var initial_trophies = trophy_system.trophy_data.current_trophies
	print("Initial trophies: %d" % initial_trophies)

	# Simulate winning a battle
	var trophy_change = trophy_system.record_battle_result("win", 50)
	print("Won battle! Trophy change: %+d" % trophy_change)
	player_profile.record_battle_result("win", 3, 0)
	player_profile.add_experience(50)

	# Update achievements
	achievement_system.increment_stat("battles_won", 1)
	achievement_system.increment_stat("total_battles", 1)

	# Test 6: Chest system
	print("\nTEST 6: Chest system")
	var chest_added = chest_system.receive_chest(ChestSystem.ChestType.SILVER)
	if chest_added:
		print("Silver chest received!")

		# Start unlocking
		chest_system.start_unlock(0)
		var chest_info = chest_system.get_chest_info(0)
		print("Chest unlocking - Time remaining: %d seconds" % chest_info.remaining_time)

		# Simulate instant unlock for testing
		print("Force opening chest for testing...")
		chest_system.chest_data.slots[0].is_ready = true
		var rewards = chest_system.open_chest(0, card_collection, currency_manager)
		if rewards:
			print("Chest opened! Rewards:")
			print("  Gold: %d" % rewards.get("gold", 0))
			print("  Gems: %d" % rewards.get("gems", 0))
			print("  Cards: ", rewards.get("cards", []))

	# Test 7: Card upgrade
	print("\nTEST 7: Card upgrade")
	if card_collection.can_upgrade_card("knight"):
		var upgrade_cost = card_collection.get_upgrade_cost("knight")
		print("Knight can be upgraded! Cost: %d cards, %d gold" % [upgrade_cost.cards, upgrade_cost.gold])

		if card_collection.upgrade_card("knight", currency_manager):
			print("Knight upgraded to level %d!" % card_collection.get_card_level("knight"))

	# Test 8: Achievement progress
	print("\nTEST 8: Achievement system")
	var stats = achievement_system.get_statistics()
	print("Achievements completed: %d/%d" % [stats.completed, stats.total_achievements])
	print("Completion percentage: %.1f%%" % stats.completion_percentage)

	var next_achievements = achievement_system.get_next_achievements()
	if next_achievements.size() > 0:
		print("Next achievements to complete:")
		for achievement in next_achievements:
			print("  - %s: %d/%d (%.1f%%)" % [
				achievement.name,
				achievement.current,
				achievement.target,
				achievement.percentage
			])

	# Test 9: Player statistics
	print("\nTEST 9: Player statistics")
	var profile_stats = player_profile.player_data
	print("Player Level: %d" % profile_stats.level)
	print("Experience: %d/%d" % [profile_stats.experience, profile_stats.experience_to_next])
	print("Battles: %d (W:%d L:%d D:%d)" % [
		profile_stats.stats.battles_played,
		profile_stats.stats.wins,
		profile_stats.stats.losses,
		profile_stats.stats.draws
	])
	print("Win Rate: %.1f%%" % player_profile.get_win_rate())

	# Test 10: Save all data
	print("\nTEST 10: Saving all data")
	player_profile.save_profile()
	card_collection.save_collection()
	deck_manager.save_decks()
	currency_manager.save_currency()
	chest_system.save_chests()
	trophy_system.save_trophy_data()
	achievement_system.save_achievements()
	print("All data saved successfully!")

	print("\n=== All Tests Completed ===")
	_print_summary()

func _print_summary() -> void:
	print("\n=== SYSTEM SUMMARY ===")
	print("\nPlayer Profile:")
	print("  Username: %s" % player_profile.player_data.username)
	print("  Level: %d" % player_profile.player_data.level)
	print("  Trophies: %d" % trophy_system.trophy_data.current_trophies)
	print("  Current Arena: %s" % trophy_system.get_current_arena().name)

	print("\nCurrency:")
	print("  Gold: %d" % currency_manager.get_gold())
	print("  Gems: %d" % currency_manager.get_gems())

	print("\nCollection:")
	var progress = card_collection.get_collection_progress()
	print("  Cards Unlocked: %d/%d (%.1f%%)" % [
		progress.unlocked_cards,
		progress.total_cards,
		progress.unlock_percentage
	])

	print("\nChests:")
	var chest_stats = chest_system.get_chest_statistics()
	print("  Slots Used: %d/%d" % [chest_stats.slots_used, ChestSystem.MAX_CHEST_SLOTS])
	print("  Total Opened: %d" % chest_stats.total_opened)

	print("\nAchievements:")
	var achievement_stats = achievement_system.get_statistics()
	print("  Completed: %d/%d (%.1f%%)" % [
		achievement_stats.completed,
		achievement_stats.total_achievements,
		achievement_stats.completion_percentage
	])

	print("\n=== END SUMMARY ===")

# Signal callbacks for testing
func _on_level_up(new_level: int, rewards: Dictionary) -> void:
	print("LEVEL UP! Now level %d" % new_level)
	print("Rewards: ", rewards)

func _on_profile_updated() -> void:
	print("Profile updated")

func _on_card_unlocked(card_id: String) -> void:
	print("New card unlocked: %s" % card_id)

func _on_card_upgraded(card_id: String, new_level: int) -> void:
	print("Card upgraded: %s to level %d" % [card_id, new_level])

func _on_currency_changed(currency_type: String, amount: int) -> void:
	print("Currency changed: %s = %d" % [currency_type, amount])

func _on_chest_received(chest_type: String, slot: int) -> void:
	print("Chest received: %s in slot %d" % [chest_type, slot])

func _on_chest_opened(slot: int, rewards: Dictionary) -> void:
	print("Chest opened in slot %d" % slot)
	print("Rewards: ", rewards)

func _on_arena_changed(new_arena: int, arena_name: String) -> void:
	print("Arena changed to: %s (Arena %d)" % [arena_name, new_arena])

func _on_milestone_reached(milestone: Dictionary) -> void:
	print("Trophy milestone reached: %d trophies!" % milestone.trophies)
	print("Rewards: Gold=%d, Gems=%d" % [milestone.get("reward_gold", 0), milestone.get("reward_gems", 0)])

func _on_achievement_unlocked(achievement_id: String) -> void:
	print("Achievement unlocked: %s" % achievement_id)

func _on_achievement_completed(achievement_id: String) -> void:
	var achievement = achievement_system.get_achievement_progress(achievement_id)
	print("Achievement completed: %s" % achievement.name)

# Utility functions for manual testing
func simulate_battle_win() -> void:
	print("Simulating battle win...")
	var trophy_change = trophy_system.record_battle_result("win", randi_range(0, 100))
	player_profile.record_battle_result("win", randi_range(1, 3), 0)
	player_profile.add_experience(randi_range(20, 50))
	achievement_system.increment_stat("battles_won", 1)
	achievement_system.increment_stat("total_battles", 1)
	print("Battle won! Trophy change: %+d" % trophy_change)

func simulate_battle_loss() -> void:
	print("Simulating battle loss...")
	var trophy_change = trophy_system.record_battle_result("loss", randi_range(0, 100))
	player_profile.record_battle_result("loss", 0, randi_range(1, 3))
	player_profile.add_experience(randi_range(5, 15))
	achievement_system.increment_stat("total_battles", 1)
	print("Battle lost! Trophy change: %+d" % trophy_change)

func give_random_chest() -> void:
	var chest_types = [
		ChestSystem.ChestType.WOODEN,
		ChestSystem.ChestType.SILVER,
		ChestSystem.ChestType.GOLDEN
	]
	var random_type = chest_types[randi() % chest_types.size()]

	if chest_system.receive_chest(random_type):
		var chest_name = chest_system.chest_definitions[random_type].name
		print("Received %s!" % chest_name)
	else:
		print("No empty chest slots!")

func reset_all_data() -> void:
	print("Resetting all progression data...")
	player_profile.reset_profile()
	card_collection.reset_collection()
	deck_manager.reset_decks()
	currency_manager.reset_currency()
	chest_system.reset_chests()
	trophy_system.reset_trophy_data()
	achievement_system.reset_all_achievements()
	print("All data reset!")