# Raspberry Pi 5 Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying and optimizing Battle Castles on Raspberry Pi 5 with 16GB RAM and optional Hailo AI kit. The game runs natively using Godot Engine with performance optimizations specific to the ARM64 architecture.

## Hardware Requirements

### Minimum Configuration
- **Model:** Raspberry Pi 5 (4GB RAM minimum)
- **Storage:** 32GB microSD Card (Class 10/A2)
- **Power:** Official 27W USB-C Power Supply
- **Display:** HDMI monitor (1080p recommended)
- **Input:** USB keyboard and mouse
- **Network:** Ethernet or WiFi for multiplayer

### Recommended Configuration
- **Model:** Raspberry Pi 5 (8GB or 16GB RAM)
- **Storage:** NVMe SSD via PCIe adapter
- **Cooling:** Active cooler or fan case
- **Network:** Gigabit Ethernet for best latency
- **Optional:** Hailo-8L AI accelerator kit

### Performance Expectations
| Configuration | Expected FPS | Resolution | Max Units |
|---------------|--------------|------------|-----------|
| RPi5 4GB | 30 FPS | 720p | 20-30 |
| RPi5 8GB | 30-45 FPS | 1080p | 30-40 |
| RPi5 16GB | 45-60 FPS | 1080p | 40 |
| RPi5 16GB + OC | 60 FPS | 1080p | 40+ |

## Initial Setup

### 1. Prepare Raspberry Pi OS

```bash
# Update to latest Raspberry Pi OS (64-bit required)
sudo apt update && sudo apt full-upgrade -y
sudo rpi-update

# Install essential packages
sudo apt install -y \
    build-essential \
    git \
    git-lfs \
    cmake \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxinerama-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxi-dev \
    libxrandr-dev \
    libwayland-dev

# Enable GPU acceleration
sudo raspi-config
# Navigate to: Advanced Options > GL Driver > GL (Full KMS)
```

### 2. Optimize System Performance

#### CPU Governor
```bash
# Set performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent
sudo nano /etc/rc.local
# Add before 'exit 0':
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
```

#### GPU Memory Split
```bash
# Edit boot configuration
sudo nano /boot/firmware/config.txt

# Add or modify:
gpu_mem=256
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# For overclocking (optional, voids warranty):
over_voltage=6
arm_freq=2800
gpu_freq=900
```

#### Swap Configuration
```bash
# Increase swap for 4GB models
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set: CONF_SWAPSIZE=2048

sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## Installation Methods

### Method 1: Pre-built Binary (.deb Package)

```bash
# Download the latest release
wget https://github.com/battle-castles/releases/download/v1.0.0/battle-castles_1.0.0_arm64.deb

# Install the package
sudo dpkg -i battle-castles_1.0.0_arm64.deb

# Fix any dependency issues
sudo apt-get install -f

# Launch the game
battle-castles
```

### Method 2: AppImage (Portable)

```bash
# Download AppImage
wget https://github.com/battle-castles/releases/download/v1.0.0/BattleCastles-arm64.AppImage

# Make executable
chmod +x BattleCastles-arm64.AppImage

# Run directly
./BattleCastles-arm64.AppImage
```

### Method 3: Build from Source

```bash
# Clone repository
git clone https://github.com/battle-castles/battle-castles.git
cd battle-castles

# Pull LFS assets
git lfs pull

# Install Godot (compile for ARM64)
wget https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.arm64.zip
unzip Godot_v4.3-stable_linux.arm64.zip
sudo mv Godot_v4.3-stable_linux.arm64 /usr/local/bin/godot

# Export the game
godot --headless --export "Linux ARM64" builds/battle_castles_arm64
chmod +x builds/battle_castles_arm64

# Run the game
./builds/battle_castles_arm64
```

## Game Configuration

### Performance Settings

Create configuration file:
```bash
mkdir -p ~/.config/battle-castles
nano ~/.config/battle-castles/settings.ini
```

```ini
[display]
# Resolution settings
resolution_width=1920
resolution_height=1080
fullscreen=true
vsync=true
max_fps=60

[graphics]
# Quality settings for RPi5
quality_preset=medium
shadows_enabled=false
anti_aliasing=fxaa
particle_quality=low
texture_quality=high
render_scale=0.9

[performance]
# RPi5 optimizations
max_units_on_screen=40
physics_tick_rate=30
network_tick_rate=20
enable_object_pooling=true
enable_lod_system=true

