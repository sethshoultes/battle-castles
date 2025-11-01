extends Node

class_name PerformanceOptimizer

# Quality presets
enum QualityPreset {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

# Performance monitoring
var fps_samples: Array = []
var fps_sample_size: int = 60
var current_fps: float = 60.0
var target_fps: float = 60.0
var min_acceptable_fps: float = 30.0

# Dynamic adjustment
var dynamic_quality_enabled: bool = true
var adjustment_cooldown: float = 5.0
var time_since_adjustment: float = 0.0

# Current quality level
var current_quality: int = QualityPreset.MEDIUM

# Platform detector reference
var platform_detector: PlatformDetector

# Quality settings cache
var quality_settings = {}

# Performance stats
var frame_time_ms: float = 0.0
var physics_time_ms: float = 0.0
var render_objects: int = 0

func _ready():
	# Get platform detector
	platform_detector = get_node_or_null("/root/PlatformDetector")
	if not platform_detector:
		platform_detector = PlatformDetector.new()
		add_child(platform_detector)

	# Set target FPS based on platform
	if platform_detector.is_raspberry_pi:
		target_fps = 30.0
		min_acceptable_fps = 25.0
	else:
		target_fps = 60.0
		min_acceptable_fps = 30.0

	# Initialize quality presets
	_initialize_quality_presets()

	# Apply recommended quality
	var recommended_quality = platform_detector.get_recommended_quality()
	apply_quality_preset_by_name(recommended_quality)

	print("Performance Optimizer Initialized:")
	print("  Target FPS: ", target_fps)
	print("  Min Acceptable FPS: ", min_acceptable_fps)
	print("  Initial Quality: ", get_quality_name(current_quality))
	print("  Dynamic Adjustment: ", dynamic_quality_enabled)

func _initialize_quality_presets():
	# LOW - Raspberry Pi 5 and low-end hardware
	quality_settings[QualityPreset.LOW] = {
		"render_scale": 0.75,
		"msaa": Viewport.MSAA_DISABLED,
		"fxaa": false,
		"ssao": false,
		"shadows_enabled": false,
		"shadow_resolution": 512,
		"reflection_enabled": false,
		"particle_lod_distance": 10.0,
		"max_lights": 4,
		"texture_filter": Viewport.TEXTURE_FILTER_BILINEAR,
		"anisotropic_filter": 1,
		"max_particles": 100,
		"view_distance": 50.0,
		"lod_distance_multiplier": 0.5
	}

	# MEDIUM - Mid-range hardware
	quality_settings[QualityPreset.MEDIUM] = {
		"render_scale": 1.0,
		"msaa": Viewport.MSAA_2X,
		"fxaa": false,
		"ssao": false,
		"shadows_enabled": true,
		"shadow_resolution": 1024,
		"reflection_enabled": false,
		"particle_lod_distance": 20.0,
		"max_lights": 8,
		"texture_filter": Viewport.TEXTURE_FILTER_BILINEAR,
		"anisotropic_filter": 2,
		"max_particles": 250,
		"view_distance": 75.0,
		"lod_distance_multiplier": 0.75
	}

	# HIGH - High-end hardware
	quality_settings[QualityPreset.HIGH] = {
		"render_scale": 1.0,
		"msaa": Viewport.MSAA_4X,
		"fxaa": true,
		"ssao": true,
		"shadows_enabled": true,
		"shadow_resolution": 2048,
		"reflection_enabled": true,
		"particle_lod_distance": 40.0,
		"max_lights": 16,
		"texture_filter": Viewport.TEXTURE_FILTER_TRILINEAR,
		"anisotropic_filter": 4,
		"max_particles": 500,
		"view_distance": 100.0,
		"lod_distance_multiplier": 1.0
	}

	# ULTRA - Top-tier hardware
	quality_settings[QualityPreset.ULTRA] = {
		"render_scale": 1.0,
		"msaa": Viewport.MSAA_8X,
		"fxaa": true,
		"ssao": true,
		"shadows_enabled": true,
		"shadow_resolution": 4096,
		"reflection_enabled": true,
		"particle_lod_distance": 80.0,
		"max_lights": 32,
		"texture_filter": Viewport.TEXTURE_FILTER_TRILINEAR,
		"anisotropic_filter": 8,
		"max_particles": 1000,
		"view_distance": 150.0,
		"lod_distance_multiplier": 1.5
	}

func _process(delta):
	time_since_adjustment += delta

	# Update FPS monitoring
	_update_fps_monitoring()

	# Dynamic quality adjustment
	if dynamic_quality_enabled and time_since_adjustment >= adjustment_cooldown:
		_check_performance_adjustment()

func _update_fps_monitoring():
	current_fps = Engine.get_frames_per_second()

	# Add to samples
	fps_samples.append(current_fps)
	if fps_samples.size() > fps_sample_size:
		fps_samples.pop_front()

	# Update frame time
	frame_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

func _check_performance_adjustment():
	if fps_samples.size() < fps_sample_size:
		return

	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_samples:
		avg_fps += fps
	avg_fps /= fps_samples.size()

	# Check if adjustment needed
	if avg_fps < min_acceptable_fps and current_quality > QualityPreset.LOW:
		# Performance too low, reduce quality
		print("Performance below target (", avg_fps, " FPS). Reducing quality...")
		decrease_quality()
		time_since_adjustment = 0.0
	elif avg_fps > target_fps + 10 and current_quality < QualityPreset.ULTRA:
		# Performance has headroom, increase quality
		print("Performance above target (", avg_fps, " FPS). Increasing quality...")
		increase_quality()
		time_since_adjustment = 0.0

func apply_quality_preset(preset: int):
	if not quality_settings.has(preset):
		push_error("Invalid quality preset: " + str(preset))
		return

