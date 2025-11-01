#!/bin/bash

###############################################################################
# Battle Castles - Raspberry Pi 5 Packaging Script
# Creates .deb package and AppImage for Raspberry Pi 5
###############################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/builds/linux-arm64"
PACKAGE_DIR="$PROJECT_ROOT/builds/packages/rpi5"

# Get version from argument or default
VERSION=${1:-"1.0.0"}
PACKAGE_NAME="battlecastles"
MAINTAINER="Battle Castles Studio <support@battlecastles.com>"
DESCRIPTION="Strategic Castle Building Game - Optimized for Raspberry Pi 5"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Raspberry Pi 5 Package Builder                    ║${NC}"
echo -e "${BLUE}║   Version: $VERSION                                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if build exists
if [ ! -f "$BUILD_DIR/BattleCastles.arm64" ]; then
    log_error "ARM64 build not found at $BUILD_DIR/BattleCastles.arm64"
    log_info "Please run build_all_platforms.sh --rpi first"
    exit 1
fi

# Clean and create package directory
log_info "Creating package directory structure..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"/{deb,appimage}

###############################################################################
# Create .deb Package
###############################################################################

create_deb_package() {
    log_info "Creating .deb package for Raspberry Pi OS..."

    local DEB_DIR="$PACKAGE_DIR/deb/${PACKAGE_NAME}_${VERSION}_arm64"
    local INSTALL_DIR="$DEB_DIR/opt/battlecastles"
    local DESKTOP_DIR="$DEB_DIR/usr/share/applications"
    local ICON_DIR="$DEB_DIR/usr/share/icons/hicolor/256x256/apps"
    local BIN_DIR="$DEB_DIR/usr/bin"

    # Create directory structure
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$ICON_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$DEB_DIR/DEBIAN"

    # Copy game files
    cp "$BUILD_DIR/BattleCastles.arm64" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/BattleCastles.arm64"

    # Copy assets if they exist
    if [ -f "$BUILD_DIR/BattleCastles.pck" ]; then
        cp "$BUILD_DIR/BattleCastles.pck" "$INSTALL_DIR/"
    fi

    # Create launcher script
    cat > "$BIN_DIR/battlecastles" << 'EOF'
#!/bin/bash
cd /opt/battlecastles
exec ./BattleCastles.arm64 "$@"
EOF
    chmod +x "$BIN_DIR/battlecastles"

    # Create desktop entry
    cat > "$DESKTOP_DIR/battlecastles.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Battle Castles
Comment=Strategic Castle Building Game - Optimized for Raspberry Pi 5
Exec=/usr/bin/battlecastles
Icon=battlecastles
Terminal=false
Type=Application
Categories=Game;StrategyGame;
StartupNotify=false
Keywords=game;strategy;castle;multiplayer;
EOF

    # Create icon (placeholder - replace with actual icon)
    # For now, create a simple text file as placeholder
    echo "ICON_PLACEHOLDER" > "$ICON_DIR/battlecastles.png"

    # Create control file
    cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: games
Priority: optional
Architecture: arm64
Depends: libc6 (>= 2.31), libgl1, libx11-6, libxcursor1, libxi6, libxinerama1, libxrandr2
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 Battle Castles is a strategic castle building game featuring:
  - Real-time multiplayer combat
  - Complex castle building mechanics
  - Resource management
  - Optimized performance for Raspberry Pi 5
  - Achieves 30+ FPS at 1080p on Raspberry Pi 5
Homepage: https://battlecastles.com
EOF

    # Create postinst script
    cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications || true
fi

echo "Battle Castles has been installed successfully!"
echo "Launch from the application menu or run: battlecastles"
echo ""
echo "Raspberry Pi 5 Optimizations Enabled:"
echo "  - 30 FPS target for optimal performance"
echo "  - Reduced quality settings for smooth gameplay"
echo "  - Memory optimizations"
echo ""

exit 0
EOF
    chmod +x "$DEB_DIR/DEBIAN/postinst"

    # Create postrm script
    cat > "$DEB_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e

if [ "$1" = "purge" ]; then
    rm -rf /opt/battlecastles
fi

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications || true
fi

exit 0
EOF
    chmod +x "$DEB_DIR/DEBIAN/postrm"

    # Build .deb package
    log_info "Building .deb package..."
    dpkg-deb --build "$DEB_DIR"

    # Move to final location
    mv "$DEB_DIR.deb" "$PACKAGE_DIR/${PACKAGE_NAME}_${VERSION}_arm64.deb"

    # Clean up
    rm -rf "$DEB_DIR"

    log_success ".deb package created: ${PACKAGE_NAME}_${VERSION}_arm64.deb"
}

