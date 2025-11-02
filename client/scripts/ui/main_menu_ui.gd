extends Control

class_name MainMenuUI

# UI Elements
@onready var play_button: Button = $MenuContainer/ButtonContainer/PlayButton
@onready var deck_builder_button: Button = $MenuContainer/ButtonContainer/DeckBuilderButton
@onready var settings_button: Button = $MenuContainer/ButtonContainer/SettingsButton
@onready var shop_button: Button = $MenuContainer/ButtonContainer/ShopButton
@onready var quit_button: Button = $MenuContainer/ButtonContainer/QuitButton

# Profile elements
@onready var profile_panel: Panel = $ProfilePanel
@onready var player_name_label: Label = $ProfilePanel/PlayerInfo/NameLabel
@onready var player_level_label: Label = $ProfilePanel/PlayerInfo/LevelLabel
@onready var trophy_count_label: Label = $ProfilePanel/PlayerInfo/TrophyContainer/TrophyCount
@onready var gold_count_label: Label = $ProfilePanel/Resources/GoldContainer/GoldCount
@onready var gem_count_label: Label = $ProfilePanel/Resources/GemContainer/GemCount
@onready var avatar_texture: TextureRect = $ProfilePanel/PlayerInfo/Avatar

# Arena display
@onready var arena_name_label: Label = $ProfilePanel/ArenaInfo/ArenaName
@onready var arena_icon: TextureRect = $ProfilePanel/ArenaInfo/ArenaIcon

# Chest slots
@onready var chest_container: HBoxContainer = $ProfilePanel/ChestSlots

# Animation elements
@onready var title_label: Label = $TitleContainer/GameTitle
@onready var version_label: Label = $VersionLabel

# Popup dialogs
@onready var matchmaking_popup: PopupPanel = $MatchmakingPopup
@onready var matchmaking_label: Label = $MatchmakingPopup/VBoxContainer/StatusLabel
@onready var cancel_matchmaking_button: Button = $MatchmakingPopup/VBoxContainer/CancelButton

# Settings
var player_data: Dictionary = {}
var is_searching_match: bool = false
var matchmaking_timer: float = 0.0

# Signals
signal play_pressed()
signal deck_builder_pressed()
signal settings_pressed()
signal shop_pressed()
signal profile_pressed()
signal quit_pressed()

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_animate_entrance()
	_load_player_data()

