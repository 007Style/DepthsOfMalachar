## Tutorial — Interactive Guide & How-to-Play Screen
## Walks players through Controls, Combat, Classes & Upgrades, Recruits & Pets, and Base Hub.

class_name Tutorial
extends CanvasLayer

@onready var tab_bar: TabContainer = $TabContainer
@onready var close_button: Button = $CloseButton

# Where to return on close — "menu" or "base"
var return_target: String = "menu"

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)

func _close() -> void:
	if return_target == "base":
		GameManager.go_to_base()
	else:
		GameManager.transition_to_scene(GameManager.SCENE_MAIN_MENU)
