## GameOver — Post-run screen showing stats and options.
## Displays run summary, allows weapon keep or return to base.

class_name GameOver
extends CanvasLayer

@onready var floor_label: Label         = $Panel/FloorLabel
@onready var enemies_label: Label       = $Panel/EnemiesLabel
@onready var coins_label: Label         = $Panel/CoinsLabel
@onready var recruits_label: Label      = $Panel/RecruitsLabel
@onready var class_label: Label         = $Panel/ClassLabel
@onready var keep_weapon_button: Button = $Panel/KeepWeaponButton
@onready var return_button: Button      = $Panel/ReturnButton
@onready var title_label: Label         = $Panel/TitleLabel

var run_stats: Dictionary = {}

signal weapon_keep_requested()
signal return_to_base_requested()

func _ready() -> void:
	visible = true
	if keep_weapon_button:
		keep_weapon_button.pressed.connect(_on_keep_weapon_pressed)
	if return_button:
		return_button.pressed.connect(_return_to_base)
	# Auto-populate from GameManager's run stats when the scene loads
	show_stats(GameManager.run_stats)

func show_stats(stats: Dictionary) -> void:
	run_stats = stats
	visible = true
	if title_label:
		title_label.text = "Run Ended" if not stats.get("victory", false) else "Victory!"
	if floor_label:
		# Key in GameManager.run_stats is "floors_reached"
		floor_label.text = "Deepest Floor: %d" % stats.get("floors_reached", 0)
	if enemies_label:
		enemies_label.text = "Enemies Slain: %d" % stats.get("enemies_killed", 0)
	if coins_label:
		# Key in GameManager.run_stats is "coins_collected" (stored as raw copper)
		var display: Dictionary = Globals.coins_to_display(stats.get("coins_collected", 0))
		coins_label.text = "Coins: %dg %ds %dc" % [display.get("gold", 0), display.get("silver", 0), display.get("copper", 0)]
	if recruits_label:
		# "recruits_lost" is an Array of names, not an int
		var lost: Array = stats.get("recruits_lost", [])
		recruits_label.text = "Recruits Lost: %d" % lost.size()
	if class_label:
		# "class_used" is a ClassType int — convert to readable name
		var class_int: int = stats.get("class_used", Globals.ClassType.WARRIOR)
		class_label.text = "Class: " + Globals.class_type_to_name(class_int)

func _on_keep_weapon_pressed() -> void:
	weapon_keep_requested.emit()
	# Navigate to WeaponKeepScreen — it will return here or go to base after selection
	# Only show WeaponKeep if we came from a non-ironman run ending
	if ResourceLoader.exists("res://scenes/ui/WeaponKeepScreen.tscn"):
		GameManager.change_state(Globals.GameState.WEAPON_KEEP)
		GameManager.transition_to_scene("res://scenes/ui/WeaponKeepScreen.tscn")
	else:
		_return_to_base()

func _return_to_base() -> void:
	return_to_base_requested.emit()
	# Route through GameManager so the transitioning flag is managed correctly
	GameManager.go_to_base()
