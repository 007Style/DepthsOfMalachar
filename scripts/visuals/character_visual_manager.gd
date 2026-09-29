## CharacterVisualManager — Manages Ethari's visual appearance based on active class.
## Swaps the sprite sheet, sets animation, applies class colour tint and particle effects.
## Attach to the Ethari scene as a child node.

class_name CharacterVisualManager
extends Node

# ---------------------------------------------------------------------------
# Class → sprite path mapping
# Each entry: sprite_sheet path, primary colour, secondary colour, eye colour
# ---------------------------------------------------------------------------
const CLASS_VISUALS: Dictionary = {
	Globals.ClassType.WARRIOR: {
		"sprite": "res://assets/sprites/characters/classes/warrior.svg",
		"primary_color": Color(0.55, 0.10, 0.10),  # deep crimson
		"secondary_color": Color(0.38, 0.38, 0.44), # iron grey
		"eye_color": Color(1.0, 0.12, 0.12),        # red glow
		"aura_color": Color(0.8, 0.1, 0.1, 0.4),
		"name": "Warrior"
	},
	Globals.ClassType.MAGE: {
		"sprite": "res://assets/sprites/characters/classes/mage.svg",
		"primary_color": Color(0.04, 0.10, 0.38),   # midnight blue
		"secondary_color": Color(0.25, 0.0, 0.60),  # arcane purple
		"eye_color": Color(0.0, 0.82, 1.0),          # cyan glow
		"aura_color": Color(0.1, 0.3, 1.0, 0.4),
		"name": "Mage"
	},
	Globals.ClassType.ROGUE: {
		"sprite": "res://assets/sprites/characters/classes/rogue.svg",
		"primary_color": Color(0.12, 0.16, 0.10),   # charcoal
		"secondary_color": Color(0.12, 0.50, 0.12), # poison green
		"eye_color": Color(0.88, 0.50, 0.0),         # amber
		"aura_color": Color(0.1, 0.5, 0.1, 0.3),
		"name": "Rogue"
	},
	Globals.ClassType.NECROMANCER: {
		"sprite": "res://assets/sprites/characters/classes/necromancer.svg",
		"primary_color": Color(0.04, 0.03, 0.08),   # void black
		"secondary_color": Color(0.0, 0.69, 0.25),  # sickly green
		"eye_color": Color(0.0, 0.88, 0.25),         # hollow green glow
		"aura_color": Color(0.0, 0.6, 0.2, 0.5),
		"name": "Necromancer"
	},
	Globals.ClassType.PALADIN: {
		"sprite": "res://assets/sprites/characters/classes/paladin.svg",
		"primary_color": Color(0.83, 0.63, 0.12),   # polished gold
		"secondary_color": Color(1.0, 0.98, 0.94),  # radiant white
		"eye_color": Color(0.19, 0.38, 0.82),        # warm blue
		"aura_color": Color(1.0, 0.95, 0.6, 0.5),
		"name": "Paladin"
	},
	Globals.ClassType.ARCHER: {
		"sprite": "res://assets/sprites/characters/classes/archer.svg",
		"primary_color": Color(0.18, 0.29, 0.13),   # forest green
		"secondary_color": Color(0.29, 0.19, 0.09), # earthy brown
		"eye_color": Color(0.50, 0.38, 0.12),        # hazel
		"aura_color": Color(0.2, 0.5, 0.1, 0.3),
		"name": "Archer"
	},
	Globals.ClassType.DRUID: {
		"sprite": "res://assets/sprites/characters/classes/druid.svg",
		"primary_color": Color(0.23, 0.16, 0.06),   # bark brown
		"secondary_color": Color(0.16, 0.35, 0.09), # moss green
		"eye_color": Color(0.12, 0.63, 0.19),        # bright green
		"aura_color": Color(0.2, 0.8, 0.2, 0.4),
		"name": "Druid"
	},
	Globals.ClassType.ASSASSIN: {
		"sprite": "res://assets/sprites/characters/classes/assassin.svg",
		"primary_color": Color(0.04, 0.04, 0.08),   # jet black
		"secondary_color": Color(0.80, 0.83, 0.90), # cold silver
		"eye_color": Color(0.12, 0.38, 1.0),         # icy blue
		"aura_color": Color(0.1, 0.2, 0.8, 0.4),
		"name": "Assassin"
	},
	Globals.ClassType.BERSERKER: {
		"sprite": "res://assets/sprites/characters/classes/berserker.svg",
		"primary_color": Color(0.75, 0.17, 0.04),   # blood red
		"secondary_color": Color(0.50, 0.50, 0.44), # wolf grey
		"eye_color": Color(0.88, 0.25, 0.0),         # blazing orange
		"aura_color": Color(1.0, 0.1, 0.0, 0.5),
		"name": "Berserker"
	},
	Globals.ClassType.ELEMENTALIST: {
		"sprite": "res://assets/sprites/characters/classes/elementalist.svg",
		"primary_color": Color(0.48, 0.12, 0.0),    # fire orange
		"secondary_color": Color(0.0, 0.19, 0.38),  # ice blue
		"eye_color": Color(0.88, 0.25, 0.0),         # split fire/ice handled in shader
		"aura_color": Color(0.9, 0.4, 0.1, 0.4),
		"name": "Elementalist"
	},
	Globals.ClassType.MONK: {
		"sprite": "res://assets/sprites/characters/classes/monk.svg",
		"primary_color": Color(0.88, 0.50, 0.12),   # saffron orange
		"secondary_color": Color(0.54, 0.25, 0.06), # brown wraps
		"eye_color": Color(0.38, 0.19, 0.09),        # dark brown
		"aura_color": Color(1.0, 0.9, 0.5, 0.4),
		"name": "Monk"
	},
	Globals.ClassType.BARD: {
		"sprite": "res://assets/sprites/characters/classes/bard.svg",
		"primary_color": Color(0.29, 0.0, 0.50),    # deep purple
		"secondary_color": Color(0.78, 0.63, 0.19), # gold
		"eye_color": Color(0.42, 0.23, 0.05),        # warm brown
		"aura_color": Color(0.7, 0.5, 1.0, 0.4),
		"name": "Bard"
	},
	Globals.ClassType.SUMMONER: {
		"sprite": "res://assets/sprites/characters/classes/summoner.svg",
		"primary_color": Color(0.04, 0.16, 0.16),   # deep teal
		"secondary_color": Color(0.78, 0.63, 0.19), # arcane gold
		"eye_color": Color(0.56, 0.56, 0.75),        # pale silver
		"aura_color": Color(0.0, 0.85, 0.69, 0.4),
		"name": "Summoner"
	},
	Globals.ClassType.WITCH_HUNTER: {
		"sprite": "res://assets/sprites/characters/classes/witch_hunter.svg",
		"primary_color": Color(0.28, 0.28, 0.31),   # slate grey
		"secondary_color": Color(0.56, 0.50, 0.38), # holy silver
		"eye_color": Color(0.75, 0.44, 0.06),        # stern amber
		"aura_color": Color(0.9, 0.85, 0.5, 0.4),
		"name": "Witch Hunter"
	},
	Globals.ClassType.KNIGHT: {
		"sprite": "res://assets/sprites/characters/classes/knight.svg",
		"primary_color": Color(0.34, 0.41, 0.63),   # steel blue-grey
		"secondary_color": Color(0.06, 0.19, 0.63), # royal blue
		"eye_color": Color(0.25, 0.50, 1.0),         # blue glow
		"aura_color": Color(0.3, 0.5, 1.0, 0.4),
		"name": "Knight"
	},
	Globals.ClassType.TRUE_FORM: {
		"sprite": "res://assets/sprites/characters/ethari/ethari_sheet.svg",
		"primary_color": Color(0.94, 0.94, 1.0),    # divine silver-white
		"secondary_color": Color(0.94, 0.75, 0.25), # golden core
		"eye_color": Color(0.75, 0.25, 1.0),         # violet divine
		"aura_color": Color(1.0, 0.9, 0.5, 0.6),
		"name": "True Form"
	}
}

