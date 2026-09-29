## Leaderboard — Daily Dungeon global leaderboard UI.
## Shows top 100 scores, personal rank, and daily reward status.

class_name Leaderboard
extends CanvasLayer

@onready var score_list: VBoxContainer = $Panel/ScrollContainer/ScoreList
@onready var personal_label: Label     = $Panel/PersonalLabel
@onready var title_label: Label        = $Panel/TitleLabel
@onready var close_button: Button      = $Panel/CloseButton
@onready var submit_button: Button     = $Panel/SubmitButton

signal score_submitted(score: int)

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	if submit_button:
		submit_button.pressed.connect(_submit_score)
	if title_label:
		title_label.text = "Daily Dungeon — Global Leaderboard"

func show_leaderboard(personal_score: int) -> void:
	visible = true
	if personal_label:
		personal_label.text = "Your Score: %d" % personal_score
	_load_leaderboard()

func _load_leaderboard() -> void:
	## Fetch from backend via HTTP — placeholder implementation.
	## In production, use Godot HTTPRequest node to query leaderboard API.
	_display_placeholder()

func _display_placeholder() -> void:
	if not score_list:
		return
	for child in score_list.get_children():
		child.queue_free()
	# Placeholder rows
	var sample_entries: Array = [
		{"rank": 1, "name": "Malachar_Slayer", "score": 99999, "class": "Berserker"},
		{"rank": 2, "name": "ShadowWalker",    "score": 87650, "class": "Assassin"},
		{"rank": 3, "name": "IronFist_42",     "score": 76100, "class": "Warrior"},
	]
	for entry in sample_entries:
		var lbl: Label = Label.new()
		lbl.text = "#%d  %s  —  %d  (%s)" % [entry["rank"], entry["name"], entry["score"], entry["class"]]
		if entry["rank"] == 1:
			lbl.modulate = Color(1.0, 0.85, 0.0)
		score_list.add_child(lbl)

func _submit_score() -> void:
	var score: int = DailyDungeon.calculate_daily_score() if DailyDungeon.has_method("calculate_daily_score") else 0
	EventBus.daily_dungeon_score_submitted.emit(score)
	EventBus.notification_requested.emit("Score submitted: %d" % score, Color(0.5, 1.0, 0.5))
	score_submitted.emit(score)

func _close() -> void:
	visible = false
