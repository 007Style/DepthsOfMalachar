## FuneralCutscene — Skippable funeral cutscene for fallen recruits.
## Shows the recruit's portrait, name, runs survived, and a farewell quote.
## Places a memorial marker at the base when completed.

class_name FuneralCutscene
extends CanvasLayer

@onready var portrait: TextureRect  = $Panel/Portrait
@onready var name_label: Label      = $Panel/NameLabel
@onready var title_label: Label     = $Panel/TitleLabel
@onready var stats_label: Label     = $Panel/StatsLabel
@onready var quote_label: Label     = $Panel/QuoteLabel
@onready var skip_button: Button    = $Panel/SkipButton
@onready var continue_button: Button = $Panel/ContinueButton
@onready var background: ColorRect  = $Background

var recruit_dict: Dictionary = {}

signal funeral_completed()

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	if skip_button:
		skip_button.pressed.connect(_on_complete)
	if continue_button:
		continue_button.pressed.connect(_on_complete)

# ---------------------------------------------------------------------------
# Open for a specific recruit
# ---------------------------------------------------------------------------
func start(r_dict: Dictionary) -> void:
	recruit_dict = r_dict
	visible = true
	_populate_ui()
	_play_sequence()

func _populate_ui() -> void:
	var r_name: String = recruit_dict.get("recruit_name", "Unknown Hero")
	var runs: int = recruit_dict.get("runs_survived", 0)
	var class_name_str: String = Globals.ClassType.keys()[recruit_dict.get("class_type", 0)]
	var backstory: String = recruit_dict.get("backstory", "Their story was not yet written.")

	if name_label:
		name_label.text = r_name
	if title_label:
		title_label.text = recruit_dict.get("veteran_title", class_name_str)
	if stats_label:
		stats_label.text = "%d Runs Survived  •  Level %d" % [runs, recruit_dict.get("level", 1)]
	if quote_label:
		quote_label.text = '"' + backstory + '"'

func _play_sequence() -> void:
	## Fade in slowly, pause for a moment, then show continue button.
	if background:
		background.modulate = Color(1, 1, 1, 0)
		var tween := create_tween()
		tween.tween_property(background, "modulate", Color.WHITE, 1.5)
		tween.tween_interval(2.0)
		tween.tween_callback(func():
			if continue_button:
				continue_button.visible = true
		)
	elif continue_button:
		continue_button.visible = true

func _on_complete() -> void:
	# Place memorial at base
	_request_memorial()
	visible = false
	funeral_completed.emit()

func _request_memorial() -> void:
	var r_name: String = recruit_dict.get("recruit_name", "")
	if r_name != "":
		EventBus.notification_requested.emit("Memorial placed for " + r_name + ".", Color(0.7, 0.7, 0.9))
