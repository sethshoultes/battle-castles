extends Node2D
class_name Battlefield

# Grid constants
const TILE_SIZE := 64  # 64 pixels per tile
const GRID_WIDTH := 18  # tiles
const GRID_HEIGHT := 28  # tiles (reduced for better proportions)
const BATTLEFIELD_WIDTH := GRID_WIDTH * TILE_SIZE  # 1152 pixels
const BATTLEFIELD_HEIGHT := GRID_HEIGHT * TILE_SIZE  # 1792 pixels

# Unit limits
const MAX_UNITS_TOTAL := 50  # Maximum units on battlefield at once
const MAX_UNITS_PER_TEAM := 30  # Maximum per team

# River position (middle of the battlefield)
const RIVER_Y := GRID_HEIGHT / 2 * TILE_SIZE  # 1024 pixels from top

# Deployment zones (where players can place units)
const PLAYER_DEPLOY_START_Y := 16  # Start at tile 16
const PLAYER_DEPLOY_END_Y := 27  # End at tile 27
const OPPONENT_DEPLOY_START_Y := 1  # Start at tile 1
const OPPONENT_DEPLOY_END_Y := 12  # End at tile 12

# Team constants
const TEAM_PLAYER := 0
const TEAM_OPPONENT := 1

# Node references
@onready var grid_visual: Node2D = $GridVisual
@onready var deployment_zones: Node2D = $DeploymentZones
@onready var towers_container: Node2D = $Towers
@onready var units_container: Node2D = $Units
@onready var projectiles_container: Node2D = $Projectiles
@onready var effects_container: Node2D = $Effects
@onready var camera: Camera2D = $Camera2D

# Tower references
@onready var player_left_tower: Tower = $Towers/PlayerLeftTower
@onready var player_right_tower: Tower = $Towers/PlayerRightTower
@onready var player_castle: Castle = $Towers/PlayerCastle
@onready var opponent_left_tower: Tower = $Towers/OpponentLeftTower
@onready var opponent_right_tower: Tower = $Towers/OpponentRightTower
@onready var opponent_castle: Castle = $Towers/OpponentCastle

# Managers
var battle_manager: BattleManager
var elixir_manager: ElixirManager

# State
var battle_ui: Control = null
var game_over: bool = false
var winner_team: int = -1

# Deployment zone highlighting
var player_deploy_area: Rect2
var opponent_deploy_area: Rect2

func _ready() -> void:
	setup_battlefield()
	setup_deployment_zones()
	setup_camera()
	setup_towers()
	draw_grid_visual()
	connect_battle_ui()
	_setup_battle_manager()
	_load_ai_difficulty()
	start_ai_timer()

func _process(delta: float) -> void:
	# Regenerate AI elixir at same rate as player
	if ai_elixir < ai_max_elixir:
		ai_elixir = min(ai_elixir + ai_elixir_rate * delta, ai_max_elixir)

func setup_battlefield() -> void:
	# Set up deployment zone rectangles
	player_deploy_area = Rect2(
		0,
		PLAYER_DEPLOY_START_Y * TILE_SIZE,
		GRID_WIDTH * TILE_SIZE,
		(PLAYER_DEPLOY_END_Y - PLAYER_DEPLOY_START_Y + 1) * TILE_SIZE
	)

	opponent_deploy_area = Rect2(
		0,
		OPPONENT_DEPLOY_START_Y * TILE_SIZE,
		GRID_WIDTH * TILE_SIZE,
		(OPPONENT_DEPLOY_END_Y - OPPONENT_DEPLOY_START_Y + 1) * TILE_SIZE
	)

func setup_deployment_zones() -> void:
	# This will create visual indicators for deployment zones
	if deployment_zones:
		queue_redraw()

