## Base Component class for the Entity-Component-System architecture
## Components are data containers that define entity properties and behaviors
class_name Component
extends Resource

## Reference to the entity that owns this component
var entity: Entity = null

## Whether this component is enabled
var enabled: bool = true


## Virtual method called when the component is attached to an entity
func on_attached() -> void:
	pass


## Virtual method called when the component is detached from an entity
func on_detached() -> void:
	entity = null


## Virtual method to get the component class name for identification
func get_class() -> String:
	push_error("Component subclass must override get_class() method")
	return "Component"


## Virtual method called to update the component
## Override in subclasses that need per-frame updates
func update(_delta: float) -> void:
	pass


## Virtual method to reset the component to its default state
func reset() -> void:
	pass


## Returns whether this component is valid and ready to use
func is_valid() -> bool:
	return entity != null and enabled


## Enables the component
func enable() -> void:
	enabled = true
	on_enabled()


## Disables the component
func disable() -> void:
	enabled = false
	on_disabled()


## Virtual method called when the component is enabled
func on_enabled() -> void:
	pass


## Virtual method called when the component is disabled
func on_disabled() -> void:
	pass


## Returns a dictionary representation of the component's data for serialization
func serialize() -> Dictionary:
	return {
		"class": get_class(),
		"enabled": enabled
	}


## Loads component data from a dictionary
func deserialize(data: Dictionary) -> void:
	if data.has("enabled"):
		enabled = data["enabled"]