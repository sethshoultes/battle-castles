extends Area2D
class_name Projectile

## Generic projectile for ranged attacks

@export var damage: float = 50.0
@export var speed: float = 400.0
@export var max_distance: float = 1000.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var owner_team: int = 0
var attacker: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(start_pos: Vector2, target_pos: Vector2, dmg: float, team: int, source: Node2D = null) -> void:
	global_position = start_pos
	damage = dmg
	owner_team = team
	attacker = source

	# Calculate direction and rotation
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# Move projectile
	var movement = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()

	# Destroy if max distance reached
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("get_team") and body.get_team() != owner_team:
		# Hit enemy unit
		if body.has_method("take_damage"):
			body.take_damage(damage, attacker)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get_team") and area.get_team() != owner_team:
		# Hit enemy building/tower
		if area.has_method("take_damage"):
			area.take_damage(damage, attacker)
		queue_free()
