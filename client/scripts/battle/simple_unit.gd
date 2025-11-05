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

# Navigation
var navigation_agent: NavigationAgent2D = null
var use_navigation: bool = false  # Start with direct movement
var navigation_init_timer: float = 0.0  # Track how long we've waited for nav
var max_nav_wait_time: float = 0.5  # Max 0.5 seconds to wait for navigation

# References
var health_bar: ProgressBar = null
var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null

func _ready() -> void:
	print("=========================================")
	print("SimpleUnit _ready() called")
	print("  Team: ", team, " Type: ", unit_type)
	print("  Position: ", global_position)
	print("  In scene tree: ", is_inside_tree())
	print("  Parent: ", get_parent())
	print("=========================================")

	# Find child nodes
	for child in get_children():
		if child is ProgressBar:
			health_bar = child
		elif child is Sprite2D:
			sprite = child
		elif child is CollisionShape2D:
			collision_shape = child

	print("  Found children - HealthBar:", health_bar != null, " Sprite:", sprite != null, " Collision:", collision_shape != null)

	# Apply stats if we have card_data already
	if card_data:
		max_health = float(card_data.hitpoints)
		current_health = max_health
		damage = float(card_data.damage)
		attack_speed = card_data.attack_speed
		move_speed = card_data.movement_speed
		attack_range = card_data.attack_range * 64.0

		print("  Stats loaded from card_data:")
		print("    HP:", max_health, " Damage:", damage)
		print("    Speed:", move_speed, " Attack Speed:", attack_speed)
		print("    Attack Range:", attack_range)
	else:
		print("  WARNING: No card_data! Using default stats.")
		print("    Default move_speed:", move_speed)

	update_health_bar()
	_setup_navigation()

	print("  Ready complete - Will move:", move_speed > 0, " use_navigation:", use_navigation)
	print("=========================================")

func _setup_navigation() -> void:
	# COMPLETELY DISABLE NAVIGATION - don't even create the agent
	# Navigation was causing units to freeze
	use_navigation = false

	# TODO: Re-implement navigation pathfinding properly
	# When re-enabling:
	# 1. Create NavigationAgent2D
	# 2. Configure properties (radius, avoidance, etc.)
	# 3. Wait for NavigationServer2D to sync (await physics_frame)
	# 4. Set use_navigation = true

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
	# DETAILED DEBUG - Print every frame for first 120 frames (2 seconds)
	if Engine.get_process_frames() <= 120:
		print("[FRAME ", Engine.get_process_frames(), "] ", unit_type, " Team:", team,
			  " Pos:", global_position, " Velocity:", velocity, " Speed:", move_speed,
			  " Target:", target != null, " Attacking:", is_attacking)

	# Debug once per second after initial 2 seconds
	elif Engine.get_process_frames() % 60 == 0:
		print(unit_type, " PROCESS - Team:", team, " HasTarget:", target != null, " Pos:", global_position, " Speed:", move_speed, " Velocity:", velocity)

	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta

	# Retarget every 30 frames (twice per second) to check for blocking units
	# More frequent retargeting would cause units to constantly switch targets
	if Engine.get_process_frames() % 30 == 0 or not target or not is_instance_valid(target):
		find_target()

	# Behavior based on whether we have a target
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)

		if distance <= attack_range:
			# In range - attack
			if not is_attacking:
				is_attacking = true
				# Disable collision so other units can pass through
				if collision_shape:
					collision_shape.disabled = true
			attack_target(delta)
		else:
			# Out of range - move closer
			if is_attacking:
				is_attacking = false
				# Re-enable collision when moving
				if collision_shape:
					collision_shape.disabled = false
			move_toward_target(delta)
	else:
		# No target - move forward
		if is_attacking:
			is_attacking = false
			# Re-enable collision when not in combat
			if collision_shape:
				collision_shape.disabled = false
		move_forward(delta)

