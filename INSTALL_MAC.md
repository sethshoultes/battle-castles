# Battle Castles - macOS Installation Guide

## System Requirements

### Minimum Requirements
- **OS**: macOS 10.15 Catalina or newer
- **CPU**: Intel Core i3 or Apple Silicon (M1/M2/M3)
- **RAM**: 4 GB
- **GPU**: Metal-compatible graphics card
- **Storage**: 500 MB available space

### Recommended Requirements
- **OS**: macOS 12 Monterey or newer
- **CPU**: Intel Core i5 or Apple Silicon (M1 Pro/M2 Pro/M3 Pro)
- **RAM**: 8 GB
- **GPU**: Dedicated GPU or Apple Silicon integrated GPU
- **Storage**: 1 GB available space

### Apple Silicon Note
Battle Castles is a **Universal Binary** that runs natively on both Intel and Apple Silicon Macs.

---

## Installation Methods

### Method 1: Using DMG Installer (Recommended)

1. Download `BattleCastles-macOS-x.x.x.dmg` from the releases page
2. Double-click the DMG file to mount it
3. Drag **Battle Castles.app** to your **Applications** folder
4. Eject the DMG (right-click > Eject)
5. Launch from Applications or Launchpad

### Method 2: Using ZIP Archive

1. Download `BattleCastles-macOS-x.x.x.zip`
2. Double-click to extract
3. Move **Battle Castles.app** to Applications folder
4. Launch the app

---

## First Launch & Gatekeeper

### Handling "Unidentified Developer" Warning

If you see "Battle Castles can't be opened because it is from an unidentified developer":

**Option 1: Using Finder**
1. Right-click (or Control-click) on **Battle Castles.app**
2. Select **Open** from the menu
3. Click **Open** in the dialog
4. macOS will remember this choice

**Option 2: Using System Settings**
1. Open **System Settings** (or System Preferences)
2. Go to **Privacy & Security**
3. Scroll down to find "Battle Castles was blocked"
4. Click **Open Anyway**
5. Enter your password if prompted

**Option 3: Using Terminal (Advanced)**
```bash
xattr -cr "/Applications/Battle Castles.app"
```

Then launch normally.

---

## First Run Configuration

1. Launch Battle Castles
2. The game will automatically:
   - Detect if you're on Apple Silicon or Intel
   - Apply appropriate graphics settings
   - Create configuration files in `~/Library/Application Support/BattleCastles`

3. First-time setup:
   - Configure graphics settings (Auto-detected based on your Mac)
   - Set up audio preferences
   - Create or log in to your account

---

## Performance Optimization

### For Apple Silicon Macs (M1/M2/M3)

Apple Silicon Macs generally achieve excellent performance:

- **M1/M2/M3**: 60+ FPS at High/Ultra settings
- **M1 Pro/Max/Ultra**: 60+ FPS at Ultra settings with all features enabled
- **M3 Pro/Max**: Highest performance, 60+ FPS at maximum settings

**Optimization Tips:**
1. Ensure you're using the native Apple Silicon version (check Activity Monitor)
2. Keep macOS updated for best Metal performance
3. Close background applications for maximum performance
4. Enable "High Performance" mode on MacBook Pro (System Settings > Battery)

### For Intel Macs

**Optimization Tips:**
1. Update to latest macOS version for Metal improvements
2. Close background applications
3. Consider using Medium/High settings instead of Ultra
4. For MacBooks, connect power adapter for best performance
5. Enable automatic graphics switching (for dual-GPU systems)

### Graphics Settings by Mac

- **MacBook Air (M1/M2)**: High preset recommended
- **MacBook Pro 13" (M1/M2)**: High preset
- **MacBook Pro 14"/16" (M1 Pro/Max/M2 Pro/Max)**: Ultra preset
- **Mac Studio**: Ultra preset
- **Mac mini (M1/M2)**: High preset
- **iMac 24" (M1)**: High preset
- **iMac 27" (Intel)**: Medium/High preset
- **Mac Pro (Intel)**: High/Ultra preset

---

## Configuration

### File Locations

