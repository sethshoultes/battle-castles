## Base class for all unit entities in the game
## Extends Entity from the ECS architecture and implements state machine
class_name BaseUnit
extends Entity

## Unit states
enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DYING,
	DEAD
}

## Current unit state
var current_state: State = State.IDLE

## Components references for quick access
var health_component: HealthComponent
var attack_component: AttackComponent
var movement_component: MovementComponent
var stats_component: StatsComponent
var team_component: TeamComponent

## Target acquisition
var current_target: Entity = null
var target_check_timer: float = 0.0
var target_check_interval: float = 0.5  # Check for targets every 0.5 seconds

## Visual components (will be set from scene)
var sprite: AnimatedSprite2D
var health_bar: ProgressBar
var collision_shape: CollisionShape2D
var attack_area: Area2D

## Death handling
var death_timer: float = 0.0
var death_duration: float = 1.0  # Time before unit is removed after death


func _ready() -> void:
	super._ready()
	_initialize_components()
	_connect_signals()
	_initialize_visuals()


## Initialize unit with specific stats
func initialize(hp: int, damage: int, attack_speed: float, move_speed: float,
				attack_range: float, elixir_cost: int, unit_name: String,
				team_id: int = 0) -> void:

	# Setup health component
	if health_component:
		health_component.max_health = hp
		health_component.current_health = hp

	# Setup attack component
	if attack_component:
		attack_component.damage = damage
		attack_component.attack_speed = attack_speed
		attack_component.range = attack_range

	# Setup movement component
	if movement_component:
		movement_component.movement_speed = move_speed

	# Setup stats component
	if stats_component:
		stats_component.unit_name = unit_name
		stats_component.elixir_cost = elixir_cost

	# Setup team component
	if team_component:
		team_component.team_id = team_id


## Initialize all required components
func _initialize_components() -> void:
	# Create and add health component
	health_component = HealthComponent.new()
	add_component(health_component)

	# Create and add attack component
	attack_component = AttackComponent.new()
	add_component(attack_component)

	# Create and add movement component
	movement_component = MovementComponent.new()
	add_component(movement_component)

	# Create and add stats component
	stats_component = StatsComponent.new()
	add_component(stats_component)

	# Create and add team component
	team_component = TeamComponent.new()
	add_component(team_component)


## Connect component signals
func _connect_signals() -> void:
	if health_component:
		health_component.died.connect(_on_unit_died)
		health_component.health_changed.connect(_on_health_changed)
		health_component.damage_taken.connect(_on_damage_taken)

	if movement_component:
		movement_component.destination_reached.connect(_on_destination_reached)
		movement_component.movement_started.connect(_on_movement_started)
		movement_component.movement_stopped.connect(_on_movement_stopped)

	if attack_component:
		attack_component.attack_performed.connect(_on_attack_performed)


## Initialize visual components
func _initialize_visuals() -> void:
	# Get visual nodes if they exist in the scene
	if has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D

	if has_node("HealthBar"):
		health_bar = $HealthBar
		if health_bar and health_component:
			health_bar.max_value = health_component.max_health
			health_bar.value = health_component.current_health

	if has_node("CollisionShape2D"):
		collision_shape = $CollisionShape2D

	if has_node("AttackArea"):
		attack_area = $AttackArea
		if attack_area:
			attack_area.body_entered.connect(_on_attack_area_entered)
			attack_area.body_exited.connect(_on_attack_area_exited)


func _process(delta: float) -> void:
	if not is_active:
		return

	# Update components
	for component in get_all_components():
		if component.enabled:
			component.update(delta)

	# Update state machine
	_update_state_machine(delta)

	# Update target acquisition
	_update_target_acquisition(delta)

	# Update visuals
	_update_visuals()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Update movement
	if movement_component and movement_component.enabled:
		movement_component.physics_update(delta)