###############################################################################
# Create AppImage
###############################################################################

create_appimage() {
    log_info "Creating AppImage for Raspberry Pi 5..."

    local APPDIR="$PACKAGE_DIR/appimage/BattleCastles.AppDir"

    # Create AppDir structure
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

    # Copy game files
    cp "$BUILD_DIR/BattleCastles.arm64" "$APPDIR/usr/bin/battlecastles"
    chmod +x "$APPDIR/usr/bin/battlecastles"

    if [ -f "$BUILD_DIR/BattleCastles.pck" ]; then
        cp "$BUILD_DIR/BattleCastles.pck" "$APPDIR/usr/bin/"
    fi

    # Create desktop entry
    cat > "$APPDIR/battlecastles.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Battle Castles
Comment=Strategic Castle Building Game
Exec=battlecastles
Icon=battlecastles
Terminal=false
Type=Application
Categories=Game;StrategyGame;
EOF

    cp "$APPDIR/battlecastles.desktop" "$APPDIR/usr/share/applications/"

    # Create AppRun script
    cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec ./battlecastles "$@"
EOF
    chmod +x "$APPDIR/AppRun"

    # Create icon (placeholder)
    echo "ICON_PLACEHOLDER" > "$APPDIR/battlecastles.png"
    cp "$APPDIR/battlecastles.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"

    # Try to download appimagetool for ARM64
    log_info "Attempting to create AppImage..."

    if command -v appimagetool &> /dev/null; then
        cd "$PACKAGE_DIR/appimage"
        ARCH=aarch64 appimagetool "$APPDIR" "BattleCastles-${VERSION}-aarch64.AppImage"
        log_success "AppImage created: BattleCastles-${VERSION}-aarch64.AppImage"
    else
        log_warning "appimagetool not found. AppImage not created."
        log_info "To create AppImage manually, install appimagetool and run:"
        log_info "  ARCH=aarch64 appimagetool $APPDIR BattleCastles-${VERSION}-aarch64.AppImage"
    fi
}

###############################################################################
# Create Installation Script
###############################################################################

create_install_script() {
    log_info "Creating installation script..."

    cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash

###############################################################################
# Battle Castles - Raspberry Pi 5 Installation Script
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Battle Castles - Raspberry Pi 5 Installer${NC}"
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a Raspberry Pi${NC}"
    echo "Continue anyway? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        exit 0
    fi
fi

# Check for .deb file
DEB_FILE=$(ls battlecastles_*.deb 2>/dev/null | head -n1)

if [ -z "$DEB_FILE" ]; then
    echo "Error: No .deb package found"
    exit 1
fi

echo "Installing $DEB_FILE..."
sudo dpkg -i "$DEB_FILE"

# Install dependencies if needed
echo "Checking dependencies..."
sudo apt-get update
sudo apt-get install -f -y

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "To launch Battle Castles:"
echo "  1. From the application menu: Games > Battle Castles"
echo "  2. From terminal: battlecastles"
echo ""
echo "Raspberry Pi 5 Performance Tips:"
echo "  - Close other applications for best performance"
echo "  - Use 1080p resolution for optimal balance"
echo "  - Game is optimized for 30 FPS on Raspberry Pi 5"
echo "  - Consider overclocking for even better performance"
echo ""
EOF

    chmod +x "$PACKAGE_DIR/install.sh"
    log_success "Installation script created"
}

