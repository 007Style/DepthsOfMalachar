#!/usr/bin/env bash
# =============================================================================
# launch.sh — Master launcher for The Depths of Malachar
# =============================================================================
# Usage:
#   ./launch.sh              — show interactive menu
#   ./launch.sh install      — download & install Godot 4
#   ./launch.sh open         — open project in Godot editor
#   ./launch.sh run          — run game directly (no editor)
#   ./launch.sh export-ios   — export to iOS Xcode project
#   ./launch.sh export-mac   — export to macOS app
#   ./launch.sh validate     — run code & asset validation checks
#   ./launch.sh clean        — remove build artifacts
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/DepthsOfMalachar"
PROJECT_FILE="$PROJECT_DIR/project.godot"
GODOT_VERSION="4.3"
GODOT_APP_NAME="Godot_v${GODOT_VERSION}-stable_macos.universal"
GODOT_DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${GODOT_APP_NAME}.zip"
GODOT_INSTALL_DIR="$HOME/Applications/Godot"
GODOT_APP="$GODOT_INSTALL_DIR/Godot.app"
GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
EXPORT_DIR="$SCRIPT_DIR/exports"

# Colour helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}▶ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✗ $*${RESET}"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}\n"; }

# ---------------------------------------------------------------------------
# Check Godot is installed
# ---------------------------------------------------------------------------
require_godot() {
    if [[ ! -f "$GODOT_BIN" ]]; then
        warn "Godot ${GODOT_VERSION} not found at: $GODOT_BIN"
        echo -e "Run ${YELLOW}./launch.sh install${RESET} to download and install it."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# COMMAND: install
# ---------------------------------------------------------------------------
cmd_install() {
    header "Installing Godot ${GODOT_VERSION}"

    if [[ -f "$GODOT_BIN" ]]; then
        success "Godot ${GODOT_VERSION} is already installed at $GODOT_BIN"
        return
    fi

    info "Creating install directory: $GODOT_INSTALL_DIR"
    mkdir -p "$GODOT_INSTALL_DIR"

    local zip_path="/tmp/${GODOT_APP_NAME}.zip"
    info "Downloading Godot ${GODOT_VERSION} for macOS..."
    info "URL: $GODOT_DOWNLOAD_URL"

    if ! curl -L --progress-bar -o "$zip_path" "$GODOT_DOWNLOAD_URL"; then
        error "Download failed. Check your internet connection or try manually:\n  $GODOT_DOWNLOAD_URL"
    fi

    info "Extracting to $GODOT_INSTALL_DIR ..."
    unzip -q -o "$zip_path" -d "$GODOT_INSTALL_DIR"
    rm "$zip_path"

    # The zip contains Godot.app directly
    if [[ ! -f "$GODOT_BIN" ]]; then
        # Some releases name the binary differently — find it
        local found
        found=$(find "$GODOT_INSTALL_DIR" -name "Godot" -type f 2>/dev/null | head -1)
        if [[ -z "$found" ]]; then
            error "Could not find Godot binary after extraction. Check $GODOT_INSTALL_DIR"
        fi
        GODOT_BIN="$found"
        success "Found Godot binary at: $GODOT_BIN"
    fi

    chmod +x "$GODOT_BIN"

    # Remove macOS quarantine attribute so it opens without a security warning
    info "Removing quarantine attribute (may require password)..."
    xattr -rd com.apple.quarantine "$GODOT_APP" 2>/dev/null || true

    success "Godot ${GODOT_VERSION} installed successfully!"
    echo -e "  Binary: ${BOLD}$GODOT_BIN${RESET}"
    echo -e "  Run ${YELLOW}./launch.sh open${RESET} to open your project."
}

# ---------------------------------------------------------------------------
# COMMAND: open
# ---------------------------------------------------------------------------
cmd_open() {
    header "Opening Project in Godot Editor"
    require_godot

    if [[ ! -f "$PROJECT_FILE" ]]; then
        error "project.godot not found at: $PROJECT_FILE"
    fi

    info "Launching Godot editor..."
    info "Project: $PROJECT_FILE"
    open -a "$GODOT_APP" "$PROJECT_FILE"
    success "Godot opened. The project should appear in the editor."
}

# ---------------------------------------------------------------------------
# COMMAND: run
# ---------------------------------------------------------------------------
cmd_run() {
    header "Running Game (Headless Launch)"
    require_godot

    info "Starting game from: $PROJECT_DIR"
    "$GODOT_BIN" --path "$PROJECT_DIR" 2>&1 &
    success "Game launched (PID $!)"
}

# ---------------------------------------------------------------------------
# COMMAND: export-ios
# ---------------------------------------------------------------------------
cmd_export_ios() {
    header "Exporting to iOS"
    require_godot

    # Check Xcode
    if ! command -v xcodebuild &>/dev/null; then
        error "Xcode not found. Install Xcode from the Mac App Store first."
    fi
    local xcode_ver
    xcode_ver=$(xcodebuild -version 2>/dev/null | head -1)
    info "Xcode: $xcode_ver"

    mkdir -p "$EXPORT_DIR/ios"

    info "Exporting iOS project (requires iOS export templates installed in Godot)..."
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" \
        --export-release "iOS" "$EXPORT_DIR/ios/DepthsOfMalachar.xcodeproj" 2>&1 | tail -20

    if [[ -d "$EXPORT_DIR/ios" ]]; then
        success "iOS Xcode project exported to: $EXPORT_DIR/ios/"
        echo ""
        echo -e "${BOLD}Next steps:${RESET}"
        echo "  1. Open $EXPORT_DIR/ios/*.xcodeproj in Xcode"
        echo "  2. Set your Apple Developer Team ID in Signing & Capabilities"
        echo "  3. Connect your iPhone and click Run, or archive for App Store"
    else
        warn "Export may have failed. Check for errors above."
    fi
}

# ---------------------------------------------------------------------------
# COMMAND: export-mac
# ---------------------------------------------------------------------------
cmd_export_mac() {
    header "Exporting to macOS"
    require_godot

    mkdir -p "$EXPORT_DIR/mac"

    info "Exporting macOS app..."
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" \
        --export-release "macOS" "$EXPORT_DIR/mac/DepthsOfMalachar.dmg" 2>&1 | tail -20

    if [[ -f "$EXPORT_DIR/mac/DepthsOfMalachar.dmg" ]]; then
        success "macOS export complete: $EXPORT_DIR/mac/DepthsOfMalachar.dmg"
    else
        warn "Export may have failed. Check output above."
    fi
}

# ---------------------------------------------------------------------------
# COMMAND: validate
# ---------------------------------------------------------------------------
cmd_validate() {
    header "Running Validation Checks"

    local pass=0 fail=0

    # --- 1. GDScript syntax & type check ---
    info "Checking GDScript files..."
    local gd_issues
    gd_issues=$(python3 "$SCRIPT_DIR/tools/validate.py" 2>&1)
    if echo "$gd_issues" | grep -q "FAIL"; then
        echo "$gd_issues"
        ((fail++))
    else
        echo "$gd_issues"
        ((pass++))
    fi

    # --- 2. SVG validity ---
    info "Checking SVG files..."
    local svg_count=0 svg_fail=0
    while IFS= read -r -d '' svg; do
        ((svg_count++))
        if ! python3 -c "import xml.etree.ElementTree as ET; ET.parse('$svg')" 2>/dev/null; then
            warn "Invalid SVG: $svg"
            ((svg_fail++))
        fi
    done < <(find "$PROJECT_DIR/assets" -name "*.svg" -print0)
    if [[ $svg_fail -eq 0 ]]; then
        success "All $svg_count SVG files are valid XML."
        ((pass++))
    else
        error_count "$svg_fail SVG files have XML errors."
        ((fail++))
    fi

    # --- 3. Scene → script reference check ---
    info "Checking scene → script references..."
    local missing=0
    while IFS= read -r tscn; do
        while IFS= read -r ref; do
            local script_path="$PROJECT_DIR/$ref"
            if [[ ! -f "$script_path" ]]; then
                warn "Missing script: $ref  (referenced in $tscn)"
                ((missing++))
            fi
        done < <(grep -o 'path="res://scripts/[^"]*\.gd"' "$tscn" | sed 's/path="res:\/\///' | sed 's/"//')
    done < <(find "$PROJECT_DIR/scenes" -name "*.tscn")
    if [[ $missing -eq 0 ]]; then
        success "All scene → script references resolve."
        ((pass++))
    else
        ((fail++))
    fi

    # --- 4. project.godot check ---
    info "Checking project.godot..."
    if [[ -f "$PROJECT_FILE" ]]; then
        local autoload_count
        autoload_count=$(grep -c '^\[autoload\]\|^[A-Z][a-zA-Z]*="' "$PROJECT_FILE" 2>/dev/null || echo 0)
        success "project.godot found ($autoload_count autoload entries)"
        ((pass++))
    else
        warn "project.godot missing!"
        ((fail++))
    fi

    # --- Summary ---
    echo ""
    echo -e "${BOLD}Validation Summary:${RESET}"
    echo -e "  ${GREEN}Passed: $pass${RESET}   ${RED}Failed: $fail${RESET}"
    [[ $fail -eq 0 ]] && success "All checks passed!" || warn "Some checks failed — see above."
}

# ---------------------------------------------------------------------------
# COMMAND: clean
# ---------------------------------------------------------------------------
cmd_clean() {
    header "Cleaning Build Artifacts"
    rm -rf "$EXPORT_DIR"
    rm -rf "$PROJECT_DIR/.godot"
    success "Cleaned exports and .godot cache."
}

# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------
show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     THE DEPTHS OF MALACHAR               ║"
    echo "  ║     Game Launcher                        ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    # Show Godot status
    if [[ -f "$GODOT_BIN" ]]; then
        echo -e "  Godot ${GODOT_VERSION}: ${GREEN}Installed ✓${RESET}"
    else
        echo -e "  Godot ${GODOT_VERSION}: ${RED}Not installed${RESET}"
    fi
    echo ""
    echo -e "  ${BOLD}1)${RESET} Install Godot ${GODOT_VERSION}"
    echo -e "  ${BOLD}2)${RESET} Open project in Godot editor"
    echo -e "  ${BOLD}3)${RESET} Run game"
    echo -e "  ${BOLD}4)${RESET} Export → iOS (Xcode project)"
    echo -e "  ${BOLD}5)${RESET} Export → macOS"
    echo -e "  ${BOLD}6)${RESET} Validate project files"
    echo -e "  ${BOLD}7)${RESET} Clean build artifacts"
    echo -e "  ${BOLD}q)${RESET} Quit"
    echo ""
    read -rp "  Choose an option: " choice
    case "$choice" in
        1) cmd_install ;;
        2) cmd_open ;;
        3) cmd_run ;;
        4) cmd_export_ios ;;
        5) cmd_export_mac ;;
        6) cmd_validate ;;
        7) cmd_clean ;;
        q|Q) exit 0 ;;
        *) warn "Unknown option: $choice" ;;
    esac
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${1:-menu}" in
    install)     cmd_install ;;
    open)        cmd_open ;;
    run)         cmd_run ;;
    export-ios)  cmd_export_ios ;;
    export-mac)  cmd_export_mac ;;
    validate)    cmd_validate ;;
    clean)       cmd_clean ;;
    menu|*)      show_menu ;;
esac
