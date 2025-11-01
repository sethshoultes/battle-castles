extends Node
class_name DeckManager

# Deck management system
# Handles deck creation, validation, and import/export

signal deck_created(deck_slot: int)
signal deck_updated(deck_slot: int)
signal deck_deleted(deck_slot: int)
signal active_deck_changed(deck_slot: int)
signal deck_validation_failed(reason: String)

const SAVE_PATH = "user://deck_data.json"
const MAX_DECK_SLOTS = 3
const CARDS_PER_DECK = 8
const MAX_ELIXIR_COST = 10.0

# Deck data structure
var deck_data: Dictionary = {
	"active_deck": 0,
	"decks": [],
	"deck_history": [],  # Previous deck configurations
	"version": "1.0.0"
}

# Card definitions reference (set by card_collection)
var card_definitions: Dictionary = {}

func _ready() -> void:
	load_decks()
	_initialize_empty_decks()

func _initialize_empty_decks() -> void:
	while deck_data.decks.size() < MAX_DECK_SLOTS:
		deck_data.decks.append({
			"name": "Deck %d" % (deck_data.decks.size() + 1),
			"cards": [],
			"average_elixir": 0.0,
			"created_at": Time.get_datetime_string_from_system(),
			"last_modified": Time.get_datetime_string_from_system(),
			"wins": 0,
			"losses": 0,
			"draws": 0
		})

func set_card_definitions(definitions: Dictionary) -> void:
	card_definitions = definitions

func create_deck(slot: int, name: String, cards: Array) -> bool:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		deck_validation_failed.emit("Invalid deck slot")
		return false

	var validation_result = validate_deck(cards)
	if not validation_result.valid:
		deck_validation_failed.emit(validation_result.reason)
		return false

	# Save current deck to history
	if not deck_data.decks[slot].cards.is_empty():
		_add_to_history(deck_data.decks[slot])

	# Create new deck
	deck_data.decks[slot] = {
		"name": name,
		"cards": cards.duplicate(),
		"average_elixir": calculate_average_elixir(cards),
		"created_at": Time.get_datetime_string_from_system(),
		"last_modified": Time.get_datetime_string_from_system(),
		"wins": 0,
		"losses": 0,
		"draws": 0
	}

	save_decks()
	deck_created.emit(slot)
	return true

func update_deck(slot: int, cards: Array) -> bool:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		deck_validation_failed.emit("Invalid deck slot")
		return false

	var validation_result = validate_deck(cards)
	if not validation_result.valid:
		deck_validation_failed.emit(validation_result.reason)
		return false

	# Save current deck to history
	if not deck_data.decks[slot].cards.is_empty():
		_add_to_history(deck_data.decks[slot])

	# Update deck
	deck_data.decks[slot].cards = cards.duplicate()
	deck_data.decks[slot].average_elixir = calculate_average_elixir(cards)
	deck_data.decks[slot].last_modified = Time.get_datetime_string_from_system()

	save_decks()
	deck_updated.emit(slot)
	return true

func rename_deck(slot: int, new_name: String) -> void:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return

	deck_data.decks[slot].name = new_name
	deck_data.decks[slot].last_modified = Time.get_datetime_string_from_system()

	save_decks()
	deck_updated.emit(slot)

func clear_deck(slot: int) -> void:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return

	# Save to history before clearing
	if not deck_data.decks[slot].cards.is_empty():
		_add_to_history(deck_data.decks[slot])

	deck_data.decks[slot].cards.clear()
	deck_data.decks[slot].average_elixir = 0.0
	deck_data.decks[slot].last_modified = Time.get_datetime_string_from_system()

	save_decks()
	deck_deleted.emit(slot)

