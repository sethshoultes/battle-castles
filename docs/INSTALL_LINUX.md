# Battle Castles - Linux Installation Guide

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04, Fedora 34, Debian 11, or equivalent
- **CPU**: Intel Core i3 or AMD equivalent (x86_64)
- **RAM**: 4 GB
- **GPU**: OpenGL 3.3 compatible graphics card
- **Storage**: 500 MB available space
- **Display**: 1280x720 resolution

### Recommended Requirements
- **OS**: Ubuntu 22.04 LTS, Fedora 38, or newer
- **CPU**: Intel Core i5 or AMD Ryzen 5
- **RAM**: 8 GB
- **GPU**: NVIDIA GTX 1060 / AMD RX 580 or better with Vulkan support
- **Storage**: 1 GB available space
- **Display**: 1920x1080 resolution or higher

### Supported Distributions
- Ubuntu 20.04+ (and derivatives: Pop!_OS, Linux Mint, etc.)
- Debian 11+
- Fedora 34+
- Arch Linux
- openSUSE Leap 15.3+
- Manjaro
- Other distributions with compatible libraries

---

## Installation Methods

### Method 1: Using .tar.gz Archive (Universal)

1. Download `BattleCastles-Linux-x64-x.x.x.tar.gz`
2. Extract the archive:
   ```bash
   tar -xzf BattleCastles-Linux-x64-x.x.x.tar.gz
   cd BattleCastles
   ```
3. Make executable:
   ```bash
   chmod +x BattleCastles.x86_64
   ```
4. Run the game:
   ```bash
   ./BattleCastles.x86_64
   ```

### Method 2: Using AppImage (No Installation Required)

1. Download `BattleCastles-x.x.x-x86_64.AppImage`
2. Make executable:
   ```bash
   chmod +x BattleCastles-x.x.x-x86_64.AppImage
   ```
3. Run:
   ```bash
   ./BattleCastles-x.x.x-x86_64.AppImage
   ```

**Optional**: Integrate with system:
```bash
# Install AppImageLauncher for better integration
# Ubuntu/Debian
sudo apt install appimagelauncher

# Fedora
sudo dnf install appimagelauncher

# Arch
yay -S appimagelauncher
```

### Method 3: System-wide Installation

```bash
# Extract to /opt
sudo tar -xzf BattleCastles-Linux-x64-x.x.x.tar.gz -C /opt/
sudo mv /opt/BattleCastles /opt/battlecastles

# Create symlink
sudo ln -s /opt/battlecastles/BattleCastles.x86_64 /usr/local/bin/battlecastles

# Create desktop entry
sudo tee /usr/share/applications/battlecastles.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Battle Castles
Comment=Strategic Castle Building Game
Exec=/usr/local/bin/battlecastles
Icon=/opt/battlecastles/icon.png
Terminal=false
Type=Application
Categories=Game;StrategyGame;
Keywords=game;strategy;castle;multiplayer;
EOF

# Update desktop database
sudo update-desktop-database
```

---

## Dependencies

### Ubuntu/Debian

```bash
# Install required libraries
sudo apt update
sudo apt install -y \
    libgl1 \
    libx11-6 \
    libxcursor1 \
    libxi6 \
    libxinerama1 \
    libxrandr2 \
    libasound2 \
    libpulse0
```

### Fedora

```bash
sudo dnf install -y \
    mesa-libGL \
    libX11 \
    libXcursor \
    libXi \
    libXinerama \
    libXrandr \
    alsa-lib \
    pulseaudio-libs
```

### Arch Linux

```bash
sudo pacman -S \
    mesa \
    libx11 \
    libxcursor \
    libxi \
    libxinerama \
    libxrandr \
    alsa-lib \
    libpulse
```

### openSUSE

```bash
sudo zypper install \
    Mesa-libGL1 \
    libX11-6 \
    libXcursor1 \
    libXi6 \
    libXinerama1 \
    libXrandr2 \
    alsa \
    libpulse0
```

---

## Graphics Drivers

### NVIDIA

**Proprietary Driver (Recommended for Gaming)**:

```bash
# Ubuntu/Debian
sudo apt install nvidia-driver-535

# Fedora
sudo dnf install akmod-nvidia

# Arch
sudo pacman -S nvidia nvidia-utils
```

**Verify Installation**:
```bash
nvidia-smi
```

### AMD

**AMDGPU (Open Source)**:

Usually included by default in modern distributions. Ensure Mesa is installed:

```bash
# Ubuntu/Debian
sudo apt install mesa-vulkan-drivers libvulkan1

# Fedora
sudo dnf install mesa-vulkan-drivers vulkan

# Arch
sudo pacman -S mesa vulkan-radeon
```

### Intel

**Mesa Driver**:

```bash
# Ubuntu/Debian
sudo apt install mesa-vulkan-drivers intel-media-va-driver

# Fedora
sudo dnf install mesa-vulkan-drivers

# Arch
sudo pacman -S mesa vulkan-intel
```