	current_quality = preset
	var settings = quality_settings[preset]

	print("Applying quality preset: ", get_quality_name(preset))

	# Apply render scale
	_apply_render_scale(settings.render_scale)

	# Apply MSAA
	get_viewport().msaa = settings.msaa

	# Apply FXAA
	get_viewport().fxaa = settings.fxaa

	# Apply shadows
	_apply_shadow_settings(settings.shadows_enabled, settings.shadow_resolution)

	# Apply SSAO
	_apply_ssao(settings.ssao)

	# Apply reflections
	_apply_reflections(settings.reflection_enabled)

	# Apply texture filtering
	_apply_texture_filtering(settings.texture_filter, settings.anisotropic_filter)

	# Broadcast quality change for other systems
	get_tree().call_group("performance_aware", "on_quality_changed", settings)

func apply_quality_preset_by_name(name: String):
	match name.to_lower():
		"low":
			apply_quality_preset(QualityPreset.LOW)
		"medium":
			apply_quality_preset(QualityPreset.MEDIUM)
		"high":
			apply_quality_preset(QualityPreset.HIGH)
		"ultra":
			apply_quality_preset(QualityPreset.ULTRA)
		_:
			push_warning("Unknown quality preset: " + name)
			apply_quality_preset(QualityPreset.MEDIUM)

func _apply_render_scale(scale: float):
	var viewport = get_viewport()
	var base_size = OS.window_size

	# For Raspberry Pi, we can render at lower resolution
	viewport.size = base_size * scale

	# Set scaling mode
	viewport.size_override_stretch = scale < 1.0

func _apply_shadow_settings(enabled: bool, resolution: int):
	# This would typically interact with DirectionalLight and other light nodes
	# For now, we'll set project settings that affect all shadows
	ProjectSettings.set_setting("rendering/quality/shadows/enabled", enabled)
	ProjectSettings.set_setting("rendering/quality/directional_shadow/size", resolution)

	# Update all light nodes
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light.has_method("set_shadow"):
			light.shadow_enabled = enabled

func _apply_ssao(enabled: bool):
	# Apply SSAO if supported
	if get_viewport().has_method("set_use_debanding"):
		get_viewport().use_debanding = enabled

func _apply_reflections(enabled: bool):
	# Enable/disable reflections in environment
	var world_environment = get_tree().get_nodes_in_group("world_environment")
	if world_environment.size() > 0:
		var env = world_environment[0]
		if env.has_method("set_ssr_enabled"):
			env.ssr_enabled = enabled

func _apply_texture_filtering(filter_mode: int, anisotropic: int):
	# Set global texture filter
	ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", anisotropic)

func apply_raspberry_pi_optimizations():
	print("Applying Raspberry Pi 5 specific optimizations...")

	# Force low quality
	apply_quality_preset(QualityPreset.LOW)

	# Additional Raspberry Pi optimizations
	Engine.target_fps = 30

	# Reduce physics FPS
	Engine.physics_jitter_fix = 0.0
	ProjectSettings.set_setting("physics/common/physics_fps", 30)

	# Disable expensive features
	ProjectSettings.set_setting("rendering/quality/filters/use_nearest_mipmap_filter", true)
	ProjectSettings.set_setting("rendering/quality/depth_prepass/enable", false)

	# Memory optimizations
	ProjectSettings.set_setting("rendering/limits/buffers/canvas_polygon_buffer_size_kb", 64)
	ProjectSettings.set_setting("rendering/limits/buffers/canvas_polygon_index_buffer_size_kb", 64)

	# Disable dynamic quality adjustment (keep it at low)
	dynamic_quality_enabled = false

	print("Raspberry Pi 5 optimizations applied")

func increase_quality():
	if current_quality < QualityPreset.ULTRA:
		apply_quality_preset(current_quality + 1)

func decrease_quality():
	if current_quality > QualityPreset.LOW:
		apply_quality_preset(current_quality - 1)

func get_quality_name(preset: int) -> String:
	match preset:
		QualityPreset.LOW:
			return "Low"
		QualityPreset.MEDIUM:
			return "Medium"
		QualityPreset.HIGH:
			return "High"
		QualityPreset.ULTRA:
			return "Ultra"
		_:
			return "Unknown"

func get_current_quality_settings() -> Dictionary:
	return quality_settings[current_quality]

func get_performance_stats() -> Dictionary:
	return {
		"fps": current_fps,
		"frame_time_ms": frame_time_ms,
		"target_fps": target_fps,
		"quality": get_quality_name(current_quality),
		"render_objects": Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME),
		"vertices": Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME),
		"draw_calls": Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME),
		"memory_static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0,
		"memory_dynamic_mb": Performance.get_monitor(Performance.MEMORY_DYNAMIC) / 1024.0 / 1024.0
	}

func optimize_memory():
	# Force garbage collection
	OS.call_deferred("delay_msec", 0)

	# Clear unused resources
	ResourceLoader.call_deferred("clear")

	print("Memory optimization performed")

func set_dynamic_quality(enabled: bool):
	dynamic_quality_enabled = enabled
	print("Dynamic quality adjustment: ", "enabled" if enabled else "disabled")