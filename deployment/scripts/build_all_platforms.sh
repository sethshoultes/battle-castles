#!/bin/bash

###############################################################################
# Battle Castles - Multi-Platform Build Script
# Builds the game for Windows, macOS, Linux x64, and Raspberry Pi 5
###############################################################################

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILDS_DIR="$PROJECT_ROOT/builds"
VERSION_FILE="$PROJECT_ROOT/VERSION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version management
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE")
else
    VERSION="1.0.0"
    echo "$VERSION" > "$VERSION_FILE"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Battle Castles - Multi-Platform Build System      ║${NC}"
echo -e "${BLUE}║   Version: $VERSION                                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse command line arguments
BUILD_WINDOWS=false
BUILD_MAC=false
BUILD_LINUX=false
BUILD_RPI=false
BUILD_ALL=false
SKIP_TESTS=false
CLEAN_BUILD=false
CODE_SIGN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --windows)
            BUILD_WINDOWS=true
            shift
            ;;
        --mac)
            BUILD_MAC=true
            shift
            ;;
        --linux)
            BUILD_LINUX=true
            shift
            ;;
        --rpi)
            BUILD_RPI=true
            shift
            ;;
        --all)
            BUILD_ALL=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --sign)
            CODE_SIGN=true
            shift
            ;;
        --version)
            VERSION=$2
            echo "$VERSION" > "$VERSION_FILE"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --windows      Build for Windows"
            echo "  --mac          Build for macOS"
            echo "  --linux        Build for Linux x64"
            echo "  --rpi          Build for Raspberry Pi 5 (ARM64)"
            echo "  --all          Build for all platforms"
            echo "  --skip-tests   Skip running tests"
            echo "  --clean        Clean build directories before building"
            echo "  --sign         Enable code signing (requires certificates)"
            echo "  --version VER  Set version number (e.g., 1.0.1)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# If no specific platform selected, build all
if [ "$BUILD_ALL" = true ] || ([ "$BUILD_WINDOWS" = false ] && [ "$BUILD_MAC" = false ] && [ "$BUILD_LINUX" = false ] && [ "$BUILD_RPI" = false ]); then
    BUILD_WINDOWS=true
    BUILD_MAC=true
    BUILD_LINUX=true
    BUILD_RPI=true
fi

# Functions
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

check_godot() {
    if ! command -v godot &> /dev/null; then
        log_error "Godot executable not found in PATH"
        log_info "Please install Godot and add it to your PATH"
        log_info "Download from: https://godotengine.org/download"
        exit 1
    fi

    GODOT_VERSION=$(godot --version)
    log_success "Found Godot: $GODOT_VERSION"
}

clean_builds() {
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "Cleaning build directories..."
        rm -rf "$BUILDS_DIR"
        log_success "Build directories cleaned"
    fi
}

create_build_dirs() {
    log_info "Creating build directories..."
    mkdir -p "$BUILDS_DIR"/{windows,mac,linux,linux-arm64}
    log_success "Build directories created"
}

run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Skipping tests (--skip-tests flag set)"
        return 0
    fi

    log_info "Running tests..."
    cd "$PROJECT_ROOT/client"

    if godot --no-window --script res://tests/run_tests.gd; then
        log_success "All tests passed"
    else
        log_error "Tests failed. Use --skip-tests to bypass."
        exit 1
    fi
}