[audio]
master_volume=0.8
sfx_volume=1.0
music_volume=0.6
enable_3d_audio=false

[network]
# LAN settings
enable_lan_discovery=true
max_latency_compensation=150
interpolation_buffer=100
```

### Godot Project Settings

For development, optimize `project.godot`:
```ini
[rendering]
# RPi5 specific optimizations
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="gl_compatibility"
driver/threads/thread_model=1

textures/vram_compression/import_etc2_astc=true
textures/default_filters/use_nearest_mipmap_filter=true

anti_aliasing/quality/screen_space_aa=0
anti_aliasing/quality/use_debanding=false

environment/ssao/quality=0
environment/ssil/quality=0
environment/glow/upscale_mode=0

lights_and_shadows/directional_shadow/size=2048
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=0

[physics]
# Reduce physics overhead
2d/default_gravity=0.0
2d/physics_ticks_per_second=30
common/physics_jitter_fix=0.0
```

## Network Setup

### Host a LAN Server

```bash
# 1. Configure firewall
sudo ufw allow 7777/tcp  # Game port
sudo ufw allow 7778/udp  # Discovery port
sudo ufw enable

# 2. Set static IP (optional but recommended)
sudo nano /etc/dhcpcd.conf
# Add:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1

# 3. Launch as server
battle-castles --server --port 7777 --max-players 4
```

### Join LAN Games

```bash
# Auto-discovery
battle-castles --join-lan

# Direct connection
battle-castles --connect 192.168.1.100:7777
```

### Multiple RPi5 LAN Party Setup

```bash
# On the host RPi5 (most powerful one)
# 1. Run dedicated server
battle-castles --dedicated-server --port 7777

# 2. Also run game client
battle-castles --connect localhost:7777

# On other RPi5 devices
battle-castles --connect 192.168.1.100:7777
```

## Performance Monitoring

### System Monitoring

```bash
# Install monitoring tools
sudo apt install -y htop iotop nmon

# Monitor during gameplay
htop  # CPU and memory usage
iotop  # Disk I/O
vcgencmd measure_temp  # Temperature
vcgencmd get_throttled  # Check for throttling

# Create monitoring script
nano monitor_game.sh
```

```bash
#!/bin/bash
# monitor_game.sh

while true; do
    clear
    echo "=== Battle Castles Performance Monitor ==="
    echo "CPU Temp: $(vcgencmd measure_temp | cut -d= -f2)"
    echo "CPU Freq: $(vcgencmd measure_clock arm | cut -d= -f2 | awk '{print $1/1000000 " MHz"}')"
    echo "GPU Freq: $(vcgencmd measure_clock core | cut -d= -f2 | awk '{print $1/1000000 " MHz"}')"
    echo "Throttled: $(vcgencmd get_throttled)"
    echo ""
    echo "Memory Usage:"
    free -h | grep -E "^Mem|^Swap"
    echo ""
    echo "Top Processes:"
    ps aux | grep battle-castles | head -1
    sleep 2
done
```

### FPS Counter

Enable in-game FPS display:
```gdscript
# Add to main game script
func _ready():
    if OS.get_name() == "Linux" and OS.get_processor_name().contains("ARM"):
        # Enable RPi5 performance overlay
        get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_FPS)
```

## Troubleshooting

### Common Issues and Solutions

#### Low FPS / Stuttering

```bash
# 1. Check for thermal throttling
vcgencmd get_throttled
# If not 0x0, improve cooling

# 2. Reduce graphics settings
nano ~/.config/battle-castles/settings.ini
# Set: quality_preset=low, render_scale=0.8

# 3. Close background applications
pkill chromium
pkill vscode
```

#### Audio Issues

```bash
# Fix audio latency
sudo nano /etc/pulse/daemon.conf
# Uncomment and set:
default-sample-rate = 44100
default-fragments = 4
default-fragment-size-msec = 5

# Restart PulseAudio
pulseaudio -k
pulseaudio --start
```

#### Network Lag

```bash
# Optimize network settings
sudo nano /etc/sysctl.conf
# Add:
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

sudo sysctl -p
```

#### Game Won't Start

```bash
# Check dependencies
ldd battle_castles | grep "not found"

# Install missing libraries
sudo apt install libgles2 libvulkan1

# Check permissions
chmod +x battle_castles

# Run with debug output
GODOT_VERBOSE=1 ./battle_castles
```

## Advanced Optimizations

### Compile Godot with RPi5 Optimizations

```bash
# Clone Godot source
git clone -b 4.3-stable https://github.com/godotengine/godot.git
cd godot