# ---------------------------------------------------------------------------
# References
# ---------------------------------------------------------------------------
var _sprite: Sprite2D = null
var _aura_particles: GPUParticles2D = null
var _current_class: int = -1

# ---------------------------------------------------------------------------
# Initialise
# ---------------------------------------------------------------------------
func initialise(sprite_node: Sprite2D, aura_node: GPUParticles2D = null) -> void:
	_sprite = sprite_node
	_aura_particles = aura_node

## Apply the visual appearance for the given class type.
func apply_class_visuals(class_type: int) -> void:
	if class_type == _current_class:
		return
	_current_class = class_type

	var visuals: Dictionary = CLASS_VISUALS.get(class_type, CLASS_VISUALS[Globals.ClassType.WARRIOR])

	# Load and apply sprite texture
	if _sprite:
		var texture: Texture2D = load(visuals["sprite"])
		if texture:
			_sprite.texture = texture
		# Apply a subtle colour modulation matching the class primary colour
		# (white stays white so SVG colours show through — only tiny modulation)
		_sprite.modulate = Color.WHITE

	# Apply aura particle colour
	if _aura_particles:
		var aura_color: Color = visuals["aura_color"]
		_aura_particles.modulate = aura_color
		_aura_particles.emitting = true

## Get the display name of the current class.
func get_class_display_name() -> String:
	var visuals: Dictionary = CLASS_VISUALS.get(_current_class, {})
	return visuals.get("name", "Unknown")

## Get the primary colour of a class (used for UI tinting).
static func get_class_primary_color(class_type: int) -> Color:
	var visuals: Dictionary = CLASS_VISUALS.get(class_type, {})
	return visuals.get("primary_color", Color.WHITE)

## Get the eye glow colour (used for hit flash and eye particles).
static func get_class_eye_color(class_type: int) -> Color:
	var visuals: Dictionary = CLASS_VISUALS.get(class_type, {})
	return visuals.get("eye_color", Color.WHITE)

## Apply a hit flash in the class's eye colour (called from ethari.gd).
func flash_hit_color(class_type: int) -> void:
	if _sprite:
		_sprite.modulate = get_class_eye_color(class_type)

## Reset modulate to white (called after hit flash timer).
func reset_color() -> void:
	if _sprite:
		_sprite.modulate = Color.WHITE

## Apply stance visual tint (stance A = primary, stance B = secondary).
func apply_stance_tint(stance_index: int, class_type: int) -> void:
	if not _sprite:
		return
	var visuals: Dictionary = CLASS_VISUALS.get(class_type, {})
	if stance_index == 0:
		_sprite.modulate = Color.WHITE
	else:
		var secondary: Color = visuals.get("secondary_color", Color.WHITE)
		# Subtle tint — blend with white so SVG art shows through
		_sprite.modulate = secondary.lerp(Color.WHITE, 0.6)
