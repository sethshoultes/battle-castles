extends Node
class_name CardCollection

# Card collection management system
# Handles owned cards, quantities, levels, and upgrades

signal card_unlocked(card_id: String)
signal card_upgraded(card_id: String, new_level: int)
signal collection_updated()
signal upgrade_available(card_id: String)

const SAVE_PATH = "user://card_collection.json"
const MAX_CARD_LEVEL = 9

# Card rarities and their properties
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Card requirements per level
var upgrade_requirements = {
	Rarity.COMMON: {
		"cards": [0, 2, 4, 10, 20, 50, 100, 200, 400],
		"gold": [0, 5, 20, 50, 150, 400, 1000, 2000, 4000]
	},
	Rarity.RARE: {
		"cards": [0, 2, 4, 10, 20, 50, 100, 200],
		"gold": [0, 50, 150, 400, 1000, 2000, 4000, 8000]
	},
	Rarity.EPIC: {
		"cards": [0, 2, 4, 10, 20, 50, 100],
		"gold": [0, 400, 1000, 2000, 4000, 8000, 15000]
	},
	Rarity.LEGENDARY: {
		"cards": [0, 2, 4, 6, 10, 20],
		"gold": [0, 5000, 20000, 35000, 50000, 100000]
	}
}

# Collection data
var collection_data: Dictionary = {
	"cards": {},  # card_id: {level, count, total_collected}
	"unlocked_cards": [],
	"new_cards": [],  # Cards that are marked as new
	"favorites": [],
	"version": "1.0.0"
}

# Card definitions (loaded from game data)
var card_definitions: Dictionary = {}

func _ready() -> void:
	_load_card_definitions()
	load_collection()

func _load_card_definitions() -> void:
	# Load card definitions from game data
	# This would normally load from a JSON file or resource
	card_definitions = {
		# Troops - Common (basic units)
		"knight": {"name": "Knight", "rarity": Rarity.COMMON, "elixir": 3, "type": "troop"},
		"archer": {"name": "Archer", "rarity": Rarity.COMMON, "elixir": 3, "type": "troop"},
		"goblin": {"name": "Goblin", "rarity": Rarity.COMMON, "elixir": 2, "type": "troop"},

		# Troops - Rare (medium units)
		"barbarian": {"name": "Barbarians", "rarity": Rarity.RARE, "elixir": 5, "type": "troop"},
		"minion": {"name": "Minions", "rarity": Rarity.RARE, "elixir": 3, "type": "troop"},
		"musketeer": {"name": "Musketeer", "rarity": Rarity.RARE, "elixir": 4, "type": "troop"},

		# Troops - Epic (special units)
		"baby_dragon": {"name": "Baby Dragon", "rarity": Rarity.EPIC, "elixir": 4, "type": "troop"},
		"valkyrie": {"name": "Valkyrie", "rarity": Rarity.EPIC, "elixir": 4, "type": "troop"},
		"wizard": {"name": "Wizard", "rarity": Rarity.EPIC, "elixir": 5, "type": "troop"},

		# Troops - Legendary (powerful units)
		"giant": {"name": "Giant", "rarity": Rarity.LEGENDARY, "elixir": 5, "type": "troop"},
		"mini_pekka": {"name": "Mini P.E.K.K.A", "rarity": Rarity.LEGENDARY, "elixir": 4, "type": "troop"},
		"skeleton": {"name": "Skeleton Army", "rarity": Rarity.LEGENDARY, "elixir": 3, "type": "troop"},

		# Other units (not yet implemented as .tres files)
		"prince": {"name": "Prince", "rarity": Rarity.EPIC, "elixir": 5, "type": "troop"},
		"dragon": {"name": "Baby Dragon", "rarity": Rarity.EPIC, "elixir": 4, "type": "troop"},
		"pekka": {"name": "P.E.K.K.A", "rarity": Rarity.EPIC, "elixir": 7, "type": "troop"},
		"ice_wizard": {"name": "Ice Wizard", "rarity": Rarity.LEGENDARY, "elixir": 3, "type": "troop"},
		"princess": {"name": "Princess", "rarity": Rarity.LEGENDARY, "elixir": 3, "type": "troop"},

		# Spells
		"fireball": {"name": "Fireball", "rarity": Rarity.RARE, "elixir": 4, "type": "spell"},
		"arrows": {"name": "Arrows", "rarity": Rarity.COMMON, "elixir": 3, "type": "spell"},
		"lightning": {"name": "Lightning", "rarity": Rarity.EPIC, "elixir": 6, "type": "spell"},
		"freeze": {"name": "Freeze", "rarity": Rarity.EPIC, "elixir": 4, "type": "spell"},
		"poison": {"name": "Poison", "rarity": Rarity.EPIC, "elixir": 4, "type": "spell"},
		"zap": {"name": "Zap", "rarity": Rarity.COMMON, "elixir": 2, "type": "spell"},
		"rage": {"name": "Rage", "rarity": Rarity.COMMON, "elixir": 2, "type": "spell"},

		# Buildings
		"cannon": {"name": "Cannon", "rarity": Rarity.COMMON, "elixir": 3, "type": "building"},
		"tesla": {"name": "Tesla", "rarity": Rarity.COMMON, "elixir": 4, "type": "building"},
		"bomb_tower": {"name": "Bomb Tower", "rarity": Rarity.RARE, "elixir": 4, "type": "building"},
		"inferno_tower": {"name": "Inferno Tower", "rarity": Rarity.RARE, "elixir": 5, "type": "building"},
		"mortar": {"name": "Mortar", "rarity": Rarity.COMMON, "elixir": 4, "type": "building"},
		"xbow": {"name": "X-Bow", "rarity": Rarity.EPIC, "elixir": 6, "type": "building"},
	}