func _setup_ui() -> void:
	# Set up button styles and text
	if play_button:
		play_button.text = "BATTLE"
		play_button.custom_minimum_size = Vector2(200, 60)

	if deck_builder_button:
		deck_builder_button.text = "DECK"
	if settings_button:
		settings_button.text = "SETTINGS"
	if shop_button:
		shop_button.text = "SHOP"
	if quit_button:
		quit_button.text = "QUIT"

	# Set version
	if version_label:
		version_label.text = "v0.1.0-alpha"

	# Initialize chest slots
	if chest_container:
		_setup_chest_slots()

	# Hide matchmaking popup initially
	if matchmaking_popup:
		matchmaking_popup.visible = false

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if deck_builder_button:
		deck_builder_button.pressed.connect(_on_deck_builder_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if cancel_matchmaking_button:
		cancel_matchmaking_button.pressed.connect(_cancel_matchmaking)

	# Profile interaction
	if profile_panel:
		profile_panel.gui_input.connect(_on_profile_input)

func _animate_entrance() -> void:
	# Animate title
	if title_label:
		title_label.modulate.a = 0.0
		var title_tween = create_tween()
		title_tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
		title_tween.tween_property(title_label, "position:y", title_label.position.y, 0.5)\
			.from(title_label.position.y - 50)

	# Animate buttons
	var delay = 0.1
	for button in [play_button, deck_builder_button, settings_button, shop_button, quit_button]:
		if button:
			button.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_interval(delay)
			tween.tween_property(button, "modulate:a", 1.0, 0.3)
			delay += 0.1

	# Animate profile panel
	if profile_panel:
		profile_panel.modulate.a = 0.0
		var profile_tween = create_tween()
		profile_tween.tween_interval(0.5)
		profile_tween.tween_property(profile_panel, "modulate:a", 1.0, 0.5)

func _load_player_data() -> void:
	# Load from save or server
	# Placeholder data for now
	player_data = {
		"name": "Player",
		"level": 1,
		"trophies": 0,
		"gold": 100,
		"gems": 10,
		"arena": "Training Camp",
		"arena_level": 0
	}
	_update_profile_display()

func _update_profile_display() -> void:
	if not player_data.is_empty():
		if player_name_label:
			player_name_label.text = player_data.get("name", "Player")
		if player_level_label:
			player_level_label.text = "Level " + str(player_data.get("level", 1))
		if trophy_count_label:
			trophy_count_label.text = str(player_data.get("trophies", 0))
		if gold_count_label:
			gold_count_label.text = str(player_data.get("gold", 0))
		if gem_count_label:
			gem_count_label.text = str(player_data.get("gems", 0))
		if arena_name_label:
			arena_name_label.text = player_data.get("arena", "Training Camp")

func _setup_chest_slots() -> void:
	# Create 4 chest slots
	for i in range(4):
		var chest_slot = Panel.new()
		chest_slot.custom_minimum_size = Vector2(60, 60)
		chest_slot.name = "ChestSlot" + str(i)

		# Add placeholder background
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		chest_slot.add_theme_stylebox_override("panel", style)

		chest_container.add_child(chest_slot)

func _on_play_pressed() -> void:
	print("BATTLE button pressed - Loading battle scene...")
	if play_button:
		_animate_button_press(play_button)
	if title_label:
		title_label.text = "STARTING BATTLE..."
	play_pressed.emit()

	# Load battle scene
	await get_tree().create_timer(0.5).timeout  # Brief delay for visual feedback
	get_tree().change_scene_to_file("res://scenes/battle/battlefield.tscn")

func _on_deck_builder_pressed() -> void:
	print("DECK button pressed - Loading deck builder...")
	if deck_builder_button:
		_animate_button_press(deck_builder_button)
	if title_label:
		title_label.text = "DECK BUILDER"
	deck_builder_pressed.emit()

	# Load deck builder scene
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/ui/deck_builder.tscn")

func _on_settings_pressed() -> void:
	print("SETTINGS button pressed - Loading settings...")
	if settings_button:
		_animate_button_press(settings_button)
	if title_label:
		title_label.text = "SETTINGS"
	settings_pressed.emit()

	# Load settings scene
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_shop_pressed() -> void:
	print("SHOP button pressed!")
	if shop_button:
		_animate_button_press(shop_button)
	if title_label:
		title_label.text = "SHOP - Coming Soon"
	shop_pressed.emit()
	# Shop scene not implemented yet

func _on_quit_pressed() -> void:
	print("QUIT button pressed!")
	if quit_button:
		_animate_button_press(quit_button)
	quit_pressed.emit()
	get_tree().quit()

func _on_profile_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		profile_pressed.emit()

func _animate_button_press(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2.ONE, 0.05)

func _start_matchmaking() -> void:
	is_searching_match = true
	matchmaking_timer = 0.0
	if matchmaking_popup:
		matchmaking_popup.visible = true
		# Animate popup appearance
		matchmaking_popup.scale = Vector2(0.8, 0.8)
		matchmaking_popup.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(matchmaking_popup, "scale", Vector2.ONE, 0.3)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(matchmaking_popup, "modulate:a", 1.0, 0.2)
	if matchmaking_label:
		matchmaking_label.text = "Searching for opponent..."
	if play_button:
		play_button.disabled = true

func _cancel_matchmaking() -> void:
	is_searching_match = false
	if play_button:
		play_button.disabled = false

	# Animate popup disappearance
	if matchmaking_popup:
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(matchmaking_popup, "scale", Vector2(0.8, 0.8), 0.2)
		tween.tween_property(matchmaking_popup, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func(): matchmaking_popup.visible = false)

func _process(delta: float) -> void:
	if is_searching_match:
		matchmaking_timer += delta
		var dots = "." . repeat(int(matchmaking_timer * 2) % 4)
		matchmaking_label.text = "Searching for opponent" + dots

func set_player_name(name: String) -> void:
	player_data["name"] = name
	player_name_label.text = name

func set_player_level(level: int, experience: int, next_level_exp: int) -> void:
	player_data["level"] = level
	player_level_label.text = "Level " + str(level)

func set_trophies(count: int) -> void:
	player_data["trophies"] = count
	trophy_count_label.text = str(count)

	# Update arena based on trophy count
	_update_arena(count)

func set_currency(gold: int, gems: int) -> void:
	player_data["gold"] = gold
	player_data["gems"] = gems
	gold_count_label.text = str(gold)
	gem_count_label.text = str(gems)

func _update_arena(trophies: int) -> void:
	# Determine arena based on trophy count
	var arena_data = _get_arena_by_trophies(trophies)
	player_data["arena"] = arena_data["name"]
	player_data["arena_level"] = arena_data["level"]
	arena_name_label.text = arena_data["name"]

func _get_arena_by_trophies(trophies: int) -> Dictionary:
	# Arena thresholds
	if trophies >= 3000:
		return {"name": "Legendary Arena", "level": 10}
	elif trophies >= 2300:
		return {"name": "Frozen Peak", "level": 9}
	elif trophies >= 1700:
		return {"name": "Royal Arena", "level": 8}
	elif trophies >= 1100:
		return {"name": "Builder's Workshop", "level": 7}
	elif trophies >= 800:
		return {"name": "Spell Valley", "level": 6}
	elif trophies >= 500:
		return {"name": "Bone Pit", "level": 5}
	elif trophies >= 300:
		return {"name": "Barbarian Bowl", "level": 4}
	elif trophies >= 150:
		return {"name": "Goblin Stadium", "level": 3}
	elif trophies >= 50:
		return {"name": "Training Camp", "level": 2}
	else:
		return {"name": "Training Camp", "level": 1}

func add_chest(chest_type: String, slot: int) -> void:
	if slot < 0 or slot >= 4:
		return

	var chest_slot = chest_container.get_child(slot)
	if chest_slot:
		# Add chest visual to slot
		var chest_icon = TextureRect.new()
		chest_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		chest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		# Set chest color based on type
		var color_rect = ColorRect.new()
		color_rect.anchor_right = 1.0
		color_rect.anchor_bottom = 1.0

		match chest_type:
			"silver":
				color_rect.color = Color(0.7, 0.7, 0.7, 0.8)
			"gold":
				color_rect.color = Color(1.0, 0.8, 0.2, 0.8)
			"magical":
				color_rect.color = Color(0.6, 0.2, 0.9, 0.8)
			"giant":
				color_rect.color = Color(0.8, 0.4, 0.2, 0.8)
			_:
				color_rect.color = Color(0.5, 0.5, 0.5, 0.8)

		chest_slot.add_child(color_rect)

func show_news(news_text: String) -> void:
	# Display news or announcements
	pass

func show_season_info(season_name: String, days_remaining: int) -> void:
	# Display current season information
	pass