func find_target() -> void:
	var battlefield = get_parent().get_parent()
	if not battlefield:
		if Engine.get_process_frames() <= 120:
			print("  [DEBUG] find_target - No battlefield! Parent:", get_parent())
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

	# Targeting priority (Clash Royale style):
	# 1. Always prioritize buildings/towers
	# 2. Only target units if they're in melee range (blocking path or attacking)
	# 3. If no buildings, then target units

	var old_target = target
	if closest_tower:
		# Buildings are ALWAYS primary target
		target = closest_tower

		# But if an enemy unit is in melee range, fight them first (they're blocking us)
		if closest_unit and closest_unit_distance <= attack_range * 1.5:
			target = closest_unit
	else:
		# No buildings left - clean up units
		target = closest_unit

	# Debug output for first 2 seconds
	if Engine.get_process_frames() <= 120 and (target != old_target or Engine.get_process_frames() % 30 == 0):
		if target:
			print("  [DEBUG] find_target - Found target:", target.name if target.has_method("get") else "unknown",
				  " Distance:", closest_tower_distance if closest_tower else closest_unit_distance)
		else:
			print("  [DEBUG] find_target - No target found")

func _on_navigation_ready() -> void:
	# Wait for physics frames to allow NavigationServer2D to sync
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Now navigation is synced and ready
	use_navigation = true
	print(unit_type, " [", team, "] navigation enabled at ", global_position)

func move_toward_target(delta: float) -> void:
	if not target:
		print("  [DEBUG] move_toward_target called but no target!")
		return

	if use_navigation and navigation_agent:
		# Use navigation pathfinding
		if navigation_agent.is_navigation_finished():
			# Set new target
			navigation_agent.target_position = target.global_position

		# Get next position from navigation
		var next_position = navigation_agent.get_next_path_position()

		# Validate we got a valid next position
		if next_position.distance_to(global_position) > 0.1:
			var direction = (next_position - global_position).normalized()

			# Set velocity for avoidance
			var desired_velocity = direction * move_speed
			navigation_agent.set_velocity(desired_velocity)
			velocity = desired_velocity
		else:
			# No valid path yet, don't move
			velocity = Vector2.ZERO
	else:
		# Use direct movement (navigation disabled or not ready)
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		if Engine.get_process_frames() <= 120:
			print("  [DEBUG] move_toward_target - Direction:", direction, " Velocity:", velocity, " move_speed:", move_speed)

	move_and_slide()

	# Maintain speed when sliding along walls
	if velocity.length() > 0 and velocity.length() < move_speed * 0.5:
		velocity = velocity.normalized() * move_speed

	# Check if we hit an enemy (not a wall)
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()

		# If we hit an enemy, become their target and stop moving
		if collider and collider.has_method("get_team"):
			if collider.get_team() != team:
				target = collider
				velocity = Vector2.ZERO

func move_forward(delta: float) -> void:
	# When no target, move towards enemy side
	if use_navigation and navigation_agent:
		# Set a target position far ahead in enemy territory
		var target_pos: Vector2
		if team == 0:  # Player team - move up
			target_pos = Vector2(576, 200)  # Enemy castle area
		else:  # Opponent team - move down
			target_pos = Vector2(576, 1600)  # Player castle area

		if navigation_agent.is_navigation_finished():
			navigation_agent.target_position = target_pos

		# Get next position from navigation
		var next_position = navigation_agent.get_next_path_position()

		# Validate we got a valid next position
		if next_position.distance_to(global_position) > 0.1:
			var direction = (next_position - global_position).normalized()

			# Set velocity for avoidance
			var desired_velocity = direction * move_speed
			navigation_agent.set_velocity(desired_velocity)
			velocity = desired_velocity
		else:
			# No valid path yet, don't move
			velocity = Vector2.ZERO
	else:
		# Use direct movement (navigation disabled or not ready)
		var direction: Vector2
		if team == 0:  # Player team - move up
			direction = Vector2(0, -1)
		else:  # Opponent team - move down
			direction = Vector2(0, 1)
		velocity = direction * move_speed
		if Engine.get_process_frames() <= 120:
			print("  [DEBUG] move_forward - Team:", team, " Direction:", direction, " Velocity:", velocity, " move_speed:", move_speed)

	move_and_slide()

	# Maintain speed when sliding along walls
	if velocity.length() > 0 and velocity.length() < move_speed * 0.5:
		velocity = velocity.normalized() * move_speed

	# Check if we collided with an enemy (not a wall)
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
		var original_modulate = sprite.modulate
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)  # Brighten the sprite
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = original_modulate

func get_team() -> int:
	return team
