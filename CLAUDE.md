# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ZMK firmware configuration for a custom "Eyelash" Sofle-style split keyboard with Nice!Nano v2 controllers and Nice!View e-paper displays. Uses urob's zmk-helpers for keymap macros and Timeless HRM (Home Row Mods).

## Build System

This repository uses **GitHub Actions CI** exclusively - there are no local build scripts. Firmware is built automatically on push to main (except for keymap-drawer changes).

**Build targets** (defined in `build.yaml`):
- `eyelash_sofle_left` - Left half with nice_view_adapter + nice_epaper shields
- `eyelash_sofle_right` - Right half with nice_view_adapter + nice_view_custom shields
- `eyelash_sofle_studio_left` - Left half with ZMK Studio support (USB debugging)

**Keymap visualization** auto-generates SVG on config changes via the draw.yml workflow using keymap-drawer.

## Architecture

### Key Configuration Files

| File | Purpose |
|------|---------|
| `config/eyelash_sofle.keymap` | Main keymap with layers, behaviors, combos, tap-dances |
| `config/eyelash_sofle.conf` | Feature flags (RGB, sleep, encoder, mouse, displays) |
| `config/mouse.dtsi` | Mouse/pointing device configuration with per-layer acceleration |
| `config/west.yml` | West manifest defining ZMK and external module dependencies |
| `boards/arm/eyelash_sofle/eyelash_sofle.dtsi` | Hardware definition (GPIO matrix, encoder, LEDs, display) |
| `boards/arm/eyelash_sofle/eyelash_sofle_left.dts` | Left half device tree (encoder enabled) |
| `boards/arm/eyelash_sofle/eyelash_sofle_right.dts` | Right half device tree (col-offset for split, hat switch) |

### Layer Structure

- **BASE (0)**: QWERTY with tap-dance numbers (1→!, 2→@, etc.) and home row mods
- **CODE (1)**: Symbols, brackets, navigation arrows, mouse movement
- **FN (2)**: Function keys F1-F12, page navigation, precision mouse
- **SYS (3)**: Bluetooth device selection, RGB controls, output switching

### Keymap Patterns

The keymap uses urob's zmk-helpers macros (in `config/zmk-helpers/`):
- `ZMK_BEHAVIOR()` - Custom behaviors
- `ZMK_LAYER()` - Layer definitions with display names
- `ZMK_COMBO()` - Multi-key combinations
- `ZMK_HOLD_TAP()` - Hold-tap behaviors
- `MAKE_HRM()` - Timeless Home Row Mod template

Key position labels for combos are defined in `config/zmk-helpers/key-labels/sofle_eyelash_3c.h`.

### Hardware Features

- 63-key matrix (split with center encoder/joystick)
- EC11 rotary encoder (left half) - volume/mute
- 5-way hat switch (right half) - navigation
- WS2812 RGB underglow (6-7 LEDs per half)
- Per-key PWM backlight
- Dual Nice!View e-paper displays with custom animations

### External Dependencies (config/west.yml)

- `zmkfirmware/zmk` - Core ZMK firmware
- `Arawasu/hammerbeam-slideshow` - Right display animation
- `Arawasu/zmk-nice-oled` - Left display Luna animation