func add_cards(card_id: String, amount: int) -> void:
	if not card_definitions.has(card_id):
		push_error("Unknown card ID: " + card_id)
		return

	var is_new_unlock = false

	# Initialize card data if not exists
	if not collection_data.cards.has(card_id):
		collection_data.cards[card_id] = {
			"level": 1,
			"count": 0,
			"total_collected": 0
		}
		collection_data.unlocked_cards.append(card_id)
		collection_data.new_cards.append(card_id)
		is_new_unlock = true

	# Add cards
	collection_data.cards[card_id].count += amount
	collection_data.cards[card_id].total_collected += amount

	# Check for upgrade availability
	if can_upgrade_card(card_id):
		upgrade_available.emit(card_id)

	save_collection()
	collection_updated.emit()

	if is_new_unlock:
		card_unlocked.emit(card_id)

func remove_cards(card_id: String, amount: int) -> bool:
	if not collection_data.cards.has(card_id):
		return false

	if collection_data.cards[card_id].count < amount:
		return false

	collection_data.cards[card_id].count -= amount
	save_collection()
	collection_updated.emit()
	return true

func upgrade_card(card_id: String, currency_manager: Node) -> bool:
	if not can_upgrade_card(card_id):
		return false

	var card_data = collection_data.cards[card_id]
	var card_def = card_definitions[card_id]
	var rarity = card_def.rarity
	var current_level = card_data.level

	# Get upgrade requirements
	var cards_required = upgrade_requirements[rarity].cards[current_level]
	var gold_required = upgrade_requirements[rarity].gold[current_level]

	# Check and consume resources
	if card_data.count < cards_required:
		return false

	if not currency_manager.spend_gold(gold_required):
		return false

	# Perform upgrade
	card_data.count -= cards_required
	card_data.level += 1

	save_collection()
	collection_updated.emit()
	card_upgraded.emit(card_id, card_data.level)

	# Check if can upgrade again
	if can_upgrade_card(card_id):
		upgrade_available.emit(card_id)

	return true

func can_upgrade_card(card_id: String) -> bool:
	if not collection_data.cards.has(card_id):
		return false

	var card_data = collection_data.cards[card_id]
	var card_def = card_definitions[card_id]
	var rarity = card_def.rarity
	var current_level = card_data.level

	# Check max level
	var max_level = upgrade_requirements[rarity].cards.size()
	if current_level >= max_level:
		return false

	# Check card requirements
	var cards_required = upgrade_requirements[rarity].cards[current_level]
	return card_data.count >= cards_required

func get_upgrade_cost(card_id: String) -> Dictionary:
	if not collection_data.cards.has(card_id):
		return {"cards": 0, "gold": 0}

	var card_data = collection_data.cards[card_id]
	var card_def = card_definitions[card_id]
	var rarity = card_def.rarity
	var current_level = card_data.level

	var max_level = upgrade_requirements[rarity].cards.size()
	if current_level >= max_level:
		return {"cards": 0, "gold": 0}

	return {
		"cards": upgrade_requirements[rarity].cards[current_level],
		"gold": upgrade_requirements[rarity].gold[current_level]
	}

