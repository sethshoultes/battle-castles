extends Node
class_name CurrencyManager

# Currency management system
# Handles gold (soft currency) and gems (premium currency)

signal currency_changed(currency_type: String, amount: int)
signal transaction_completed(transaction_id: String)
signal transaction_failed(reason: String)
signal insufficient_funds(currency_type: String, required: int, available: int)

const SAVE_PATH = "user://currency_data.json"
const TRANSACTION_LOG_PATH = "user://transaction_log.json"
const MAX_GOLD = 999999999
const MAX_GEMS = 999999
const MAX_LOG_ENTRIES = 1000

# Currency types
enum CurrencyType {
	GOLD,
	GEMS
}

# Currency data
var currency_data: Dictionary = {
	"gold": 1000,  # Starting gold
	"gems": 50,     # Starting gems
	"total_earned": {
		"gold": 1000,
		"gems": 50
	},
	"total_spent": {
		"gold": 0,
		"gems": 0
	},
	"version": "1.0.0"
}

# Transaction log
var transaction_log: Array = []

# Transaction types for logging
enum TransactionType {
	BATTLE_REWARD,
	CHEST_REWARD,
	QUEST_REWARD,
	ACHIEVEMENT_REWARD,
	CARD_UPGRADE,
	CHEST_UNLOCK,
	SHOP_PURCHASE,
	DONATION,
	REFUND,
	ADMIN_GRANT,
	OTHER
}

func _ready() -> void:
	load_currency()
	load_transaction_log()

func get_gold() -> int:
	return currency_data.gold

func get_gems() -> int:
	return currency_data.gems

func has_gold(amount: int) -> bool:
	return currency_data.gold >= amount

func has_gems(amount: int) -> bool:
	return currency_data.gems >= amount

func add_gold(amount: int, source: int = TransactionType.OTHER, description: String = "") -> bool:
	if amount <= 0:
		transaction_failed.emit("Invalid gold amount")
		return false

	var new_total = currency_data.gold + amount
	if new_total > MAX_GOLD:
		amount = MAX_GOLD - currency_data.gold
		new_total = MAX_GOLD

	currency_data.gold = new_total
	currency_data.total_earned.gold += amount

	# Log transaction
	var transaction_id = _log_transaction(CurrencyType.GOLD, amount, source, description, true)

	save_currency()
	currency_changed.emit("gold", currency_data.gold)
	transaction_completed.emit(transaction_id)
	return true

func add_gems(amount: int, source: int = TransactionType.OTHER, description: String = "") -> bool:
	if amount <= 0:
		transaction_failed.emit("Invalid gem amount")
		return false

	var new_total = currency_data.gems + amount
	if new_total > MAX_GEMS:
		amount = MAX_GEMS - currency_data.gems
		new_total = MAX_GEMS

	currency_data.gems = new_total
	currency_data.total_earned.gems += amount

	# Log transaction
	var transaction_id = _log_transaction(CurrencyType.GEMS, amount, source, description, true)

	save_currency()
	currency_changed.emit("gems", currency_data.gems)
	transaction_completed.emit(transaction_id)
	return true

func spend_gold(amount: int, purpose: int = TransactionType.OTHER, description: String = "") -> bool:
	if amount <= 0:
		transaction_failed.emit("Invalid gold amount")
		return false

	if currency_data.gold < amount:
		insufficient_funds.emit("gold", amount, currency_data.gold)
		transaction_failed.emit("Insufficient gold")
		return false

	currency_data.gold -= amount
	currency_data.total_spent.gold += amount

	# Log transaction
	var transaction_id = _log_transaction(CurrencyType.GOLD, -amount, purpose, description, false)

	save_currency()
	currency_changed.emit("gold", currency_data.gold)
	transaction_completed.emit(transaction_id)
	return true

func spend_gems(amount: int, purpose: int = TransactionType.OTHER, description: String = "") -> bool:
	if amount <= 0:
		transaction_failed.emit("Invalid gem amount")
		return false

	if currency_data.gems < amount:
		insufficient_funds.emit("gems", amount, currency_data.gems)
		transaction_failed.emit("Insufficient gems")
		return false

	currency_data.gems -= amount
	currency_data.total_spent.gems += amount

	# Log transaction
	var transaction_id = _log_transaction(CurrencyType.GEMS, -amount, purpose, description, false)

	save_currency()
	currency_changed.emit("gems", currency_data.gems)
	transaction_completed.emit(transaction_id)
	return true

func try_purchase(gold_cost: int, gem_cost: int, purpose: int = TransactionType.SHOP_PURCHASE, description: String = "") -> bool:
	# Check if player can afford the purchase
	if currency_data.gold < gold_cost:
		insufficient_funds.emit("gold", gold_cost, currency_data.gold)
		return false

	if currency_data.gems < gem_cost:
		insufficient_funds.emit("gems", gem_cost, currency_data.gems)
		return false

	# Process the purchase
	var success = true

	if gold_cost > 0:
		success = success and spend_gold(gold_cost, purpose, description)

	if gem_cost > 0 and success:
		success = success and spend_gems(gem_cost, purpose, description)

	# Rollback if partial failure (shouldn't happen but safety check)
	if not success:
		load_currency()  # Reload to rollback any partial changes
		transaction_failed.emit("Purchase failed")

	return success

func convert_gems_to_gold(gem_amount: int) -> bool:
	# Conversion rate: 1 gem = 100 gold
	var gold_value = gem_amount * 100

	if not has_gems(gem_amount):
		insufficient_funds.emit("gems", gem_amount, currency_data.gems)
		return false

	spend_gems(gem_amount, TransactionType.OTHER, "Gem to gold conversion")
	add_gold(gold_value, TransactionType.OTHER, "Gem to gold conversion")
	return true

