#!/bin/bash
#
# ZMK Build Helper Script
# Builds firmware and generates keymap visualizations using Docker
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="$HOME/.zmk-workspace"
IMAGE_NAME="zmk-eyelash-builder"
BOARD_NAME="eyelash_sofle"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Build Docker image if not exists
build_image() {
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        info "Building Docker image '$IMAGE_NAME'..."
        docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
        success "Docker image built successfully"
    else
        info "Docker image '$IMAGE_NAME' already exists"
    fi
}

# Initialize west workspace
init_workspace() {
    build_image

    if [ -d "$WORKSPACE_DIR/.west" ]; then
        warn "Workspace already initialized at $WORKSPACE_DIR"
        info "Run '$0 clean' first if you want to reinitialize"
        return 0
    fi

    info "Initializing west workspace at $WORKSPACE_DIR..."
    mkdir -p "$WORKSPACE_DIR"

    docker run --rm \
        -v "$PROJECT_DIR/config:/workspace/zmk-workspace/config:ro,z" \
        -v "$WORKSPACE_DIR:/workspace/zmk-workspace:z" \
        -w /workspace/zmk-workspace \
        "$IMAGE_NAME" \
        bash -c "
            west init -l config && \
            west update && \
            west zephyr-export
        "

    success "Workspace initialized at $WORKSPACE_DIR"
}

# Build firmware for a specific target
build_target() {
    local target="$1"
    local board=""
    local shield=""
    local extra_args=""
    local build_dir=""

    case "$target" in
        left)
            board="${BOARD_NAME}_left"
            shield="nice_view_adapter nice_epaper"
            build_dir="left"
            ;;
        right)
            board="${BOARD_NAME}_right"
            shield="nice_view_adapter nice_view_custom"
            build_dir="right"
            ;;
        studio)
            board="${BOARD_NAME}_left"
            shield="nice_view"
            extra_args="-DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -S studio-rpc-usb-uart"
            build_dir="studio_left"
            ;;
        *)
            error "Unknown target: $target (use: left, right, studio)"
            ;;
    esac

    build_image

    if [ ! -d "$WORKSPACE_DIR/.west" ]; then
        error "Workspace not initialized. Run '$0 init' first."
    fi

    info "Building $target firmware..."

    docker run --rm \
        -v "$PROJECT_DIR/config:/workspace/zmk-workspace/config:ro,z" \
        -v "$PROJECT_DIR/boards:/workspace/zmk-workspace/boards:ro,z" \
        -v "$WORKSPACE_DIR:/workspace/zmk-workspace:z" \
        -w /workspace/zmk-workspace \
        "$IMAGE_NAME" \
        bash -c "
            west build -s zmk/app -p -b $board -d build/$build_dir -- \
                -DZMK_CONFIG=/workspace/zmk-workspace/config \
                -DZMK_EXTRA_MODULES=/workspace/zmk-workspace/boards \
                -DSHIELD='$shield' \
                $extra_args
        "

    local uf2_path="$WORKSPACE_DIR/build/$build_dir/zephyr/zmk.uf2"
    if [ -f "$uf2_path" ]; then
        success "Firmware built: $uf2_path"
    else
        error "Build failed - firmware not found"
    fi
}

# Build all firmware targets
build_firmware() {
    build_target left
    build_target right
    echo ""
    info "All firmware built successfully!"
    echo "  Left:  $WORKSPACE_DIR/build/left/zephyr/zmk.uf2"
    echo "  Right: $WORKSPACE_DIR/build/right/zephyr/zmk.uf2"
}

# Generate keymap SVG
draw_keymap() {
    build_image

    local yaml_file="$PROJECT_DIR/keymap-drawer/eyelash_sofle.yaml"
    local svg_file="$PROJECT_DIR/keymap-drawer/eyelash_sofle.svg"

    if [ ! -f "$yaml_file" ]; then
        error "Keymap YAML not found: $yaml_file"
    fi

    info "Generating keymap SVG..."

    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$PROJECT_DIR/keymap-drawer:/workspace/keymap-drawer:z" \
        -w /workspace \
        "$IMAGE_NAME" \
        keymap draw /workspace/keymap-drawer/eyelash_sofle.yaml \
            -o /workspace/keymap-drawer/eyelash_sofle.svg

    if [ -f "$svg_file" ]; then
        success "Keymap SVG generated: $svg_file"
    else
        error "Failed to generate SVG"
    fi
}

# Clean build artifacts
clean_build() {
    if [ -d "$WORKSPACE_DIR/build" ]; then
        info "Cleaning build directory..."
        rm -rf "$WORKSPACE_DIR/build"
        success "Build directory cleaned"
    else
        info "Nothing to clean"
    fi
}

# Clean entire workspace
clean_all() {
    if [ -d "$WORKSPACE_DIR" ]; then
        warn "This will delete the entire workspace at $WORKSPACE_DIR"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$WORKSPACE_DIR"
            success "Workspace removed"
        else
            info "Cancelled"
        fi
    else
        info "Nothing to clean"
    fi
}

# Show help
show_help() {
    cat << EOF
ZMK Build Helper for Eyelash Sofle

Usage: $0 <command>

Commands:
  init        Initialize west workspace (downloads ~2GB of dependencies)
  firmware    Build both left and right firmware
  left        Build left half firmware only
  right       Build right half firmware only
  studio      Build studio-enabled left firmware
  draw        Generate keymap SVG visualization
  all         Build firmware + generate SVG
  clean       Remove build artifacts (keeps workspace)
  clean-all   Remove entire workspace (requires confirmation)
  help        Show this help message

Paths:
  Workspace:  $WORKSPACE_DIR
  Firmware:   $WORKSPACE_DIR/build/*/zephyr/zmk.uf2
  Keymap SVG: $PROJECT_DIR/keymap-drawer/eyelash_sofle.svg

Examples:
  $0 init              # First time setup
  $0 left              # Build left half
  $0 firmware          # Build both halves
  $0 draw              # Update keymap visualization
  $0 all               # Full build + visualization
EOF
}

# Main
case "${1:-help}" in
    init)
        init_workspace
        ;;
    firmware)
        build_firmware
        ;;
    left)
        build_target left
        ;;
    right)
        build_target right
        ;;
    studio)
        build_target studio
        ;;
    draw)
        draw_keymap
        ;;
    all)
        build_firmware
        echo ""
        draw_keymap
        ;;
    clean)
        clean_build
        ;;
    clean-all)
        clean_all
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        ;;
esac