func setup_camera() -> void:
	if camera:
		# Center camera on battlefield
		camera.position = Vector2(BATTLEFIELD_WIDTH / 2, BATTLEFIELD_HEIGHT / 2)

		# Set zoom to fit battlefield on screen
		# Adjust zoom based on viewport size (to be configured based on resolution)
		camera.zoom = Vector2(1.0, 1.0)

func setup_towers() -> void:
	# Position player towers (bottom of field)
	if player_left_tower:
		player_left_tower.position = grid_to_world(Vector2i(3, 20))
		player_left_tower.team = TEAM_PLAYER

	if player_right_tower:
		player_right_tower.position = grid_to_world(Vector2i(14, 20))
		player_right_tower.team = TEAM_PLAYER

	if player_castle:
		player_castle.position = grid_to_world(Vector2i(8, 23))
		player_castle.team = TEAM_PLAYER
		player_castle.linked_towers = [
			player_left_tower.get_path(),
			player_right_tower.get_path()
		]
		# Connect to castle destruction for game over
		player_castle.tower_destroyed.connect(_on_castle_destroyed)

	# Position opponent towers (top of field)
	if opponent_left_tower:
		opponent_left_tower.position = grid_to_world(Vector2i(14, 4))  # Mirror of player right
		opponent_left_tower.team = TEAM_OPPONENT

	if opponent_right_tower:
		opponent_right_tower.position = grid_to_world(Vector2i(3, 4))  # Mirror of player left
		opponent_right_tower.team = TEAM_OPPONENT

	if opponent_castle:
		opponent_castle.position = grid_to_world(Vector2i(8, 3))
		opponent_castle.team = TEAM_OPPONENT
		opponent_castle.linked_towers = [
			opponent_left_tower.get_path(),
			opponent_right_tower.get_path()
		]
		# Connect to castle destruction for game over
		opponent_castle.tower_destroyed.connect(_on_castle_destroyed)

func _setup_battle_manager() -> void:
	# Create and initialize battle manager
	if not battle_manager:
		battle_manager = BattleManager.new()
		add_child(battle_manager)

	# Create and initialize elixir manager
	if not elixir_manager:
		elixir_manager = ElixirManager.new()
		add_child(elixir_manager)

	# Initialize battle manager with references
	battle_manager.initialize(self, elixir_manager)

	# Connect battle manager signals
	battle_manager.time_updated.connect(_on_battle_time_updated)
	battle_manager.double_elixir_started.connect(_on_double_elixir_started)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# Start the battle
	battle_manager.start_battle()
	print("Battle manager initialized and started")

func draw_grid_visual() -> void:
	# This will be called to draw the grid
	queue_redraw()

func _draw() -> void:
	# Draw grid lines
	draw_grid()

	# Draw deployment zones
	draw_deployment_zones()

	# Draw river
	draw_river()

func draw_grid() -> void:
	var grid_color := Color(0.2, 0.2, 0.2, 0.3)

	# Vertical lines
	for x in range(GRID_WIDTH + 1):
		draw_line(
			Vector2(x * TILE_SIZE, 0),
			Vector2(x * TILE_SIZE, BATTLEFIELD_HEIGHT),
			grid_color,
			1.0
		)

	# Horizontal lines
	for y in range(GRID_HEIGHT + 1):
		draw_line(
			Vector2(0, y * TILE_SIZE),
			Vector2(BATTLEFIELD_WIDTH, y * TILE_SIZE),
			grid_color,
			1.0
		)

func draw_deployment_zones() -> void:
	# Player deployment zone (blue tint)
	draw_rect(
		player_deploy_area,
		Color(0, 0.5, 1, 0.1)
	)

	# Opponent deployment zone (red tint)
	draw_rect(
		opponent_deploy_area,
		Color(1, 0.2, 0.2, 0.1)
	)

