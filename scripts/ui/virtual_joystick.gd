## VirtualJoystick — On-screen touch joystick for mobile movement.
## Emits a normalised direction vector via EventBus each frame when active.
## Self-contained: handles its own touch input and visual update.

class_name VirtualJoystick
extends Control

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
@export var joystick_radius: float = 52.0   # Max travel radius of the knob (px)
@export var dead_zone: float = 8.0           # Minimum movement before registering input
@export var return_speed: float = 18.0       # How fast knob snaps back when released

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var base_circle: Control = $BaseCircle
@onready var knob: Control = $BaseCircle/Knob

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var _touch_index: int = -1           # Which finger owns this joystick
var _touch_origin: Vector2 = Vector2.ZERO
var _current_direction: Vector2 = Vector2.ZERO
var _is_active: bool = false

# Knob resting position (centre of base)
var _knob_rest: Vector2 = Vector2.ZERO

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_knob_rest = knob.position

func _process(delta: float) -> void:
	if not _is_active:
		# Smoothly return knob to centre
		knob.position = knob.position.lerp(_knob_rest, return_speed * delta)
		if knob.position.distance_to(_knob_rest) < 0.5:
			knob.position = _knob_rest
			_current_direction = Vector2.ZERO
			EventBus.hud_move_direction.emit(Vector2.ZERO)

# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only claim this touch if it started inside the joystick base area
		if _touch_index == -1 and _is_inside_base(event.position):
			_touch_index = event.index
			_touch_origin = event.position
			_is_active = true
	else:
		if event.index == _touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var offset: Vector2 = event.position - _touch_origin
	var distance: float = offset.length()

	if distance < dead_zone:
		_current_direction = Vector2.ZERO
	else:
		# Clamp to joystick radius
		var clamped: Vector2 = offset.normalized() * min(distance, joystick_radius)
		knob.position = _knob_rest + clamped
		_current_direction = clamped / joystick_radius  # Normalised 0..1 in each axis

	# Emit to EventBus — ethari.gd listens for this
	EventBus.hud_move_direction.emit(_current_direction)

func _release() -> void:
	_touch_index = -1
	_is_active = false
	_current_direction = Vector2.ZERO
	EventBus.hud_move_direction.emit(Vector2.ZERO)

func _is_inside_base(screen_pos: Vector2) -> bool:
	# Convert screen position to local coordinates of base_circle
	var local_pos: Vector2 = base_circle.get_global_transform().affine_inverse() * screen_pos
	return local_pos.length() <= joystick_radius + 20.0  # Slight tolerance

## Returns the current normalised direction (0..1 magnitude).
func get_direction() -> Vector2:
	return _current_direction