# Configure for RPi5
scons platform=linuxbsd \
    target=template_release \
    arch=arm64 \
    use_lto=yes \
    optimize=speed \
    builtin_freetype=yes \
    builtin_libpng=yes \
    builtin_zlib=yes \
    module_mono_enabled=no \
    -j4

# Build export template
cp bin/godot.linuxbsd.template_release.arm64 \
    ~/.local/share/godot/export_templates/4.3.stable/linux_release.arm64
```

### Use Hailo AI Kit (Experimental)

```bash
# Install Hailo runtime
wget https://hailo.ai/download/hailo-rte-4.16.0-arm64.deb
sudo dpkg -i hailo-rte-4.16.0-arm64.deb

# Python bindings for AI features
pip3 install hailo-platform==4.16.0

# Configure game to use Hailo
export BATTLE_CASTLES_USE_HAILO=1
export HAILO_DEVICE=/dev/hailo0
```

Future AI features could include:
- Smart AI opponents using neural networks
- Real-time strategy prediction
- Automated highlight detection in replays

### Kiosk Mode Setup

For dedicated gaming station:

```bash
# 1. Auto-login
sudo raspi-config
# System Options > Boot > Desktop Autologin

# 2. Create autostart entry
mkdir -p ~/.config/autostart
nano ~/.config/autostart/battle-castles.desktop
```

```ini
[Desktop Entry]
Type=Application
Name=Battle Castles Kiosk
Exec=/usr/local/bin/battle-castles --fullscreen --kiosk
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

```bash
# 3. Disable screen blanking
xset s off
xset -dpms
xset s noblank

# 4. Hide mouse cursor when idle
sudo apt install unclutter
unclutter -idle 3 &
```

## Deployment Checklist

### Pre-Deployment
- [ ] Raspberry Pi OS updated
- [ ] GPU memory set to 256MB
- [ ] Performance governor enabled
- [ ] Cooling solution installed
- [ ] Network configured (static IP for server)

### Installation
- [ ] Game binary installed
- [ ] Dependencies resolved
- [ ] Permissions set correctly
- [ ] Configuration file created

### Optimization
- [ ] Graphics settings adjusted for hardware
- [ ] Background services disabled
- [ ] Network settings optimized
- [ ] Audio latency minimized

### Testing
- [ ] Single-player mode works
- [ ] LAN multiplayer connects
- [ ] FPS meets target (30+ FPS)
- [ ] No thermal throttling
- [ ] Audio plays without issues

### Production
- [ ] Kiosk mode configured (if needed)
- [ ] Monitoring scripts in place
- [ ] Backup of configuration
- [ ] Documentation for users

## Maintenance

### Regular Updates

```bash
# Update game
sudo apt update
sudo apt upgrade battle-castles

# Or for manual installation
wget https://github.com/battle-castles/releases/latest/battle-castles_arm64.deb
sudo dpkg -i battle-castles_arm64.deb
```

### Log Rotation

```bash
# Configure log rotation
sudo nano /etc/logrotate.d/battle-castles
```

```
/home/pi/.local/share/battle-castles/logs/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

### Backup Save Games

```bash
# Backup script
nano backup_saves.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/pi/backups/battle-castles"
SAVE_DIR="/home/pi/.local/share/battle-castles/saves"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/saves_$DATE.tar.gz" "$SAVE_DIR"
echo "Backup completed: saves_$DATE.tar.gz"

# Keep only last 10 backups
ls -t "$BACKUP_DIR"/saves_*.tar.gz | tail -n +11 | xargs -r rm
```

## Support Resources

### Performance Benchmarks
- Expected: 30-60 FPS at 1080p
- Minimum: 24 FPS at 720p
- Network: <10ms LAN latency

### Community Resources
- Discord: [Battle Castles RPi Channel]
- Forum: [Raspberry Pi Gaming Section]
- Wiki: [RPi5 Optimization Guide]

### Reporting Issues
When reporting RPi5-specific issues, include:
- Raspberry Pi model and RAM
- OS version: `cat /etc/os-release`
- Temperature: `vcgencmd measure_temp`
- Throttling: `vcgencmd get_throttled`
- Game version: `battle-castles --version`

---

**Note:** This guide assumes Raspberry Pi 5 with 64-bit Raspberry Pi OS. Performance may vary based on cooling, power supply, and storage speed. The game is optimized for RPi5's Cortex-A76 CPU and VideoCore VII GPU architecture.