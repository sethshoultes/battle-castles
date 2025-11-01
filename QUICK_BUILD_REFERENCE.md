# Quick Build Reference

## Fast Build Commands

```bash
# Build everything
cd deployment/scripts && ./build_all_platforms.sh --all

# Build single platform
./build_all_platforms.sh --windows   # Windows
./build_all_platforms.sh --mac       # macOS
./build_all_platforms.sh --linux     # Linux x64
./build_all_platforms.sh --rpi       # Raspberry Pi 5

# Quick build (skip tests)
./build_all_platforms.sh --all --skip-tests

# Clean build
./build_all_platforms.sh --all --clean

# Set version
./build_all_platforms.sh --all --version 1.0.1
```

## Platform Detection API

```gdscript
# Get platform detector
var platform = get_node("/root/PlatformDetector")

# Check platform
platform.is_raspberry_pi        # bool
platform.is_desktop_platform()  # bool
platform.is_mobile_platform()   # bool
platform.is_arm_platform()      # bool

# Get info
platform.current_platform       # Platform enum
platform.cpu_count              # int
platform.memory_mb              # int
platform.hardware_tier          # "low"|"medium"|"high"|"ultra"

# Get capabilities
platform.supports_shadows()     # bool
platform.supports_particles()   # bool
platform.get_max_particle_count() # int
```

## Performance Optimizer API

```gdscript
# Get optimizer
var opt = get_node("/root/PerformanceOptimizer")

# Change quality
opt.apply_quality_preset_by_name("high")  # "low"|"medium"|"high"|"ultra"
opt.increase_quality()
opt.decrease_quality()

# Get stats
var stats = opt.get_performance_stats()
print(stats.fps)
print(stats.quality)
print(stats.memory_static_mb)

# Control dynamic adjustment
opt.set_dynamic_quality(true)  # Enable auto-adjustment
opt.set_dynamic_quality(false) # Disable auto-adjustment

# Raspberry Pi optimizations
if get_node("/root/PlatformDetector").is_raspberry_pi:
    opt.apply_raspberry_pi_optimizations()
```

## Quality Presets

| Setting | Low (Pi 5) | Medium | High | Ultra |
|---------|------------|--------|------|-------|
| Render Scale | 0.75 | 1.0 | 1.0 | 1.0 |
| MSAA | Off | 2x | 4x | 8x |
| Shadows | No | Yes | Yes | Yes |
| Shadow Res | 512 | 1024 | 2048 | 4096 |
| Particles | 100 | 250 | 500 | 1000 |
| View Dist | 50 | 75 | 100 | 150 |

## Build Outputs

```
builds/
├── windows/BattleCastles.exe
├── mac/BattleCastles.app
├── linux/BattleCastles.x86_64
└── linux-arm64/BattleCastles.arm64
```

## Performance Targets

- **Desktop**: 60 FPS
- **Raspberry Pi 5**: 30 FPS

## File Locations

```
/Users/sethshoultes/Local Sites/battle-castles/
├── export_presets.cfg                          # Godot export configs
├── VERSION                                      # Version number
├── client/scripts/core/
│   ├── platform_detector.gd                    # Platform detection
│   └── performance_optimizer.gd                # Performance optimization
├── deployment/scripts/
│   ├── build_all_platforms.sh                  # Main build script
│   └── package_rpi5.sh                         # Raspberry Pi packager
├── INSTALL_WINDOWS.md                          # Windows guide
├── INSTALL_MAC.md                              # macOS guide
├── INSTALL_LINUX.md                            # Linux guide
├── INSTALL_RASPBERRY_PI.md                     # Raspberry Pi guide
└── PLATFORM_BUILD_GUIDE.md                     # Complete guide
```

## Common Issues

### Build fails
```bash
# Check Godot installed
godot --version

# Make scripts executable
chmod +x deployment/scripts/*.sh

# Install export templates in Godot editor
```

### Platform detection not working
```gdscript
# Ensure autoload is configured
# Project Settings > Autoload
# Add PlatformDetector: res://scripts/core/platform_detector.gd
# Add PerformanceOptimizer: res://scripts/core/performance_optimizer.gd
```

### Raspberry Pi performance low
- Enable active cooling
- Close background apps
- Verify GPU memory: `vcgencmd get_mem gpu` (should be 256MB)
- Check temperature: `vcgencmd measure_temp` (should be <70°C)

## Quick Test

```bash
# Launch with debug
godot client/project.godot -- --debug

# Force platform for testing
godot client/project.godot -- --platform=raspberry_pi

# Windowed mode
godot client/project.godot -- --windowed --width 1280 --height 720
```

## Distribution Checklist

- [ ] Update VERSION file
- [ ] Run: `./build_all_platforms.sh --all --clean`
- [ ] Test each platform
- [ ] Code sign (optional)
- [ ] Tag release: `git tag v1.0.0`
- [ ] Upload artifacts
- [ ] Update documentation

## Support

- Docs: [PLATFORM_BUILD_GUIDE.md](PLATFORM_BUILD_GUIDE.md)
- Windows: [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)
- macOS: [INSTALL_MAC.md](INSTALL_MAC.md)
- Linux: [INSTALL_LINUX.md](INSTALL_LINUX.md)
- Raspberry Pi: [INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md)