## Goblin Squad spawner class
## Spawns 3 goblins in triangle formation for 2 elixir
class_name GoblinSquad
extends Node2D

## Squad constants
const SQUAD_SIZE = 3
const ELIXIR_COST = 2
const FORMATION_SPACING = 40.0  # Pixels between goblins

## Goblin scene to instantiate
@export var goblin_scene: PackedScene

## Team ID for the squad
@export var team_id: int = 0

## Player name
@export var player_name: String = "Player"

## Level of the goblins
@export var level: int = 1

## Whether to maintain formation
var maintain_formation: bool = true

## Array of spawned goblins
var goblins: Array[Goblin] = []

## Formation positions (triangle)
var formation_offsets: Array[Vector2] = [
	Vector2(0, -FORMATION_SPACING),  # Front goblin
	Vector2(-FORMATION_SPACING * 0.866, FORMATION_SPACING * 0.5),  # Back left
	Vector2(FORMATION_SPACING * 0.866, FORMATION_SPACING * 0.5)   # Back right
]

## Signal emitted when all goblins are dead
signal squad_eliminated()

## Signal emitted when a goblin dies
signal goblin_died(goblin: Goblin)


func _ready() -> void:
	spawn_goblins()


## Spawn the goblin squad
func spawn_goblins() -> void:
	# Clear any existing goblins
	for goblin in goblins:
		if is_instance_valid(goblin):
			goblin.queue_free()
	goblins.clear()

	# Spawn new goblins
	for i in range(SQUAD_SIZE):
		_spawn_single_goblin(i)

	# After initial spawn, goblins act independently
	await get_tree().create_timer(0.5).timeout
	maintain_formation = false


## Spawn a single goblin at the given index
func _spawn_single_goblin(index: int) -> void:
	var goblin: Goblin

	# Create goblin instance
	if goblin_scene:
		goblin = goblin_scene.instantiate() as Goblin
	else:
		# Create goblin programmatically if no scene
		goblin = Goblin.new()

	if not goblin:
		push_error("Failed to create goblin instance")
		return

	# Set position with formation offset
	goblin.position = formation_offsets[index]

	# Setup goblin properties
	if goblin.team_component:
		goblin.team_component.team_id = team_id
		goblin.team_component.player_name = player_name

	if goblin.stats_component:
		goblin.stats_component.level = level

	# Set squad reference
	goblin.set_squad(self, formation_offsets[index])

	# Add as child
	add_child(goblin)
	goblins.append(goblin)

	# Connect death signal
	goblin.died.connect(_on_goblin_died.bind(goblin))


## Called when a goblin in the squad dies
func on_goblin_died(goblin: Goblin) -> void:
	if goblin in goblins:
		goblins.erase(goblin)
		goblin_died.emit(goblin)

		# Check if all goblins are dead
		if goblins.is_empty():
			squad_eliminated.emit()
			queue_free()


## Move the entire squad to a position
func move_squad_to(target_position: Vector2) -> void:
	maintain_formation = true

	# Move squad center
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 1.0)

	# Update goblin targets
	for goblin in goblins:
		if is_instance_valid(goblin) and goblin.movement_component:
			var target = target_position + goblin.squad_offset
			goblin.movement_component.move_to(target)

	# Release formation after movement
	await tween.finished
	maintain_formation = false


## Set all goblins to attack a specific target
func attack_target(target: Entity) -> void:
	maintain_formation = false

	for goblin in goblins:
		if is_instance_valid(goblin):
			goblin.current_target = target


## Get the average position of all living goblins
func get_squad_center() -> Vector2:
	if goblins.is_empty():
		return global_position

	var center = Vector2.ZERO
	var count = 0

	for goblin in goblins:
		if is_instance_valid(goblin):
			center += goblin.global_position
			count += 1

	if count > 0:
		return center / count
	return global_position


## Get total squad health
func get_squad_health() -> int:
	var total_health = 0
	for goblin in goblins:
		if is_instance_valid(goblin) and goblin.health_component:
			total_health += goblin.health_component.current_health
	return total_health


## Get squad stats for UI
func get_squad_stats() -> Dictionary:
	return {
		"name": "Goblin Squad",
		"unit_count": SQUAD_SIZE,
		"elixir_cost": ELIXIR_COST,
		"level": level,
		"alive_count": goblins.size(),
		"total_health": get_squad_health(),
		"description": "Spawns 3 fast melee goblins"
	}


## Handle area damage to the squad
func apply_area_damage(damage: int, source: Entity) -> void:
	for goblin in goblins:
		if is_instance_valid(goblin) and goblin.health_component:
			goblin.health_component.take_damage(damage, source)


## Signal callback for goblin death
func _on_goblin_died(goblin: Goblin) -> void:
	on_goblin_died(goblin)