###############################################################################
# Create README
###############################################################################

create_readme() {
    log_info "Creating README..."

    cat > "$PACKAGE_DIR/README.txt" << EOF
Battle Castles - Raspberry Pi 5 Edition
Version $VERSION

═══════════════════════════════════════════════════════════════

INSTALLATION
────────────────────────────────────────────────────────────────

Option 1: Using the .deb package (Recommended)
  1. Run: sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_arm64.deb
  2. Install dependencies: sudo apt-get install -f -y
  3. Launch from the application menu or run: battlecastles

Option 2: Using the installation script
  1. Run: bash install.sh
  2. Follow the prompts

Option 3: Manual installation
  1. Extract: tar -xzf BattleCastles-RaspberryPi5-$VERSION.tar.gz
  2. Run: ./BattleCastles.arm64

═══════════════════════════════════════════════════════════════

SYSTEM REQUIREMENTS
────────────────────────────────────────────────────────────────

Minimum:
  - Raspberry Pi 5 (4GB RAM)
  - Raspberry Pi OS (64-bit)
  - 500MB free storage
  - OpenGL ES 3.0 support

Recommended:
  - Raspberry Pi 5 (8GB RAM)
  - Updated Raspberry Pi OS
  - 1GB free storage
  - Active cooling

═══════════════════════════════════════════════════════════════

PERFORMANCE OPTIMIZATION
────────────────────────────────────────────────────────────────

The Raspberry Pi 5 edition is specially optimized for:
  ✓ 30+ FPS at 1080p resolution
  ✓ Reduced particle effects
  ✓ Optimized texture streaming
  ✓ Lower shadow quality
  ✓ Memory-efficient rendering

For best performance:
  1. Close unnecessary applications
  2. Ensure proper cooling (heatsink/fan recommended)
  3. Use the latest Raspberry Pi OS updates
  4. Consider overclocking (see overclocking guide below)

═══════════════════════════════════════════════════════════════

OVERCLOCKING (Optional)
────────────────────────────────────────────────────────────────

For better performance, you can overclock your Raspberry Pi 5.

WARNING: Overclocking may void warranty and requires good cooling!

Edit /boot/config.txt and add:
  over_voltage=6
  arm_freq=2400

Then reboot: sudo reboot

═══════════════════════════════════════════════════════════════

TROUBLESHOOTING
────────────────────────────────────────────────────────────────

Low FPS:
  - Close background applications
  - Enable fullscreen mode
  - Ensure active cooling is working
  - Lower in-game graphics settings

Game won't start:
  - Check dependencies: sudo apt-get install -f
  - Verify OpenGL: glxinfo | grep "OpenGL version"
  - Check logs: ~/.local/share/battlecastles/logs/

Graphics glitches:
  - Update GPU drivers: sudo apt update && sudo apt upgrade
  - Try different resolution

═══════════════════════════════════════════════════════════════

SUPPORT
────────────────────────────────────────────────────────────────

Website: https://battlecastles.com
Documentation: https://docs.battlecastles.com
Support: support@battlecastles.com
Community: https://discord.gg/battlecastles

═══════════════════════════════════════════════════════════════

LICENSE

Copyright (c) 2025 Battle Castles Studio
All rights reserved.

═══════════════════════════════════════════════════════════════
EOF

    log_success "README created"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    create_deb_package
    create_appimage
    create_install_script
    create_readme

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Raspberry Pi 5 Packaging Complete                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Packages created in: $PACKAGE_DIR"
    echo ""
    echo "Files created:"
    echo "  - ${PACKAGE_NAME}_${VERSION}_arm64.deb (Debian package)"
    echo "  - install.sh (Installation script)"
    echo "  - README.txt (Documentation)"
    if [ -f "$PACKAGE_DIR/appimage/BattleCastles-${VERSION}-aarch64.AppImage" ]; then
        echo "  - BattleCastles-${VERSION}-aarch64.AppImage"
    fi
    echo ""
}

main