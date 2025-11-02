## Base Entity class for the Entity-Component-System architecture
## Entities are containers that hold components and represent game objects
class_name Entity
extends Node2D

## Dictionary storing all components attached to this entity
var _components: Dictionary = {}

## Unique identifier for this entity
var entity_id: int = 0

## Whether this entity is active in the game world
var is_active: bool = true


func _ready() -> void:
	entity_id = get_instance_id()


## Adds a component to this entity
## Returns true if the component was successfully added
func add_component(component: Component) -> bool:
	if component == null:
		push_error("Cannot add null component to entity")
		return false

	var component_class: String = component.get_component_class()

	if has_component(component_class):
		push_warning("Entity already has component of type: " + component_class)
		return false

	_components[component_class] = component
	component.entity = self

	# Components are Resources, not Nodes, so they don't need to be added to scene tree
	# If you need Node-based components, consider a different architecture

	component.on_attached()
	return true


## Gets a component of the specified class type
## Returns null if the component is not found
func get_component(component_class: String) -> Component:
	if not has_component(component_class):
		return null

	return _components[component_class]


## Checks if this entity has a component of the specified class type
func has_component(component_class: String) -> bool:
	return _components.has(component_class)


## Removes a component from this entity
## Returns true if the component was successfully removed
func remove_component(component_class: String) -> bool:
	if not has_component(component_class):
		push_warning("Entity does not have component of type: " + component_class)
		return false

	var component: Component = _components[component_class]
	component.on_detached()

	# Components are Resources, not Nodes, so no need to remove from scene tree
	# Resource cleanup is handled by Godot's reference counting

	_components.erase(component_class)
	return true


## Gets all components attached to this entity
func get_all_components() -> Array[Component]:
	var result: Array[Component] = []
	for component in _components.values():
		result.append(component)
	return result


## Clears all components from this entity
func clear_components() -> void:
	for component_class in _components.keys():
		remove_component(component_class)


## Called when the entity is destroyed
func destroy() -> void:
	is_active = false
	clear_components()
	queue_free()


## Returns a string representation of this entity for debugging
func _to_string() -> String:
	var component_names: Array = []
	for key in _components.keys():
		component_names.append(key)

	return "Entity[id=%d, components=%s]" % [entity_id, str(component_names)]