func draw_river() -> void:
	# Draw river line
	draw_line(
		Vector2(0, RIVER_Y),
		Vector2(BATTLEFIELD_WIDTH, RIVER_Y),
		Color(0.2, 0.4, 0.8, 0.5),
		3.0
	)

	# Draw river area
	draw_rect(
		Rect2(0, RIVER_Y - 32, BATTLEFIELD_WIDTH, 64),
		Color(0.2, 0.4, 0.8, 0.1)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2
	)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

func is_valid_deployment_position(world_pos: Vector2, team: int) -> bool:
	var grid_pos := world_to_grid(world_pos)

	# Check bounds
	if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH:
		return false
	if grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:
		return false

	# Check deployment zone based on team
	if team == TEAM_PLAYER:
		return grid_pos.y >= PLAYER_DEPLOY_START_Y and grid_pos.y <= PLAYER_DEPLOY_END_Y
	else:
		return grid_pos.y >= OPPONENT_DEPLOY_START_Y and grid_pos.y <= OPPONENT_DEPLOY_END_Y

func can_deploy_at_position(world_pos: Vector2, team: int) -> bool:
	if not is_valid_deployment_position(world_pos, team):
		return false

	# Additional checks for obstacles, other units, etc.
	# This will be expanded when unit system is implemented

	return true

func spawn_unit(unit_type: String, position: Vector2, team: int) -> Node2D:
	if not can_deploy_at_position(position, team):
		print("Cannot deploy unit at position: ", position)
		return null

	# Check unit limits
	var total_units = units_container.get_child_count()
	if total_units >= MAX_UNITS_TOTAL:
		print("Cannot spawn - max total units reached (", MAX_UNITS_TOTAL, ")")
		return null

	# Count units for this team
	var team_units = 0
	for unit in units_container.get_children():
		if unit.has_method("get_team") and unit.get_team() == team:
			team_units += 1

	if team_units >= MAX_UNITS_PER_TEAM:
		print("Cannot spawn - max units for team ", team, " reached (", MAX_UNITS_PER_TEAM, ")")
		return null

	print("Spawning ", unit_type, " at ", position, " for team ", team, " (", team_units + 1, "/", MAX_UNITS_PER_TEAM, ")")

	# Load the SimpleUnit script
	var SimpleUnitScript = load("res://scripts/battle/simple_unit.gd")
	var unit = CharacterBody2D.new()
	unit.set_script(SimpleUnitScript)
	unit.position = position

	print("Creating unit at position: ", position, " for team: ", team)

	# Load card data FIRST
	var card_path = "res://resources/cards/" + unit_type + ".tres"
	var card_data: CardData = load(card_path)

	print("  Loaded card data: ", card_data.card_name if card_data else "NULL")

	# Set data directly on unit BEFORE adding children
	unit.unit_type = unit_type
	unit.team = team
	unit.card_data = card_data

	# Get unit-specific visuals
	var unit_visuals = _get_unit_visuals(unit_type)

	# Add visual representation - Try to load actual sprite first
	var sprite_suffix = "_player" if team == TEAM_PLAYER else "_enemy"
	var sprite_path = "res://assets/sprites/units/" + unit_type + sprite_suffix + ".png"
	var texture = load(sprite_path)

	if texture:
		# Use sprite if available
		var sprite = Sprite2D.new()
		sprite.texture = texture
		# Scale sprite MUCH larger for visibility (3x the target size)
		var texture_size = texture.get_size()
		var target_size = unit_visuals.size * 3.0  # Make 3x larger
		sprite.scale = Vector2(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)
		# Center the sprite - bottom of sprite at unit position (feet)
		sprite.offset = Vector2(0, -unit_visuals.size.y * 3)  # Sprite bottom at origin
		unit.add_child(sprite)
		print("  Loaded sprite: ", sprite_path, " (", texture_size, ") scaled to ", target_size)
	else:
		# Use colored rectangle as fallback
		print("  Sprite not found: ", sprite_path, " - using colored placeholder")
		var color_rect = ColorRect.new()
		var rect_size = unit_visuals.size * 3.0  # Match expected size
		color_rect.size = rect_size
		color_rect.position = Vector2(-rect_size.x / 2, -rect_size.y)  # Center and align to feet

		# Set color based on team
		if team == TEAM_PLAYER:
			color_rect.color = unit_visuals.player_color
		else:
			color_rect.color = unit_visuals.enemy_color

		unit.add_child(color_rect)

	# Add health bar - ABOVE the head
	var health_bar = ProgressBar.new()
	var health_bar_height = 6

	# Calculate top of visual (works for both sprite and ColorRect)
	var visual_top_y = -unit_visuals.size.y * 3
	var bar_y_position = visual_top_y - health_bar_height - 1

	health_bar.position = Vector2(-30, bar_y_position)
	health_bar.size = Vector2(60, health_bar_height)  # Wide bar
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the health bar with team-specific color
	var style_box = StyleBoxFlat.new()
	# Blue for player, red for enemy
	if team == TEAM_PLAYER:
		style_box.bg_color = Color(0.2, 0.5, 1.0, 1.0)  # Bright blue
	else:
		style_box.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # Bright red
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("fill", style_box)

	# Dark background for health bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray background
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", bg_style)

	unit.add_child(health_bar)

	# Configure CharacterBody2D for smooth sliding
	unit.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	unit.wall_min_slide_angle = 0  # Allow sliding at any angle

	# Add collision shape - this is for physics, not rendering
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12  # Very small collision for maximum flow
	collision_shape.shape = shape
	collision_shape.position = Vector2(0, 0)
	collision_shape.debug_color = Color(0, 0, 0, 0)  # Make debug shape invisible
	unit.add_child(collision_shape)

	# Set collision layers - separate layers per team to prevent same-team collisions
	if team == TEAM_PLAYER:
		unit.collision_layer = 1  # Player units on layer 1 (value 1)
		unit.collision_mask = 10  # Collide with layer 2 (value 2) and layer 4 (value 8)
	else:
		unit.collision_layer = 2  # Enemy units on layer 2 (value 2)
		unit.collision_mask = 9  # Collide with layer 1 (value 1) and layer 4 (value 8)

	# Add unit to scene
	units_container.add_child(unit)

	print("  Unit added to scene with team: ", team, " and type: ", unit_type)
	return unit