build_windows() {
    log_info "Building for Windows (x64)..."

    cd "$PROJECT_ROOT/client"
    godot --export "Windows Desktop" "$BUILDS_DIR/windows/BattleCastles.exe" --no-window

    if [ $? -eq 0 ]; then
        log_success "Windows build completed: $BUILDS_DIR/windows/BattleCastles.exe"

        # Create ZIP archive
        cd "$BUILDS_DIR/windows"
        zip -r "BattleCastles-Windows-$VERSION.zip" ./*
        log_success "Windows ZIP created: BattleCastles-Windows-$VERSION.zip"

        if [ "$CODE_SIGN" = true ]; then
            log_warning "Code signing for Windows not implemented"
            log_info "Please use SignTool.exe manually"
        fi
    else
        log_error "Windows build failed"
        return 1
    fi
}

build_mac() {
    log_info "Building for macOS (Universal Binary)..."

    cd "$PROJECT_ROOT/client"
    godot --export "Mac OSX" "$BUILDS_DIR/mac/BattleCastles.zip" --no-window

    if [ $? -eq 0 ]; then
        log_success "macOS build completed: $BUILDS_DIR/mac/BattleCastles.zip"

        # Unzip and prepare .app bundle
        cd "$BUILDS_DIR/mac"
        unzip -q BattleCastles.zip

        if [ "$CODE_SIGN" = true ]; then
            log_warning "Code signing for macOS not implemented"
            log_info "Use: codesign --force --deep --sign 'Developer ID Application: Your Name' BattleCastles.app"
            log_info "Use: xcrun notarytool submit BattleCastles.zip --apple-id your@email.com --wait"
        fi

        # Create DMG (requires macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "Creating DMG installer..."
            hdiutil create -volname "Battle Castles" -srcfolder BattleCastles.app -ov -format UDZO "BattleCastles-macOS-$VERSION.dmg"
            log_success "macOS DMG created: BattleCastles-macOS-$VERSION.dmg"
        else
            log_warning "Skipping DMG creation (requires macOS)"
        fi
    else
        log_error "macOS build failed"
        return 1
    fi
}

build_linux() {
    log_info "Building for Linux (x64)..."

    cd "$PROJECT_ROOT/client"
    godot --export "Linux/X11" "$BUILDS_DIR/linux/BattleCastles.x86_64" --no-window

    if [ $? -eq 0 ]; then
        chmod +x "$BUILDS_DIR/linux/BattleCastles.x86_64"
        log_success "Linux build completed: $BUILDS_DIR/linux/BattleCastles.x86_64"

        # Create tar.gz archive
        cd "$BUILDS_DIR/linux"
        tar -czf "BattleCastles-Linux-x64-$VERSION.tar.gz" ./*
        log_success "Linux archive created: BattleCastles-Linux-x64-$VERSION.tar.gz"

        # Create .desktop file
        cat > BattleCastles.desktop << EOF
[Desktop Entry]
Name=Battle Castles
Comment=Strategic Castle Building Game
Exec=BattleCastles.x86_64
Icon=battlecastles
Terminal=false
Type=Application
Categories=Game;StrategyGame;
EOF
        log_success "Desktop entry file created"
    else
        log_error "Linux build failed"
        return 1
    fi
}

build_raspberry_pi() {
    log_info "Building for Raspberry Pi 5 (ARM64)..."

    cd "$PROJECT_ROOT/client"
    godot --export "Linux ARM64 (Raspberry Pi 5)" "$BUILDS_DIR/linux-arm64/BattleCastles.arm64" --no-window

    if [ $? -eq 0 ]; then
        chmod +x "$BUILDS_DIR/linux-arm64/BattleCastles.arm64"
        log_success "Raspberry Pi build completed: $BUILDS_DIR/linux-arm64/BattleCastles.arm64"

        # Run packaging script
        if [ -f "$SCRIPT_DIR/package_rpi5.sh" ]; then
            log_info "Running Raspberry Pi packaging script..."
            bash "$SCRIPT_DIR/package_rpi5.sh" "$VERSION"
        else
            log_warning "Raspberry Pi packaging script not found"
        fi

        # Create tar.gz archive
        cd "$BUILDS_DIR/linux-arm64"
        tar -czf "BattleCastles-RaspberryPi5-$VERSION.tar.gz" ./*
        log_success "Raspberry Pi archive created: BattleCastles-RaspberryPi5-$VERSION.tar.gz"
    else
        log_error "Raspberry Pi build failed"
        return 1
    fi
}

verify_builds() {
    log_info "Verifying builds..."

    local all_good=true

    if [ "$BUILD_WINDOWS" = true ]; then
        if [ -f "$BUILDS_DIR/windows/BattleCastles.exe" ]; then
            log_success "Windows build verified"
        else
            log_error "Windows build missing"
            all_good=false
        fi
    fi

    if [ "$BUILD_MAC" = true ]; then
        if [ -f "$BUILDS_DIR/mac/BattleCastles.zip" ]; then
            log_success "macOS build verified"
        else
            log_error "macOS build missing"
            all_good=false
        fi
    fi

    if [ "$BUILD_LINUX" = true ]; then
        if [ -f "$BUILDS_DIR/linux/BattleCastles.x86_64" ]; then
            log_success "Linux build verified"
        else
            log_error "Linux build missing"
            all_good=false
        fi
    fi

    if [ "$BUILD_RPI" = true ]; then
        if [ -f "$BUILDS_DIR/linux-arm64/BattleCastles.arm64" ]; then
            log_success "Raspberry Pi build verified"
        else
            log_error "Raspberry Pi build missing"
            all_good=false
        fi
    fi

    if [ "$all_good" = true ]; then
        log_success "All builds verified successfully"
        return 0
    else
        log_error "Some builds are missing"
        return 1
    fi
}

create_build_manifest() {
    log_info "Creating build manifest..."

    cat > "$BUILDS_DIR/BUILD_MANIFEST.txt" << EOF
Battle Castles - Build Manifest
Version: $VERSION
Build Date: $(date)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
Git Branch: $(git branch --show-current 2>/dev/null || echo "N/A")

Builds:
EOF

    if [ "$BUILD_WINDOWS" = true ]; then
        echo "  - Windows x64: builds/windows/BattleCastles.exe" >> "$BUILDS_DIR/BUILD_MANIFEST.txt"
    fi

    if [ "$BUILD_MAC" = true ]; then
        echo "  - macOS Universal: builds/mac/BattleCastles.app" >> "$BUILDS_DIR/BUILD_MANIFEST.txt"
    fi

    if [ "$BUILD_LINUX" = true ]; then
        echo "  - Linux x64: builds/linux/BattleCastles.x86_64" >> "$BUILDS_DIR/BUILD_MANIFEST.txt"
    fi

    if [ "$BUILD_RPI" = true ]; then
        echo "  - Raspberry Pi 5 ARM64: builds/linux-arm64/BattleCastles.arm64" >> "$BUILDS_DIR/BUILD_MANIFEST.txt"
    fi

    log_success "Build manifest created: $BUILDS_DIR/BUILD_MANIFEST.txt"
}

# Main execution
main() {
    log_info "Starting build process..."

    check_godot
    clean_builds
    create_build_dirs
    run_tests

    # Build platforms
    if [ "$BUILD_WINDOWS" = true ]; then
        build_windows
    fi

    if [ "$BUILD_MAC" = true ]; then
        build_mac
    fi

    if [ "$BUILD_LINUX" = true ]; then
        build_linux
    fi

    if [ "$BUILD_RPI" = true ]; then
        build_raspberry_pi
    fi

    # Verification
    verify_builds
    create_build_manifest

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Build Process Completed Successfully       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Builds located in: $BUILDS_DIR"
    log_info "Version: $VERSION"
}

# Run main function
main