## CooldownArc — Custom draw node that renders a circular cooldown arc
## over the ultimate button. Fraction 0.0 = empty, 1.0 = full/ready.

extends Control

var fraction: float = 1.0   # Set by HUD via ultimate_arc.fraction = value

const ARC_COLOR_READY:    Color = Color(1.0, 0.85, 0.1, 0.9)
const ARC_COLOR_CHARGING: Color = Color(0.4, 0.4, 0.5, 0.7)
const ARC_BG_COLOR:       Color = Color(0.0, 0.0, 0.0, 0.5)

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0 - 3.0
	var thickness: float = 4.0

	# Background ring
	draw_arc(center, radius, 0.0, TAU, 48, ARC_BG_COLOR, thickness, true)

	if fraction <= 0.0:
		return

	# Coloured fill arc (starts from top = -PI/2, goes clockwise)
	var end_angle: float = -PI / 2.0 + TAU * fraction
	var color: Color = ARC_COLOR_READY if fraction >= 1.0 else ARC_COLOR_CHARGING
	draw_arc(center, radius, -PI / 2.0, end_angle, 48, color, thickness, true)

	# Ready pulse dot at tip of arc
	if fraction >= 1.0:
		draw_circle(center, 5.0, ARC_COLOR_READY)