func _get_unit_visuals(unit_type: String) -> Dictionary:
	# Returns visual properties for each unit type
	match unit_type:
		"knight":
			return {
				"display_name": "KNIGHT",
				"size": Vector2(36, 52),
				"player_color": Color(0.2, 0.4, 0.9),  # Bright Blue
				"enemy_color": Color(0.9, 0.2, 0.2)    # Bright Red
			}
		"goblin":
			return {
				"display_name": "GOBLIN",
				"size": Vector2(28, 40),
				"player_color": Color(0.3, 0.8, 0.3),  # Bright Green
				"enemy_color": Color(0.9, 0.5, 0.1)    # Orange
			}
		"archer":
			return {
				"display_name": "ARCHER",
				"size": Vector2(32, 48),
				"player_color": Color(0.6, 0.3, 0.9),  # Purple
				"enemy_color": Color(0.9, 0.3, 0.5)    # Pink
			}
		"giant":
			return {
				"display_name": "GIANT",
				"size": Vector2(50, 70),
				"player_color": Color(0.5, 0.5, 0.5),  # Gray
				"enemy_color": Color(0.7, 0.1, 0.1)    # Dark Red
			}
		"barbarians":
			return {
				"display_name": "BARBARIAN",
				"size": Vector2(38, 54),
				"player_color": Color(0.9, 0.6, 0.2),  # Orange
				"enemy_color": Color(0.7, 0.3, 0.1)    # Dark Orange
			}
		"musketeer":
			return {
				"display_name": "MUSKETEER",
				"size": Vector2(34, 50),
				"player_color": Color(0.2, 0.5, 0.8),  # Blue
				"enemy_color": Color(0.8, 0.2, 0.4)    # Red-Pink
			}
		"mini_pekka":
			return {
				"display_name": "MINI PEKKA",
				"size": Vector2(40, 56),
				"player_color": Color(0.3, 0.3, 0.5),  # Dark Blue
				"enemy_color": Color(0.5, 0.1, 0.1)    # Dark Red
			}
		"wizard":
			return {
				"display_name": "WIZARD",
				"size": Vector2(35, 52),
				"player_color": Color(0.5, 0.2, 0.8),  # Purple
				"enemy_color": Color(0.8, 0.2, 0.2)    # Red
			}
		"baby_dragon":
			return {
				"display_name": "BABY DRAGON",
				"size": Vector2(45, 60),
				"player_color": Color(0.6, 0.3, 0.9),  # Purple
				"enemy_color": Color(0.9, 0.3, 0.3)    # Red
			}
		"skeleton_army":
			return {
				"display_name": "SKELETON",
				"size": Vector2(26, 42),
				"player_color": Color(0.9, 0.9, 0.9),  # White
				"enemy_color": Color(0.7, 0.7, 0.7)    # Gray
			}
		"minions":
			return {
				"display_name": "MINION",
				"size": Vector2(28, 44),
				"player_color": Color(0.4, 0.2, 0.6),  # Purple
				"enemy_color": Color(0.6, 0.2, 0.2)    # Dark Red
			}
		"valkyrie":
			return {
				"display_name": "VALKYRIE",
				"size": Vector2(38, 54),
				"player_color": Color(0.9, 0.5, 0.3),  # Orange
				"enemy_color": Color(0.7, 0.2, 0.2)    # Red
			}
		_:
			# Default fallback
			return {
				"display_name": unit_type.to_upper(),
				"size": Vector2(32, 48),
				"player_color": Color(0.5, 0.5, 0.8),
				"enemy_color": Color(0.8, 0.3, 0.3)
			}

