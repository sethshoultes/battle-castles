extends Node
class_name ChestSystem

# Chest reward and unlocking system
# Manages different chest types with timer-based unlocking

signal chest_received(chest_type: String, slot: int)
signal chest_unlock_started(slot: int)
signal chest_unlock_completed(slot: int)
signal chest_opened(slot: int, rewards: Dictionary)
signal chest_slot_full()
signal chest_progress_updated(slot: int, remaining_time: float)

const SAVE_PATH = "user://chest_data.json"
const MAX_CHEST_SLOTS = 4
const UNLOCK_SPEED_MULTIPLIER = 1.0  # Can be modified for events

# Chest types and their properties
enum ChestType {
	WOODEN,
	SILVER,
	GOLDEN,
	GIANT,
	MAGICAL,
	SUPER_MAGICAL,
	LEGENDARY
}

# Chest definitions
var chest_definitions = {
	ChestType.WOODEN: {
		"name": "Wooden Chest",
		"unlock_time": 5,  # 5 seconds for testing (normally 15 seconds)
		"gem_cost": 1,
		"guaranteed_gold": [20, 30],
		"guaranteed_cards": 3,
		"rare_chance": 0.1,
		"epic_chance": 0.0,
		"legendary_chance": 0.0
	},
	ChestType.SILVER: {
		"name": "Silver Chest",
		"unlock_time": 180,  # 3 minutes (normally 3 hours)
		"gem_cost": 18,
		"guaranteed_gold": [50, 80],
		"guaranteed_cards": 8,
		"rare_chance": 0.15,
		"epic_chance": 0.02,
		"legendary_chance": 0.0
	},
	ChestType.GOLDEN: {
		"name": "Golden Chest",
		"unlock_time": 480,  # 8 minutes (normally 8 hours)
		"gem_cost": 48,
		"guaranteed_gold": [150, 250],
		"guaranteed_cards": 20,
		"rare_chance": 0.25,
		"epic_chance": 0.05,
		"legendary_chance": 0.001
	},
	ChestType.GIANT: {
		"name": "Giant Chest",
		"unlock_time": 720,  # 12 minutes (normally 12 hours)
		"gem_cost": 72,
		"guaranteed_gold": [500, 750],
		"guaranteed_cards": 85,
		"rare_chance": 0.3,
		"epic_chance": 0.08,
		"legendary_chance": 0.002
	},
	ChestType.MAGICAL: {
		"name": "Magical Chest",
		"unlock_time": 720,  # 12 minutes (normally 12 hours)
		"gem_cost": 72,
		"guaranteed_gold": [400, 600],
		"guaranteed_cards": 40,
		"rare_chance": 0.5,
		"epic_chance": 0.15,
		"legendary_chance": 0.005
	},
	ChestType.SUPER_MAGICAL: {
		"name": "Super Magical Chest",
		"unlock_time": 1440,  # 24 minutes (normally 24 hours)
		"gem_cost": 144,
		"guaranteed_gold": [2000, 3000],
		"guaranteed_cards": 180,
		"rare_chance": 0.6,
		"epic_chance": 0.25,
		"legendary_chance": 0.01
	},
	ChestType.LEGENDARY: {
		"name": "Legendary Chest",
		"unlock_time": 1440,  # 24 minutes (normally 24 hours)
		"gem_cost": 144,
		"guaranteed_gold": [1500, 2000],
		"guaranteed_cards": 50,
		"rare_chance": 0.5,
		"epic_chance": 0.3,
		"legendary_chance": 1.0  # Guaranteed legendary
	}
}

# Chest queue data
var chest_data: Dictionary = {
	"slots": [],
	"unlocking_slot": -1,
	"chest_cycle_position": 0,
	"super_magical_counter": 0,
	"total_chests_opened": 0,
	"version": "1.0.0"
}

# Chest cycle (determines order of chest rewards)
var chest_cycle: Array = []
var super_magical_cycle: int = 500  # Super magical chest every 500 chests

# Timer for updating chest progress
var update_timer: Timer

func _ready() -> void:
	_initialize_chest_slots()
	_generate_chest_cycle()
	load_chests()

	# Create update timer
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_chest_timers)
	add_child(update_timer)
	update_timer.start()

