# ZMK Build Environment with keymap-drawer support
# Based on the official ZMK development image

FROM zmkfirmware/zmk-dev-arm:stable

LABEL maintainer="apug"
LABEL description="ZMK firmware build environment with keymap-drawer for visualization"

# Install keymap-drawer for SVG generation
# Using --break-system-packages is safe in isolated Docker containers
RUN pip3 install --no-cache-dir --break-system-packages keymap-drawer

# Set working directory
WORKDIR /workspace

# Default command shows help
CMD ["echo", "Use build.sh to run builds. See docker/README.md for usage."]