## Update the state machine
func _update_state_machine(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.MOVING:
			_state_moving(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.DYING:
			_state_dying(delta)
		State.DEAD:
			_state_dead(delta)


## Idle state logic
func _state_idle(delta: float) -> void:
	# Look for targets
	if current_target and is_instance_valid(current_target):
		if attack_component and attack_component.is_in_range(current_target):
			_change_state(State.ATTACKING)
		else:
			_change_state(State.MOVING)
	elif _find_nearest_target():
		if attack_component and attack_component.is_in_range(current_target):
			_change_state(State.ATTACKING)
		else:
			_change_state(State.MOVING)


## Moving state logic
func _state_moving(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		_change_state(State.IDLE)
		return

	# Check if target is in attack range
	if attack_component and attack_component.is_in_range(current_target):
		movement_component.stop()
		_change_state(State.ATTACKING)
	else:
		# Move towards target
		if movement_component and not movement_component.is_moving:
			movement_component.move_to(current_target.global_position)


## Attacking state logic
func _state_attacking(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		_change_state(State.IDLE)
		return

	# Check if target is still in range
	if attack_component and not attack_component.is_in_range(current_target):
		_change_state(State.MOVING)
		return

	# Perform attack if ready
	if attack_component and attack_component.can_attack:
		attack_component.perform_attack(current_target)
		_on_attack_animation()


## Dying state logic
func _state_dying(delta: float) -> void:
	death_timer += delta
	if death_timer >= death_duration:
		_change_state(State.DEAD)


## Dead state logic
func _state_dead(delta: float) -> void:
	destroy()


## Change to a new state
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	# Exit current state
	_exit_state(current_state)

	# Enter new state
	current_state = new_state
	_enter_state(new_state)


## Called when entering a state
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			if sprite:
				sprite.play("idle")
		State.MOVING:
			if sprite:
				sprite.play("walk")
		State.ATTACKING:
			if sprite:
				sprite.play("attack")
		State.DYING:
			death_timer = 0.0
			is_active = false
			if sprite:
				sprite.play("death")
			if collision_shape:
				collision_shape.disabled = true
		State.DEAD:
			pass


## Called when exiting a state
func _exit_state(state: State) -> void:
	match state:
		State.MOVING:
			if movement_component:
				movement_component.stop()
		State.ATTACKING:
			pass


## Update target acquisition
func _update_target_acquisition(delta: float) -> void:
	target_check_timer += delta
	if target_check_timer >= target_check_interval:
		target_check_timer = 0.0

		# Validate current target
		if current_target and is_instance_valid(current_target):
			var target_health = current_target.get_component("HealthComponent") as HealthComponent
			if target_health and target_health.is_dead:
				current_target = null

		# Find new target if needed
		if not current_target:
			_find_nearest_target()


## Find the nearest valid target
func _find_nearest_target() -> bool:
	# This would query the game manager or use the attack area
	# For now, return false (will be implemented with game manager)
	return false


## Update visual components
func _update_visuals() -> void:
	# Update health bar
	if health_bar and health_component:
		health_bar.value = health_component.current_health
		health_bar.visible = health_component.current_health < health_component.max_health

	# Face movement direction
	if sprite and movement_component and movement_component.is_moving:
		var direction = movement_component.get_direction()
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false


## Signal callbacks
func _on_unit_died() -> void:
	_change_state(State.DYING)


func _on_health_changed(new_health: int, max_health: int) -> void:
	pass  # Override in derived classes if needed


func _on_damage_taken(amount: int, source: Entity) -> void:
	# Apply damage reduction from stats
	if stats_component:
		var is_from_building = false
		if source and source.has_component("StatsComponent"):
			var source_stats = source.get_component("StatsComponent") as StatsComponent
			is_from_building = source_stats.is_building

		var reduced_damage = stats_component.calculate_damage_reduction(amount, is_from_building)
		# The actual damage application is handled by HealthComponent


func _on_destination_reached() -> void:
	if current_state == State.MOVING:
		_change_state(State.IDLE)


func _on_movement_started(destination: Vector2) -> void:
	pass  # Override in derived classes if needed


func _on_movement_stopped() -> void:
	if current_state == State.MOVING:
		_change_state(State.IDLE)


func _on_attack_performed(target: Entity, damage: int) -> void:
	pass  # Override in derived classes if needed


func _on_attack_animation() -> void:
	# Play attack animation
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")


## Attack area callbacks
func _on_attack_area_entered(body: Node2D) -> void:
	if body is Entity and body != self:
		var body_team = body.get_component("TeamComponent") as TeamComponent
		if team_component and body_team and team_component.is_enemy(body):
			# Potential target entered range
			if not current_target:
				current_target = body as Entity


func _on_attack_area_exited(body: Node2D) -> void:
	if body == current_target:
		# Target left range, might need to find new target
		if current_state == State.ATTACKING:
			_change_state(State.IDLE)