- **Application**: `/Applications/Battle Castles.app`
- **Save Files**: `~/Library/Application Support/BattleCastles/saves/`
- **Configuration**: `~/Library/Application Support/BattleCastles/config/`
- **Logs**: `~/Library/Application Support/BattleCastles/logs/`
- **Screenshots**: `~/Pictures/Battle Castles/`
- **Cache**: `~/Library/Caches/BattleCastles/`

**To access Library folder:**
1. In Finder, click **Go** menu
2. Hold **Option** key
3. Click **Library**

Or use Terminal:
```bash
open ~/Library/Application\ Support/BattleCastles/
```

### Graphics Settings

Adjust in-game settings:
1. Press **ESC** or **Command+Comma** (⌘,)
2. Navigate to **Graphics**
3. Choose preset or customize:
   - **Low**: For older Intel Macs
   - **Medium**: For Intel iMacs and base MacBook Pros
   - **High**: For M1/M2 Macs and high-end Intel Macs
   - **Ultra**: For M1 Pro/Max/Ultra and newer

---

## Command Line Arguments

Launch from Terminal with options:

```bash
open -a "Battle Castles" --args [options]
```

**Available Options:**
- `--fullscreen` - Start in fullscreen mode
- `--windowed` - Start in windowed mode
- `--width <value>` - Set window width
- `--height <value>` - Set window height
- `--quality <preset>` - Set quality (low, medium, high, ultra)
- `--no-intro` - Skip intro cinematic
- `--debug` - Enable debug console

**Example:**
```bash
open -a "Battle Castles" --args --fullscreen --quality ultra
```

---

## Troubleshooting

### Game Won't Launch

**Issue**: App bounces in dock then closes

**Solutions**:
1. Remove quarantine attribute:
   ```bash
   xattr -cr "/Applications/Battle Castles.app"
   ```
2. Check Console app for crash logs:
   - Open **Console.app**
   - Search for "Battle Castles"
   - Look for error messages
3. Verify macOS version compatibility
4. Try removing preferences:
   ```bash
   rm -rf ~/Library/Preferences/com.battlecastles.game.plist
   ```

### Low FPS / Performance Issues

**For Intel Macs:**
1. Lower graphics quality in settings
2. Close background applications
3. Check Activity Monitor for high CPU usage
4. Reset SMC (System Management Controller):
   - Shut down Mac
   - For laptops: Press Shift+Control+Option+Power for 10 seconds
   - For desktops: Unplug power for 15 seconds
5. Update macOS and graphics drivers

**For Apple Silicon Macs:**
1. Verify running native version (not Rosetta):
   - Open **Activity Monitor**
   - Find "Battle Castles"
   - Check "Kind" column shows "Apple" not "Intel"
2. If running under Rosetta, reinstall from DMG
3. Update to latest macOS version
4. Close background apps

### Forced to Run Under Rosetta

**Issue**: App runs slower than expected on Apple Silicon

**Solution**:
1. Quit Battle Castles
2. Right-click **Battle Castles.app**
3. Select **Get Info**
4. **Uncheck** "Open using Rosetta"
5. Close Info window
6. Launch Battle Castles again

### Black Screen on Launch

**Solutions**:
1. Update to latest macOS version
2. Try windowed mode:
   ```bash
   open -a "Battle Castles" --args --windowed
   ```
3. Reset graphics settings:
   ```bash
   rm ~/Library/Application\ Support/BattleCastles/config/graphics.ini
   ```
4. Check for display driver updates

### Connection/Multiplayer Issues

**Solutions**:
1. Check Firewall settings:
   - System Settings > Network > Firewall
   - Add Battle Castles to allowed apps
2. Check network connection
3. Disable VPN temporarily
4. Try different network

### Audio Issues

**Solutions**:
1. Check System Settings > Sound > Output
2. Try different audio output device
3. Reset NVRAM/PRAM:
   - Restart Mac
   - Immediately press Command+Option+P+R
   - Hold for 20 seconds
4. Check in-game audio settings

### Game Crashes

**Solutions**:
1. Check crash logs in Console.app
2. Remove preferences:
   ```bash
   rm -rf ~/Library/Preferences/com.battlecastles.game.plist
   ```
3. Remove saved games (backup first):
   ```bash
   mv ~/Library/Application\ Support/BattleCastles ~/Desktop/BattleCastles-backup
   ```