func highlight_deployment_zone(team: int, highlight: bool) -> void:
	# Visual feedback for deployment zones
	# This could modify the alpha or color of deployment zone overlays
	queue_redraw()

func _input(event: InputEvent) -> void:
	if game_over:
		return  # Don't allow input after game over

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if we have a selected card
		if battle_ui and battle_ui.selected_card:
			# Get mouse position in battlefield coordinates
			var mouse_pos = get_global_mouse_position()

			# Check if click is in valid deployment zone
			if can_deploy_at_position(mouse_pos, TEAM_PLAYER):
				# Tell BattleUI to play the selected card at this position
				battle_ui.play_selected_card(mouse_pos)
			else:
				print("Invalid deployment position")

func set_managers(battle: BattleManager, elixir: ElixirManager) -> void:
	battle_manager = battle
	elixir_manager = elixir

	# Connect tower destruction signals to battle manager
	if player_left_tower:
		player_left_tower.tower_destroyed.connect(battle_manager.tower_destroyed)
	if player_right_tower:
		player_right_tower.tower_destroyed.connect(battle_manager.tower_destroyed)
	if player_castle:
		player_castle.tower_destroyed.connect(battle_manager.tower_destroyed)
	if opponent_left_tower:
		opponent_left_tower.tower_destroyed.connect(battle_manager.tower_destroyed)
	if opponent_right_tower:
		opponent_right_tower.tower_destroyed.connect(battle_manager.tower_destroyed)
	if opponent_castle:
		opponent_castle.tower_destroyed.connect(battle_manager.tower_destroyed)

