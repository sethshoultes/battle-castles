extends Control

class_name DeckBuilderUI

# UI Elements
@onready var deck_name_label: Label = $DeckPanel/Header/DeckName
@onready var deck_slots_container: GridContainer = $DeckPanel/ScrollContainer/DeckSlotsContainer
@onready var card_collection_container: GridContainer = $CollectionPanel/ScrollContainer/CardCollectionContainer
@onready var save_button: Button = $ButtonContainer/SaveButton
@onready var cancel_button: Button = $ButtonContainer/CancelButton
@onready var deck_stats_panel: Panel = $StatsPanel

# Deck stats
@onready var average_elixir_label: Label = $StatsPanel/VBoxContainer/AverageElixir
@onready var card_count_label: Label = $StatsPanel/VBoxContainer/CardCount
@onready var deck_validation_label: Label = $StatsPanel/VBoxContainer/ValidationStatus

# Filter buttons
@onready var filter_all_button: Button = $CollectionPanel/FilterContainer/AllButton
@onready var filter_troops_button: Button = $CollectionPanel/FilterContainer/TroopsButton
@onready var filter_spells_button: Button = $CollectionPanel/FilterContainer/SpellsButton
@onready var filter_buildings_button: Button = $CollectionPanel/FilterContainer/BuildingsButton

# Search
@onready var search_line_edit: LineEdit = $CollectionPanel/SearchContainer/SearchLineEdit
@onready var sort_option_button: OptionButton = $CollectionPanel/SearchContainer/SortOptionButton

# Deck data
var current_deck: Array = []
var max_deck_size: int = 8
var collection_cards: Array = []
var filtered_cards: Array = []
var current_filter: String = "all"
var deck_modified: bool = false

# Card slot references
var deck_card_slots: Array = []
var collection_card_slots: Array = []

# Signals
signal deck_saved(deck: Array)
signal deck_cancelled()
signal card_info_requested(card: Resource)

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_create_deck_slots()
	_load_card_collection()

func _setup_ui() -> void:
	# Set up grid containers
	deck_slots_container.columns = 4

	# Collection can show more cards
	card_collection_container.columns = 6

	# Set up sort options
	sort_option_button.add_item("Elixir Cost")
	sort_option_button.add_item("Rarity")
	sort_option_button.add_item("Type")
	sort_option_button.add_item("Name")
	sort_option_button.selected = 0

	# Initial button states
	save_button.disabled = true
	filter_all_button.button_pressed = true

func _connect_signals() -> void:
	# Buttons
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Filters
	filter_all_button.pressed.connect(_on_filter_changed.bind("all"))
	filter_troops_button.pressed.connect(_on_filter_changed.bind("troops"))
	filter_spells_button.pressed.connect(_on_filter_changed.bind("spells"))
	filter_buildings_button.pressed.connect(_on_filter_changed.bind("buildings"))

	# Search and sort
	search_line_edit.text_changed.connect(_on_search_text_changed)
	sort_option_button.item_selected.connect(_on_sort_changed)

func _create_deck_slots() -> void:
	# Create 8 deck slots
	for i in range(max_deck_size):
		var slot = _create_card_slot(true, i)
		deck_slots_container.add_child(slot)
		deck_card_slots.append(slot)

