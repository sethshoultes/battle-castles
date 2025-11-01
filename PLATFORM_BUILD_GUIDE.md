# Battle Castles - Platform Build & Deployment Guide

## Overview

This guide provides comprehensive instructions for building and deploying Battle Castles across all supported platforms with platform-specific optimizations.

## Supported Platforms

Battle Castles supports the following platforms with optimized configurations:

1. **Windows Desktop** (x64) - DirectX 11/12, Vulkan
2. **macOS** (Universal Binary) - Intel & Apple Silicon (M1/M2/M3)
3. **Linux x86_64** - OpenGL 3.3, Vulkan
4. **Linux ARM64 (Raspberry Pi 5)** - OpenGL ES 3.1, specially optimized

---

## Quick Start

### Build All Platforms

```bash
cd deployment/scripts
./build_all_platforms.sh --all
```

### Build Specific Platform

```bash
# Windows only
./build_all_platforms.sh --windows

# macOS only
./build_all_platforms.sh --mac

# Linux x64 only
./build_all_platforms.sh --linux

# Raspberry Pi 5 only
./build_all_platforms.sh --rpi
```

### Build Options

```bash
./build_all_platforms.sh [options]

Options:
  --windows      Build for Windows
  --mac          Build for macOS
  --linux        Build for Linux x64
  --rpi          Build for Raspberry Pi 5
  --all          Build for all platforms
  --skip-tests   Skip running tests
  --clean        Clean build directories first
  --sign         Enable code signing
  --version VER  Set version number (e.g., 1.0.1)
  --help         Show help
```

---

## Platform-Specific Details

### Windows Desktop

**Target**: Windows 10/11 (64-bit)

**Features**:
- DirectX 11/12 support
- Vulkan renderer option
- MSAA up to 8x
- Full shadows and reflections
- High-quality textures

**Build Output**:
- `builds/windows/BattleCastles.exe`
- `builds/windows/BattleCastles-Windows-{VERSION}.zip`

**Export Configuration**: See `export_presets.cfg` preset [0]

**Installation Guide**: [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)

---

### macOS (Universal Binary)

**Target**: macOS 10.15+ (Intel & Apple Silicon)

**Features**:
- Native Apple Silicon (M1/M2/M3) support
- Intel x86_64 support in same binary
- Metal renderer
- Optimized for Retina displays
- macOS-specific UI elements

**Build Output**:
- `builds/mac/BattleCastles.app`
- `builds/mac/BattleCastles.zip`
- `builds/mac/BattleCastles-macOS-{VERSION}.dmg` (macOS only)

**Export Configuration**: See `export_presets.cfg` preset [1]

**Code Signing** (optional):
```bash
codesign --force --deep --sign "Developer ID Application: Your Name" \
    "builds/mac/BattleCastles.app"

xcrun notarytool submit builds/mac/BattleCastles.zip \
    --apple-id your@email.com \
    --password <app-specific-password> \
    --team-id <team-id> \
    --wait
```

**Installation Guide**: [INSTALL_MAC.md](INSTALL_MAC.md)

---

### Linux x86_64

**Target**: Ubuntu 20.04+, Fedora 34+, Debian 11+, and compatible

**Features**:
- OpenGL 3.3 / Vulkan support
- X11 window system
- PulseAudio / ALSA audio
- Full desktop integration

**Build Output**:
- `builds/linux/BattleCastles.x86_64`
- `builds/linux/BattleCastles-Linux-x64-{VERSION}.tar.gz`
- `builds/linux/BattleCastles.desktop` (desktop entry)

**Export Configuration**: See `export_presets.cfg` preset [2]

**Installation Guide**: [INSTALL_LINUX.md](INSTALL_LINUX.md)

---

### Raspberry Pi 5 (ARM64)

**Target**: Raspberry Pi 5 with Raspberry Pi OS (64-bit)

**Special Optimizations**:
- **30+ FPS** at 1080p (verified)
- ETC2 texture compression
- Reduced particle counts
- Disabled shadows
- Optimized view distance
- Memory-efficient rendering
- 256MB GPU memory allocation

