extends Node2D
class_name Battlefield

# Grid constants
const TILE_SIZE := 64  # 64 pixels per tile
const GRID_WIDTH := 18  # tiles
const GRID_HEIGHT := 32  # tiles
const BATTLEFIELD_WIDTH := GRID_WIDTH * TILE_SIZE  # 1152 pixels
const BATTLEFIELD_HEIGHT := GRID_HEIGHT * TILE_SIZE  # 2048 pixels

# River position (middle of the battlefield)
const RIVER_Y := GRID_HEIGHT / 2 * TILE_SIZE  # 1024 pixels from top

# Deployment zones (where players can place units)
const PLAYER_DEPLOY_START_Y := 18  # Start at tile 18
const PLAYER_DEPLOY_END_Y := 31  # End at tile 31
const OPPONENT_DEPLOY_START_Y := 1  # Start at tile 1
const OPPONENT_DEPLOY_END_Y := 14  # End at tile 14

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
var selected_card_cost: int = 0
var is_placing_unit: bool = false
var placement_preview: Sprite2D = null

# Deployment zone highlighting
var player_deploy_area: Rect2
var opponent_deploy_area: Rect2

func _ready() -> void:
	setup_battlefield()
	setup_deployment_zones()
	setup_camera()
	setup_towers()
	draw_grid_visual()

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
		player_left_tower.position = grid_to_world(Vector2i(3, 27))
		player_left_tower.team = TEAM_PLAYER

	if player_right_tower:
		player_right_tower.position = grid_to_world(Vector2i(14, 27))
		player_right_tower.team = TEAM_PLAYER

	if player_castle:
		player_castle.position = grid_to_world(Vector2i(8, 30))
		player_castle.team = TEAM_PLAYER
		player_castle.linked_towers = [
			player_left_tower.get_path(),
			player_right_tower.get_path()
		]

	# Position opponent towers (top of field)
	if opponent_left_tower:
		opponent_left_tower.position = grid_to_world(Vector2i(14, 4))  # Mirror of player right
		opponent_left_tower.team = TEAM_OPPONENT

	if opponent_right_tower:
		opponent_right_tower.position = grid_to_world(Vector2i(3, 4))  # Mirror of player left
		opponent_right_tower.team = TEAM_OPPONENT

	if opponent_castle:
		opponent_castle.position = grid_to_world(Vector2i(8, 1))
		opponent_castle.team = TEAM_OPPONENT
		opponent_castle.linked_towers = [
			opponent_left_tower.get_path(),
			opponent_right_tower.get_path()
		]

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
		return null

	# Unit spawning logic will be implemented here
	# For now, return null as placeholder

	return null

func highlight_deployment_zone(team: int, highlight: bool) -> void:
	# Visual feedback for deployment zones
	# This could modify the alpha or color of deployment zone overlays
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_placing_unit:
		# Update placement preview position
		if placement_preview:
			placement_preview.position = get_global_mouse_position()

			# Snap to grid
			var grid_pos := world_to_grid(placement_preview.position)
			placement_preview.position = grid_to_world(grid_pos)

			# Update preview validity visual
			var valid := can_deploy_at_position(placement_preview.position, TEAM_PLAYER)
			placement_preview.modulate = Color.GREEN if valid else Color.RED

	elif event is InputEventMouseButton and event.pressed and is_placing_unit:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Try to place unit
			attempt_unit_placement(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel placement
			cancel_unit_placement()

func start_unit_placement(unit_type: String, cost: int) -> void:
	is_placing_unit = true
	selected_card_cost = cost

	# Create placement preview
	# This will be expanded when we have unit sprites
	create_placement_preview(unit_type)

func create_placement_preview(unit_type: String) -> void:
	# Placeholder for preview creation
	# Will be implemented with actual unit sprites
	pass

func attempt_unit_placement(position: Vector2) -> void:
	if not elixir_manager or not elixir_manager.can_afford(selected_card_cost):
		# Not enough elixir
		cancel_unit_placement()
		return

	if can_deploy_at_position(position, TEAM_PLAYER):
		# Spend elixir and spawn unit
		if elixir_manager.spend(selected_card_cost):
			spawn_unit("placeholder", position, TEAM_PLAYER)
			cancel_unit_placement()
	else:
		# Invalid position
		# Could show error feedback here
		pass

func cancel_unit_placement() -> void:
	is_placing_unit = false
	selected_card_cost = 0

	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null

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