---

## First Launch

1. Launch Battle Castles:
   ```bash
   ./BattleCastles.x86_64
   # Or if installed system-wide
   battlecastles
   ```

2. The game will automatically:
   - Detect your hardware
   - Apply appropriate graphics settings
   - Create config directories in `~/.local/share/BattleCastles/`

3. First-time setup:
   - Configure graphics (auto-detected)
   - Set audio preferences
   - Create or log in to account

---

## Configuration

### File Locations

- **Save Files**: `~/.local/share/BattleCastles/saves/`
- **Configuration**: `~/.config/BattleCastles/`
- **Logs**: `~/.local/share/BattleCastles/logs/`
- **Screenshots**: `~/Pictures/BattleCastles/`
- **Cache**: `~/.cache/BattleCastles/`

### Graphics Settings

Battle Castles auto-detects hardware and applies:

- **High-end GPU (NVIDIA RTX, AMD RX 6000+)**: Ultra/High
- **Mid-range GPU**: Medium/High
- **Integrated GPU**: Low/Medium

Manual adjustment:
1. Press **ESC**
2. Settings > Graphics
3. Choose preset: Low, Medium, High, Ultra

### Performance by GPU

- **NVIDIA RTX Series**: Ultra @ 60+ FPS
- **NVIDIA GTX 1060+**: High @ 60 FPS
- **AMD RX 580+**: High @ 60 FPS
- **Intel Iris Xe**: Medium @ 45+ FPS
- **Older Integrated GPU**: Low @ 30+ FPS

---

## Command Line Arguments

```bash
./BattleCastles.x86_64 [options]
```

**Options**:
- `--fullscreen` - Start fullscreen
- `--windowed` - Start windowed
- `--width <value>` - Window width
- `--height <value>` - Window height
- `--quality <preset>` - Graphics quality (low/medium/high/ultra)
- `--no-intro` - Skip intro
- `--debug` - Enable debug console
- `--vulkan` - Force Vulkan renderer
- `--opengl3` - Force OpenGL 3 renderer

**Examples**:
```bash
# Fullscreen at high quality
./BattleCastles.x86_64 --fullscreen --quality high

# Debug mode with Vulkan
./BattleCastles.x86_64 --debug --vulkan

# Windowed 1080p
./BattleCastles.x86_64 --windowed --width 1920 --height 1080
```

---

## Troubleshooting

### Game Won't Start

**Check Missing Libraries**:
```bash
ldd ./BattleCastles.x86_64 | grep "not found"
```

Install any missing libraries using your package manager.

**Check Logs**:
```bash
cat ~/.local/share/BattleCastles/logs/latest.log
```

**Common Fixes**:
```bash
# Update system
sudo apt update && sudo apt upgrade  # Ubuntu/Debian
sudo dnf update  # Fedora
sudo pacman -Syu  # Arch

# Install OpenGL/Vulkan
sudo apt install libgl1-mesa-glx libvulkan1  # Ubuntu/Debian
```

### Low FPS / Performance

**1. Check if using correct GPU** (for hybrid graphics):
```bash
# NVIDIA Optimus
prime-select query  # Check current GPU
sudo prime-select nvidia  # Switch to NVIDIA

# Or launch with dedicated GPU
prime-run ./BattleCastles.x86_64
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia ./BattleCastles.x86_64
```

**2. Disable Compositor** (can cause stuttering):
```bash
# KDE Plasma
qdbus org.kde.KWin /Compositor suspend

# XFCE
xfconf-query -c xfwm4 -p /general/use_compositing -s false
```

**3. Check CPU Governor**:
```bash
# Check current
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

**4. Lower Graphics Settings**:
- In-game: Settings > Graphics > Low/Medium

**5. Close Background Apps**:
```bash
htop  # Check for CPU/RAM hogs
```

### Black Screen / Graphics Issues

**Try Different Renderer**:
```bash
# Force OpenGL
./BattleCastles.x86_64 --opengl3

# Force Vulkan
./BattleCastles.x86_64 --vulkan
```

**Update Graphics Drivers**:
```bash
# Ubuntu/Debian - NVIDIA
sudo ubuntu-drivers autoinstall

# Fedora - NVIDIA
sudo dnf update

# AMD - Update Mesa
sudo apt install --upgrade mesa-vulkan-drivers
```

**Disable Full Composition Pipeline** (NVIDIA):
```bash
nvidia-settings
# X Server Display Configuration > Advanced > Uncheck "Force Full Composition Pipeline"
```

### Audio Issues

**Check PulseAudio**:
```bash
# Test audio
speaker-test -t wav -c 2