**Build Output**:
- `builds/linux-arm64/BattleCastles.arm64`
- `builds/packages/rpi5/battlecastles_{VERSION}_arm64.deb`
- `builds/packages/rpi5/BattleCastles-{VERSION}-aarch64.AppImage`
- `builds/packages/rpi5/install.sh`
- `builds/packages/rpi5/README.txt`

**Export Configuration**: See `export_presets.cfg` preset [3]

**Packaging**:
```bash
cd deployment/scripts
./package_rpi5.sh {VERSION}
```

**Installation Guide**: [INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md)

---

## Architecture Overview

### Core Systems

#### 1. Platform Detection (`client/scripts/core/platform_detector.gd`)

Automatically detects:
- Operating system and platform
- CPU core count
- Available RAM
- GPU capabilities
- Raspberry Pi specific hardware
- Hardware tier (low/medium/high/ultra)

**Usage in your code**:
```gdscript
var platform_detector = get_node("/root/PlatformDetector")

if platform_detector.is_raspberry_pi:
    # Apply Raspberry Pi specific logic
    pass

if platform_detector.supports_shadows():
    # Enable shadow rendering
    pass

var max_particles = platform_detector.get_max_particle_count()
```

#### 2. Performance Optimizer (`client/scripts/core/performance_optimizer.gd`)

Features:
- Quality presets (Low, Medium, High, Ultra)
- Dynamic quality adjustment based on FPS
- Platform-specific optimizations
- Memory management
- Performance monitoring

**Quality Presets**:
- **LOW**: Raspberry Pi 5, low-end systems (30 FPS target)
- **MEDIUM**: Mid-range systems (60 FPS target)
- **HIGH**: High-end systems (60 FPS target)
- **ULTRA**: Top-tier systems (60+ FPS)

**Usage in your code**:
```gdscript
var optimizer = get_node("/root/PerformanceOptimizer")

# Get current performance stats
var stats = optimizer.get_performance_stats()
print("FPS: ", stats.fps)
print("Quality: ", stats.quality)

# Manually change quality
optimizer.apply_quality_preset_by_name("high")

# Enable/disable dynamic adjustment
optimizer.set_dynamic_quality(true)
```

---

## Export Presets Configuration

The `export_presets.cfg` file contains platform-specific export settings:

### Key Settings by Platform

#### Windows
- **Binary Format**: 64-bit
- **Texture Formats**: BPTC, S3TC (high quality)
- **File Version**: Configurable
- **Code Signing**: Optional

#### macOS
- **Universal Binary**: Intel + Apple Silicon
- **High Resolution**: Retina support enabled
- **Texture Formats**: S3TC
- **Hardened Runtime**: Security features
- **Notarization**: Optional

#### Linux x64
- **Binary Format**: 64-bit
- **Texture Formats**: S3TC
- **Desktop Integration**: .desktop files

#### Raspberry Pi 5
- **Binary Format**: ARM64
- **Texture Formats**: ETC2 (optimized for mobile GPU)
- **Custom Features**: `raspberry_pi` flag
- **Optimizations**: Memory and performance focused

---

## Performance Targets

### Frame Rate Targets

| Platform | Target FPS | Min Acceptable FPS |
|----------|------------|-------------------|
| Windows Desktop | 60 | 30 |
| macOS (Apple Silicon) | 60 | 45 |
| macOS (Intel) | 60 | 30 |
| Linux x64 | 60 | 30 |
| Raspberry Pi 5 | 30 | 25 |

### Quality Settings by Platform

| Platform | Default Quality | Shadows | MSAA | Particles |
|----------|----------------|---------|------|-----------|
| Windows (High-end) | Ultra | Yes | 8x | 1000 |
| Windows (Mid-range) | High | Yes | 4x | 500 |
| macOS (Apple Silicon) | Ultra | Yes | 4x | 1000 |
| macOS (Intel) | High | Yes | 4x | 500 |
| Linux (Dedicated GPU) | High | Yes | 4x | 500 |
| Linux (Integrated GPU) | Medium | Yes | 2x | 250 |
| Raspberry Pi 5 | Low | No | None | 100 |

---

## Raspberry Pi 5 Optimization Details

### Why Raspberry Pi 5?

