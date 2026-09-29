## WeaponKeepScreen — Post-run screen where player chooses one weapon to keep.
## The chosen weapon is stored in the Weapon Cabinet for future runs.

class_name WeaponKeepScreen
extends CanvasLayer

@onready var weapon_list: VBoxContainer = $Panel/WeaponList
@onready var keep_button: Button        = $Panel/KeepButton
@onready var discard_button: Button     = $Panel/DiscardButton
@onready var title_label: Label         = $Panel/TitleLabel
@onready var selected_label: Label      = $Panel/SelectedLabel

var collected_weapons: Array = []  # Array of WeaponData
var selected_weapon: WeaponData = null

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	if keep_button:
		keep_button.pressed.connect(_keep_selected)
	if discard_button:
		discard_button.pressed.connect(_discard_selected)
	visible = false

# ---------------------------------------------------------------------------
# Open the screen with weapons found this run
# ---------------------------------------------------------------------------
func open(weapons: Array) -> void:
	collected_weapons = weapons
	visible = true
	if title_label:
		title_label.text = "Choose One Weapon to Keep"
	_populate_list()

func _populate_list() -> void:
	if not weapon_list:
		return
	# Clear existing
	for child in weapon_list.get_children():
		child.queue_free()
	# Build weapon buttons
	for weapon in collected_weapons:
		if not weapon:
			continue
		var btn: Button = Button.new()
		btn.text = "[%s] %s — %s DMG | %s" % [
			Globals.RARITY_NAMES.get(weapon.rarity, "?"),
			weapon.item_name,
			str(int(weapon.base_damage)),
			Globals.ElementType.keys()[weapon.element] if weapon.element < Globals.ElementType.size() else "NONE"
		]
		btn.modulate = Globals.RARITY_COLORS.get(weapon.rarity, Color.WHITE)
		btn.pressed.connect(func(): _select_weapon(weapon))
		weapon_list.add_child(btn)

func _select_weapon(weapon: WeaponData) -> void:
	selected_weapon = weapon
	if selected_label:
		selected_label.text = "Selected: " + weapon.item_name
	if keep_button:
		keep_button.disabled = false

# ---------------------------------------------------------------------------
# Keep / Discard
# ---------------------------------------------------------------------------
func _keep_selected() -> void:
	if not selected_weapon:
		return
	ProgressionManager.add_weapon_to_cabinet(selected_weapon)
	EventBus.notification_requested.emit(selected_weapon.item_name + " added to Weapon Cabinet!", Color(1.0, 0.85, 0.0))
	_close()

func _discard_selected() -> void:
	EventBus.notification_requested.emit("No weapon kept this run.", Color(0.7, 0.7, 0.7))
	_close()

func _close() -> void:
	visible = false
	# Go to Game Over screen which shows run summary, then returns to Base
	GameManager.change_state(Globals.GameState.GAME_OVER)
	GameManager.transition_to_scene("res://scenes/ui/GameOver.tscn")
