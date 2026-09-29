## DreamSequence — Short dream cutscene triggered randomly at base.
## Shows a ghostly memory fragment from Aelion — pre-fall Kingdom visions.

class_name DreamSequence
extends CanvasLayer

@onready var dream_text: Label    = $DreamPanel/DreamText
@onready var fade_rect: ColorRect = $FadeRect
@onready var skip_button: Button  = $SkipButton

const DREAM_FRAGMENTS: Array = [
	"The golden spires of Aelion's city reach upward. Children laugh in marble courtyards. The ley lines hum with pure magic.",
	"A great hall. Seven priests in golden robes. An eighth, face turned away, fists clenched. Nobody notices.",
	"The king sits on his throne, weeping silently. The seal beneath his feet pulses. He knows what he guards. He chose it anyway.",
	"Malachar, before the corruption. A smile without malice. Two gods walking a world still in bloom.",
	"The first crack in the ley line. Just a hairline fracture. Nobody worries. They should have worried.",
	"Aelion's final act. Light so bright it burns the memory blank. Then only you. Only this body. Only the dungeon ahead.",
]

signal dream_completed()

func _ready() -> void:
	visible = false
	if skip_button:
		skip_button.pressed.connect(_end_dream)
	EventBus.dream_sequence_triggered.connect(_start_dream)

func _start_dream() -> void:
	visible = true
	var fragment: String = DREAM_FRAGMENTS[randi() % DREAM_FRAGMENTS.size()]
	if dream_text:
		dream_text.text = fragment
	# Fade in
	if fade_rect:
		fade_rect.modulate = Color(1, 1, 1, 0)
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate", Color.WHITE, 1.2)
		tween.tween_interval(3.5)
		tween.tween_callback(func():
			if skip_button:
				skip_button.visible = true
		)

func _end_dream() -> void:
	if fade_rect:
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate", Color(1, 1, 1, 0), 0.8)
		tween.tween_callback(func():
			visible = false
			dream_completed.emit()
		)
	else:
		visible = false
		dream_completed.emit()
