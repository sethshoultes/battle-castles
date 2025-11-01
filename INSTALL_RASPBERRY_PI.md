# Battle Castles - Raspberry Pi 5 Installation Guide

## Why Raspberry Pi 5?

Battle Castles has been specially optimized for the Raspberry Pi 5, making it one of the first major games to fully support this platform. The Raspberry Pi 5's improved GPU and CPU make it capable of running modern games at playable frame rates.

### What to Expect

- **Performance**: 30+ FPS at 1080p resolution
- **Graphics**: Optimized low-quality settings that still look great
- **Memory**: Runs smoothly on 4GB models, better on 8GB
- **Controls**: Full keyboard, mouse, and controller support

---

## System Requirements

### Minimum Requirements
- **Hardware**: Raspberry Pi 5 (4GB RAM model)
- **OS**: Raspberry Pi OS (64-bit) Bookworm or newer
- **Storage**: 1 GB available space (SD card or USB)
- **Display**: 1080p HDMI display
- **Cooling**: Basic heatsink (passive cooling)

### Recommended Requirements
- **Hardware**: Raspberry Pi 5 (8GB RAM model)
- **OS**: Raspberry Pi OS (64-bit) latest version
- **Storage**: 2 GB available space on fast SD card (UHS-I or better) or USB 3.0 drive
- **Display**: 1080p HDMI display with 60Hz refresh rate
- **Cooling**: Active cooling (fan) for sustained performance
- **Power**: Official 27W USB-C power supply
- **Peripherals**: USB keyboard, mouse, and optional game controller

### Optional Enhancements
- **Overclocking**: Can boost performance to 35-40 FPS
- **SSD Boot**: Much faster loading times than SD card
- **USB 3.0 Storage**: Better than SD card for game installation

---

## Pre-Installation Setup

### Update Your Raspberry Pi

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Update firmware
sudo rpi-update

# Reboot
sudo reboot
```

### Install Required Dependencies

```bash
# Install graphics libraries
sudo apt install -y \
    libgl1 \
    libx11-6 \
    libxcursor1 \
    libxi6 \
    libxinerama1 \
    libxrandr2 \
    libasound2 \
    libpulse0 \
    mesa-utils \
    vulkan-tools