func connect_battle_ui() -> void:
	# Find and connect to BattleUI
	battle_ui = get_node_or_null("UI/BattleUI")
	if battle_ui:
		print("✅ SUCCESS: BattleUI FOUND AND CONNECTED!")
		battle_ui.card_selected.connect(_on_card_selected)
		battle_ui.card_deselected.connect(_on_card_deselected)
		battle_ui.card_played.connect(_on_card_played)
	else:
		print("❌ ERROR: BattleUI not found - trying alternate paths...")
		# Try different paths
		battle_ui = get_node_or_null("/root/Battlefield/UI/BattleUI")
		if battle_ui:
			print("✅ Found BattleUI at absolute path!")
			battle_ui.card_selected.connect(_on_card_selected)
			battle_ui.card_deselected.connect(_on_card_deselected)
			battle_ui.card_played.connect(_on_card_played)
		else:
			print("❌ FAILED: Could not find BattleUI anywhere!")

func _on_card_selected(card: Resource, slot_index: int) -> void:
	print("Card selected: ", card.card_name if card else "null", " at slot ", slot_index)
	# Card is now selected - waiting for battlefield click

func _on_card_deselected() -> void:
	print("Card deselected")

func _on_card_played(card: Resource, position: Vector2) -> void:
	print("Card played! Type: ", card.unit_type if card else "null", " Position: ", position)

	if not card:
		return

	# Spawn the unit
	var unit = spawn_unit(card.unit_type, position, TEAM_PLAYER)

	if unit:
		print("Player deployed: ", card.card_name)
	else:
		# Failed to spawn (likely hit unit limit) - refund elixir
		if battle_ui and card is CardData:
			battle_ui.refund_elixir(card.elixir_cost)
			print("Refunded ", card.elixir_cost, " elixir - unit limit reached")

# AI Enemy System
enum AILevel {
	EASY,
	MEDIUM,
	HARD
}

var ai_timer: Timer
var ai_cards: Array = []
var ai_elixir: float = 5.0  # AI starts with 5 elixir like player
var ai_max_elixir: float = 10.0
var ai_elixir_rate: float = 1.0 / 2.8  # Same rate as player: 1 per 2.8 seconds
var ai_difficulty: AILevel = AILevel.MEDIUM  # Default to medium difficulty
var ai_elixir_reserve: float = 0.5  # AI keeps this much elixir in reserve for defense

func _load_ai_difficulty() -> void:
	# Load AI difficulty from GameManager
	if GameManager:
		match GameManager.ai_difficulty:
			0:
				ai_difficulty = AILevel.EASY
			1:
				ai_difficulty = AILevel.MEDIUM
			2:
				ai_difficulty = AILevel.HARD
			_:
				ai_difficulty = AILevel.MEDIUM
		print("AI difficulty set to: ", ai_difficulty)

func start_ai_timer() -> void:
	# Load AI cards
	ai_cards = [
		load("res://resources/cards/knight.tres"),
		load("res://resources/cards/goblin.tres"),
		load("res://resources/cards/archer.tres"),
		load("res://resources/cards/giant.tres")
	]

	# Create AI timer - check every 1 second if we can deploy
	ai_timer = Timer.new()
	ai_timer.wait_time = 1.0  # Check every second for deployment opportunities
	ai_timer.autostart = true
	ai_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(ai_timer)
	print("AI system started - will deploy when elixir available")

func _on_ai_timer_timeout() -> void:
	# Stop spawning if game is over
	if game_over:
		if ai_timer:
			ai_timer.stop()
		return

	# Skip if no cards available
	if ai_cards.is_empty():
		return

	# Analyze battlefield situation
	var threat_data = _analyze_threat_level()

	# Choose card strategically based on situation
	var chosen_card = _choose_ai_card_strategic(threat_data)

	if not chosen_card:
		return  # No good option right now or saving elixir

	# Deduct elixir cost
	ai_elixir -= chosen_card.elixir_cost
	ai_elixir = max(0, ai_elixir)

	# Choose strategic spawn position
	var spawn_pos = _choose_spawn_position(chosen_card, threat_data)

	# Spawn unit
	var unit = spawn_unit(chosen_card.unit_type, spawn_pos, TEAM_OPPONENT)

	if unit:
		var action = "defended" if threat_data.threat_level > 3 else "attacked"
		print("AI ", action, " with: ", chosen_card.card_name, " (cost: ", chosen_card.elixir_cost, " | remaining: ", ai_elixir, ")")

