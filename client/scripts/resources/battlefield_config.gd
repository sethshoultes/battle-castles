## BattlefieldConfig resource for storing battlefield configuration
## Eliminates hardcoded values and enables data-driven battlefield setup
class_name BattlefieldConfig
extends Resource

## Grid configuration
@export_group("Grid Settings")
@export var tile_size: int = 64  ## Size of each grid tile in pixels
@export var grid_width: int = 18  ## Number of tiles horizontally
@export var grid_height: int = 28  ## Number of tiles vertically

## Calculated battlefield dimensions (computed properties)
var battlefield_width: int:
	get: return grid_width * tile_size

var battlefield_height: int:
	get: return grid_height * tile_size

## River configuration
@export_group("River Settings")
@export var river_position_tile: int = 14  ## Y-position of river in tiles (middle of field)
@export var river_width: int = 64  ## Width of river visual in pixels

## Calculated river position
var river_y: int:
	get: return river_position_tile * tile_size

## Deployment zones
@export_group("Deployment Zones")
@export var player_deploy_start_y: int = 16  ## Player deploy zone start (tile)
@export var player_deploy_end_y: int = 27  ## Player deploy zone end (tile)
@export var opponent_deploy_start_y: int = 1  ## Opponent deploy zone start (tile)
@export var opponent_deploy_end_y: int = 12  ## Opponent deploy zone end (tile)

## Unit limits
@export_group("Unit Limits")
@export var max_units_total: int = 50  ## Maximum total units on battlefield
@export var max_units_per_team: int = 30  ## Maximum units per team

## Team identifiers
@export_group("Team Configuration")
@export var team_player: int = 0  ## Player team ID
@export var team_opponent: int = 1  ## Opponent team ID

## Tower positions (grid coordinates)
@export_group("Tower Positions")
@export var player_left_tower_pos: Vector2i = Vector2i(3, 20)
@export var player_right_tower_pos: Vector2i = Vector2i(14, 20)
@export var player_castle_pos: Vector2i = Vector2i(8, 23)
@export var opponent_left_tower_pos: Vector2i = Vector2i(14, 4)
@export var opponent_right_tower_pos: Vector2i = Vector2i(3, 4)
@export var opponent_castle_pos: Vector2i = Vector2i(8, 3)

## Visual settings
@export_group("Visual Settings")
@export var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)
@export var grid_line_width: float = 1.0
@export var player_zone_color: Color = Color(0, 0.5, 1, 0.1)  ## Blue tint
@export var opponent_zone_color: Color = Color(1, 0.2, 0.2, 0.1)  ## Red tint
@export var river_color: Color = Color(0.2, 0.4, 0.8, 0.5)
@export var river_area_color: Color = Color(0.2, 0.4, 0.8, 0.1)


## Helper function to convert grid position to world position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * tile_size + tile_size / 2,
		grid_pos.y * tile_size + tile_size / 2
	)


## Helper function to convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / tile_size),
		int(world_pos.y / tile_size)
	)


## Check if grid position is within bounds
func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and \
		   grid_pos.y >= 0 and grid_pos.y < grid_height


## Get deployment zone rect for a team
func get_deploy_zone_rect(team: int) -> Rect2:
	if team == team_player:
		return Rect2(
			0,
			player_deploy_start_y * tile_size,
			grid_width * tile_size,
			(player_deploy_end_y - player_deploy_start_y + 1) * tile_size
		)
	else:
		return Rect2(
			0,
			opponent_deploy_start_y * tile_size,
			grid_width * tile_size,
			(opponent_deploy_end_y - opponent_deploy_start_y + 1) * tile_size
		)


## Check if a world position is in valid deployment zone for team
func is_in_deployment_zone(world_pos: Vector2, team: int) -> bool:
	var grid_pos := world_to_grid(world_pos)

	if not is_valid_grid_position(grid_pos):
		return false

	if team == team_player:
		return grid_pos.y >= player_deploy_start_y and grid_pos.y <= player_deploy_end_y
	else:
		return grid_pos.y >= opponent_deploy_start_y and grid_pos.y <= opponent_deploy_end_y
