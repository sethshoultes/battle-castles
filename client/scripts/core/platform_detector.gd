extends Node

class_name PlatformDetector

# Platform identifiers
enum Platform {
	WINDOWS,
	MAC_OS,
	LINUX_X86,
	LINUX_ARM64,
	RASPBERRY_PI,
	ANDROID,
	IOS,
	WEB,
	UNKNOWN
}

# Hardware capabilities
var cpu_count: int = 1
var memory_mb: int = 1024
var gpu_name: String = "Unknown"
var current_platform: int = Platform.UNKNOWN
var is_raspberry_pi: bool = false
var hardware_tier: String = "medium"  # low, medium, high, ultra

# Platform-specific defaults
var platform_settings = {
	Platform.WINDOWS: {
		"default_quality": "high",
		"target_fps": 60,
		"vsync": true,
		"fullscreen": false
	},
	Platform.MAC_OS: {
		"default_quality": "high",
		"target_fps": 60,
		"vsync": true,
		"fullscreen": false
	},
	Platform.LINUX_X86: {
		"default_quality": "medium",
		"target_fps": 60,
		"vsync": true,
		"fullscreen": false
	},
	Platform.LINUX_ARM64: {
		"default_quality": "low",
		"target_fps": 30,
		"vsync": true,
		"fullscreen": false
	},
	Platform.RASPBERRY_PI: {
		"default_quality": "low",
		"target_fps": 30,
		"vsync": true,
		"fullscreen": true
	},
	Platform.WEB: {
		"default_quality": "medium",
		"target_fps": 60,
		"vsync": true,
		"fullscreen": false
	}
}

func _ready():
	detect_platform()
	detect_hardware()
	determine_hardware_tier()
	apply_platform_defaults()

	print("Platform Detection Complete:")
	print("  Platform: ", get_platform_name())
	print("  CPU Cores: ", cpu_count)
	print("  Memory: ", memory_mb, " MB")
	print("  GPU: ", gpu_name)
	print("  Hardware Tier: ", hardware_tier)
	print("  Is Raspberry Pi: ", is_raspberry_pi)

func detect_platform():
	var os_name = OS.get_name()

	match os_name:
		"Windows":
			current_platform = Platform.WINDOWS
		"OSX", "macOS":
			current_platform = Platform.MAC_OS
		"X11", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			_detect_linux_variant()
		"Android":
			current_platform = Platform.ANDROID
		"iOS":
			current_platform = Platform.IOS
		"HTML5":
			current_platform = Platform.WEB
		_:
			current_platform = Platform.UNKNOWN

func _detect_linux_variant():
	# Check for ARM architecture
	var processor_info = OS.get_processor_name()

	if "arm" in processor_info.to_lower() or "aarch64" in processor_info.to_lower():
		current_platform = Platform.LINUX_ARM64

		# Check specifically for Raspberry Pi
		if _is_raspberry_pi():
			current_platform = Platform.RASPBERRY_PI
			is_raspberry_pi = true
	else:
		current_platform = Platform.LINUX_X86

func _is_raspberry_pi() -> bool:
	# Check for Raspberry Pi specific markers
	if OS.has_feature("raspberry_pi"):
		return true

	# Check for common Raspberry Pi indicators
	var model_info = _read_file("/proc/device-tree/model")
	if model_info and "raspberry pi" in model_info.to_lower():
		return true

	var cpu_info = _read_file("/proc/cpuinfo")
	if cpu_info:
		if "bcm2835" in cpu_info.to_lower() or "bcm2711" in cpu_info.to_lower():
			return true
		if "raspberry pi" in cpu_info.to_lower():
			return true

	return false

func _read_file(path: String) -> String:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return ""
	var content = file.get_as_text()
	file.close()
	return content

func detect_hardware():
	# CPU detection
	cpu_count = OS.get_processor_count()

	# Memory detection (in MB)
	# Note: Godot doesn't have direct memory detection, so we estimate
	memory_mb = _estimate_memory()

	# GPU detection
	gpu_name = OS.get_video_driver_name(OS.get_current_video_driver())

	# Additional Raspberry Pi 5 specific detection
	if is_raspberry_pi:
		var model = _get_raspberry_pi_model()
		if "5" in model:
			# Raspberry Pi 5 specific settings
			memory_mb = _get_raspberry_pi_memory()