# Restart PulseAudio
pulseaudio -k
pulseaudio --start
```

**Check ALSA**:
```bash
alsamixer  # Adjust volume levels
```

**Run with specific audio device**:
```bash
SDL_AUDIODRIVER=pulse ./BattleCastles.x86_64  # Use PulseAudio
SDL_AUDIODRIVER=alsa ./BattleCastles.x86_64   # Use ALSA
```

### Connection Issues

**Check Firewall**:
```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 7777/tcp
sudo ufw allow 7777/udp

# Fedora (firewalld)
sudo firewall-cmd --add-port=7777/tcp --permanent
sudo firewall-cmd --add-port=7777/udp --permanent
sudo firewall-cmd --reload
```

**Test Connection**:
```bash
ping battlecastles.com
nslookup battlecastles.com
```

### Wayland Issues

If experiencing issues on Wayland:

```bash
# Force X11
GDK_BACKEND=x11 ./BattleCastles.x86_64

# Or switch to X11 session
# (Log out and select X11 session at login screen)
```

---

## Building from Source

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt install git build-essential scons pkg-config libx11-dev \
    libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu1-dev \
    libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev

# Fedora
sudo dnf install git gcc-c++ scons pkgconfig libX11-devel \
    libXcursor-devel libXinerama-devel mesa-libGL-devel \
    alsa-lib-devel pulseaudio-libs-devel libXi-devel libXrandr-devel

# Arch
sudo pacman -S git base-devel scons pkgconf libx11 libxcursor \
    libxinerama mesa libgl alsa-lib libpulse libxi libxrandr
```

### Install Godot

```bash
# Download from https://godotengine.org/download/linux
# Or use package manager

# Flatpak (Universal)
flatpak install flathub org.godotengine.Godot

# Snap
sudo snap install godot-4

# Or add to PATH
wget https://downloads.tuxfamily.org/godotengine/4.x/Godot_v4.x_linux.x86_64.zip
unzip Godot_v4.x_linux.x86_64.zip
sudo mv Godot_v4.x_linux.x86_64 /usr/local/bin/godot
```

### Build Steps

```bash
# Clone repository
git clone https://github.com/battlecastles/battle-castles.git
cd battle-castles

# Open in Godot
godot -e client/project.godot

# Export from Godot Editor:
# Project > Export > Linux/X11 > Export Project

# Or use build script
cd deployment/scripts
bash build_all_platforms.sh --linux
```

---

## Desktop Integration

### Create Desktop Entry Manually

```bash
mkdir -p ~/.local/share/applications/

cat > ~/.local/share/applications/battlecastles.desktop << 'EOF'
[Desktop Entry]
Name=Battle Castles
Comment=Strategic Castle Building Game
Exec=/path/to/BattleCastles.x86_64
Icon=/path/to/icon.png
Terminal=false
Type=Application
Categories=Game;StrategyGame;
Keywords=game;strategy;castle;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

### Add to Steam (Optional)

1. Open Steam
2. Games > Add a Non-Steam Game
3. Browse to Battle Castles executable
4. Click "Add Selected Programs"

---

## Uninstallation

### Remove Application

```bash
# If installed to /opt
sudo rm -rf /opt/battlecastles
sudo rm /usr/local/bin/battlecastles
sudo rm /usr/share/applications/battlecastles.desktop
sudo update-desktop-database

# Remove user data (optional)
rm -rf ~/.local/share/BattleCastles
rm -rf ~/.config/BattleCastles
rm -rf ~/.cache/BattleCastles
```

---

## Keyboard Controls

- **WASD** - Camera movement
- **Mouse** - Select/interact
- **Q/E** - Rotate camera
- **Space** - Action/confirm
- **ESC** - Menu
- **F11** - Toggle fullscreen
- **F12** - Screenshot
- **~ (tilde)** - Debug console

---

## Support

### Resources

- **Documentation**: https://docs.battlecastles.com
- **Discord**: https://discord.gg/battlecastles
- **Email**: support@battlecastles.com
- **Bug Reports**: https://github.com/battlecastles/battle-castles/issues

### Reporting Bugs

Include:
1. Linux distribution and version (`cat /etc/os-release`)
2. Kernel version (`uname -r`)
3. Graphics card (`lspci | grep VGA`)
4. Driver info (`glxinfo | grep "OpenGL version"`)
5. Game logs (`~/.local/share/BattleCastles/logs/`)

---

## FAQ

### Q: Which graphics API should I use?
**A**: Vulkan for modern GPUs (better performance), OpenGL 3.3 for older hardware.

### Q: Does it work on Steam Deck?
**A**: Yes! Use Proton or native Linux build. Low/Medium settings recommended.

### Q: Can I use a controller?
**A**: Yes, most controllers are supported via SDL2.

### Q: Does it work with NVIDIA Optimus?
**A**: Yes, use `prime-run` or `__NV_PRIME_RENDER_OFFLOAD=1` to force discrete GPU.

---

## License

Copyright (c) 2025 Battle Castles Studio. All rights reserved.