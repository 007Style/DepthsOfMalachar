#!/usr/bin/env bash
# =============================================================================
# setup_ios_export.sh — iOS Export Setup Guide for The Depths of Malachar
# Checks prerequisites and walks you through the iOS export setup.
# =============================================================================

set -euo pipefail

GODOT_VERSION="4.3"
GODOT_APP="$HOME/Applications/Godot/Godot.app"
GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/DepthsOfMalachar"
EXPORT_DIR="$SCRIPT_DIR/exports/ios"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

check() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $*"; }
fail()  { echo -e "  ${RED}✗${RESET} $*"; }
info()  { echo -e "  ${CYAN}▶${RESET} $*"; }

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Depths of Malachar — iOS Export Setup  ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

READY=true

# ---------------------------------------------------------------------------
# 1. Check macOS
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 1 — System Check${RESET}"
OS=$(sw_vers -productName)
VER=$(sw_vers -productVersion)
check "Running on $OS $VER"

# ---------------------------------------------------------------------------
# 2. Check Xcode
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Step 2 — Xcode${RESET}"
if command -v xcodebuild &>/dev/null; then
    XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1)
    check "$XCODE_VER"
    # Check Xcode command line tools
    if xcode-select -p &>/dev/null; then
        check "Xcode Command Line Tools: $(xcode-select -p)"
    else
        warn "Xcode Command Line Tools not installed."
        warn "Run: xcode-select --install"
        READY=false
    fi
else
    fail "Xcode not found."
    echo "       Install Xcode from: https://apps.apple.com/us/app/xcode/id497799835"
    READY=false
fi

# ---------------------------------------------------------------------------
# 3. Check Godot
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Step 3 — Godot ${GODOT_VERSION}${RESET}"
if [[ -f "$GODOT_BIN" ]]; then
    check "Godot found at: $GODOT_BIN"
else
    fail "Godot ${GODOT_VERSION} not found."
    echo "       Run: ./install_godot.sh"
    READY=false
fi

# ---------------------------------------------------------------------------
# 4. Check iOS Export Templates
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Step 4 — Godot iOS Export Templates${RESET}"
TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
if [[ -d "$TEMPLATE_DIR" ]]; then
    IOS_TEMPLATE=$(ls "$TEMPLATE_DIR"/ios* 2>/dev/null | head -1)
    if [[ -n "$IOS_TEMPLATE" ]]; then
        check "iOS export templates found at: $TEMPLATE_DIR"
    else
        warn "Export templates directory exists but iOS templates missing."
        READY=false
        echo ""
        echo "  To install iOS export templates:"
        echo "  1. Open Godot editor: ./launch.sh open"
        echo "  2. Go to Editor → Export Templates → Download"
        echo "  3. Download version ${GODOT_VERSION} stable"
    fi
else
    warn "Export templates not found at: $TEMPLATE_DIR"
    READY=false
    echo ""
    echo "  To install iOS export templates:"
    echo "  1. Open Godot: ./launch.sh open"
    echo "  2. Editor menu → Export Templates → Download and Install"
fi

# ---------------------------------------------------------------------------
# 5. Check Apple Developer account
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Step 5 — Apple Developer Account${RESET}"
if command -v security &>/dev/null; then
    CERTS=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "iPhone\|iOS" || true)
    if [[ "$CERTS" -gt 0 ]]; then
        check "$CERTS iOS signing certificate(s) found in Keychain"
    else
        warn "No iOS signing certificates found in Keychain."
        echo ""
        echo "  You need an Apple Developer account (\$99/year) to build for iOS:"
        echo "  https://developer.apple.com/programs/"
        echo ""
        echo "  Once enrolled:"
        echo "  1. Open Xcode → Preferences → Accounts → Add Apple ID"
        echo "  2. Download your certificates and provisioning profiles"
        READY=false
    fi
fi

# ---------------------------------------------------------------------------
# 6. Project export preset check
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Step 6 — Export Preset${RESET}"
EXPORT_PRESETS="$PROJECT_DIR/export_presets.cfg"
if [[ -f "$EXPORT_PRESETS" ]]; then
    if grep -q "iOS" "$EXPORT_PRESETS" 2>/dev/null; then
        check "iOS export preset found in export_presets.cfg"
    else
        warn "export_presets.cfg exists but no iOS preset found."
        READY=false
    fi
else
    warn "export_presets.cfg not found — you need to add an iOS preset in Godot editor."
    echo ""
    echo "  To add the iOS export preset:"
    echo "  1. Open Godot: ./launch.sh open"
    echo "  2. Project menu → Export → Add → iOS"
    echo "  3. Set Bundle Identifier (e.g. com.yourname.depthsofmalachar)"
    echo "  4. Set your Team ID from your Apple Developer account"
    READY=false
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────────────"
if $READY; then
    echo -e "${GREEN}${BOLD}✓ All prerequisites met! Ready to export.${RESET}"
    echo ""
    echo "  Run: ./launch.sh export-ios"
    echo ""
    echo "  This will generate an Xcode project at:"
    mkdir -p "$EXPORT_DIR"
    echo "    $EXPORT_DIR"
else
    echo -e "${YELLOW}${BOLD}⚠ Some prerequisites are missing (see above).${RESET}"
    echo ""
    echo "  Quick setup order:"
    echo "    1. Install Xcode from the App Store"
    echo "    2. Run: ./install_godot.sh"
    echo "    3. Open Godot and install iOS export templates"
    echo "    4. Enrol in Apple Developer Program"
    echo "    5. Add iOS export preset in Godot"
    echo "    6. Run this script again to verify"
fi
echo "────────────────────────────────────────────"
