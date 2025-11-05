extends Control

class_name LoadingScreen

## Loading screen UI with progress bar and spinner
## Used by SceneManager during scene transitions

# UI Elements
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var spinner: ColorRect = $CenterContainer/VBoxContainer/SpinnerContainer/Spinner

# Loading tips
const LOADING_TIPS: Array[String] = [
	"Tip: Deploy units strategically to counter your opponent's cards",
	"Tip: Elixir regenerates faster in the final minute of battle",
	"Tip: Knights are tanky units that can absorb damage for your tower",
	"Tip: Archers have long range and can hit air units",
	"Tip: Goblin Squads are cheap units perfect for quick defense",
	"Tip: Giants deal massive damage to towers but move slowly",
	"Tip: Balance your deck with offense, defense, and support units",
	"Tip: Watch your elixir carefully and don't overspend",
	"Tip: Timing is everything - wait for the right moment to push",
	"Tip: Destroying a tower unlocks new deployment areas"
]

var spinner_rotation: float = 0.0
var rotation_speed: float = 3.0  # Radians per second


func _ready() -> void:
	# Initialize progress bar
	progress_bar.value = 0.0
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0

	# Show random tip
	_show_random_tip()

	# Connect to SceneManager signals if available
	if SceneManager:
		SceneManager.scene_load_progress.connect(_on_scene_load_progress)


func _process(delta: float) -> void:
	# Rotate spinner
	spinner_rotation += rotation_speed * delta
	if spinner_rotation >= TAU:  # TAU = 2 * PI
		spinner_rotation -= TAU

	spinner.rotation = spinner_rotation


func _show_random_tip() -> void:
	if LOADING_TIPS.is_empty():
		tip_label.visible = false
		return

	var random_index: int = randi() % LOADING_TIPS.size()
	tip_label.text = LOADING_TIPS[random_index]


func _on_scene_load_progress(progress: float) -> void:
	set_progress(progress)


func set_progress(value: float) -> void:
	"""Update the progress bar value (0.0 to 1.0)"""
	progress_bar.value = clamp(value, 0.0, 1.0)

	# Update loading text
	var percent: int = int(value * 100)
	loading_label.text = "Loading... %d%%" % percent


func set_loading_text(text: String) -> void:
	"""Set custom loading text"""
	loading_label.text = text


func show_tip(tip: String) -> void:
	"""Show a specific loading tip"""
	tip_label.text = tip
	tip_label.visible = true


func hide_tip() -> void:
	"""Hide the loading tip"""
	tip_label.visible = false


func reset() -> void:
	"""Reset loading screen to initial state"""
	progress_bar.value = 0.0
	loading_label.text = "Loading... 0%"
	_show_random_tip()
	spinner_rotation = 0.0
