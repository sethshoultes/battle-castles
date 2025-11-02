extends CharacterBody2D
class_name SimpleUnit

# Unit properties
var unit_type: String = "knight"
var team: int = 0
var card_data: CardData = null

func _init():
	print("==========================================")
	print("SIMPLE UNIT CREATED!!!")
	print("==========================================")


# Stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var damage: float = 50.0
var attack_speed: float = 1.0
var move_speed: float = 60.0
var attack_range: float = 64.0

# Combat state
var target: Node2D = null
var attack_timer: float = 0.0
var is_attacking: bool = false

# References
var health_bar: ProgressBar = null
var sprite: ColorRect = null

func _ready() -> void:
	print("SimpleUnit _ready() called - Team: ", team, " Type: ", unit_type, " Pos: ", global_position)

	# Find child nodes
	for child in get_children():
		if child is ProgressBar:
			health_bar = child
		elif child is ColorRect:
			sprite = child

	# Apply stats if we have card_data already
	if card_data:
		max_health = float(card_data.hitpoints)
		current_health = max_health
		damage = float(card_data.damage)
		attack_speed = card_data.attack_speed
		move_speed = card_data.movement_speed
		attack_range = card_data.attack_range * 64.0

		print("  Stats loaded - HP:", max_health, " Damage:", damage, " Speed:", move_speed)

	update_health_bar()

	print("  Ready complete - Will move: ", move_speed > 0)

func initialize(type: String, team_id: int, data: CardData) -> void:
	unit_type = type
	team = team_id
	card_data = data

	print("Unit initialized: ", unit_type, " Team: ", team, " Position: ", global_position)

	if card_data:
		max_health = float(card_data.hitpoints)
		current_health = max_health
		damage = float(card_data.damage)
		attack_speed = card_data.attack_speed
		move_speed = card_data.movement_speed
		attack_range = card_data.attack_range * 64.0  # Convert tiles to pixels

		print("  Stats - HP:", max_health, " Damage:", damage, " Speed:", move_speed)

		update_health_bar()

func _process(delta: float) -> void:
	# Debug once per second
	if Engine.get_process_frames() % 60 == 0:
		print(unit_type, " PROCESS - Team:", team, " HasTarget:", target != null, " Pos:", global_position, " Speed:", move_speed)

	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta

	# Find target if we don't have one
	if not target or not is_instance_valid(target):
		find_target()

	# Behavior based on whether we have a target
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)

		if distance <= attack_range:
			# In range - attack
			attack_target(delta)
		else:
			# Out of range - move closer
			move_toward_target(delta)
	else:
		# No target - move forward
		move_forward(delta)

func find_target() -> void:
	var battlefield = get_parent().get_parent()
	if not battlefield:
		return

	var closest_tower: Node2D = null
	var closest_tower_distance: float = 999999.0
	var closest_unit: Node2D = null
	var closest_unit_distance: float = 999999.0

	# Find closest enemy tower/castle (PRIORITY)
	var towers_container = battlefield.get_node_or_null("Towers")
	if towers_container:
		for tower in towers_container.get_children():
			if not tower.has_method("get"):
				continue
			if "team" in tower and tower.team == team:
				continue  # Same team

			var dist = global_position.distance_to(tower.global_position)
			if dist < closest_tower_distance:
				closest_tower_distance = dist
				closest_tower = tower

	# Find closest enemy unit (SECONDARY)
	var units_container = battlefield.get_node_or_null("Units")
	if units_container:
		for unit in units_container.get_children():
			if unit == self:
				continue
			if not unit.has_method("get_team"):
				continue
			if unit.get_team() == team:
				continue  # Same team

			var dist = global_position.distance_to(unit.global_position)
			if dist < closest_unit_distance:
				closest_unit_distance = dist
				closest_unit = unit

	# Targeting priority:
	# 1. If enemy unit is in attack range, target it
	# 2. Otherwise target closest tower (even if far)
	# 3. If no towers, target closest unit
	if closest_unit and closest_unit_distance <= attack_range * 1.5:
		# Enemy in range - fight them
		target = closest_unit
	elif closest_tower:
		# Head for tower
		target = closest_tower
	else:
		# No towers left, clean up units
		target = closest_unit

func move_toward_target(delta: float) -> void:
	if not target:
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Check if we hit something
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()

		# If we hit an enemy, become their target and stop moving
		if collider and collider.has_method("get_team"):
			if collider.get_team() != team:
				target = collider
				velocity = Vector2.ZERO

func move_forward(delta: float) -> void:
	# Move up or down depending on team
	var direction: Vector2
	if team == 0:  # Player team - move up
		direction = Vector2(0, -1)
	else:  # Opponent team - move down
		direction = Vector2(0, 1)

	velocity = direction * move_speed
	move_and_slide()

	# Check if we collided with something
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()

		# If we hit an enemy, stop and attack them
		if collider and collider.has_method("get_team"):
			if collider.get_team() != team:
				target = collider
				velocity = Vector2.ZERO

func attack_target(delta: float) -> void:
	if attack_timer > 0:
		return

	if not target or not is_instance_valid(target):
		return

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		print(unit_type, " attacked ", target.name, " for ", damage, " damage")

	# Reset attack timer
	attack_timer = attack_speed

	# Visual feedback
	flash_sprite()

func take_damage(amount: float, attacker: Node2D = null) -> void:
	current_health -= amount
	current_health = max(0, current_health)

	update_health_bar()
	flash_sprite()

	if current_health <= 0:
		die()

func die() -> void:
	print(unit_type, " died")
	queue_free()

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func flash_sprite() -> void:
	if sprite:
		var original_color = sprite.color
		sprite.color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.color = original_color

func get_team() -> int:
	return team