func refund(currency_type: CurrencyType, amount: int, reason: String = "") -> bool:
	match currency_type:
		CurrencyType.GOLD:
			return add_gold(amount, TransactionType.REFUND, reason)
		CurrencyType.GEMS:
			return add_gems(amount, TransactionType.REFUND, reason)
		_:
			return false

func _log_transaction(currency_type: CurrencyType, amount: int, transaction_type: int, description: String, is_income: bool) -> String:
	var transaction_id = _generate_transaction_id()

	var transaction = {
		"id": transaction_id,
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(),
		"currency": "gold" if currency_type == CurrencyType.GOLD else "gems",
		"amount": amount,
		"type": transaction_type,
		"description": description,
		"is_income": is_income,
		"balance_after": {
			"gold": currency_data.gold,
			"gems": currency_data.gems
		}
	}

	transaction_log.append(transaction)

	# Trim log if too large
	if transaction_log.size() > MAX_LOG_ENTRIES:
		transaction_log = transaction_log.slice(-MAX_LOG_ENTRIES)

	save_transaction_log()
	return transaction_id

func _generate_transaction_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "TXN_%d_%04d" % [timestamp, random_suffix]

func get_transaction_history(limit: int = 50) -> Array:
	var start_index = max(0, transaction_log.size() - limit)
	return transaction_log.slice(start_index)

func get_transactions_by_type(transaction_type: int, limit: int = 50) -> Array:
	var filtered = []
	for transaction in transaction_log:
		if transaction.type == transaction_type:
			filtered.append(transaction)
			if filtered.size() >= limit:
				break
	return filtered

func get_daily_income() -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var day_start = current_time - (current_time % 86400)  # Start of current day

	var daily_income = {
		"gold": 0,
		"gems": 0
	}

	for transaction in transaction_log:
		if transaction.timestamp >= day_start and transaction.is_income:
			if transaction.currency == "gold":
				daily_income.gold += transaction.amount
			else:
				daily_income.gems += transaction.amount

	return daily_income

func get_spending_summary() -> Dictionary:
	var summary = {}

	for i in range(TransactionType.size()):
		summary[i] = {
			"gold": 0,
			"gems": 0,
			"count": 0
		}

	for transaction in transaction_log:
		if not transaction.is_income:
			var type = transaction.type
			if transaction.currency == "gold":
				summary[type].gold += abs(transaction.amount)
			else:
				summary[type].gems += abs(transaction.amount)
			summary[type].count += 1

	return summary

func get_statistics() -> Dictionary:
	return {
		"current_gold": currency_data.gold,
		"current_gems": currency_data.gems,
		"total_earned_gold": currency_data.total_earned.gold,
		"total_earned_gems": currency_data.total_earned.gems,
		"total_spent_gold": currency_data.total_spent.gold,
		"total_spent_gems": currency_data.total_spent.gems,
		"net_gold": currency_data.total_earned.gold - currency_data.total_spent.gold,
		"net_gems": currency_data.total_earned.gems - currency_data.total_spent.gems,
		"transactions_count": transaction_log.size()
	}

func validate_currency() -> bool:
	# Check for negative values
	if currency_data.gold < 0:
		push_error("Invalid gold amount: " + str(currency_data.gold))
		currency_data.gold = 0
		return false

	if currency_data.gems < 0:
		push_error("Invalid gem amount: " + str(currency_data.gems))
		currency_data.gems = 0
		return false

	# Check for exceeding max values
	if currency_data.gold > MAX_GOLD:
		currency_data.gold = MAX_GOLD

	if currency_data.gems > MAX_GEMS:
		currency_data.gems = MAX_GEMS

	return true

func save_currency() -> void:
	validate_currency()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(currency_data)
		file.store_string(json_string)
		file.close()
		print("Currency saved successfully")
	else:
		push_error("Failed to save currency data")

func load_currency() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No currency save found, using default values")
		save_currency()
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			currency_data = json.data
			validate_currency()
			currency_changed.emit("gold", currency_data.gold)
			currency_changed.emit("gems", currency_data.gems)
			print("Currency loaded successfully")
			return true

	return false

func save_transaction_log() -> void:
	var file = FileAccess.open(TRANSACTION_LOG_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(transaction_log)
		file.store_string(json_string)
		file.close()

func load_transaction_log() -> void:
	if not FileAccess.file_exists(TRANSACTION_LOG_PATH):
		return

	var file = FileAccess.open(TRANSACTION_LOG_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			transaction_log = json.data

func reset_currency() -> void:
	currency_data = {
		"gold": 1000,
		"gems": 50,
		"total_earned": {
			"gold": 1000,
			"gems": 50
		},
		"total_spent": {
			"gold": 0,
			"gems": 0
		},
		"version": "1.0.0"
	}
	transaction_log.clear()
	save_currency()
	save_transaction_log()
	currency_changed.emit("gold", currency_data.gold)
	currency_changed.emit("gems", currency_data.gems)

func export_data() -> String:
	return JSON.stringify({
		"currency": currency_data,
		"transactions": transaction_log
	})

func import_data(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		var imported_data = json.data
		if imported_data.has("currency"):
			currency_data = imported_data.currency
			validate_currency()
		if imported_data.has("transactions"):
			transaction_log = imported_data.transactions

		save_currency()
		save_transaction_log()
		currency_changed.emit("gold", currency_data.gold)
		currency_changed.emit("gems", currency_data.gems)
		return true

	return false