func _analyze_threat_level() -> Dictionary:
	"""
	Analyzes the battlefield to determine threat level to AI towers/castle
	Returns:
	{
		"threat_level": int (0-10),
		"threatened_tower": Node2D or null,
		"enemy_units_near_tower": Array,
		"our_units_alive": int
	}
	"""
	var threat_data = {
		"threat_level": 0,
		"threatened_tower": null,
		"enemy_units_near_tower": [],
		"our_units_alive": 0
	}

	# Count our units
	var units_container = get_node_or_null("Units")
	if units_container:
		for unit in units_container.get_children():
			if unit.has_method("get_team") and unit.get_team() == TEAM_OPPONENT:
				threat_data.our_units_alive += 1

	# Find enemy units near our towers
	var towers_container = get_node_or_null("Towers")
	if not towers_container or not units_container:
		return threat_data

	for tower in towers_container.get_children():
		if not tower.has_method("get"):
			continue
		if not ("team" in tower) or tower.team != TEAM_OPPONENT:
			continue  # Not our tower

		# Check for enemy units near this tower
		var nearby_enemies = []
		for unit in units_container.get_children():
			if not unit.has_method("get_team"):
				continue
			if unit.get_team() == TEAM_OPPONENT:
				continue  # Same team

			var distance = tower.global_position.distance_to(unit.global_position)
			if distance < 400:  # Within threat range
				nearby_enemies.append(unit)

		# Calculate threat level for this tower
		if nearby_enemies.size() > 0:
			threat_data.threat_level = nearby_enemies.size() * 2  # 2 points per enemy
			threat_data.threatened_tower = tower
			threat_data.enemy_units_near_tower = nearby_enemies
			break  # Focus on most threatened tower

	return threat_data

func _choose_ai_card_strategic(threat_data: Dictionary) -> CardData:
	"""
	Choose card based on situation and AI difficulty
	"""
	var affordable_cards = []
	for card in ai_cards:
		if card.elixir_cost <= ai_elixir:
			affordable_cards.append(card)

	if affordable_cards.is_empty():
		return null

	# EASY AI: Random (simple behavior)
	if ai_difficulty == AILevel.EASY:
		return affordable_cards[randi() % affordable_cards.size()]

	# MEDIUM+ AI: Strategic decisions

	# Save elixir reserve unless defending
	var available_elixir = ai_elixir
	if threat_data.threat_level <= 3:
		available_elixir = ai_elixir - ai_elixir_reserve

	# Re-filter cards we can afford while keeping reserve
	var strategic_cards = []
	for card in affordable_cards:
		if card.elixir_cost <= available_elixir or threat_data.threat_level > 5:
			strategic_cards.append(card)

	if strategic_cards.is_empty():
		return null  # Saving elixir

	# Defend if threatened (threat_level > 3)
	if threat_data.threat_level > 3:
		# Prefer defensive cards (tanks and swarm)
		var defensive_cards = strategic_cards.filter(func(card):
			return card.unit_type in ["knight", "giant", "valkyrie", "barbarians"]
		)
		if not defensive_cards.is_empty():
			return defensive_cards[randi() % defensive_cards.size()]

	# Attack with any available card
	return strategic_cards[randi() % strategic_cards.size()]