func _initialize_chest_slots() -> void:
	while chest_data.slots.size() < MAX_CHEST_SLOTS:
		chest_data.slots.append(null)

func _generate_chest_cycle() -> void:
	# Generate a 240 chest cycle
	chest_cycle.clear()

	# Add wooden chests (52%)
	for i in range(125):
		chest_cycle.append(ChestType.WOODEN)

	# Add silver chests (38%)
	for i in range(91):
		chest_cycle.append(ChestType.SILVER)

	# Add golden chests (9%)
	for i in range(22):
		chest_cycle.append(ChestType.GOLDEN)

	# Add giant chests (0.8%)
	for i in range(2):
		chest_cycle.append(ChestType.GIANT)

	# Shuffle the cycle
	chest_cycle.shuffle()

func receive_chest(chest_type: int = -1, force_slot: int = -1) -> bool:
	# Find available slot
	var slot = force_slot
	if slot == -1:
		slot = _find_empty_slot()

	if slot == -1:
		chest_slot_full.emit()
		return false

	# Determine chest type if not specified
	if chest_type == -1:
		chest_type = _get_next_chest_from_cycle()

	# Create chest data
	var chest = {
		"type": chest_type,
		"received_at": Time.get_unix_time_from_system(),
		"unlock_started_at": 0,
		"unlock_duration": chest_definitions[chest_type].unlock_time,
		"is_unlocking": false,
		"is_ready": false
	}

	chest_data.slots[slot] = chest
	save_chests()
	chest_received.emit(chest_definitions[chest_type].name, slot)
	return true

func _find_empty_slot() -> int:
	for i in range(MAX_CHEST_SLOTS):
		if chest_data.slots[i] == null:
			return i
	return -1

func _get_next_chest_from_cycle() -> int:
	# Check for super magical chest
	chest_data.super_magical_counter += 1
	if chest_data.super_magical_counter >= super_magical_cycle:
		chest_data.super_magical_counter = 0
		return ChestType.SUPER_MAGICAL

	# Get chest from regular cycle
	var chest_type = chest_cycle[chest_data.chest_cycle_position]
	chest_data.chest_cycle_position = (chest_data.chest_cycle_position + 1) % chest_cycle.size()

	# Small chance for magical chest to replace regular chest
	if randf() < 0.001:  # 0.1% chance
		return ChestType.MAGICAL

	return chest_type

func start_unlock(slot: int) -> bool:
	if slot < 0 or slot >= MAX_CHEST_SLOTS:
		return false

	if chest_data.slots[slot] == null:
		return false

	# Check if another chest is already unlocking
	if chest_data.unlocking_slot != -1 and chest_data.unlocking_slot != slot:
		return false

	var chest = chest_data.slots[slot]

	if chest.is_ready:
		return true  # Already unlocked

	chest.is_unlocking = true
	chest.unlock_started_at = Time.get_unix_time_from_system()
	chest_data.unlocking_slot = slot

	save_chests()
	chest_unlock_started.emit(slot)
	return true

func instant_unlock_with_gems(slot: int, currency_manager: Node) -> bool:
	if slot < 0 or slot >= MAX_CHEST_SLOTS:
		return false

	if chest_data.slots[slot] == null:
		return false

	var chest = chest_data.slots[slot]

	if chest.is_ready:
		return true  # Already unlocked

	# Calculate gem cost based on remaining time
	var remaining_time = _get_remaining_unlock_time(slot)
	var gem_cost = _calculate_gem_cost(remaining_time, chest.type)

	if not currency_manager.spend_gems(gem_cost, CurrencyManager.TransactionType.CHEST_UNLOCK, "Instant unlock chest"):
		return false

	# Mark as ready
	chest.is_ready = true
	chest.is_unlocking = false

	if chest_data.unlocking_slot == slot:
		chest_data.unlocking_slot = -1

	save_chests()
	chest_unlock_completed.emit(slot)
	return true

