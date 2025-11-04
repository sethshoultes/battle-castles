## Component that manages an entity's team affiliation
class_name TeamComponent
extends Component

## Signal emitted when team changes
signal team_changed(new_team: int, old_team: int)

## Enum for team IDs
enum Team {
	TEAM_BLUE = 0,
	TEAM_RED = 1,
	NEUTRAL = -1
}

## Team ID (0 for blue, 1 for red, -1 for neutral)
@export var team_id: int = Team.TEAM_BLUE

## Team color for visual representation
@export var team_color: Color = Color.BLUE

## Team name for display
@export var team_name: String = "Blue"

## Whether this entity is hostile to all teams
@export var hostile_to_all: bool = false

## Predefined team colors
const TEAM_COLORS: Dictionary = {
	Team.TEAM_BLUE: Color(0.2, 0.4, 1.0),
	Team.TEAM_RED: Color(1.0, 0.2, 0.2),
	Team.NEUTRAL: Color(0.7, 0.7, 0.7)
}

## Predefined team names
const TEAM_NAMES: Dictionary = {
	Team.TEAM_BLUE: "Blue",
	Team.TEAM_RED: "Red",
	Team.NEUTRAL: "Neutral"
}


## Returns the component class name for identification
func get_component_class() -> String:
	return "TeamComponent"


## Called when the component is attached to an entity
func on_attached() -> void:
	_update_team_properties()


## Sets the team ID and updates related properties
func set_team(new_team_id: int) -> void:
	if new_team_id == team_id:
		return

	var old_team: int = team_id
	team_id = new_team_id
	_update_team_properties()

	team_changed.emit(team_id, old_team)


## Updates team color and name based on team ID
func _update_team_properties() -> void:
	if TEAM_COLORS.has(team_id):
		team_color = TEAM_COLORS[team_id]
	else:
		team_color = Color.WHITE

	if TEAM_NAMES.has(team_id):
		team_name = TEAM_NAMES[team_id]
	else:
		team_name = "Unknown"

	# Apply visual changes if entity has a sprite
	_apply_team_visuals()


## Applies team-specific visual changes to the entity
func _apply_team_visuals() -> void:
	if not entity:
		return

	# Look for sprite nodes to apply team color
	for child in entity.get_children():
		if child is Sprite2D:
			child.modulate = team_color
		elif child is AnimatedSprite2D:
			child.modulate = team_color


## Checks if another entity is an enemy
func is_enemy(other_entity: Entity) -> bool:
	if not other_entity or other_entity == entity:
		return false

	if hostile_to_all:
		return true

	var other_team: TeamComponent = other_entity.get_component("TeamComponent") as TeamComponent
	if not other_team:
		return false

	if other_team.hostile_to_all:
		return true

	# Neutral entities are not enemies to anyone (unless hostile_to_all)
	if team_id == Team.NEUTRAL or other_team.team_id == Team.NEUTRAL:
		return false

	return team_id != other_team.team_id


## Checks if another entity is an ally
func is_ally(other_entity: Entity) -> bool:
	if not other_entity or other_entity == entity:
		return false

	if hostile_to_all:
		return false

	var other_team: TeamComponent = other_entity.get_component("TeamComponent") as TeamComponent
	if not other_team:
		return false

	if other_team.hostile_to_all:
		return false

	return team_id == other_team.team_id and team_id != Team.NEUTRAL


## Checks if this entity is neutral
func is_neutral() -> bool:
	return team_id == Team.NEUTRAL and not hostile_to_all


## Gets the opposite team ID
func get_opposite_team() -> int:
	match team_id:
		Team.TEAM_BLUE:
			return Team.TEAM_RED
		Team.TEAM_RED:
			return Team.TEAM_BLUE
		_:
			return Team.NEUTRAL


## Switches to the opposite team
func switch_team() -> void:
	set_team(get_opposite_team())


## Gets all entities on the same team
func get_team_members() -> Array[Entity]:
	var team_members: Array[Entity] = []

	# This would be implemented when GameManager is available
	# var game_manager = get_node("/root/GameManager")
	# var all_entities = game_manager.get_all_entities()
	# for entity in all_entities:
	#     if is_ally(entity):
	#         team_members.append(entity)

	return team_members


## Gets all enemy entities
func get_enemies() -> Array[Entity]:
	var enemies: Array[Entity] = []

	# This would be implemented when GameManager is available
	# var game_manager = get_node("/root/GameManager")
	# var all_entities = game_manager.get_all_entities()
	# for entity in all_entities:
	#     if is_enemy(entity):
	#         enemies.append(entity)

	return enemies


## Gets the team's base/castle position
func get_team_base_position() -> Vector2:
	# This would return the position of the team's castle
	# For now, return placeholder positions
	match team_id:
		Team.TEAM_BLUE:
			return Vector2(-500, 0)  # Left side
		Team.TEAM_RED:
			return Vector2(500, 0)   # Right side
		_:
			return Vector2.ZERO


## Resets the component to its default state
func reset() -> void:
	set_team(Team.TEAM_BLUE)
	hostile_to_all = false


## Returns a dictionary representation of the component's data
func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["team_id"] = team_id
	data["team_color"] = team_color.to_html()
	data["team_name"] = team_name
	data["hostile_to_all"] = hostile_to_all
	return data


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("team_id"):
		team_id = data["team_id"]
	if data.has("team_color"):
		team_color = Color.html(data["team_color"])
	if data.has("team_name"):
		team_name = data["team_name"]
	if data.has("hostile_to_all"):
		hostile_to_all = data["hostile_to_all"]

	_update_team_properties()
