## MainMenu — Main menu screen controller.
## Includes animated title glow, floating particle effect, and atmospheric visuals.

extends Control

@onready var play_button: Button        = $VBoxContainer/PlayButton
@onready var tutorial_button: Button    = $VBoxContainer/TutorialButton
@onready var daily_button: Button       = $VBoxContainer/DailyButton
@onready var friends_button: Button     = $VBoxContainer/FriendsButton
@onready var lore_button: Button        = $VBoxContainer/LoreButton
@onready var settings_button: Button    = $VBoxContainer/SettingsButton
@onready var quit_button: Button        = $VBoxContainer/QuitButton
@onready var notification_label: Label  = $NotificationLabel
@onready var title_label: Label         = $VBoxContainer/TitleLabel
@onready var glow_top: ColorRect        = $GlowTop

var _notif_tween: Tween = null
var _title_tween: Tween = null
var _particles: Array[ColorRect] = []
var _particle_velocities: Array[Vector2] = []
const PARTICLE_COUNT: int = 28

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	daily_button.pressed.connect(_on_daily_pressed)
	friends_button.pressed.connect(_on_friends_pressed)
	lore_button.pressed.connect(_on_lore_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Update daily button label
	if DailyDungeon.is_completed_today():
		daily_button.text = "📅  DAILY DUNGEON  ✓"
		daily_button.disabled = true

	_spawn_particles()
	_start_title_glow()
	_start_glow_pulse()

# ---------------------------------------------------------------------------
# Animated title glow
# ---------------------------------------------------------------------------
func _start_title_glow() -> void:
	if not title_label:
		return
	_title_tween = create_tween().set_loops()
	_title_tween.tween_property(title_label, "theme_override_colors/font_color",
		Color(1.0, 0.95, 0.7, 1.0), 1.5).set_ease(Tween.EASE_IN_OUT)
	_title_tween.tween_property(title_label, "theme_override_colors/font_color",
		Color(0.85, 0.65, 0.3, 1.0), 1.5).set_ease(Tween.EASE_IN_OUT)

func _start_glow_pulse() -> void:
	if not glow_top:
		return
	var glow_tween := create_tween().set_loops()
	glow_tween.tween_property(glow_top, "color",
		Color(0.20, 0.07, 0.35, 0.5), 2.0).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(glow_top, "color",
		Color(0.10, 0.03, 0.18, 0.2), 2.0).set_ease(Tween.EASE_IN_OUT)

# ---------------------------------------------------------------------------
# Floating particle system (pure GDScript — no GPUParticles2D needed)
# ---------------------------------------------------------------------------
func _spawn_particles() -> void:
	var viewport_size := get_viewport_rect().size
	for i in PARTICLE_COUNT:
		var dot := ColorRect.new()
		var sz: float = randf_range(2.0, 5.0)
		dot.custom_minimum_size = Vector2(sz, sz)
		dot.size = Vector2(sz, sz)
		# Purples, teals, golds
		var palettes: Array[Color] = [
			Color(0.7, 0.3, 1.0, 0.6),
			Color(0.2, 0.8, 1.0, 0.5),
			Color(1.0, 0.85, 0.3, 0.55),
			Color(0.5, 0.1, 0.8, 0.6),
			Color(0.3, 0.9, 0.6, 0.5),
		]
		dot.color = palettes[randi() % palettes.size()]
		dot.position = Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y))
		add_child(dot)
		_particles.append(dot)
		var speed: float = randf_range(10.0, 35.0)
		var angle: float = randf_range(0, TAU)
		_particle_velocities.append(Vector2(cos(angle), sin(angle)) * speed)

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	for i in _particles.size():
		var dot: ColorRect = _particles[i]
		dot.position += _particle_velocities[i] * delta
		# Wrap around screen edges
		if dot.position.x > viewport_size.x + 6:
			dot.position.x = -6
		elif dot.position.x < -6:
			dot.position.x = viewport_size.x + 6
		if dot.position.y > viewport_size.y + 6:
			dot.position.y = -6
		elif dot.position.y < -6:
			dot.position.y = viewport_size.y + 6
		# Gentle bob
		dot.modulate.a = 0.4 + 0.3 * sin(Time.get_ticks_msec() * 0.001 + i * 0.7)

func _on_play_pressed() -> void:
	if ResourceLoader.exists(GameManager.SCENE_SAVE_SLOTS):
		GameManager.transition_to_scene(GameManager.SCENE_SAVE_SLOTS)
	else:
		GameManager.go_to_base()

func _on_tutorial_pressed() -> void:
	if ResourceLoader.exists(GameManager.SCENE_TUTORIAL):
		GameManager.transition_to_scene(GameManager.SCENE_TUTORIAL)
	else:
		_show_notification("Tutorial — Coming soon!", Color(0.7, 0.5, 1.0))

func _on_daily_pressed() -> void:
	if DailyDungeon.is_completed_today():
		_show_notification("Already completed today's dungeon!", Color(0.9, 0.7, 0.2))
		return
	GameManager.start_class_select()

func _on_friends_pressed() -> void:
	var code: String = FriendSystem.my_friend_code
	_show_notification("Your friend code: " + code, Color(0.4, 0.9, 1.0))

func _on_lore_pressed() -> void:
	if ResourceLoader.exists("res://scenes/ui/LoreLog.tscn"):
		GameManager.transition_to_scene("res://scenes/ui/LoreLog.tscn")
	else:
		_show_notification("Lore Log — Coming soon!", Color(0.7, 0.5, 1.0))

func _on_settings_pressed() -> void:
	if ResourceLoader.exists("res://scenes/ui/Settings.tscn"):
		# Keep state as MENU so Settings _close() returns here
		GameManager.transition_to_scene("res://scenes/ui/Settings.tscn")
	else:
		_show_notification("Settings — Coming soon!", Color(0.7, 0.5, 1.0))

func _on_quit_pressed() -> void:
	get_tree().quit()

func _show_notification(message: String, color: Color) -> void:
	notification_label.text = message
	notification_label.modulate = color
	if _notif_tween:
		_notif_tween.kill()
	_notif_tween = create_tween()
	_notif_tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)
	_notif_tween.tween_interval(2.5)
	_notif_tween.tween_property(notification_label, "modulate:a", 0.0, 0.4)