func _choose_spawn_position(card: CardData, threat_data: Dictionary) -> Vector2:
	"""
	Choose strategic spawn position based on situation
	"""
	# If defending, spawn near threatened tower
	if threat_data.threat_level > 3 and threat_data.threatened_tower:
		var tower_pos = threat_data.threatened_tower.global_position

		# Calculate average enemy position
		var avg_enemy_x = 0.0
		for enemy in threat_data.enemy_units_near_tower:
			avg_enemy_x += enemy.global_position.x

		if threat_data.enemy_units_near_tower.size() > 0:
			avg_enemy_x /= threat_data.enemy_units_near_tower.size()

			# Place unit between tower and enemies (defensive positioning)
			var spawn_x = clamp(
				(tower_pos.x + avg_enemy_x) / 2.0,
				opponent_deploy_area.position.x + 100,
				opponent_deploy_area.position.x + opponent_deploy_area.size.x - 100
			)
			var spawn_y = randf_range(
				opponent_deploy_area.position.y + 100,
				opponent_deploy_area.position.y + opponent_deploy_area.size.y - 100
			)

			return Vector2(spawn_x, spawn_y)

	# Otherwise, random placement for attack
	var random_x = randf_range(
		opponent_deploy_area.position.x + 100,
		opponent_deploy_area.position.x + opponent_deploy_area.size.x - 100
	)
	var random_y = randf_range(
		opponent_deploy_area.position.y + 100,
		opponent_deploy_area.position.y + opponent_deploy_area.size.y - 100
	)

	return Vector2(random_x, random_y)

func _on_castle_destroyed(team: int, tower_type: String) -> void:
	# A castle was destroyed - game over!
	if tower_type == "castle":
		game_over = true
		winner_team = TEAM_OPPONENT if team == TEAM_PLAYER else TEAM_PLAYER

		# Stop AI spawning
		if ai_timer:
			ai_timer.stop()

		# Show game over message
		var winner_text = "VICTORY!" if winner_team == TEAM_PLAYER else "DEFEAT!"
		print("===================")
		print("GAME OVER - ", winner_text)
		print("===================")

		# Create a simple game over label
		var game_over_label = Label.new()
		game_over_label.text = winner_text
		game_over_label.position = Vector2(BATTLEFIELD_WIDTH / 2 - 100, BATTLEFIELD_HEIGHT / 2)
		game_over_label.add_theme_font_size_override("font_size", 64)
		game_over_label.add_theme_color_override("font_color", Color(1, 1, 0, 1) if winner_team == TEAM_PLAYER else Color(1, 0, 0, 1))
		game_over_label.add_theme_color_override("font_outline_color", Color.BLACK)
		game_over_label.add_theme_constant_override("outline_size", 8)
		add_child(game_over_label)

func _on_battle_time_updated(time_remaining: float) -> void:
	# Update UI with time remaining
	if battle_ui:
		battle_ui.update_timer(time_remaining)

func _on_double_elixir_started() -> void:
	# Double elixir mode started
	print("DOUBLE ELIXIR MODE ACTIVATED!")
	if battle_ui:
		battle_ui.show_double_elixir_indicator()

func _on_battle_ended(winner: int) -> void:
	# Battle ended by timer
	game_over = true
	winner_team = winner

	# Stop AI spawning
	if ai_timer:
		ai_timer.stop()

	# Show game over message
	var winner_text = "VICTORY!" if winner == TEAM_PLAYER else ("DEFEAT!" if winner == TEAM_OPPONENT else "DRAW!")
	print("===================")
	print("BATTLE ENDED - ", winner_text)
	print("===================")

	# Create a simple game over label
	var game_over_label = Label.new()
	game_over_label.text = winner_text
	game_over_label.position = Vector2(BATTLEFIELD_WIDTH / 2 - 100, BATTLEFIELD_HEIGHT / 2)
	game_over_label.add_theme_font_size_override("font_size", 64)

	# Color based on outcome
	if winner == TEAM_PLAYER:
		game_over_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))  # Yellow for victory
	elif winner == TEAM_OPPONENT:
		game_over_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))  # Red for defeat
	else:
		game_over_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))  # Gray for draw

	game_over_label.add_theme_color_override("font_outline_color", Color.BLACK)
	game_over_label.add_theme_constant_override("outline_size", 8)
	add_child(game_over_label)
