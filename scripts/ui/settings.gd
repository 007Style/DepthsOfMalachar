## Settings — Settings screen with audio, accessibility, and gameplay toggles.
## Can be opened from MainMenu or Base hub.

class_name Settings
extends CanvasLayer

@onready var music_slider: HSlider    = $Panel/MusicSlider
@onready var sfx_slider: HSlider      = $Panel/SFXSlider
@onready var shake_toggle: CheckButton = $Panel/ShakeToggle
@onready var autoloot_toggle: CheckButton = $Panel/AutolootToggle
@onready var colorblind_toggle: CheckButton = $Panel/ColorblindToggle
@onready var larger_ui_toggle: CheckButton = $Panel/LargerUIToggle
@onready var close_button: Button     = $Panel/CloseButton

# Where to return on close — "menu" or "base"
var return_target: String = "menu"

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	_load_settings()
	if music_slider:
		music_slider.value_changed.connect(func(v): _set_music_volume(v))
	if sfx_slider:
		sfx_slider.value_changed.connect(func(v): _set_sfx_volume(v))
	if shake_toggle:
		shake_toggle.toggled.connect(func(v): SaveManager.set_setting("screen_shake", v))
	if autoloot_toggle:
		autoloot_toggle.toggled.connect(func(v): SaveManager.set_setting("auto_loot", v))
	if colorblind_toggle:
		colorblind_toggle.toggled.connect(func(v): SaveManager.set_setting("colorblind_mode", v))
	if larger_ui_toggle:
		larger_ui_toggle.toggled.connect(func(v): SaveManager.set_setting("larger_ui", v))

func _load_settings() -> void:
	if music_slider:
		music_slider.value = SaveManager.get_setting("music_volume", 0.8)
	if sfx_slider:
		sfx_slider.value = SaveManager.get_setting("sfx_volume", 1.0)
	if shake_toggle:
		shake_toggle.button_pressed = SaveManager.get_setting("screen_shake", true)
	if autoloot_toggle:
		autoloot_toggle.button_pressed = SaveManager.get_setting("auto_loot", false)
	if colorblind_toggle:
		colorblind_toggle.button_pressed = SaveManager.get_setting("colorblind_mode", false)
	if larger_ui_toggle:
		larger_ui_toggle.button_pressed = SaveManager.get_setting("larger_ui", false)

func _set_music_volume(value: float) -> void:
	var db: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	SaveManager.set_setting("music_volume", value)

func _set_sfx_volume(value: float) -> void:
	var db: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	SaveManager.set_setting("sfx_volume", value)

func _close() -> void:
	SaveManager.save()
	# Return to wherever we came from
	match GameManager.current_state:
		Globals.GameState.BASE:
			GameManager.go_to_base()
		Globals.GameState.MENU:
			GameManager.go_to_main_menu()
		_:
			GameManager.go_to_main_menu()