func duplicate_deck(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= MAX_DECK_SLOTS:
		return false
	if to_slot < 0 or to_slot >= MAX_DECK_SLOTS:
		return false

	var source_deck = deck_data.decks[from_slot]
	if source_deck.cards.is_empty():
		return false

	# Save target deck to history
	if not deck_data.decks[to_slot].cards.is_empty():
		_add_to_history(deck_data.decks[to_slot])

	deck_data.decks[to_slot] = source_deck.duplicate(true)
	deck_data.decks[to_slot].name = source_deck.name + " (Copy)"
	deck_data.decks[to_slot].created_at = Time.get_datetime_string_from_system()
	deck_data.decks[to_slot].last_modified = Time.get_datetime_string_from_system()
	deck_data.decks[to_slot].wins = 0
	deck_data.decks[to_slot].losses = 0
	deck_data.decks[to_slot].draws = 0

	save_decks()
	deck_created.emit(to_slot)
	return true

func set_active_deck(slot: int) -> void:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return

	if deck_data.decks[slot].cards.is_empty():
		deck_validation_failed.emit("Cannot activate empty deck")
		return

	deck_data.active_deck = slot
	save_decks()
	active_deck_changed.emit(slot)

func get_active_deck() -> Dictionary:
	return deck_data.decks[deck_data.active_deck].duplicate(true)

func get_deck(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return {}
	return deck_data.decks[slot].duplicate(true)

func get_all_decks() -> Array:
	return deck_data.decks.duplicate(true)

func validate_deck(cards: Array) -> Dictionary:
	var result = {"valid": false, "reason": ""}

	# Check card count
	if cards.size() != CARDS_PER_DECK:
		result.reason = "Deck must contain exactly %d cards" % CARDS_PER_DECK
		return result

	# Check for duplicates
	var unique_cards = {}
	for card_id in cards:
		if unique_cards.has(card_id):
			result.reason = "Deck cannot contain duplicate cards"
			return result
		unique_cards[card_id] = true

	# Check if all cards exist
	for card_id in cards:
		if not card_definitions.has(card_id):
			result.reason = "Invalid card: " + card_id
			return result

	# Check average elixir cost
	var avg_elixir = calculate_average_elixir(cards)
	if avg_elixir > MAX_ELIXIR_COST:
		result.reason = "Average elixir cost too high (max: %.1f)" % MAX_ELIXIR_COST
		return result

	result.valid = true
	return result

func calculate_average_elixir(cards: Array) -> float:
	if cards.is_empty():
		return 0.0

	var total_elixir = 0
	for card_id in cards:
		if card_definitions.has(card_id):
			total_elixir += card_definitions[card_id].elixir

	return float(total_elixir) / float(cards.size())

func export_deck(slot: int) -> String:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return ""

	var deck = deck_data.decks[slot]
	if deck.cards.is_empty():
		return ""

	# Create a compact deck code
	var deck_code = _encode_deck(deck.cards)
	return deck_code

func import_deck(deck_code: String, slot: int = -1) -> bool:
	var cards = _decode_deck(deck_code)
	if cards.is_empty():
		deck_validation_failed.emit("Invalid deck code")
		return false

	var validation_result = validate_deck(cards)
	if not validation_result.valid:
		deck_validation_failed.emit(validation_result.reason)
		return false

	# Find available slot if not specified
	if slot == -1:
		for i in range(MAX_DECK_SLOTS):
			if deck_data.decks[i].cards.is_empty():
				slot = i
				break

	if slot == -1:
		deck_validation_failed.emit("No empty deck slots available")
		return false

	return create_deck(slot, "Imported Deck", cards)

func _encode_deck(cards: Array) -> String:
	# Simple encoding: join card IDs with dashes
	# In a real implementation, this could be compressed/encrypted
	var sorted_cards = cards.duplicate()
	sorted_cards.sort()
	return "-".join(sorted_cards)

func _decode_deck(deck_code: String) -> Array:
	# Simple decoding: split by dashes
	if deck_code.is_empty():
		return []

	var cards = deck_code.split("-")
	if cards.size() != CARDS_PER_DECK:
		return []

	# Validate all cards exist
	for card_id in cards:
		if not card_definitions.has(card_id):
			return []

	return cards

func record_battle_result(slot: int, result: String) -> void:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return

	match result.to_lower():
		"win":
			deck_data.decks[slot].wins += 1
		"loss":
			deck_data.decks[slot].losses += 1
		"draw":
			deck_data.decks[slot].draws += 1

	save_decks()

func get_deck_statistics(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return {}

	var deck = deck_data.decks[slot]
	var total_games = deck.wins + deck.losses + deck.draws

	return {
		"wins": deck.wins,
		"losses": deck.losses,
		"draws": deck.draws,
		"total_games": total_games,
		"win_rate": 0.0 if total_games == 0 else float(deck.wins) / float(total_games) * 100.0,
		"average_elixir": deck.average_elixir
	}

func _add_to_history(deck: Dictionary) -> void:
	deck_data.deck_history.append({
		"name": deck.name,
		"cards": deck.cards.duplicate(),
		"saved_at": Time.get_datetime_string_from_system()
	})

	# Keep only last 20 deck configurations
	if deck_data.deck_history.size() > 20:
		deck_data.deck_history.pop_front()

func get_deck_history() -> Array:
	return deck_data.deck_history.duplicate(true)

func restore_from_history(history_index: int, slot: int) -> bool:
	if history_index < 0 or history_index >= deck_data.deck_history.size():
		return false

	var historical_deck = deck_data.deck_history[history_index]
	return create_deck(slot, historical_deck.name + " (Restored)", historical_deck.cards)

func get_deck_composition(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_DECK_SLOTS:
		return {}

	var deck = deck_data.decks[slot]
	var composition = {
		"troops": 0,
		"spells": 0,
		"buildings": 0,
		"win_conditions": 0,
		"tank_killers": 0,
		"splash_damage": 0,
		"air_targeting": 0
	}

	for card_id in deck.cards:
		if card_definitions.has(card_id):
			var card_def = card_definitions[card_id]

			# Count by type
			match card_def.type:
				"troop":
					composition.troops += 1
				"spell":
					composition.spells += 1
				"building":
					composition.buildings += 1

	return composition

func save_decks() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(deck_data)
		file.store_string(json_string)
		file.close()
		print("Decks saved successfully")
	else:
		push_error("Failed to save deck data")

func load_decks() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No deck save found, creating default decks")
		_create_default_decks()
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			deck_data = json.data
			_initialize_empty_decks()
			print("Decks loaded successfully")
			return true

	return false

func _create_default_decks() -> void:
	# Create some starter decks for new players
	var starter_deck_1 = ["knight", "archer", "goblin", "giant", "fireball", "arrows", "cannon", "musketeer"]
	var starter_deck_2 = ["barbarian", "wizard", "goblin", "giant", "arrows", "rage", "tesla", "musketeer"]

	create_deck(0, "Starter Deck", starter_deck_1)
	create_deck(1, "Alternative Deck", starter_deck_2)
	set_active_deck(0)

func reset_decks() -> void:
	deck_data = {
		"active_deck": 0,
		"decks": [],
		"deck_history": [],
		"version": "1.0.0"
	}
	_initialize_empty_decks()
	save_decks()

func export_all_decks() -> String:
	return JSON.stringify(deck_data)

func import_all_decks(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		deck_data = json.data
		save_decks()
		return true

	return false