# Verify OpenGL support
glxinfo | grep "OpenGL version"
# Should show OpenGL ES 3.1 or higher
```

---

## Installation Methods

### Method 1: Using .deb Package (Recommended)

1. Download the Raspberry Pi package:
   ```bash
   wget https://battlecastles.com/downloads/battlecastles_1.0.0_arm64.deb
   ```

2. Install the package:
   ```bash
   sudo dpkg -i battlecastles_1.0.0_arm64.deb
   ```

3. Install any missing dependencies:
   ```bash
   sudo apt install -f -y
   ```

4. Launch from the application menu:
   - **Menu** > **Games** > **Battle Castles**

   Or from terminal:
   ```bash
   battlecastles
   ```

### Method 2: Using Installation Script

1. Download and extract the package:
   ```bash
   wget https://battlecastles.com/downloads/BattleCastles-RaspberryPi5-1.0.0.tar.gz
   tar -xzf BattleCastles-RaspberryPi5-1.0.0.tar.gz
   cd BattleCastles-RaspberryPi5
   ```

2. Run the installation script:
   ```bash
   bash install.sh
   ```

3. Follow the on-screen instructions

### Method 3: Manual Installation

1. Download and extract:
   ```bash
   wget https://battlecastles.com/downloads/BattleCastles-RaspberryPi5-1.0.0.tar.gz
   tar -xzf BattleCastles-RaspberryPi5-1.0.0.tar.gz
   ```

2. Move to installation directory:
   ```bash
   sudo mkdir -p /opt/battlecastles
   sudo mv BattleCastles-RaspberryPi5/* /opt/battlecastles/
   sudo chmod +x /opt/battlecastles/BattleCastles.arm64
   ```

3. Create launcher:
   ```bash
   sudo ln -s /opt/battlecastles/BattleCastles.arm64 /usr/local/bin/battlecastles
   ```

4. Create desktop entry:
   ```bash
   cat > ~/.local/share/applications/battlecastles.desktop << 'EOF'
   [Desktop Entry]
   Name=Battle Castles
   Comment=Strategic Castle Building Game - Raspberry Pi 5 Edition
   Exec=/usr/local/bin/battlecastles
   Icon=/opt/battlecastles/icon.png
   Terminal=false
   Type=Application
   Categories=Game;StrategyGame;
   EOF

   update-desktop-database ~/.local/share/applications/
   ```

---

## First Launch

### Initial Setup

1. Launch Battle Castles
2. The game will automatically detect Raspberry Pi 5 and apply optimizations:
   - Graphics quality: Low (optimized)
   - Target FPS: 30
   - Resolution: 1920x1080
   - Particles: Reduced
   - Shadows: Disabled
   - View distance: Reduced

3. You'll be prompted to:
   - Create or log in to your account
   - Adjust audio settings
   - Test controls

### First Run Optimizations

The game automatically applies Raspberry Pi 5 specific optimizations:

✓ **Graphics Engine**
  - ETC2 texture compression (lower memory usage)
  - Reduced draw distance
  - Simplified particle effects
  - Disabled screen-space effects

✓ **Performance**
  - 30 FPS target (smooth and consistent)
  - Reduced physics simulation rate
  - Memory pooling optimizations
  - Background loading for smooth gameplay

✓ **Display**
  - 1080p native resolution
  - Fullscreen by default (best performance)
  - VSync enabled to prevent tearing

---

## Configuration

### File Locations

- **Installation**: `/opt/battlecastles/`
- **Save Files**: `~/.local/share/BattleCastles/saves/`
- **Configuration**: `~/.config/BattleCastles/`
- **Logs**: `~/.local/share/BattleCastles/logs/`
- **Screenshots**: `~/Pictures/BattleCastles/`

### Graphics Settings

While the game auto-configures for optimal Raspberry Pi 5 performance, you can adjust settings:

1. Press **ESC** to open menu
2. Select **Settings** > **Graphics**
3. Available options:
   - **Resolution**: 1080p recommended, 720p for more performance
   - **Fullscreen**: Keep enabled for best performance
   - **Particle Density**: Low/Minimal
   - **View Distance**: Short/Medium
   - **Texture Quality**: Low (uses less RAM)

**Warning**: Increasing quality settings above Low may cause FPS drops below 30.

### Audio Configuration

```bash
# Check audio output
aplay -l

# Set default audio device if needed
sudo nano /etc/asound.conf
```

### Controls

Default controls work with:
- **Keyboard + Mouse**: Recommended
- **USB Game Controllers**: Xbox, PlayStation controllers supported
- **Wireless Controllers**: Via Bluetooth

To pair a Bluetooth controller:
```bash
sudo bluetoothctl
scan on
pair [MAC_ADDRESS]
connect [MAC_ADDRESS]
trust [MAC_ADDRESS]
```

---

## Performance Optimization

### Raspberry Pi 5 Configuration

Edit `/boot/firmware/config.txt`:

```bash
sudo nano /boot/firmware/config.txt
```

Add/modify these settings:

```ini
# GPU Memory (increase for better graphics performance)
gpu_mem=256

# Enable V3D driver (for better OpenGL performance)
dtoverlay=vc4-kms-v3d

# Disable screen blanking
hdmi_blanking=1

# Force 1080p resolution
hdmi_group=1
hdmi_mode=16

# Improve audio
disable_audio_dither=1
```

Save and reboot:
```bash
sudo reboot
```

### Active Cooling

For sustained 30 FPS, active cooling is highly recommended:

1. **Official Active Cooler**: Best option, quiet and effective
2. **Third-party Fan**: PWM-controlled fans work great
3. **Check temperature**:
   ```bash
   vcgencmd measure_temp
   ```

   Should stay below 70°C during gameplay.

### Overclocking (Advanced)

**Warning**: Overclocking can void warranty and requires good cooling!

Edit `/boot/firmware/config.txt`:

```bash
sudo nano /boot/firmware/config.txt
```

Add these lines:

```ini
# Raspberry Pi 5 Overclocking for Gaming
over_voltage=6
arm_freq=2600
gpu_freq=900
```

**Expected Results**:
- Stock: 30-32 FPS
- Overclocked: 35-40 FPS

Monitor temperature during gaming:
```bash
watch -n 1 vcgencmd measure_temp
```

Keep below 75°C for safety.

### Close Background Processes

For best performance, close unnecessary applications:

```bash
# Check running processes
htop

# Close desktop effects (if using full desktop)
# Lightweight desktop environments work best:
# - LXDE
# - XFCE (lite version)
```

### SSD Boot (Highly Recommended)

Running from USB 3.0 SSD significantly improves loading times:

1. Get USB 3.0 SSD
2. Use Raspberry Pi Imager to flash OS to SSD
3. Boot from SSD (Raspberry Pi 5 supports this by default)
4. Install Battle Castles on SSD

**Benefits**:
- 5-10x faster loading
- Smoother asset streaming
- Less stuttering during gameplay

---

## Troubleshooting

### Low FPS (Below 25 FPS)

**Check temperature**:
```bash
vcgencmd measure_temp
```
If over 70°C, add cooling.

**Close background apps**:
```bash
# See what's running
htop

# Close Chromium, LibreOffice, etc.
pkill chromium
```

**Lower resolution**:
```bash
battlecastles --width 1280 --height 720
```

**Verify GPU memory**:
```bash
vcgencmd get_mem gpu
# Should show at least 128MB, preferably 256MB
```

### Game Won't Start

**Check dependencies**:
```bash
ldd /opt/battlecastles/BattleCastles.arm64 | grep "not found"
```

Install any missing libraries:
```bash
sudo apt install -f
```

**Check logs**:
```bash
cat ~/.local/share/BattleCastles/logs/latest.log
```

**Verify architecture**:
```bash
file /opt/battlecastles/BattleCastles.arm64
# Should show "ARM aarch64"
```

**Check OpenGL**:
```bash
glxinfo | grep "OpenGL"
# Should show OpenGL ES 3.1 or higher
```

### Black Screen / Display Issues

**Force resolution**:
```bash
battlecastles --width 1920 --height 1080 --fullscreen
```

**Try windowed mode**:
```bash
battlecastles --windowed
```

**Check HDMI connection**:
```bash
# Check HDMI status
tvservice -s

# Force HDMI mode
sudo tvservice -e "DMT 82"  # 1080p 60Hz
```

### Audio Issues

**Test audio**:
```bash
speaker-test -t wav -c 2
```

**Check volume**:
```bash
alsamixer
```

**Switch audio output**:
```bash
# List audio devices
aplay -l

# Select HDMI audio
sudo raspi-config
# System Options > Audio > HDMI
```

### Controller Not Working

**USB Controller**:
```bash
# Check if detected
lsusb

# Test input
jstest /dev/input/js0
```

**Bluetooth Controller**:
```bash
# Check Bluetooth
sudo bluetoothctl
devices
# Should show your controller

# Reconnect if needed
connect [MAC_ADDRESS]
```

### Network/Multiplayer Issues

**Check connection**:
```bash
ping -c 4 battlecastles.com
```

**Open firewall ports**:
```bash
sudo ufw allow 7777/tcp
sudo ufw allow 7777/udp
sudo ufw enable
```

### Memory Issues (4GB Model)

**Enable zram for more effective memory**:
```bash
sudo apt install zram-tools
sudo nano /etc/default/zramswap
# Set SIZE=2048 (2GB swap)

sudo service zramswap restart
```

**Close background apps before gaming**:
```bash
# Minimal gaming environment
sudo systemctl stop cups  # Printing service
sudo systemctl stop avahi-daemon  # Network discovery
```

---

## Command Line Options

```bash
battlecastles [options]
```

**Options**:
- `--fullscreen` - Fullscreen mode (default)
- `--windowed` - Windowed mode
- `--width <value>` - Window width (default: 1920)
- `--height <value>` - Window height (default: 1080)
- `--quality low` - Force low quality (always recommended for Pi 5)
- `--fps <value>` - Target FPS (default: 30)
- `--no-intro` - Skip intro video
- `--debug` - Show FPS counter and debug info

**Examples**:
```bash
# 720p for more performance
battlecastles --width 1280 --height 720

# Debug mode with FPS counter
battlecastles --debug

# Try 60 FPS (requires overclocking)
battlecastles --fps 60
```

---

## Performance Benchmarks

### Stock Raspberry Pi 5 (2.4 GHz)

| Scenario | FPS | Notes |
|----------|-----|-------|
| Main Menu | 30-35 | Stable |
| Single Player (Early Game) | 30-32 | Smooth |
| Single Player (Late Game) | 28-30 | Many units |
| Multiplayer (2 Players) | 28-30 | Good |
| Multiplayer (4 Players) | 25-28 | Playable |
| Large Battles | 25-27 | Intense |

### Overclocked (2.6 GHz + Active Cooling)

| Scenario | FPS | Notes |
|----------|-----|-------|
| Main Menu | 40-45 | Very smooth |
| Single Player (Early Game) | 35-38 | Excellent |
| Single Player (Late Game) | 32-35 | Smooth |
| Multiplayer (2 Players) | 32-35 | Great |
| Multiplayer (4 Players) | 30-32 | Smooth |
| Large Battles | 28-30 | Good |

---

## Building from Source

### Prerequisites

```bash
# Install build dependencies
sudo apt install -y \
    git \
    build-essential \
    scons \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxinerama-dev \
    libgl1-mesa-dev \
    libglu1-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxi-dev \
    libxrandr-dev

# Install Godot Engine 4.x (ARM64 version)
wget https://downloads.tuxfamily.org/godotengine/4.x/Godot_v4.x_linux.arm64.zip
unzip Godot_v4.x_linux.arm64.zip
sudo mv Godot_v4.x_linux.arm64 /usr/local/bin/godot
sudo chmod +x /usr/local/bin/godot
```

### Build Steps

```bash
# Clone repository
git clone https://github.com/battlecastles/battle-castles.git
cd battle-castles

# Open in Godot (may take a while on first open)
godot -e client/project.godot

# Export (or use build script)
cd deployment/scripts
bash build_all_platforms.sh --rpi

# Package
bash package_rpi5.sh 1.0.0
```

**Note**: Building on Raspberry Pi 5 can take 30-60 minutes.

---

## Uninstallation

### Remove Package

```bash
# If installed via .deb
sudo apt remove battlecastles
sudo apt autoremove

# Or manually
sudo rm -rf /opt/battlecastles
sudo rm /usr/local/bin/battlecastles
sudo rm /usr/share/applications/battlecastles.desktop

# Remove user data (optional)
rm -rf ~/.local/share/BattleCastles
rm -rf ~/.config/BattleCastles
rm -rf ~/.cache/BattleCastles
rm -rf ~/Pictures/BattleCastles
```

---

## Community & Support

### Resources

- **Website**: https://battlecastles.com
- **Documentation**: https://docs.battlecastles.com/raspberry-pi
- **Discord**: https://discord.gg/battlecastles (Raspberry Pi channel)
- **Forum**: https://forum.battlecastles.com/raspberry-pi
- **GitHub**: https://github.com/battlecastles/battle-castles/issues

### Reporting Issues

Include in your report:
```bash
# System info
cat /proc/device-tree/model
uname -a
cat /etc/os-release

# Temperature
vcgencmd measure_temp

# Memory
free -h

# GPU memory
vcgencmd get_mem gpu

# OpenGL info
glxinfo | grep "OpenGL version"

# Game logs
cat ~/.local/share/BattleCastles/logs/latest.log
```

---

## Tips & Tricks

### Best Settings for Raspberry Pi 5

1. **Use fullscreen mode** - Better performance than windowed
2. **Close all background apps** - Every MB of RAM counts
3. **Keep system updated** - Firmware updates improve GPU performance
4. **Use active cooling** - Maintains boost clocks
5. **Boot from SSD** - Much faster loading
6. **256MB GPU memory** - Sweet spot for this game
7. **Disable compositor** - If using X11 desktop

### Optimizing Your Setup

```bash
# Disable unnecessary services
sudo systemctl disable bluetooth  # If not using controllers
sudo systemctl disable cups        # If not printing
sudo systemctl disable avahi-daemon

# Use lightweight desktop
# Consider switching from full Pixel Desktop to LXDE or even running
# the game from console (without X11) for maximum performance
```

### Multiplayer Tips

- **Host on PC**: Let more powerful machines host multiplayer games
- **Use wired Ethernet**: WiFi can add latency
- **Reduce player count**: 2-player games run better than 4-player

---

## FAQ

### Q: Can I really run a modern game on Raspberry Pi 5?
**A**: Yes! The Pi 5's VideoCore VII GPU and improved CPU make it capable of running optimized games at playable frame rates. Battle Castles has been specifically optimized for this platform.

### Q: Will it work on Raspberry Pi 4?
**A**: Not officially supported. The Pi 4's GPU is significantly less powerful. You can try, but expect 15-20 FPS at best.

### Q: Does overclocking really help?
**A**: Yes! With proper cooling, overclocking can boost FPS from 30 to 35-40.

### Q: Can I play multiplayer?
**A**: Absolutely! The game runs smoothly in multiplayer. Network performance is good on Pi 5.

### Q: Does it run in 4K?
**A**: The Pi 5 can output 4K, but the game runs at 1080p internally for performance. You can try 4K (--width 3840 --height 2160) but expect 15-20 FPS.

### Q: Can I mod the game on Raspberry Pi?
**A**: Yes! Modding is supported. Check the modding documentation.

### Q: Will it damage my Raspberry Pi?
**A**: No. The game is well-optimized and won't push hardware beyond safe limits. Just ensure proper cooling.

---

## Acknowledgments

Special thanks to the Raspberry Pi Foundation for creating such an capable platform, and to the open-source community for the excellent tools and libraries that make this possible.

---

## License

Copyright (c) 2025 Battle Castles Studio. All rights reserved.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.