## Scene transition and loading manager
## Handles smooth transitions between scenes with loading screens
## Add to Project Settings -> Autoload as "SceneManager"
extends Node

## Signals
signal scene_load_started(scene_path: String)
signal scene_load_progress(progress: float)
signal scene_load_completed(scene_path: String)
signal transition_started(transition_type: TransitionType)
signal transition_completed()

## Transition types
enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	DISSOLVE,
	CIRCLE_CLOSE,
	CIRCLE_OPEN
}

## Scene cache for instant loading
var scene_cache: Dictionary = {}
var cache_enabled: bool = true
var max_cached_scenes: int = 5

## Current scene info
var current_scene: Node = null
var current_scene_path: String = ""
var previous_scene_path: String = ""

## Loading state
var is_loading: bool = false
var loading_progress: float = 0.0
var load_thread: Thread = null

## Transition settings
var transition_duration: float = 0.5
var current_transition: TransitionType = TransitionType.FADE
var transition_overlay: ColorRect = null

## Loading screen
var loading_screen: Control = null
var loading_screen_scene: PackedScene = null


func _ready() -> void:
	# Get the current scene
	var root := get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

	# Create transition overlay
	_create_transition_overlay()

	# Try to load loading screen if it exists
	if ResourceLoader.exists("res://scenes/ui/loading_screen.tscn"):
		loading_screen_scene = load("res://scenes/ui/loading_screen.tscn")

	print("SceneManager initialized")


## Creates the transition overlay
func _create_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.visible = false
	transition_overlay.z_index = 1000  # Always on top

	# Add to tree (deferred to avoid "parent busy" error during _ready)
	get_tree().root.add_child.call_deferred(transition_overlay)


## Changes to a new scene with transition
func change_scene(scene_path: String, transition: TransitionType = TransitionType.FADE) -> void:
	if is_loading:
		push_warning("Scene change already in progress")
		return

	if not ResourceLoader.exists(scene_path):
		push_error("Scene does not exist: " + scene_path)
		return

	is_loading = true
	current_transition = transition
	previous_scene_path = current_scene_path
	current_scene_path = scene_path

	print("Changing scene to: ", scene_path)

	# Start transition
	await _transition_out()

	# Show loading screen for larger scenes
	var show_loading := _should_show_loading_screen(scene_path)
	if show_loading:
		_show_loading_screen()

	# Load the scene
	await _load_scene(scene_path)

	# Hide loading screen
	if show_loading:
		_hide_loading_screen()

	# Transition in
	await _transition_in()

	is_loading = false
	scene_load_completed.emit(scene_path)


## Transitions out the current scene
func _transition_out() -> void:
	transition_started.emit(current_transition)
	transition_overlay.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	match current_transition:
		TransitionType.FADE:
			transition_overlay.modulate.a = 0.0
			tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)

		TransitionType.SLIDE_LEFT:
			transition_overlay.position.x = get_viewport().size.x
			tween.tween_property(transition_overlay, "position:x", 0.0, transition_duration)

		TransitionType.SLIDE_RIGHT:
			transition_overlay.position.x = -get_viewport().size.x
			tween.tween_property(transition_overlay, "position:x", 0.0, transition_duration)

		TransitionType.SLIDE_UP:
			transition_overlay.position.y = get_viewport().size.y
			tween.tween_property(transition_overlay, "position:y", 0.0, transition_duration)

		TransitionType.SLIDE_DOWN:
			transition_overlay.position.y = -get_viewport().size.y
			tween.tween_property(transition_overlay, "position:y", 0.0, transition_duration)

		TransitionType.DISSOLVE:
			transition_overlay.modulate.a = 0.0
			tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration * 0.8)

		TransitionType.CIRCLE_CLOSE, TransitionType.CIRCLE_OPEN:
			# Implement circular transition with shader or animation
			transition_overlay.modulate.a = 0.0
			tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)

	await tween.finished


## Transitions in the new scene
func _transition_in() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	match current_transition:
		TransitionType.FADE:
			tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)

		TransitionType.SLIDE_LEFT:
			tween.tween_property(transition_overlay, "position:x", -get_viewport().size.x, transition_duration)

		TransitionType.SLIDE_RIGHT:
			tween.tween_property(transition_overlay, "position:x", get_viewport().size.x, transition_duration)

		TransitionType.SLIDE_UP:
			tween.tween_property(transition_overlay, "position:y", -get_viewport().size.y, transition_duration)

		TransitionType.SLIDE_DOWN:
			tween.tween_property(transition_overlay, "position:y", get_viewport().size.y, transition_duration)

		TransitionType.DISSOLVE:
			tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration * 1.2)

		TransitionType.CIRCLE_CLOSE, TransitionType.CIRCLE_OPEN:
			tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)

	await tween.finished

	transition_overlay.visible = false
	transition_completed.emit()


