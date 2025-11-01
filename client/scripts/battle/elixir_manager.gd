extends Node
class_name ElixirManager

# Elixir properties
var current_elixir: float = 5.0
var max_elixir: float = 10.0
var base_regen_rate: float = 1.0 / 2.8  # 1 elixir per 2.8 seconds
var regen_rate: float = base_regen_rate
var is_double_elixir: bool = false

# Signals
signal elixir_changed(amount: float)
signal elixir_spent(amount: float)
signal elixir_full()

func _ready() -> void:
	# Start with 5 elixir
	current_elixir = 5.0

func _process(delta: float) -> void:
	regenerate_elixir(delta)

func regenerate_elixir(delta: float) -> void:
	if current_elixir < max_elixir:
		var previous_elixir := current_elixir
		current_elixir = min(current_elixir + (regen_rate * delta), max_elixir)

		if current_elixir != previous_elixir:
			elixir_changed.emit(current_elixir)

			if current_elixir >= max_elixir:
				elixir_full.emit()

func can_afford(cost: int) -> bool:
	return current_elixir >= cost

func spend(cost: int) -> bool:
	if can_afford(cost):
		current_elixir -= cost
		elixir_spent.emit(cost)
		elixir_changed.emit(current_elixir)
		return true
	return false

func add_elixir(amount: float) -> void:
	current_elixir = min(current_elixir + amount, max_elixir)
	elixir_changed.emit(current_elixir)

func set_double_elixir(enabled: bool) -> void:
	is_double_elixir = enabled
	if enabled:
		regen_rate = base_regen_rate * 2.0
	else:
		regen_rate = base_regen_rate

func get_elixir_percentage() -> float:
	return current_elixir / max_elixir

func reset() -> void:
	current_elixir = 5.0
	is_double_elixir = false
	regen_rate = base_regen_rate
	elixir_changed.emit(current_elixir)