func _calculate_gem_cost(remaining_seconds: float, chest_type: int) -> int:
	# Base cost per minute remaining
	var minutes = ceil(remaining_seconds / 60.0)
	var base_cost = chest_definitions[chest_type].gem_cost
	var cost_per_minute = base_cost / float(chest_definitions[chest_type].unlock_time / 60)

	return int(ceil(cost_per_minute * minutes))

func open_chest(slot: int, card_collection: Node, currency_manager: Node) -> Dictionary:
	if slot < 0 or slot >= MAX_CHEST_SLOTS:
		return {}

	if chest_data.slots[slot] == null:
		return {}

	var chest = chest_data.slots[slot]

	if not chest.is_ready:
		return {}

	# Generate rewards
	var rewards = _generate_chest_rewards(chest.type, card_collection)

	# Apply rewards
	if rewards.has("gold") and rewards.gold > 0:
		currency_manager.add_gold(rewards.gold, CurrencyManager.TransactionType.CHEST_REWARD, "Chest reward")

	if rewards.has("gems") and rewards.gems > 0:
		currency_manager.add_gems(rewards.gems, CurrencyManager.TransactionType.CHEST_REWARD, "Chest reward")

	if rewards.has("cards"):
		for card_reward in rewards.cards:
			card_collection.add_cards(card_reward.id, card_reward.count)

	# Clear slot
	chest_data.slots[slot] = null

	if chest_data.unlocking_slot == slot:
		chest_data.unlocking_slot = -1

	chest_data.total_chests_opened += 1

	save_chests()
	chest_opened.emit(slot, rewards)

	# Auto-start next chest if any
	_auto_start_next_chest()

	return rewards

func _generate_chest_rewards(chest_type: int, card_collection: Node) -> Dictionary:
	var chest_def = chest_definitions[chest_type]
	var rewards = {
		"gold": 0,
		"gems": 0,
		"cards": []
	}

	# Generate gold
	var gold_range = chest_def.guaranteed_gold
	rewards.gold = randi_range(gold_range[0], gold_range[1])

	# Small chance for gems
	if randf() < 0.1:  # 10% chance for gems
		rewards.gems = randi_range(1, 5)

	# Generate cards
	var total_cards = chest_def.guaranteed_cards
	var cards_generated = 0

	# Get available cards based on player's arena
	var available_cards = _get_available_cards(card_collection)

	while cards_generated < total_cards:
		var rarity = _determine_card_rarity(chest_def)
		var eligible_cards = _filter_cards_by_rarity(available_cards, rarity, card_collection)

		if eligible_cards.is_empty():
			continue

		var card_id = eligible_cards[randi() % eligible_cards.size()]
		var count = _get_card_count_by_rarity(rarity)

		# Add to rewards
		var existing_reward = null
		for reward in rewards.cards:
			if reward.id == card_id:
				existing_reward = reward
				break

		if existing_reward:
			existing_reward.count += count
		else:
			rewards.cards.append({
				"id": card_id,
				"count": count,
				"rarity": rarity
			})

		cards_generated += count

	return rewards

func _determine_card_rarity(chest_def: Dictionary) -> int:
	var roll = randf()

	if roll < chest_def.legendary_chance:
		return CardCollection.Rarity.LEGENDARY
	elif roll < chest_def.legendary_chance + chest_def.epic_chance:
		return CardCollection.Rarity.EPIC
	elif roll < chest_def.legendary_chance + chest_def.epic_chance + chest_def.rare_chance:
		return CardCollection.Rarity.RARE
	else:
		return CardCollection.Rarity.COMMON

func _get_card_count_by_rarity(rarity: int) -> int:
	match rarity:
		CardCollection.Rarity.COMMON:
			return randi_range(5, 15)
		CardCollection.Rarity.RARE:
			return randi_range(2, 5)
		CardCollection.Rarity.EPIC:
			return 1
		CardCollection.Rarity.LEGENDARY:
			return 1
		_:
			return 1

func _get_available_cards(card_collection: Node) -> Array:
	# Get all card IDs from card collection
	# In a real implementation, this would filter by arena
	return card_collection.card_definitions.keys()

