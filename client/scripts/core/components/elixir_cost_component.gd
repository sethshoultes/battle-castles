## Component that manages an entity's elixir cost for deployment
class_name ElixirCostComponent
extends Component

## Signal emitted when elixir cost changes
signal cost_changed(new_cost: int, old_cost: int)

## Base elixir cost to deploy this entity
@export_range(1, 10) var cost: int = 3

## Whether the cost can be modified by game effects
@export var can_be_modified: bool = true

## Current cost modifier (multiplicative)
var cost_modifier: float = 1.0

## Current cost reduction (flat reduction)
var cost_reduction: int = 0

## Minimum allowed cost after modifications
@export_range(1, 10) var minimum_cost: int = 1

## Maximum allowed cost after modifications
@export_range(1, 10) var maximum_cost: int = 10


## Returns the component class name for identification
func get_class() -> String:
	return "ElixirCostComponent"


## Called when the component is attached to an entity
func on_attached() -> void:
	cost = clamp(cost, minimum_cost, maximum_cost)


## Gets the effective elixir cost after all modifiers
func get_effective_cost() -> int:
	if not can_be_modified:
		return cost

	# Apply multiplicative modifier first
	var modified_cost: float = cost * cost_modifier

	# Apply flat reduction
	modified_cost -= cost_reduction

	# Clamp to valid range
	var final_cost: int = int(modified_cost)
	final_cost = clamp(final_cost, minimum_cost, maximum_cost)

	return final_cost


## Sets the base elixir cost
func set_cost(new_cost: int) -> void:
	var old_cost: int = cost
	cost = clamp(new_cost, minimum_cost, maximum_cost)

	if cost != old_cost:
		cost_changed.emit(cost, old_cost)


## Applies a multiplicative cost modifier
func apply_cost_modifier(modifier: float, duration: float = -1.0) -> void:
	if not can_be_modified:
		return

	var old_effective_cost: int = get_effective_cost()
	cost_modifier = max(0.1, modifier)  # Minimum 10% cost

	var new_effective_cost: int = get_effective_cost()
	if new_effective_cost != old_effective_cost:
		cost_changed.emit(new_effective_cost, old_effective_cost)

	# Reset after duration if specified
	if duration > 0.0 and entity and entity.is_inside_tree():
		await entity.get_tree().create_timer(duration).timeout
		reset_cost_modifier()


## Applies a flat cost reduction
func apply_cost_reduction(reduction: int, duration: float = -1.0) -> void:
	if not can_be_modified:
		return

	var old_effective_cost: int = get_effective_cost()
	cost_reduction = max(0, reduction)

	var new_effective_cost: int = get_effective_cost()
	if new_effective_cost != old_effective_cost:
		cost_changed.emit(new_effective_cost, old_effective_cost)

	# Reset after duration if specified
	if duration > 0.0 and entity and entity.is_inside_tree():
		await entity.get_tree().create_timer(duration).timeout
		reset_cost_reduction()


## Resets the cost modifier to default
func reset_cost_modifier() -> void:
	if cost_modifier == 1.0:
		return

	var old_effective_cost: int = get_effective_cost()
	cost_modifier = 1.0

	var new_effective_cost: int = get_effective_cost()
	if new_effective_cost != old_effective_cost:
		cost_changed.emit(new_effective_cost, old_effective_cost)


## Resets the cost reduction to zero
func reset_cost_reduction() -> void:
	if cost_reduction == 0:
		return

	var old_effective_cost: int = get_effective_cost()
	cost_reduction = 0

	var new_effective_cost: int = get_effective_cost()
	if new_effective_cost != old_effective_cost:
		cost_changed.emit(new_effective_cost, old_effective_cost)


## Resets all cost modifications
func reset_all_modifiers() -> void:
	var old_effective_cost: int = get_effective_cost()
	cost_modifier = 1.0
	cost_reduction = 0

	var new_effective_cost: int = get_effective_cost()
	if new_effective_cost != old_effective_cost:
		cost_changed.emit(new_effective_cost, old_effective_cost)


## Checks if the entity can be deployed with the given elixir amount
func can_deploy_with_elixir(available_elixir: int) -> bool:
	return available_elixir >= get_effective_cost()


## Gets the elixir deficit (how much more elixir is needed)
func get_elixir_deficit(available_elixir: int) -> int:
	var deficit: int = get_effective_cost() - available_elixir
	return max(0, deficit)


## Gets a color based on cost (for UI representation)
func get_cost_color() -> Color:
	var effective_cost: int = get_effective_cost()

	if effective_cost <= 3:
		return Color.GREEN  # Low cost
	elif effective_cost <= 5:
		return Color.YELLOW  # Medium cost
	elif effective_cost <= 7:
		return Color.ORANGE  # High cost
	else:
		return Color.RED  # Very high cost


## Gets a description of the cost for UI
func get_cost_description() -> String:
	var effective_cost: int = get_effective_cost()

	if cost_modifier != 1.0 or cost_reduction > 0:
		var modifier_text: String = ""

		if cost_modifier < 1.0:
			modifier_text = " (Discounted)"
		elif cost_modifier > 1.0:
			modifier_text = " (Increased)"

		if cost_reduction > 0:
			modifier_text += " (-" + str(cost_reduction) + ")"

		return str(effective_cost) + modifier_text
	else:
		return str(effective_cost)


## Resets the component to its default state
func reset() -> void:
	cost_modifier = 1.0
	cost_reduction = 0
	cost = clamp(cost, minimum_cost, maximum_cost)


## Returns a dictionary representation of the component's data
func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["cost"] = cost
	data["can_be_modified"] = can_be_modified
	data["cost_modifier"] = cost_modifier
	data["cost_reduction"] = cost_reduction
	data["minimum_cost"] = minimum_cost
	data["maximum_cost"] = maximum_cost
	return data


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("cost"):
		cost = data["cost"]
	if data.has("can_be_modified"):
		can_be_modified = data["can_be_modified"]
	if data.has("cost_modifier"):
		cost_modifier = data["cost_modifier"]
	if data.has("cost_reduction"):
		cost_reduction = data["cost_reduction"]
	if data.has("minimum_cost"):
		minimum_cost = data["minimum_cost"]
	if data.has("maximum_cost"):
		maximum_cost = data["maximum_cost"]

	cost = clamp(cost, minimum_cost, maximum_cost)