func _create_card_slot(is_deck_slot: bool, index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(80, 100)
	slot.name = "Slot_" + str(index)

	# Background panel
	var background = Panel.new()
	background.name = "Background"
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0

	var style = StyleBoxFlat.new()
	if is_deck_slot:
		style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
		style.border_color = Color(0.3, 0.3, 0.4, 1.0)
	else:
		style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
		style.border_color = Color(0.25, 0.25, 0.3, 1.0)

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	background.add_theme_stylebox_override("panel", style)
	slot.add_child(background)

	# Card display area
	var card_display = Control.new()
	card_display.name = "CardDisplay"
	card_display.anchor_right = 1.0
	card_display.anchor_bottom = 1.0
	card_display.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(card_display)

	# Empty slot label
	var empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.anchor_right = 1.0
	empty_label.anchor_bottom = 1.0
	empty_label.text = "+"
	empty_label.add_theme_font_size_override("font_size", 32)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.modulate = Color(0.5, 0.5, 0.5, 0.5)
	card_display.add_child(empty_label)

	# Set up interaction
	slot.gui_input.connect(_on_slot_gui_input.bind(slot, is_deck_slot, index))

	return slot

func _load_card_collection() -> void:
	# Load available cards from player's collection
	# This would normally load from game data
	# For now, create placeholder cards
	for i in range(30):
		var card_data = {
			"id": "card_" + str(i),
			"name": "Card " + str(i),
			"elixir_cost": (i % 8) + 1,
			"type": ["troops", "spells", "buildings"][i % 3],
			"rarity": ["common", "rare", "epic", "legendary"][i % 4],
			"level": 1,
			"owned": true
		}
		collection_cards.append(card_data)

	_apply_filter()

func _apply_filter() -> void:
	filtered_cards.clear()

	for card in collection_cards:
		var matches_filter = false

		match current_filter:
			"all":
				matches_filter = true
			"troops":
				matches_filter = card.type == "troops"
			"spells":
				matches_filter = card.type == "spells"
			"buildings":
				matches_filter = card.type == "buildings"

		# Apply search filter
		if matches_filter and not search_line_edit.text.is_empty():
			matches_filter = card.name.to_lower().contains(search_line_edit.text.to_lower())

		if matches_filter:
			filtered_cards.append(card)

	_sort_cards()
	_display_collection()

func _sort_cards() -> void:
	match sort_option_button.selected:
		0: # Elixir Cost
			filtered_cards.sort_custom(func(a, b): return a.elixir_cost < b.elixir_cost)
		1: # Rarity
			filtered_cards.sort_custom(func(a, b): return _get_rarity_value(a.rarity) > _get_rarity_value(b.rarity))
		2: # Type
			filtered_cards.sort_custom(func(a, b): return a.type < b.type)
		3: # Name
			filtered_cards.sort_custom(func(a, b): return a.name < b.name)

func _get_rarity_value(rarity: String) -> int:
	match rarity:
		"common": return 0
		"rare": return 1
		"epic": return 2
		"legendary": return 3
		_: return 0

func _display_collection() -> void:
	# Clear existing collection display
	for child in card_collection_container.get_children():
		child.queue_free()
	collection_card_slots.clear()

	# Create card slots for filtered collection
	for i in range(filtered_cards.size()):
		var slot = _create_collection_card_slot(filtered_cards[i], i)
		card_collection_container.add_child(slot)
		collection_card_slots.append(slot)

func _create_collection_card_slot(card_data: Dictionary, index: int) -> Control:
	var slot = _create_card_slot(false, index)

	# Update the display with card data
	var card_display = slot.get_node("CardDisplay")
	var empty_label = card_display.get_node("EmptyLabel")
	empty_label.visible = false

	# Add card visual
	var card_visual = Panel.new()
	card_visual.name = "CardVisual"
	card_visual.anchor_right = 1.0
	card_visual.anchor_bottom = 0.75
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Set color based on type
	var visual_style = StyleBoxFlat.new()
	match card_data.type:
		"troops":
			visual_style.bg_color = Color(0.3, 0.5, 0.3, 0.8)
		"spells":
			visual_style.bg_color = Color(0.5, 0.3, 0.5, 0.8)
		"buildings":
			visual_style.bg_color = Color(0.4, 0.4, 0.3, 0.8)

	card_visual.add_theme_stylebox_override("panel", visual_style)
	card_display.add_child(card_visual)

	# Add elixir cost
	var elixir_label = Label.new()
	elixir_label.name = "ElixirCost"
	elixir_label.anchor_top = 0.75
	elixir_label.anchor_bottom = 1.0
	elixir_label.anchor_right = 0.3
	elixir_label.text = str(card_data.elixir_cost)
	elixir_label.add_theme_font_size_override("font_size", 16)
	elixir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elixir_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_display.add_child(elixir_label)

	# Store card data
	slot.set_meta("card_data", card_data)

	# Check if card is already in deck
	var is_in_deck = _is_card_in_deck(card_data.id)
	if is_in_deck:
		slot.modulate = Color(0.5, 0.5, 0.5, 0.5)

	return slot

func _is_card_in_deck(card_id: String) -> bool:
	for card in current_deck:
		if card.id == card_id:
			return true
	return false

func _on_slot_gui_input(event: InputEvent, slot: Control, is_deck_slot: bool, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_deck_slot:
				_handle_deck_slot_click(slot, index)
			else:
				_handle_collection_slot_click(slot, index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Show card info
			var card_data = slot.get_meta("card_data", null)
			if card_data:
				card_info_requested.emit(card_data)

func _handle_deck_slot_click(slot: Control, index: int) -> void:
	if index < current_deck.size():
		# Remove card from deck
		var removed_card = current_deck[index]
		current_deck.remove_at(index)
		_update_deck_display()
		_update_collection_availability()
		_update_deck_stats()
		deck_modified = true
		_validate_deck()

func _handle_collection_slot_click(slot: Control, index: int) -> void:
	if index >= filtered_cards.size():
		return

	var card_data = filtered_cards[index]

	# Check if card is already in deck
	if _is_card_in_deck(card_data.id):
		return

	# Check if deck is full
	if current_deck.size() >= max_deck_size:
		_show_deck_full_message()
		return

	# Add card to deck
	current_deck.append(card_data)
	_update_deck_display()
	_update_collection_availability()
	_update_deck_stats()
	deck_modified = true
	_validate_deck()

func _update_deck_display() -> void:
	# Clear all deck slots first
	for i in range(deck_card_slots.size()):
		var slot = deck_card_slots[i]
		var card_display = slot.get_node("CardDisplay")

		# Remove existing card visuals
		for child in card_display.get_children():
			if child.name != "EmptyLabel":
				child.queue_free()

		# Show/hide empty label
		var empty_label = card_display.get_node("EmptyLabel")
		empty_label.visible = i >= current_deck.size()

		# Add card if exists
		if i < current_deck.size():
			_add_card_to_slot(slot, current_deck[i])

func _add_card_to_slot(slot: Control, card_data: Dictionary) -> void:
	var card_display = slot.get_node("CardDisplay")

	# Add card visual (similar to collection display)
	var card_visual = Panel.new()
	card_visual.name = "CardVisual"
	card_visual.anchor_right = 1.0
	card_visual.anchor_bottom = 0.75
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var visual_style = StyleBoxFlat.new()
	match card_data.type:
		"troops":
			visual_style.bg_color = Color(0.3, 0.5, 0.3, 0.8)
		"spells":
			visual_style.bg_color = Color(0.5, 0.3, 0.5, 0.8)
		"buildings":
			visual_style.bg_color = Color(0.4, 0.4, 0.3, 0.8)

	card_visual.add_theme_stylebox_override("panel", visual_style)
	card_display.add_child(card_visual)

	# Add elixir cost
	var elixir_label = Label.new()
	elixir_label.name = "ElixirCost"
	elixir_label.anchor_top = 0.75
	elixir_label.anchor_bottom = 1.0
	elixir_label.anchor_right = 0.3
	elixir_label.text = str(card_data.elixir_cost)
	elixir_label.add_theme_font_size_override("font_size", 16)
	elixir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elixir_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_display.add_child(elixir_label)

	slot.set_meta("card_data", card_data)

func _update_collection_availability() -> void:
	# Update the visual state of collection cards
	for i in range(collection_card_slots.size()):
		var slot = collection_card_slots[i]
		var card_data = slot.get_meta("card_data", null)
		if card_data:
			var is_in_deck = _is_card_in_deck(card_data.id)
			slot.modulate = Color(0.5, 0.5, 0.5, 0.5) if is_in_deck else Color.WHITE

func _update_deck_stats() -> void:
	# Calculate average elixir
	var total_elixir = 0.0
	for card in current_deck:
		total_elixir += card.elixir_cost

	var avg_elixir = total_elixir / max(current_deck.size(), 1)
	average_elixir_label.text = "Avg Elixir: %.1f" % avg_elixir

	# Update card count
	card_count_label.text = "Cards: %d/%d" % [current_deck.size(), max_deck_size]

func _validate_deck() -> void:
	var is_valid = current_deck.size() == max_deck_size

	if is_valid:
		deck_validation_label.text = "Deck Valid ✓"
		deck_validation_label.modulate = Color.GREEN
		save_button.disabled = false
	else:
		deck_validation_label.text = "Need %d more cards" % (max_deck_size - current_deck.size())
		deck_validation_label.modulate = Color.YELLOW
		save_button.disabled = true

func _show_deck_full_message() -> void:
	# Show a temporary message
	var message = Label.new()
	message.text = "Deck is full!"
	message.add_theme_font_size_override("font_size", 18)
	message.modulate = Color.RED
	add_child(message)
	message.position = get_viewport().size / 2 - message.size / 2

	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 0.0, 1.0).set_delay(1.0)
	tween.tween_callback(message.queue_free)

func _on_filter_changed(filter_type: String) -> void:
	current_filter = filter_type

	# Update button states
	filter_all_button.button_pressed = filter_type == "all"
	filter_troops_button.button_pressed = filter_type == "troops"
	filter_spells_button.button_pressed = filter_type == "spells"
	filter_buildings_button.button_pressed = filter_type == "buildings"

	_apply_filter()

func _on_search_text_changed(text: String) -> void:
	_apply_filter()

func _on_sort_changed(index: int) -> void:
	_apply_filter()

func _on_save_pressed() -> void:
	if current_deck.size() == max_deck_size:
		deck_saved.emit(current_deck)
		deck_modified = false

func _on_cancel_pressed() -> void:
	if deck_modified:
		_show_unsaved_changes_dialog()
	else:
		deck_cancelled.emit()

func _show_unsaved_changes_dialog() -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "You have unsaved changes. Discard them?"
	dialog.add_button("Discard", true, "discard")
	dialog.confirmed.connect(func(): deck_cancelled.emit())
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func load_deck(deck: Array) -> void:
	current_deck = deck.duplicate()
	_update_deck_display()
	_update_collection_availability()
	_update_deck_stats()
	_validate_deck()
	deck_modified = false

func get_current_deck() -> Array:
	return current_deck
