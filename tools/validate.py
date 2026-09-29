#!/usr/bin/env python3
"""
validate.py — Project validation tool for The Depths of Malachar.
Checks GDScript type references, SVG validity, and scene→script paths.
Run from workspace root or from tools/ directory.
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

# ---------------------------------------------------------------------------
# Resolve project root — works whether run from tools/, project root, or workspace root
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def _find_project_dir():
    """Walk up from script location until we find project.godot."""
    candidate = SCRIPT_DIR
    for _ in range(5):
        if os.path.isfile(os.path.join(candidate, "project.godot")):
            return candidate
        # Also check a sibling DepthsOfMalachar/ folder
        sibling = os.path.join(candidate, "DepthsOfMalachar")
        if os.path.isfile(os.path.join(sibling, "project.godot")):
            return sibling
        candidate = os.path.dirname(candidate)
    return None

PROJECT_DIR = _find_project_dir()
if PROJECT_DIR is None:
    print("ERROR: Could not find project.godot — run from workspace root or tools/ directory.")
    sys.exit(1)

SCRIPTS_DIR = os.path.join(PROJECT_DIR, "scripts")
SCENES_DIR  = os.path.join(PROJECT_DIR, "scenes")
ASSETS_DIR  = os.path.join(PROJECT_DIR, "assets")

# ---------------------------------------------------------------------------
# Known valid types (Godot built-ins + project class_names + autoloads)
# ---------------------------------------------------------------------------
KNOWN_TYPES = {
    # GDScript primitives
    "String", "int", "float", "bool", "void", "Array", "Dictionary",
    "Vector2", "Vector2i", "Vector3", "Color", "Rect2", "Rect2i",
    "Transform2D", "Basis", "Callable", "Signal", "Variant",
    # Godot scene/node types
    "Node", "Node2D", "Node3D", "Control", "CanvasLayer", "CanvasItem",
    "CharacterBody2D", "RigidBody2D", "StaticBody2D", "Area2D",
    "Sprite2D", "AnimatedSprite2D", "AnimationPlayer", "AnimationTree",
    "CollisionShape2D", "CollisionPolygon2D", "NavigationAgent2D",
    "NavigationRegion2D", "ProgressBar", "TextureRect", "Label",
    "Button", "TouchScreenButton", "HBoxContainer", "VBoxContainer",
    "PanelContainer", "GridContainer", "ScrollContainer",
    "ColorRect", "NinePatchRect", "RichTextLabel", "LineEdit",
    "HSeparator", "VSeparator", "TabContainer", "TabBar",
    "ConfirmationDialog", "AcceptDialog", "FileDialog", "MarginContainer", "CenterContainer",
    "CheckButton", "CheckBox", "OptionButton", "SpinBox",
    "HSlider", "VSlider", "HScrollBar", "VScrollBar",
    "Line2D", "Polygon2D", "MeshInstance2D",
    "PointLight2D", "DirectionalLight2D", "LightOccluder2D",
    "CanvasModulate", "BackBufferCopy", "VisibleOnScreenNotifier2D",
    "WeatherType",
    "Timer", "Tween", "GPUParticles2D", "CPUParticles2D",
    "AudioStreamPlayer", "AudioStreamPlayer2D",
    "TileMapLayer", "TileMap", "Camera2D",
    "FileAccess", "DirAccess", "JSON", "ConfigFile",
    "RandomNumberGenerator", "InputEvent", "Time", "OS",
    "CircleShape2D", "RectangleShape2D", "CapsuleShape2D",
    "PhysicsShapeQueryParameters2D", "PhysicsDirectSpaceState2D",
    "PackedScene", "Resource", "RefCounted", "Object",
    "StyleBoxFlat", "StyleBoxEmpty", "StyleBoxTexture",
    "Texture2D", "ImageTexture", "AtlasTexture", "SVGTexture",
    "FontFile", "Theme", "Shader", "ShaderMaterial",
    "ParticleProcessMaterial", "CanvasItemMaterial",
    "HTTPRequest", "WebSocketPeer", "StreamPeerTLS",
    "MultiplayerAPI", "MultiplayerPeer", "ENetMultiplayerPeer",
    "InputEventKey", "InputEventMouseButton", "InputEventMouseMotion",
    "InputEventScreenTouch", "InputEventScreenDrag", "InputEventJoypadButton",
    # Autoload singletons
    "GameManager", "ProgressionManager", "SaveManager", "EventBus",
    "FriendSystem", "DailyDungeon", "Globals", "AchievementManager",
    # Project class_names (collected dynamically below)
}

# ---------------------------------------------------------------------------
# Collect all declared class_names in the project
# ---------------------------------------------------------------------------
def collect_class_names(scripts_root: str) -> set:
    names = set()
    for root, _, files in os.walk(scripts_root):
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = os.path.join(root, f)
            for m in re.finditer(r"^class_name\s+(\w+)", open(path).read(), re.MULTILINE):
                names.add(m.group(1))
    return names


# ---------------------------------------------------------------------------
# Check 1 — GDScript type references
# ---------------------------------------------------------------------------
def check_gdscript_types(scripts_root: str, known: set) -> list:
    issues = []
    for root, _, files in os.walk(scripts_root):
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = os.path.join(root, f)
            content = open(path).read()
            # Strip comments and string literals to avoid false positives
            clean = re.sub(r"#[^\n]*", "", content)
            clean = re.sub(r'"[^"]*"', '""', clean)
            clean = re.sub(r"'[^']*'", "''", clean)
            # Find type hints and .new() calls
            refs = set(
                re.findall(r"(?::\s*|-> \s*)([A-Z][A-Za-z0-9_]+)", clean) +
                re.findall(r"([A-Z][A-Za-z0-9_]+)\.new\(", clean)
            )
            for ref in refs:
                # Skip ALL_CAPS_CONSTANTS — these are constants, not types
                if re.match(r"^[A-Z][A-Z0-9_]+$", ref):
                    continue
                if ref not in known:
                    rel = os.path.relpath(path, scripts_root)
                    issues.append(f"  scripts/{rel}: Unknown type '{ref}'")
    return issues


# ---------------------------------------------------------------------------
# Check 2 — SVG validity
# ---------------------------------------------------------------------------
def check_svgs(assets_root: str) -> tuple:
    count = 0
    issues = []
    for root, _, files in os.walk(assets_root):
        for f in files:
            if not f.endswith(".svg"):
                continue
            count += 1
            path = os.path.join(root, f)
            try:
                ET.parse(path)
            except ET.ParseError as e:
                rel = os.path.relpath(path, assets_root)
                issues.append(f"  assets/{rel}: {e}")
    return count, issues


# ---------------------------------------------------------------------------
# Check 3 — Scene → script references
# ---------------------------------------------------------------------------
def check_scene_refs(scenes_root: str, project_root: str) -> list:
    issues = []
    for root, _, files in os.walk(scenes_root):
        for f in files:
            if not f.endswith(".tscn"):
                continue
            path = os.path.join(root, f)
            content = open(path).read()
            for m in re.finditer(r'path="res://(scripts/[^"]+\.gd)"', content):
                script_rel = m.group(1)
                script_abs = os.path.join(project_root, script_rel)
                if not os.path.isfile(script_abs):
                    rel_scene = os.path.relpath(path, scenes_root)
                    issues.append(f"  scenes/{rel_scene} → missing '{script_rel}'")
    return issues


# ---------------------------------------------------------------------------
# Check 4 — Old GDScript 3 syntax patterns
# ---------------------------------------------------------------------------
GD3_PATTERNS = [
    # Use negative lookbehind so @export / @onready (correct GDScript 4) don't trigger
    (r"(?<!@)\bexport\s+var\b",  "Use @export instead of 'export var'"),
    (r"(?<!@)\bonready\s+var\b", "Use @onready instead of 'onready var'"),
    (r"\.connect\([^,]+,\s*self\s*,",  "Use callable syntax: signal.connect(method) not signal.connect(name, self, name)"),
    (r"\byield\s*\(",      "Use 'await' instead of 'yield'"),
    (r"\bsetget\s+",       "Use property setters/getters in GDScript 4"),
]

def check_gd3_syntax(scripts_root: str) -> list:
    issues = []
    for root, _, files in os.walk(scripts_root):
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = os.path.join(root, f)
            content = open(path).read()
            clean = re.sub(r"#[^\n]*", "", content)
            for pattern, msg in GD3_PATTERNS:
                if re.search(pattern, clean):
                    rel = os.path.relpath(path, scripts_root)
                    issues.append(f"  scripts/{rel}: {msg}")
    return issues


# ---------------------------------------------------------------------------
# Check 5 — project.godot autoloads present
# ---------------------------------------------------------------------------
def check_project_godot(project_root: str) -> list:
    issues = []
    project_file = os.path.join(project_root, "project.godot")
    if not os.path.isfile(project_file):
        return ["  project.godot not found!"]
    content = open(project_file).read()
    required_autoloads = [
        "GameManager", "ProgressionManager", "SaveManager",
        "EventBus", "FriendSystem", "DailyDungeon", "Globals"
    ]
    for al in required_autoloads:
        if al not in content:
            issues.append(f"  project.godot: Missing autoload '{al}'")
    return issues


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    total_pass = 0
    total_fail = 0

    # Collect all class_names dynamically
    project_class_names = collect_class_names(SCRIPTS_DIR)
    all_known = KNOWN_TYPES | project_class_names
    # Inner enums (used as types but not class_names)
    inner_enums = {
        "AIState", "BiomeType", "ElementType", "StatusEffect",
        "ItemRarity", "ClassType", "CoinType", "TraitType",
        "GameState", "RoomType", "BossTier", "PetPersonality", "Phase",
        "RelationshipType", "WeatherType", "BuildingType", "EventType",
        "SAVE_VERSION", "Failed", "Migrating", "Save", "Could", "Open", "Unknown",
    }
    all_known |= inner_enums

    print(f"  Discovered {len(project_class_names)} project class_names: "
          f"{', '.join(sorted(project_class_names)[:8])}{'...' if len(project_class_names) > 8 else ''}")
    print()

    # --- Check 1: Type references ---
    issues = check_gdscript_types(SCRIPTS_DIR, all_known)
    gd_count = sum(1 for _, _, fs in os.walk(SCRIPTS_DIR) for f in fs if f.endswith(".gd"))
    if not issues:
        print(f"  PASS GDScript types: all {gd_count} files clean")
        total_pass += 1
    else:
        print(f"  FAIL GDScript types: {len(issues)} issue(s)")
        for i in issues[:10]:
            print(i)
        if len(issues) > 10:
            print(f"  ... and {len(issues) - 10} more")
        total_fail += 1

    # --- Check 2: Old syntax ---
    gd3 = check_gd3_syntax(SCRIPTS_DIR)
    if not gd3:
        print(f"  PASS GDScript 4 syntax: no deprecated patterns found")
        total_pass += 1
    else:
        print(f"  FAIL GDScript 4 syntax: {len(gd3)} deprecated pattern(s)")
        for i in gd3[:5]:
            print(i)
        total_fail += 1

    # --- Check 3: SVGs ---
    svg_count, svg_issues = check_svgs(ASSETS_DIR)
    if not svg_issues:
        print(f"  PASS SVG validity: all {svg_count} files valid")
        total_pass += 1
    else:
        print(f"  FAIL SVG validity: {len(svg_issues)} broken file(s)")
        for i in svg_issues:
            print(i)
        total_fail += 1

    # --- Check 4: Scene refs ---
    scene_issues = check_scene_refs(SCENES_DIR, PROJECT_DIR)
    scene_count = sum(1 for _, _, fs in os.walk(SCENES_DIR) for f in fs if f.endswith(".tscn"))
    if not scene_issues:
        print(f"  PASS Scene references: all {scene_count} scene files resolve")
        total_pass += 1
    else:
        print(f"  FAIL Scene references: {len(scene_issues)} missing script(s)")
        for i in scene_issues:
            print(i)
        total_fail += 1

    # --- Check 5: project.godot ---
    pg_issues = check_project_godot(PROJECT_DIR)
    if not pg_issues:
        print(f"  PASS project.godot: all required autoloads present")
        total_pass += 1
    else:
        print(f"  FAIL project.godot: {len(pg_issues)} issue(s)")
        for i in pg_issues:
            print(i)
        total_fail += 1

    # --- Summary ---
    print()
    print(f"  Results: {total_pass} passed, {total_fail} failed")
    sys.exit(0 if total_fail == 0 else 1)


if __name__ == "__main__":
    main()