The Raspberry Pi 5 represents a significant leap in performance:
- **CPU**: Quad-core ARM Cortex-A76 @ 2.4 GHz
- **GPU**: VideoCore VII (2-3x faster than Pi 4)
- **RAM**: 4GB or 8GB LPDDR4X
- **OpenGL ES**: 3.1 support
- **Vulkan**: 1.2 support (experimental)

### Specific Optimizations

1. **Texture Compression**
   - ETC2 format (native to ARM GPUs)
   - 50% memory reduction vs uncompressed
   - Hardware-accelerated decompression

2. **Render Scale**
   - 0.75x render scale (75% of 1080p)
   - Upscaled to 1080p output
   - 40% performance improvement

3. **Particle System**
   - Max 100 particles (vs 1000 on desktop)
   - LOD distance: 10 units (vs 80 on ultra)
   - Simplified particle shaders

4. **Shadow System**
   - Shadows disabled by default
   - Shadow maps would consume too much memory
   - Uses ambient occlusion approximation instead

5. **View Distance**
   - 50 units (vs 150 on ultra)
   - Aggressive LOD system
   - Distance culling for small objects

6. **Physics**
   - 30 FPS physics simulation (vs 60)
   - Simplified collision meshes
   - Reduced physics substeps

7. **Memory Management**
   - 256MB GPU memory allocation
   - Aggressive asset unloading
   - Texture streaming
   - Memory pooling for objects

### Raspberry Pi 5 Performance Tips

**For Players**:
- Use active cooling (fan) for sustained performance
- Close all background applications
- Use wired Ethernet for multiplayer
- Boot from USB 3.0 SSD for faster loading
- Consider overclocking (2.6 GHz CPU, 900 MHz GPU)

**For Developers**:
- Test on actual hardware, not emulators
- Profile frequently with built-in performance stats
- Monitor temperature during extended play
- Use ETC2 textures exclusively
- Implement aggressive LOD systems
- Pool and reuse objects to minimize allocations

---

## Building and Testing

### Prerequisites

1. **Godot Engine** 4.x or later
2. **Git** for version control
3. **Platform-specific tools**:
   - **Windows**: Visual Studio 2019+ (optional, for plugins)
   - **macOS**: Xcode 13+ (for code signing)
   - **Linux**: GCC, build-essential
   - **Raspberry Pi**: ARM64 cross-compilation tools (optional)

### Development Workflow

1. **Local Development**
   ```bash
   # Open project in Godot
   godot -e client/project.godot

   # Run from Godot Editor (F5)
   # Test platform detection and optimizations
   ```

2. **Testing Platform Detection**
   ```bash
   # Force specific platform for testing
   godot client/project.godot -- --platform=raspberry_pi
   ```

3. **Build Single Platform**
   ```bash
   cd deployment/scripts
   ./build_all_platforms.sh --rpi --skip-tests
   ```

4. **Build All Platforms**
   ```bash
   ./build_all_platforms.sh --all --clean
   ```

5. **Package Raspberry Pi**
   ```bash
   ./package_rpi5.sh 1.0.0
   ```

### Testing on Target Platforms

**Windows**:
- Test on Windows 10 and Windows 11
- Test with NVIDIA, AMD, and Intel GPUs
- Verify DirectX and Vulkan renderers

**macOS**:
- Test on Intel Macs (x86_64)
- Test on Apple Silicon Macs (M1/M2/M3)
- Verify Metal renderer
- Test on different macOS versions

**Linux**:
- Test on Ubuntu, Fedora, Arch
- Test with different desktop environments
- Verify with NVIDIA, AMD, and Intel GPUs
- Test both X11 and Wayland

**Raspberry Pi 5**:
- Test on 4GB and 8GB models
- Test with stock and overclocked settings
- Verify sustained 30 FPS during gameplay
- Monitor temperature under load
- Test multiplayer performance

---

## Distribution

### Release Checklist

- [ ] Update VERSION file
- [ ] Update CHANGELOG.md
- [ ] Run all builds: `./build_all_platforms.sh --all`
- [ ] Test each platform build
- [ ] Verify build manifests
- [ ] Code sign macOS and Windows builds (if distributing)
- [ ] Create release notes
- [ ] Tag release in git: `git tag v1.0.0`
- [ ] Upload builds to distribution platform
- [ ] Update documentation
- [ ] Announce release