func get_card_level(card_id: String) -> int:
	if not collection_data.cards.has(card_id):
		return 0
	return collection_data.cards[card_id].level

func get_card_count(card_id: String) -> int:
	if not collection_data.cards.has(card_id):
		return 0
	return collection_data.cards[card_id].count

func is_card_unlocked(card_id: String) -> bool:
	return card_id in collection_data.unlocked_cards

func get_unlocked_cards() -> Array:
	return collection_data.unlocked_cards.duplicate()

func get_cards_by_rarity(rarity: Rarity) -> Array:
	var cards = []
	for card_id in collection_data.unlocked_cards:
		if card_definitions[card_id].rarity == rarity:
			cards.append(card_id)
	return cards

func get_cards_by_type(type: String) -> Array:
	var cards = []
	for card_id in collection_data.unlocked_cards:
		if card_definitions[card_id].type == type:
			cards.append(card_id)
	return cards

func mark_card_as_seen(card_id: String) -> void:
	if card_id in collection_data.new_cards:
		collection_data.new_cards.erase(card_id)
		save_collection()

func toggle_favorite(card_id: String) -> void:
	if card_id in collection_data.favorites:
		collection_data.favorites.erase(card_id)
	else:
		collection_data.favorites.append(card_id)
	save_collection()
	collection_updated.emit()

func is_favorite(card_id: String) -> bool:
	return card_id in collection_data.favorites

func get_collection_progress() -> Dictionary:
	var total_cards = card_definitions.size()
	var unlocked_cards = collection_data.unlocked_cards.size()
	var max_level_cards = 0

	for card_id in collection_data.cards:
		var card_data = collection_data.cards[card_id]
		var card_def = card_definitions[card_id]
		var rarity = card_def.rarity
		var max_level = upgrade_requirements[rarity].cards.size()

		if card_data.level >= max_level:
			max_level_cards += 1

	return {
		"total_cards": total_cards,
		"unlocked_cards": unlocked_cards,
		"max_level_cards": max_level_cards,
		"unlock_percentage": float(unlocked_cards) / float(total_cards) * 100.0,
		"max_level_percentage": float(max_level_cards) / float(total_cards) * 100.0
	}

func get_total_card_value() -> int:
	var total_value = 0

	for card_id in collection_data.cards:
		var card_data = collection_data.cards[card_id]
		var card_def = card_definitions[card_id]
		var rarity = card_def.rarity

		# Calculate value based on rarity and level
		var base_value = 0
		match rarity:
			Rarity.COMMON:
				base_value = 5
			Rarity.RARE:
				base_value = 50
			Rarity.EPIC:
				base_value = 500
			Rarity.LEGENDARY:
				base_value = 20000

		total_value += base_value * card_data.level
		total_value += base_value * card_data.count / 10

	return total_value

func save_collection() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(collection_data)
		file.store_string(json_string)
		file.close()
		print("Collection saved successfully")
	else:
		push_error("Failed to save card collection")

func load_collection() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No collection save found, starting fresh")
		_initialize_starter_collection()
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			collection_data = json.data
			collection_updated.emit()
			print("Collection loaded successfully")
			return true

	return false

func _initialize_starter_collection() -> void:
	# Give player some starter cards
	var starter_cards = [
		{"id": "knight", "count": 1},
		{"id": "archer", "count": 2},
		{"id": "goblin", "count": 4},
		{"id": "fireball", "count": 1},
		{"id": "arrows", "count": 2},
		{"id": "cannon", "count": 1},
		{"id": "musketeer", "count": 1},
		{"id": "giant", "count": 1}
	]

	for card_info in starter_cards:
		add_cards(card_info.id, card_info.count)

func reset_collection() -> void:
	collection_data = {
		"cards": {},
		"unlocked_cards": [],
		"new_cards": [],
		"favorites": [],
		"version": "1.0.0"
	}
	save_collection()
	collection_updated.emit()

func export_collection() -> String:
	return JSON.stringify(collection_data)

func import_collection(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		collection_data = json.data
		save_collection()
		collection_updated.emit()
		return true

	return false