func _filter_cards_by_rarity(cards: Array, rarity: int, card_collection: Node) -> Array:
	var filtered = []

	# Filter cards by checking their actual rarity from card_definitions
	for card_id in cards:
		if card_collection.card_definitions.has(card_id):
			var card_def = card_collection.card_definitions[card_id]
			if card_def.rarity == rarity:
				filtered.append(card_id)

	return filtered

func _auto_start_next_chest() -> void:
	# If no chest is currently unlocking, start the next one
	if chest_data.unlocking_slot == -1:
		for i in range(MAX_CHEST_SLOTS):
			if chest_data.slots[i] != null and not chest_data.slots[i].is_ready:
				start_unlock(i)
				break

func _update_chest_timers() -> void:
	if chest_data.unlocking_slot == -1:
		return

	var slot = chest_data.unlocking_slot
	if chest_data.slots[slot] == null:
		chest_data.unlocking_slot = -1
		return

	var chest = chest_data.slots[slot]
	var remaining_time = _get_remaining_unlock_time(slot)

	if remaining_time <= 0:
		# Chest is ready
		chest.is_ready = true
		chest.is_unlocking = false
		chest_data.unlocking_slot = -1

		save_chests()
		chest_unlock_completed.emit(slot)

		# Auto-start next chest
		_auto_start_next_chest()
	else:
		# Update progress
		chest_progress_updated.emit(slot, remaining_time)

func _get_remaining_unlock_time(slot: int) -> float:
	if slot < 0 or slot >= MAX_CHEST_SLOTS:
		return 0.0

	if chest_data.slots[slot] == null:
		return 0.0

	var chest = chest_data.slots[slot]

	if chest.is_ready:
		return 0.0

	if not chest.is_unlocking:
		return chest.unlock_duration

	var elapsed = Time.get_unix_time_from_system() - chest.unlock_started_at
	var remaining = chest.unlock_duration - elapsed

	return max(0.0, remaining * UNLOCK_SPEED_MULTIPLIER)

func get_chest_info(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_CHEST_SLOTS:
		return {}

	if chest_data.slots[slot] == null:
		return {}

	var chest = chest_data.slots[slot]
	var chest_def = chest_definitions[chest.type]

	return {
		"type": chest.type,
		"name": chest_def.name,
		"is_unlocking": chest.is_unlocking,
		"is_ready": chest.is_ready,
		"remaining_time": _get_remaining_unlock_time(slot),
		"total_time": chest.unlock_duration,
		"gem_cost": _calculate_gem_cost(_get_remaining_unlock_time(slot), chest.type)
	}

func get_all_chest_slots() -> Array:
	var slots = []
	for i in range(MAX_CHEST_SLOTS):
		if chest_data.slots[i] != null:
			slots.append(get_chest_info(i))
		else:
			slots.append(null)
	return slots

func has_empty_slot() -> bool:
	return _find_empty_slot() != -1

func get_chest_statistics() -> Dictionary:
	return {
		"total_opened": chest_data.total_chests_opened,
		"cycle_position": chest_data.chest_cycle_position,
		"super_magical_progress": float(chest_data.super_magical_counter) / float(super_magical_cycle) * 100.0,
		"slots_used": get_used_slots_count(),
		"is_unlocking": chest_data.unlocking_slot != -1
	}

func get_used_slots_count() -> int:
	var count = 0
	for slot in chest_data.slots:
		if slot != null:
			count += 1
	return count

func save_chests() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(chest_data)
		file.store_string(json_string)
		file.close()
		print("Chest data saved successfully")
	else:
		push_error("Failed to save chest data")

func load_chests() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No chest save found, starting fresh")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			chest_data = json.data
			_initialize_chest_slots()
			print("Chest data loaded successfully")
			return true

	return false

func reset_chests() -> void:
	chest_data = {
		"slots": [],
		"unlocking_slot": -1,
		"chest_cycle_position": 0,
		"super_magical_counter": 0,
		"total_chests_opened": 0,
		"version": "1.0.0"
	}
	_initialize_chest_slots()
	save_chests()

func export_chest_data() -> String:
	return JSON.stringify(chest_data)

func import_chest_data(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		chest_data = json.data
		save_chests()
		return true

	return false