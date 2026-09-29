#!/usr/bin/env bash
# =============================================================================
# install_godot.sh — Standalone Godot installer for The Depths of Malachar
# Downloads Godot 4, installs it, and opens the project automatically.
# =============================================================================

set -euo pipefail

GODOT_VERSION="4.3"
GODOT_APP_NAME="Godot_v${GODOT_VERSION}-stable_macos.universal"
GODOT_DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${GODOT_APP_NAME}.zip"
INSTALL_DIR="$HOME/Applications/Godot"
GODOT_APP="$INSTALL_DIR/Godot.app"
GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$SCRIPT_DIR/DepthsOfMalachar/project.godot"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Depths of Malachar — Godot Installer   ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# Already installed?
if [[ -f "$GODOT_BIN" ]]; then
    echo -e "${GREEN}✓ Godot ${GODOT_VERSION} is already installed at:${RESET}"
    echo "    $GODOT_BIN"
    echo ""
    read -rp "Open the project now? [Y/n] " ans
    if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
        open -a "$GODOT_APP" "$PROJECT_FILE"
    fi
    exit 0
fi

echo -e "${CYAN}▶ Installing Godot ${GODOT_VERSION} for macOS...${RESET}"
echo ""

# Create install dir
mkdir -p "$INSTALL_DIR"

# Download
ZIP_PATH="/tmp/${GODOT_APP_NAME}.zip"
echo -e "${CYAN}▶ Downloading from GitHub Releases...${RESET}"
echo "  $GODOT_DOWNLOAD_URL"
echo ""

if ! curl -L --progress-bar -o "$ZIP_PATH" "$GODOT_DOWNLOAD_URL"; then
    echo -e "${RED}✗ Download failed.${RESET}"
    echo ""
    echo "Manual download option:"
    echo "  1. Go to https://godotengine.org/download/macos/"
    echo "  2. Download Godot ${GODOT_VERSION} (Standard, macOS Universal)"
    echo "  3. Move Godot.app to ~/Applications/Godot/"
    exit 1
fi

# Extract
echo ""
echo -e "${CYAN}▶ Extracting...${RESET}"
unzip -q -o "$ZIP_PATH" -d "$INSTALL_DIR"
rm "$ZIP_PATH"

# Verify
if [[ ! -f "$GODOT_BIN" ]]; then
    # Try to find it
    FOUND=$(find "$INSTALL_DIR" -name "Godot" -type f 2>/dev/null | head -1)
    if [[ -n "$FOUND" ]]; then
        GODOT_BIN="$FOUND"
    else
        echo -e "${RED}✗ Could not find Godot binary after extraction.${RESET}"
        echo "  Check: $INSTALL_DIR"
        exit 1
    fi
fi

chmod +x "$GODOT_BIN"

# Remove quarantine (macOS security)
echo -e "${CYAN}▶ Removing macOS quarantine flag...${RESET}"
xattr -rd com.apple.quarantine "$GODOT_APP" 2>/dev/null && \
    echo -e "${GREEN}✓ Quarantine removed.${RESET}" || \
    echo -e "${YELLOW}⚠ Could not remove quarantine — you may see a security warning on first launch.${RESET}"

echo ""
echo -e "${GREEN}✓ Godot ${GODOT_VERSION} installed successfully!${RESET}"
echo "  Location: $GODOT_BIN"
echo ""

# Open project?
read -rp "Open The Depths of Malachar project now? [Y/n] " ans
if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}▶ Opening project in Godot editor...${RESET}"
    open -a "$GODOT_APP" "$PROJECT_FILE"
    echo -e "${GREEN}✓ Done! Godot should open with your project shortly.${RESET}"
fi
