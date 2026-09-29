## ClassSelect — Class selection screen before a dungeon run.
## Shows all 15 starter classes as interactive cards.
## Locked classes are shown dimmed with a lock icon.
## Confirms class choice and calls GameManager.start_run(class_type).

class_name ClassSelect
extends CanvasLayer

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var class_grid: GridContainer        = $Background/ScrollContainer/ClassGrid
@onready var title_label: Label              = $Background/TitleLabel
@onready var desc_label: Label               = $Background/DescLabel
@onready var confirm_button: Button          = $Background/ConfirmButton
@onready var back_button: Button             = $Background/BackButton
@onready var selected_label: Label           = $Background/SelectedLabel

# ---------------------------------------------------------------------------
# Class definitions — icon, name, description, colour
# ---------------------------------------------------------------------------
const CLASS_DATA: Array = [
	{ "type": Globals.ClassType.WARRIOR,      "name": "Warrior",      "icon": "⚔",  "color": Color(0.7, 0.3, 0.2),  "desc": "Balanced fighter. High health, medium damage. Cleave attack hits multiple enemies." },
	{ "type": Globals.ClassType.MAGE,         "name": "Mage",         "icon": "✦",  "color": Color(0.3, 0.4, 0.9),  "desc": "Arcane spellcaster. Low health, very high spell damage. Chain Lightning ultimate." },
	{ "type": Globals.ClassType.ROGUE,        "name": "Rogue",        "icon": "🗡",  "color": Color(0.5, 0.5, 0.5),  "desc": "Agile duelist. High crit chance and dodge. Assassinate one-shots weakened foes." },
	{ "type": Globals.ClassType.NECROMANCER,  "name": "Necromancer",  "icon": "💀",  "color": Color(0.5, 0.0, 0.5),  "desc": "Death mage. Raises slain enemies as undead minions. Drains life from foes." },
	{ "type": Globals.ClassType.PALADIN,      "name": "Paladin",      "icon": "🛡",  "color": Color(0.9, 0.8, 0.2),  "desc": "Holy warrior. High defence and party healing. Divine Shield blocks all damage." },
	{ "type": Globals.ClassType.ARCHER,       "name": "Archer",       "icon": "🏹",  "color": Color(0.4, 0.7, 0.3),  "desc": "Ranged specialist. Long attack range. Rain of Arrows devastates groups." },
	{ "type": Globals.ClassType.DRUID,        "name": "Druid",        "icon": "🌿",  "color": Color(0.2, 0.6, 0.2),  "desc": "Nature shaman. Shapeshifts and summons natural spirits. Regeneration over time." },
	{ "type": Globals.ClassType.ASSASSIN,     "name": "Assassin",     "icon": "🌑",  "color": Color(0.2, 0.2, 0.4),  "desc": "Shadow killer. Invisible approach. Guaranteed critical backstab from stealth." },
	{ "type": Globals.ClassType.BERSERKER,    "name": "Berserker",    "icon": "💢",  "color": Color(0.8, 0.2, 0.1),  "desc": "Rage warrior. Damage increases as HP falls. Unstoppable Fury mode at low health." },
	{ "type": Globals.ClassType.ELEMENTALIST, "name": "Elementalist", "icon": "⚡",  "color": Color(0.3, 0.8, 0.9),  "desc": "Element master. Rotates fire/ice/lightning. Elemental Overload triggers combos." },
	{ "type": Globals.ClassType.MONK,         "name": "Monk",         "icon": "☯",  "color": Color(0.9, 0.7, 0.3),  "desc": "Martial artist. Fast unarmed combos. Inner Peace heals on consecutive hits." },
	{ "type": Globals.ClassType.BARD,         "name": "Bard",         "icon": "🎵",  "color": Color(0.9, 0.5, 0.8),  "desc": "Battle musician. Songs buff allies and debuff enemies. Grand Finale stuns all." },
	{ "type": Globals.ClassType.SUMMONER,     "name": "Summoner",     "icon": "👁",  "color": Color(0.6, 0.3, 0.7),  "desc": "Beast caller. Permanent elemental familiars fight alongside you. Army of Spirits." },
	{ "type": Globals.ClassType.WITCH_HUNTER, "name": "Witch Hunter", "icon": "🔥",  "color": Color(0.7, 0.5, 0.2),  "desc": "Monster slayer. Bonus damage vs magical enemies. Silver Bolt pierces all targets." },
	{ "type": Globals.ClassType.KNIGHT,       "name": "Knight",       "icon": "🏰",  "color": Color(0.5, 0.5, 0.6),  "desc": "Armoured vanguard. Highest defence in game. Fortress Stance reflects damage." },
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _selected_class_type: int = Globals.ClassType.WARRIOR
var _card_buttons: Array = []

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	if title_label:
		title_label.text = "Choose Your Class"
	if desc_label:
		desc_label.text = "Select a class to see its description."
	if selected_label:
		selected_label.text = "Selected: Warrior"
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
		confirm_button.text = "Enter the Depths"
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.text = "← Back to Base"
	_build_class_cards()

# ---------------------------------------------------------------------------
# Build class cards
# ---------------------------------------------------------------------------
func _build_class_cards() -> void:
	if not class_grid:
		return
	# Clear any old cards
	for child in class_grid.get_children():
		child.queue_free()
	_card_buttons.clear()

	for data in CLASS_DATA:
		var is_unlocked: bool = ProgressionManager.is_class_unlocked(data["type"])
		var card := _make_card(data, is_unlocked)
		class_grid.add_child(card)
		_card_buttons.append(card)

func _make_card(data: Dictionary, is_unlocked: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(130, 108)
	card.text = ""

	# Build card content as a VBoxContainer
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	# Class Portrait Sprite
	var class_file: String = data["name"].to_lower().replace(" ", "_")
	var sprite_path: String = "res://assets/sprites/characters/classes/" + class_file + ".svg"
	if ResourceLoader.exists(sprite_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.custom_minimum_size = Vector2(36, 36)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(tex_rect)
	else:
		var icon_label := Label.new()
		icon_label.text = data["icon"]
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 24)
		vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", data["color"])
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(name_label)

	if not is_unlocked:
		var lock_label := Label.new()
		lock_label.text = "🔒 LOCKED"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 9)
		lock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(lock_label)

	# Style card background
	var stylebox := StyleBoxFlat.new()
	if is_unlocked:
		stylebox.bg_color = Color(data["color"].r * 0.25, data["color"].g * 0.25, data["color"].b * 0.25, 1.0)
		stylebox.border_color = data["color"]
	else:
		stylebox.bg_color = Color(0.08, 0.08, 0.10, 1.0)
		stylebox.border_color = Color(0.2, 0.2, 0.2)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(6)
	card.add_theme_stylebox_override("normal", stylebox)

	# Hover style
	var hover_style := stylebox.duplicate() as StyleBoxFlat
	if is_unlocked:
		hover_style.bg_color = Color(data["color"].r * 0.4, data["color"].g * 0.4, data["color"].b * 0.4, 1.0)
		hover_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	card.add_theme_stylebox_override("hover", hover_style)

	if is_unlocked:
		card.pressed.connect(func(): _on_card_selected(data))
	else:
		card.disabled = false  # Visible but won't trigger selection
		card.pressed.connect(func(): _show_locked_message(data["name"]))

	return card

# ---------------------------------------------------------------------------
# Card selection
# ---------------------------------------------------------------------------
func _on_card_selected(data: Dictionary) -> void:
	_selected_class_type = data["type"]
	if desc_label:
		desc_label.text = data["desc"]
	if selected_label:
		selected_label.text = "Selected: " + data["name"]
		selected_label.add_theme_color_override("font_color", data["color"])
		# Quick punch animation on select
		var tw := create_tween()
		selected_label.scale = Vector2(1.15, 1.15)
		tw.tween_property(selected_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Highlight selected card
	_refresh_card_highlights()

func _refresh_card_highlights() -> void:
	for i in _card_buttons.size():
		var btn: Button = _card_buttons[i]
		var data: Dictionary = CLASS_DATA[i]
		var is_selected: bool = (data["type"] == _selected_class_type)
		var is_unlocked: bool = ProgressionManager.is_class_unlocked(data["type"])
		if is_unlocked and is_selected:
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(data["color"].r * 0.5, data["color"].g * 0.5, data["color"].b * 0.5, 1.0)
			sel_style.border_color = Color(1.0, 1.0, 0.5, 1.0)
			sel_style.set_border_width_all(3)
			sel_style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", sel_style)
		elif is_unlocked:
			var norm_style := StyleBoxFlat.new()
			norm_style.bg_color = Color(data["color"].r * 0.25, data["color"].g * 0.25, data["color"].b * 0.25, 1.0)
			norm_style.border_color = data["color"]
			norm_style.set_border_width_all(2)
			norm_style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", norm_style)

func _show_locked_message(class_name_str: String) -> void:
	if desc_label:
		desc_label.text = class_name_str + " is locked. Unlock it through progression."

# ---------------------------------------------------------------------------
# Confirm / Back
# ---------------------------------------------------------------------------
func _on_confirm_pressed() -> void:
	# Verify class is still unlocked (shouldn't change, but safety check)
	if not ProgressionManager.is_class_unlocked(_selected_class_type):
		if desc_label:
			desc_label.text = "That class is locked!"
		return
	# Start the run via GameManager with chosen class
	GameManager.start_run(_selected_class_type)

func _on_back_pressed() -> void:
	GameManager.go_to_base()