4. Reinstall the game
5. Report crash with logs to support

---

## Uninstallation

### Complete Removal

1. Delete the application:
   ```bash
   rm -rf /Applications/Battle\ Castles.app
   ```

2. Delete support files (optional):
   ```bash
   rm -rf ~/Library/Application\ Support/BattleCastles
   rm -rf ~/Library/Caches/BattleCastles
   rm ~/Library/Preferences/com.battlecastles.game.plist
   rm -rf ~/Library/Saved\ Application\ State/com.battlecastles.game.savedState
   ```

3. Delete screenshots (optional):
   ```bash
   rm -rf ~/Pictures/Battle\ Castles
   ```

**Or use AppCleaner:**
1. Download [AppCleaner](https://freemacsoft.net/appcleaner/)
2. Drag Battle Castles.app to AppCleaner
3. Click "Remove" to delete app and associated files

---

## Building from Source

### Prerequisites

- **Xcode** 13 or newer (from Mac App Store)
- **Godot Engine** 4.x
- **Homebrew** (recommended)
- **Git**

### Install Dependencies

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Godot
brew install godot

# Clone repository
git clone https://github.com/battlecastles/battle-castles.git
cd battle-castles
```

### Build Steps

1. Open Godot project:
   ```bash
   godot -e client/project.godot
   ```

2. Export for macOS:
   - Project > Export
   - Select "Mac OSX"
   - Configure export settings
   - Click "Export Project"

3. Or use build script:
   ```bash
   cd deployment/scripts
   bash build_all_platforms.sh --mac
   ```

### Code Signing (For Distribution)

If you want to distribute your build:

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" "Battle Castles.app"

# Create ZIP for notarization
ditto -c -k --keepParent "Battle Castles.app" "BattleCastles.zip"

# Submit for notarization
xcrun notarytool submit BattleCastles.zip --apple-id your@email.com --password <app-specific-password> --team-id <team-id> --wait

# Staple notarization
xcrun stapler staple "Battle Castles.app"
```

---

## Keyboard Controls

Default controls:

- **WASD** - Move camera
- **Mouse** - Select and interact
- **Q/E** - Rotate camera
- **Space** - Action/Confirm
- **ESC** or **⌘Q** - Menu/Quit
- **⌘F** - Toggle fullscreen
- **⌘Shift+3** - Screenshot
- **⌘,** - Settings

macOS-specific:
- **⌘Q** - Quit application
- **⌘M** - Minimize window
- **⌘H** - Hide application
- **⌘Tab** - Switch applications

---

## Multi-Monitor Setup

### Using Multiple Displays

Battle Castles supports multi-monitor setups:

1. The game launches on the primary display by default
2. To move to another display:
   - Use windowed mode
   - Drag window to desired display
   - Press **⌘F** to fullscreen on that display

### Display Scaling

For Retina displays:
- Game automatically detects Retina/HiDPI displays
- Renders at native resolution for sharp graphics
- UI elements scale appropriately

---

## Support

### Getting Help

- **Documentation**: https://docs.battlecastles.com
- **Discord Community**: https://discord.gg/battlecastles
- **Email Support**: support@battlecastles.com
- **Bug Reports**: https://github.com/battlecastles/battle-castles/issues

### Reporting Bugs

Include in your report:
1. macOS version (About This Mac)
2. Mac model (Intel/Apple Silicon)
3. Game version (Help > About)
4. Steps to reproduce
5. Log files:
   ```bash
   open ~/Library/Application\ Support/BattleCastles/logs/
   ```
6. Screenshots if applicable

---

## FAQ

### Q: Does it run natively on Apple Silicon?
**A**: Yes! Battle Castles is a Universal Binary with native Apple Silicon support.

### Q: Can I use a controller?
**A**: Yes, PlayStation and Xbox controllers work. Most MFi controllers are supported.

### Q: Does it support Touch Bar?
**A**: Yes, on supported MacBook Pro models.

### Q: Can I play in windowed mode?
**A**: Yes, toggle with **⌘F** or set in Settings > Display.

### Q: Does it support cloud saves?
**A**: Yes, through your Battle Castles account.

---

## License

Copyright (c) 2025 Battle Castles Studio. All rights reserved.

See LICENSE.txt for full license information.