## Loads a scene (with caching support)
func _load_scene(scene_path: String) -> void:
	scene_load_started.emit(scene_path)

	var new_scene: Node = null

	# Try to get from cache first
	if cache_enabled and scene_cache.has(scene_path):
		new_scene = scene_cache[scene_path].instantiate()
		print("Scene loaded from cache: ", scene_path)
	else:
		# Load normally
		var packed_scene: PackedScene = await _load_resource(scene_path)
		if packed_scene:
			new_scene = packed_scene.instantiate()

			# Cache the packed scene
			if cache_enabled:
				_cache_scene(scene_path, packed_scene)

	if not new_scene:
		push_error("Failed to load scene: " + scene_path)
		return

	# Replace current scene
	if current_scene:
		current_scene.queue_free()

	current_scene = new_scene
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene


## Loads a resource with progress tracking
func _load_resource(path: String) -> Resource:
	if ResourceLoader.has_cached(path):
		return ResourceLoader.load(path)

	# Use threaded loading for large scenes
	var request_status: Error = ResourceLoader.load_threaded_request(path)
	if request_status != OK:
		push_error("Failed to start loading: " + path)
		return null

	# Poll loading progress
	while true:
		var progress_array: Array = []
		var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress_array)

		if load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress_array.size() > 0:
				loading_progress = progress_array[0]
				scene_load_progress.emit(loading_progress)
			await get_tree().process_frame
		elif load_status == ResourceLoader.THREAD_LOAD_LOADED:
			loading_progress = 1.0
			scene_load_progress.emit(1.0)
			return ResourceLoader.load_threaded_get(path)
		else:
			push_error("Failed to load resource: " + path)
			return null

	# Unreachable, but satisfies static analysis
	return null


## Caches a scene for faster loading
func _cache_scene(scene_path: String, packed_scene: PackedScene) -> void:
	if scene_cache.size() >= max_cached_scenes:
		# Remove oldest cached scene
		var oldest_key: String = scene_cache.keys()[0]
		scene_cache.erase(oldest_key)

	scene_cache[scene_path] = packed_scene
	print("Scene cached: ", scene_path)


## Determines if loading screen should be shown
func _should_show_loading_screen(scene_path: String) -> bool:
	# Show for battle scenes (typically larger)
	if "battle" in scene_path.to_lower():
		return true
	return false


## Shows the loading screen
func _show_loading_screen() -> void:
	if not loading_screen_scene:
		return

	loading_screen = loading_screen_scene.instantiate()
	get_tree().root.add_child(loading_screen)
	loading_screen.z_index = 999


## Hides the loading screen
func _hide_loading_screen() -> void:
	if loading_screen:
		loading_screen.queue_free()
		loading_screen = null


## Preloads a scene into cache
func preload_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("Cannot preload non-existent scene: " + scene_path)
		return

	if scene_cache.has(scene_path):
		return  # Already cached

	var packed_scene: PackedScene = load(scene_path)
	if packed_scene:
		_cache_scene(scene_path, packed_scene)
		print("Scene preloaded: ", scene_path)


## Clears the scene cache
func clear_cache() -> void:
	scene_cache.clear()
	print("Scene cache cleared")


## Goes back to previous scene
func go_back(transition: TransitionType = TransitionType.FADE) -> void:
	if previous_scene_path.is_empty():
		push_warning("No previous scene to go back to")
		return

	change_scene(previous_scene_path, transition)


## Reloads the current scene
func reload_current_scene(transition: TransitionType = TransitionType.FADE) -> void:
	if current_scene_path.is_empty():
		push_warning("No current scene to reload")
		return

	change_scene(current_scene_path, transition)


## Quick scene changes (common scenes)
func goto_main_menu() -> void:
	change_scene("res://scenes/main_menu.tscn", TransitionType.FADE)


func goto_battle() -> void:
	change_scene("res://scenes/battle/battle.tscn", TransitionType.FADE)


func goto_deck_builder() -> void:
	change_scene("res://scenes/ui/deck_builder.tscn", TransitionType.SLIDE_LEFT)


func goto_settings() -> void:
	change_scene("res://scenes/ui/settings.tscn", TransitionType.SLIDE_UP)


## Sets transition duration
func set_transition_duration(duration: float) -> void:
	transition_duration = duration


## Gets loading progress (0.0 to 1.0)
func get_loading_progress() -> float:
	return loading_progress


## Checks if currently loading
func is_scene_loading() -> bool:
	return is_loading
