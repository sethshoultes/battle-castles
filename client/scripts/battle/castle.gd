extends Tower
class_name Castle

# Castle-specific properties (King's Tower)
@export var requires_activation: bool = true
@export var activated: bool = false
@export var linked_towers: Array[NodePath] = []

# Castle has higher stats than princess towers
func _ready() -> void:
	# Set castle-specific stats
	tower_type = "castle"
	max_health = 4824.0  # King tower health
	current_health = max_health
	attack_damage = 139.0  # Higher damage
	attack_speed = 1.2  # Slightly faster than princess towers (1.2 attacks/sec)
	attack_range = 6.5 * 64  # 6.5 tiles

	# Initially inactive if requires activation
	if requires_activation:
		is_active = false

	# Call parent ready
	super._ready()

	# Monitor linked towers
	monitor_linked_towers()

func monitor_linked_towers() -> void:
	for tower_path in linked_towers:
		var tower = get_node_or_null(tower_path)
		if tower and tower.has_signal("tower_destroyed"):
			tower.tower_destroyed.connect(_on_linked_tower_destroyed)

func _on_linked_tower_destroyed(_team: int, _tower_type: String) -> void:
	# Activate castle when any princess tower is destroyed
	if not activated and requires_activation:
		activate_castle()

func activate_castle() -> void:
	if activated:
		return

	activated = true
	is_active = true

	# Visual feedback for activation
	show_activation_effect()

	# Start attacking if there are enemies in range
	if enemies_in_range.size() > 0:
		acquire_target()

func show_activation_effect() -> void:
	# Placeholder for activation visual effects
	# This could include:
	# - Particle effects
	# - Screen shake
	# - Sound effects
	# - Animation of the king "waking up"

	# For now, just modulate the sprite to show activation
	if sprite:
		var tween := get_tree().create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.2), 0.3)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func destroy() -> void:
	# Castle destruction ends the game
	super.destroy()

	# Additional castle-specific destruction effects
	trigger_victory_condition()

func trigger_victory_condition() -> void:
	# When castle is destroyed, the game ends
	# This will be handled by BattleManager
	pass

func take_damage(damage: float, attacker: Node2D = null) -> void:
	# Castle takes damage normally but may have special effects
	super.take_damage(damage, attacker)

	# Activate if taking damage and not yet active
	if requires_activation and not activated and not is_destroyed:
		activate_castle()

# Override to handle castle-specific targeting
func acquire_target() -> void:
	if not is_active or not activated:
		return

	super.acquire_target()

func get_status_info() -> Dictionary:
	return {
		"type": "castle",
		"team": team,
		"health": current_health,
		"max_health": max_health,
		"activated": activated,
		"destroyed": is_destroyed
	}