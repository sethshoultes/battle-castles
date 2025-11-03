# Battle Castles - Windows Installation Guide

## System Requirements

### Minimum Requirements
- **OS**: Windows 10 (64-bit) or newer
- **CPU**: Intel Core i3 or AMD equivalent
- **RAM**: 4 GB
- **GPU**: DirectX 11 compatible graphics card
- **Storage**: 500 MB available space
- **DirectX**: Version 11

### Recommended Requirements
- **OS**: Windows 10/11 (64-bit)
- **CPU**: Intel Core i5 or AMD Ryzen 5
- **RAM**: 8 GB
- **GPU**: NVIDIA GTX 1060 / AMD RX 580 or better
- **Storage**: 1 GB available space
- **DirectX**: Version 12

---

## Installation Methods

### Method 1: Using the Installer (Recommended)

1. Download `BattleCastles-Windows-Setup.exe` from the releases page
2. Double-click the installer
3. Follow the installation wizard:
   - Accept the license agreement
   - Choose installation directory (default: `C:\Program Files\Battle Castles`)
   - Select Start Menu folder
   - Choose to create desktop shortcut
4. Click "Install"
5. Launch from Start Menu or desktop shortcut

### Method 2: Portable ZIP Version

1. Download `BattleCastles-Windows-x.x.x.zip`
2. Extract to your preferred location (e.g., `C:\Games\BattleCastles`)
3. Run `BattleCastles.exe`

**Note**: The portable version stores save files and settings in the game directory.

---

## First Launch

1. Launch Battle Castles
2. The game will automatically:
   - Detect your hardware capabilities
   - Apply appropriate graphics settings
   - Create configuration files in `%APPDATA%\BattleCastles`

3. If this is your first time, you'll be prompted to:
   - Configure graphics settings
   - Set up audio preferences
   - Create or log in to your account

---

## Configuration

### Graphics Settings

Battle Castles automatically detects your hardware and applies appropriate settings:

- **High-end systems** (GTX 1060+): Ultra/High preset
- **Mid-range systems**: Medium preset
- **Low-end systems**: Low preset

You can manually adjust settings in-game:
1. Open Settings (ESC key)
2. Navigate to Graphics
3. Choose from presets: Low, Medium, High, Ultra
4. Or customize individual settings

### Performance Tips

For best performance on Windows:

1. **Update Graphics Drivers**
   - NVIDIA: Use GeForce Experience or download from nvidia.com
   - AMD: Use AMD Radeon Software or download from amd.com

2. **Close Background Applications**
   - Close unnecessary programs
   - Disable overlays (Discord, Steam, etc.) if experiencing issues

3. **Windows Game Mode**
   - Enable Windows Game Mode (Windows 10/11)
   - Settings > Gaming > Game Mode > On

4. **Power Settings**
   - Set power plan to "High Performance"
   - Control Panel > Power Options

5. **Fullscreen vs Windowed**
   - Fullscreen typically offers better performance
   - Borderless windowed for multi-monitor setups

### File Locations