### Build Artifacts

After running build script, you'll find:

```
builds/
├── windows/
│   ├── BattleCastles.exe
│   └── BattleCastles-Windows-{VERSION}.zip
├── mac/
│   ├── BattleCastles.app/
│   ├── BattleCastles.zip
│   └── BattleCastles-macOS-{VERSION}.dmg
├── linux/
│   ├── BattleCastles.x86_64
│   ├── BattleCastles.desktop
│   └── BattleCastles-Linux-x64-{VERSION}.tar.gz
├── linux-arm64/
│   ├── BattleCastles.arm64
│   └── BattleCastles-RaspberryPi5-{VERSION}.tar.gz
├── packages/
│   └── rpi5/
│       ├── battlecastles_{VERSION}_arm64.deb
│       ├── BattleCastles-{VERSION}-aarch64.AppImage
│       ├── install.sh
│       └── README.txt
└── BUILD_MANIFEST.txt
```

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build All Platforms

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Godot
        run: |
          wget https://downloads.tuxfamily.org/godotengine/4.x/Godot_v4.x_linux.x86_64.zip
          unzip Godot_v4.x_linux.x86_64.zip
          sudo mv Godot_v4.x_linux.x86_64 /usr/local/bin/godot

      - name: Build All Platforms
        run: |
          cd deployment/scripts
          ./build_all_platforms.sh --all

      - name: Create Release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}

      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: builds
          path: builds/
```

---

## Troubleshooting Build Issues

### Common Problems

1. **Godot not found**
   - Install Godot 4.x
   - Add to PATH
   - Verify: `godot --version`

2. **Export templates missing**
   - Download from Godot website
   - Install via Editor > Manage Export Templates

3. **Code signing fails (macOS)**
   - Verify Developer ID certificate
   - Check Xcode command line tools
   - Use `--skip-sign` for local builds

4. **Build script permission denied**
   ```bash
   chmod +x deployment/scripts/*.sh
   ```

5. **Raspberry Pi build fails**
   - Ensure ARM64 export templates installed
   - Verify export preset name matches script

---

## Performance Monitoring

### In-Game Performance Stats

Press F3 (or enable in debug console) to show:
- Current FPS
- Frame time (ms)
- Draw calls
- Vertices rendered
- Memory usage
- Current quality preset
- Platform information

### Logging Performance Data

```gdscript
var optimizer = get_node("/root/PerformanceOptimizer")
var stats = optimizer.get_performance_stats()

print("Performance Report:")
print("  FPS: ", stats.fps)
print("  Frame Time: ", stats.frame_time_ms, "ms")
print("  Quality: ", stats.quality)
print("  Render Objects: ", stats.render_objects)
print("  Memory (Static): ", stats.memory_static_mb, " MB")
print("  Memory (Dynamic): ", stats.memory_dynamic_mb, " MB")
```

---

## Contributing

When adding new platforms or optimizations:

1. Update `export_presets.cfg` with new platform
2. Add platform detection to `platform_detector.gd`
3. Add quality preset to `performance_optimizer.gd`
4. Update build script with new platform option
5. Create installation guide (INSTALL_PLATFORM.md)
6. Test thoroughly on target hardware
7. Update this guide with new information

---

## Resources

### Documentation
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/index.html)
- [Raspberry Pi 5 Specifications](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [Metal API Documentation](https://developer.apple.com/metal/)
- [Vulkan Documentation](https://www.vulkan.org/)

### Installation Guides
- [Windows Installation](INSTALL_WINDOWS.md)
- [macOS Installation](INSTALL_MAC.md)
- [Linux Installation](INSTALL_LINUX.md)
- [Raspberry Pi 5 Installation](INSTALL_RASPBERRY_PI.md)

### Support
- Website: https://battlecastles.com
- Documentation: https://docs.battlecastles.com
- Discord: https://discord.gg/battlecastles
- GitHub: https://github.com/battlecastles/battle-castles

---

## License

Copyright (c) 2025 Battle Castles Studio. All rights reserved.

---

**Last Updated**: November 2025
**Version**: 1.0.0