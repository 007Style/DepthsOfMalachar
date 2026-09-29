## HallOfLegends — Visual hall showing every Ethari from every legacy run.
## Reads from ProgressionManager.legacy_history and displays cards.

class_name HallOfLegends
extends CanvasLayer

@onready var scroll: VBoxContainer = $ScrollContainer/LegendList
@onready var title_label: Label    = $TitleLabel
@onready var close_button: Button  = $CloseButton

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	if title_label:
		title_label.text = "Hall of Legends — Those Who Came Before"
	_populate()

func _close() -> void:
	visible = false

func _populate() -> void:
	if not scroll:
		return
	for child in scroll.get_children():
		child.queue_free()
	var history: Array = ProgressionManager.legacy_history
	if history.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No legends yet. Your story is still unwritten."
		lbl.horizontal_alignment = 1
		scroll.add_child(lbl)
		return
	# Most recent first
	for i in range(history.size() - 1, -1, -1):
		var run: Dictionary = history[i]
		_add_legend_card(run, i + 1)

func _add_legend_card(run: Dictionary, gen: int) -> void:
	var card: PanelContainer = PanelContainer.new()
	var vbox: VBoxContainer = VBoxContainer.new()

	var gen_lbl: Label = Label.new()
	gen_lbl.text = "Generation %d — Ethari the %s" % [gen, run.get("class_name", "Warrior")]
	gen_lbl.modulate = Color(1.0, 0.9, 0.5)

	var stats_lbl: Label = Label.new()
	stats_lbl.text = "Floor %d  •  %d Enemies  •  %d Runs  •  NG+%d" % [
		run.get("deepest_floor", 0),
		run.get("enemies_killed", 0),
		run.get("runs_completed", 0),
		run.get("ng_plus_tier", 0),
	]

	var death_lbl: Label = Label.new()
	death_lbl.text = "Fell to: " + run.get("death_cause", "Unknown")
	death_lbl.modulate = Color(0.8, 0.5, 0.5)

	var sep: HSeparator = HSeparator.new()
	for lbl in [gen_lbl, stats_lbl, death_lbl, sep]:
		vbox.add_child(lbl)
	card.add_child(vbox)
	scroll.add_child(card)