- **Game Installation**: `C:\Program Files\Battle Castles\`
- **Save Files**: `%APPDATA%\BattleCastles\saves\`
- **Configuration**: `%APPDATA%\BattleCastles\config\`
- **Logs**: `%APPDATA%\BattleCastles\logs\`
- **Screenshots**: `%USERPROFILE%\Documents\Battle Castles\Screenshots\`

---

## Command Line Arguments

Launch with additional options:

```cmd
BattleCastles.exe [options]
```

**Available Options:**
- `--fullscreen` - Start in fullscreen mode
- `--windowed` - Start in windowed mode
- `--width <value>` - Set window width (e.g., --width 1920)
- `--height <value>` - Set window height (e.g., --height 1080)
- `--quality <preset>` - Set quality preset (low, medium, high, ultra)
- `--no-intro` - Skip intro cinematic
- `--debug` - Enable debug console
- `--server <address>` - Connect to specific server

**Example:**
```cmd
BattleCastles.exe --fullscreen --quality high --no-intro
```

---

## Troubleshooting

### Game Won't Start

**Issue**: Double-clicking does nothing or shows error

**Solutions**:
1. Install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
2. Install [DirectX End-User Runtime](https://www.microsoft.com/en-us/download/details.aspx?id=35)
3. Update Windows to latest version
4. Run as Administrator (right-click > Run as administrator)
5. Check logs in `%APPDATA%\BattleCastles\logs\`

### Low FPS / Stuttering

**Solutions**:
1. Lower graphics quality in-game settings
2. Update graphics drivers
3. Close background applications
4. Disable Windows Game DVR:
   - Settings > Gaming > Game Bar > Record in the background while I'm playing > Off
5. Verify game files integrity
6. Check if running on integrated GPU instead of dedicated GPU

### Graphics Issues

**Problem**: Black screen, flickering, or artifacts

**Solutions**:
1. Update graphics drivers
2. Try different graphics API:
   - Edit config file: `%APPDATA%\BattleCastles\config\settings.ini`
   - Change `graphics_api` to `dx11`, `dx12`, or `vulkan`
3. Disable overlays (Steam, Discord, GeForce Experience)
4. Run in windowed mode
5. Verify DirectX installation

### Connection Issues

**Problem**: Cannot connect to multiplayer servers

**Solutions**:
1. Check firewall settings:
   - Allow BattleCastles.exe through Windows Firewall
   - Control Panel > Windows Defender Firewall > Allow an app
2. Check antivirus software
3. Verify internet connection
4. Try different network (disable VPN if using)

### Audio Issues

**Problem**: No sound or crackling audio

**Solutions**:
1. Update audio drivers
2. Check Windows audio settings
3. In-game: Settings > Audio > Try different audio devices
4. Disable audio enhancements:
   - Right-click speaker icon > Sounds > Playback > Properties
   - Advanced > Disable all enhancements

---

## Uninstallation

### Installed Version
1. Control Panel > Programs and Features
2. Select "Battle Castles"
3. Click "Uninstall"
4. Follow the uninstaller

**Or:**
1. Settings > Apps > Apps & features
2. Search for "Battle Castles"
3. Click Uninstall

### Portable Version
1. Delete the game folder
2. Optionally delete: `%APPDATA%\BattleCastles`

---

## Building from Source

For developers wanting to build from source:

### Prerequisites
- Godot Engine 4.x
- Git
- Visual Studio 2019 or newer (for building custom modules)

### Build Steps

1. Clone the repository:
```cmd
git clone https://github.com/battlecastles/battle-castles.git
cd battle-castles
```

2. Open Godot project:
```cmd
godot -e client/project.godot
```

3. Export for Windows:
   - Project > Export
   - Select "Windows Desktop"
   - Configure export settings
   - Click "Export Project"

4. Or use build script:
```cmd
cd deployment/scripts
bash build_all_platforms.sh --windows
```

---

## Keyboard Controls

Default keyboard controls:

- **WASD** - Move camera
- **Mouse** - Select and interact
- **Q/E** - Rotate camera
- **Space** - Action/Confirm
- **ESC** - Menu/Cancel
- **F11** - Toggle fullscreen
- **F12** - Screenshot
- **~ (tilde)** - Debug console (debug mode only)

Controls can be customized in Settings > Controls.

---

## Support

### Getting Help

- **Documentation**: https://docs.battlecastles.com
- **Discord Community**: https://discord.gg/battlecastles
- **Email Support**: support@battlecastles.com
- **Bug Reports**: https://github.com/battlecastles/battle-castles/issues

### Reporting Bugs

When reporting bugs, please include:
1. Your Windows version
2. Hardware specifications (CPU, GPU, RAM)
3. Game version (Help > About)
4. Steps to reproduce
5. Log files from `%APPDATA%\BattleCastles\logs\`
6. Screenshots if applicable

---

## Frequently Asked Questions

### Q: Does Battle Castles support controllers?
**A**: Yes, Xbox and PlayStation controllers are supported. Most USB controllers will work.

### Q: Can I run multiple instances?
**A**: Not recommended. Multiple instances may cause performance issues.

### Q: Does it support mods?
**A**: Yes! Check the modding documentation at https://docs.battlecastles.com/modding

### Q: Can I play offline?
**A**: Yes, single-player and AI matches work offline. Multiplayer requires internet connection.

### Q: What graphics APIs are supported?
**A**: DirectX 11, DirectX 12, and Vulkan.

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

## License

Copyright (c) 2025 Battle Castles Studio. All rights reserved.

See [LICENSE.txt](LICENSE.txt) for full license information.