func _estimate_memory() -> int:
	# Platform-specific memory estimation
	if is_raspberry_pi:
		return _get_raspberry_pi_memory()

	# Default estimation based on platform
	match current_platform:
		Platform.WINDOWS, Platform.MAC_OS:
			return 8192  # Assume 8GB for desktop
		Platform.LINUX_X86:
			return 4096  # Assume 4GB for Linux desktop
		Platform.LINUX_ARM64:
			return 2048  # Assume 2GB for ARM devices
		Platform.WEB:
			return 2048  # Conservative for web
		_:
			return 2048

func _get_raspberry_pi_model() -> String:
	var model_info = _read_file("/proc/device-tree/model")
	if model_info:
		return model_info
	return "Unknown Raspberry Pi"

func _get_raspberry_pi_memory() -> int:
	var meminfo = _read_file("/proc/meminfo")
	if meminfo:
		var lines = meminfo.split("\n")
		for line in lines:
			if line.begins_with("MemTotal:"):
				var parts = line.split(" ")
				for part in parts:
					if part.is_valid_integer():
						return int(part) / 1024  # Convert KB to MB

	# Default Raspberry Pi 5 memory variants
	return 4096  # Assume 4GB model

func determine_hardware_tier():
	# Score-based tier determination
	var score = 0

	# CPU score
	if cpu_count >= 8:
		score += 3
	elif cpu_count >= 4:
		score += 2
	elif cpu_count >= 2:
		score += 1

	# Memory score
	if memory_mb >= 16384:  # 16GB+
		score += 3
	elif memory_mb >= 8192:  # 8GB+
		score += 2
	elif memory_mb >= 4096:  # 4GB+
		score += 1

	# Platform-specific adjustments
	if is_raspberry_pi:
		hardware_tier = "low"
		return
	elif current_platform == Platform.WEB:
		score -= 1

	# Determine tier
	if score >= 5:
		hardware_tier = "ultra"
	elif score >= 3:
		hardware_tier = "high"
	elif score >= 2:
		hardware_tier = "medium"
	else:
		hardware_tier = "low"

func apply_platform_defaults():
	if not platform_settings.has(current_platform):
		return

	var settings = platform_settings[current_platform]

	# Apply FPS target
	Engine.target_fps = settings.target_fps

	# Apply VSync
	OS.vsync_enabled = settings.vsync

	# Apply fullscreen
	OS.window_fullscreen = settings.fullscreen

	# Store quality setting for performance optimizer
	set_meta("default_quality", settings.default_quality)

func get_platform_name() -> String:
	match current_platform:
		Platform.WINDOWS:
			return "Windows"
		Platform.MAC_OS:
			return "macOS"
		Platform.LINUX_X86:
			return "Linux x86_64"
		Platform.LINUX_ARM64:
			return "Linux ARM64"
		Platform.RASPBERRY_PI:
			return "Raspberry Pi"
		Platform.ANDROID:
			return "Android"
		Platform.IOS:
			return "iOS"
		Platform.WEB:
			return "Web"
		_:
			return "Unknown"

func get_recommended_quality() -> String:
	# Override for specific platforms
	if is_raspberry_pi:
		return "low"

	# Use hardware tier
	match hardware_tier:
		"ultra":
			return "ultra"
		"high":
			return "high"
		"medium":
			return "medium"
		_:
			return "low"

func is_mobile_platform() -> bool:
	return current_platform in [Platform.ANDROID, Platform.IOS]

func is_desktop_platform() -> bool:
	return current_platform in [Platform.WINDOWS, Platform.MAC_OS, Platform.LINUX_X86]

func is_arm_platform() -> bool:
	return current_platform in [Platform.LINUX_ARM64, Platform.RASPBERRY_PI]

func supports_shadows() -> bool:
	return hardware_tier in ["high", "ultra"] and not is_raspberry_pi

func supports_particles() -> bool:
	return true  # All platforms support particles, but count varies

func get_max_particle_count() -> int:
	if is_raspberry_pi:
		return 100

	match hardware_tier:
		"ultra":
			return 1000
		"high":
			return 500
		"medium":
			return 250
		_:
			return 100