# Docker Build Environment

Build ZMK firmware and generate keymap visualizations without local dependencies.

## Prerequisites

- Docker installed and running
- ~2GB disk space for the ZMK workspace

## Quick Start

```bash
# First time setup (downloads ZMK dependencies)
./docker/build.sh init

# Build firmware for both halves
./docker/build.sh firmware

# Generate keymap visualization
./docker/build.sh draw
```

## Commands

| Command | Description |
|---------|-------------|
| `init` | Initialize west workspace (~2GB download) |
| `firmware` | Build left and right firmware |
| `left` | Build left half only |
| `right` | Build right half only |
| `studio` | Build studio-enabled left (USB debugging) |
| `draw` | Generate keymap SVG |
| `all` | Build everything |
| `clean` | Remove build artifacts |
| `clean-all` | Remove entire workspace |

## Output Locations

- **Firmware**: `~/.zmk-workspace/build/*/zephyr/zmk.uf2`
- **Keymap SVG**: `keymap-drawer/eyelash_sofle.svg`

## Flashing Firmware

1. Put the keyboard half in bootloader mode (double-tap reset)
2. Copy the appropriate `.uf2` file to the mounted drive:
   ```bash
   cp ~/.zmk-workspace/build/left/zephyr/zmk.uf2 /media/NICENANO/
   cp ~/.zmk-workspace/build/right/zephyr/zmk.uf2 /media/NICENANO/
   ```

## Troubleshooting

### "Workspace not initialized"
Run `./docker/build.sh init` first.

### Build errors after keymap changes
Run `./docker/build.sh clean` then rebuild.

### Need fresh workspace
Run `./docker/build.sh clean-all` then `./docker/build.sh init`.
