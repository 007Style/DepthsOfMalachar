## HUD — In-run heads-up display controller.
## Manages all on-screen elements: joystick, buttons, HP bars, coins,
## floor counter, combo, rage bar, ultimate cooldown, inventory panel,
## recruit send-back button, pet icon, notification toasts, and revive prompt.

extends CanvasLayer

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
# Left side
@onready var joystick: VirtualJoystick            = $Left/VirtualJoystick

# Right side buttons
@onready var btn_attack: TouchScreenButton        = $Right/BtnAttack
@onready var btn_ability1: TouchScreenButton      = $Right/BtnAbility1
@onready var btn_ability2: TouchScreenButton      = $Right/BtnAbility2
@onready var btn_ultimate: TouchScreenButton      = $Right/BtnUltimate
# BtnStance and BtnRage are at root CanvasLayer level (not under $Right)
@onready var btn_stance: TouchScreenButton        = $BtnStance
@onready var btn_rage: TouchScreenButton          = $BtnRage

# Top bar
@onready var hp_bar: ProgressBar                  = $TopBar/PlayerHP
@onready var hp_label: Label                      = $TopBar/PlayerHP/HPLabel
@onready var recruit_hp_bar: ProgressBar          = $TopBar/RecruitHP
@onready var recruit_hp_label: Label              = $TopBar/RecruitHP/HPLabel
@onready var floor_label: Label                   = $TopBar/FloorLabel
@onready var ng_plus_label: Label                 = $TopBar/NGPlusLabel

# Coin display (top right)
@onready var copper_label: Label                  = $TopBar/Coins/CopperLabel
@onready var silver_label: Label                  = $TopBar/Coins/SilverLabel
@onready var gold_label: Label                    = $TopBar/Coins/GoldLabel

# Combat feedback
@onready var combo_label: Label                   = $ComboLabel
@onready var rage_bar_node: ProgressBar           = $RageBar
@onready var ultimate_arc: Control                = $Right/BtnUltimate/CooldownArc

# Pet & recruit
@onready var pet_icon: TextureRect                = $PetIcon
@onready var btn_send_recruit: Button             = $SendRecruitBtn

# Inventory slide-up panel
@onready var inventory_panel: Control             = $InventoryPanel
# Correct path through InventoryVBox → WeaponRow → WeaponSlot
@onready var weapon_slot: TextureRect             = $InventoryPanel/InventoryVBox/WeaponRow/WeaponSlot
@onready var artifact_slots: Array                = []   # Populated in _ready

# Notification toast
@onready var notification_label: Label            = $NotificationLabel
@onready var notification_timer: Timer            = $NotificationTimer

# Revive prompt (shown on player death)
@onready var revive_panel: Control                = $RevivePanel
# Revive panel children are under RevivePanel/ReviveVBox/
@onready var btn_revive: Button                   = $RevivePanel/ReviveVBox/BtnRevive
@onready var btn_end_run: Button                  = $RevivePanel/ReviveVBox/BtnEndRun
@onready var revive_crystal_count_label: Label    = $RevivePanel/ReviveVBox/CrystalCount

# Scene fade overlay (registered with GameManager)
@onready var fade_overlay: ColorRect              = $FadeOverlay
@onready var fade_anim: AnimationPlayer           = $FadeOverlay/FadeAnim

# Inventory open button
@onready var btn_inventory: Button                = $BtnInventory

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _inventory_open: bool = false
var _player_node: Node = null   # Set by dungeon room after spawning player
var _revive_crystals: int = 0
var _ultimate_fraction: float = 1.0

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
const COLOR_HP_FULL:    Color = Color(0.18, 0.80, 0.18)
const COLOR_HP_MID:     Color = Color(0.90, 0.75, 0.08)
const COLOR_HP_LOW:     Color = Color(0.90, 0.18, 0.08)
const COLOR_RECRUIT_HP: Color = Color(0.20, 0.60, 0.90)

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_connect_event_bus()
	_connect_buttons()
	_populate_artifact_slots()
	_apply_class_colours()
	recruit_hp_bar.visible = false
	recruit_hp_label.visible = false
	btn_send_recruit.visible = false
	btn_stance.visible = false
	btn_rage.visible = false
	revive_panel.visible = false
	inventory_panel.visible = false
	notification_label.modulate.a = 0.0
	# Register fade overlay with GameManager
	GameManager.register_transition_overlay(self)
	# Show NG+ tier if applicable
	var tier: int = GameManager.ng_plus_tier
	ng_plus_label.text = "NG+%d" % tier if tier > 0 else ""
	ng_plus_label.visible = tier > 0
	# Update floor display
	_update_floor(GameManager.current_floor)
	# Update coins from run state
	_refresh_coins()

func _connect_event_bus() -> void:
	EventBus.hud_update_hp.connect(_on_hp_updated)
	EventBus.hud_update_recruit_hp.connect(_on_recruit_hp_updated)
	EventBus.hud_update_coins.connect(_on_coins_updated)
	EventBus.hud_update_floor.connect(_update_floor)
	EventBus.hud_update_combo.connect(_on_combo_updated)
	EventBus.hud_update_ultimate_cooldown.connect(_on_ultimate_cooldown_updated)
	EventBus.rage_bar_changed.connect(_on_rage_bar_changed)
	EventBus.notification_requested.connect(show_notification)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_revived.connect(func(_f): revive_panel.visible = false)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.artifact_equipped.connect(_on_artifact_equipped)
	EventBus.pet_equipped.connect(_on_pet_equipped)
	EventBus.pet_unequipped.connect(func(): pet_icon.visible = false)
	EventBus.recruit_joined_party.connect(func(_r): btn_send_recruit.visible = true)
	EventBus.recruit_left_party.connect(func(_r): btn_send_recruit.visible = false)
	EventBus.revive_crystal_collected.connect(_on_revive_crystal_collected)
	EventBus.floor_changed.connect(_update_floor)

func _connect_buttons() -> void:
	btn_attack.pressed.connect(_on_attack_pressed)
	btn_ability1.pressed.connect(_on_ability1_pressed)
	btn_ability2.pressed.connect(_on_ability2_pressed)
	btn_ultimate.pressed.connect(_on_ultimate_pressed)
	btn_stance.pressed.connect(_on_stance_pressed)
	btn_rage.pressed.connect(_on_rage_pressed)
	btn_send_recruit.pressed.connect(_on_send_recruit_pressed)
	btn_inventory.pressed.connect(_toggle_inventory)
	btn_revive.pressed.connect(_on_revive_pressed)
	btn_end_run.pressed.connect(_on_end_run_pressed)
	notification_timer.timeout.connect(_hide_notification)

func _populate_artifact_slots() -> void:
	artifact_slots.clear()
	# Artifact slots live under InventoryVBox/ArtifactRow
	for i in range(5):
		var slot_node: Node = inventory_panel.find_child("ArtifactSlot%d" % i, true, false)
		if slot_node:
			artifact_slots.append(slot_node)

func _apply_class_colours() -> void:
	## Tint the action buttons with the active class's primary colour.
	var primary: Color = CharacterVisualManager.get_class_primary_color(GameManager.active_class)
	var eye: Color = CharacterVisualManager.get_class_eye_color(GameManager.active_class)
	btn_ultimate.modulate = eye.lerp(Color.WHITE, 0.5)
	hp_bar.modulate = primary.lerp(COLOR_HP_FULL, 0.6)

# ---------------------------------------------------------------------------
# Keyboard Hotkeys (Space for attack, J/K/L for abilities, Tab/I for inventory)
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_on_attack_pressed()
			KEY_J, KEY_1:
				_on_ability1_pressed()
			KEY_K, KEY_2:
				_on_ability2_pressed()
			KEY_L, KEY_3:
				_on_ultimate_pressed()
			KEY_Q:
				_on_stance_pressed()
			KEY_E:
				_on_rage_pressed()
			KEY_TAB, KEY_I:
				_toggle_inventory()

# ---------------------------------------------------------------------------
# Button handlers — emit to EventBus, player listens
# ---------------------------------------------------------------------------
func _on_attack_pressed() -> void:
	var target: Vector2 = _get_aim_target()
	if _player_node and _player_node.has_method("perform_attack"):
		_player_node.perform_attack(target)

func _on_ability1_pressed() -> void:
	var target: Vector2 = _get_aim_target()
	if _player_node and _player_node.has_method("perform_ability_1"):
		_player_node.perform_ability_1(target)

func _on_ability2_pressed() -> void:
	var target: Vector2 = _get_aim_target()
	if _player_node and _player_node.has_method("perform_ability_2"):
		_player_node.perform_ability_2(target)

func _on_ultimate_pressed() -> void:
	if _ultimate_fraction < 1.0:
		show_notification("Ultimate not ready!", Color(0.9, 0.4, 0.1))
		return
	var target: Vector2 = _get_aim_target()
	if _player_node and _player_node.has_method("perform_ultimate"):
		_player_node.perform_ultimate(target)

func _on_stance_pressed() -> void:
	if _player_node and _player_node.has_method("toggle_stance"):
		_player_node.toggle_stance()

func _on_rage_pressed() -> void:
	if _player_node and _player_node.has_method("activate_rage"):
		_player_node.activate_rage()

func _on_send_recruit_pressed() -> void:
	## Find active recruit node and call send_to_base
	var recruits: Array = get_tree().get_nodes_in_group("recruits")
	for recruit in recruits:
		if recruit.has_method("send_to_base"):
			recruit.send_to_base()
			show_notification("Recruit safely sent to base!", Color(0.2, 0.8, 0.2))
			break

func _on_revive_pressed() -> void:
	if _player_node and _player_node.has_method("attempt_revive"):
		var success: bool = _player_node.attempt_revive()
		if not success:
			show_notification("No Revive Crystals!", Color(0.9, 0.2, 0.1))
		else:
			revive_panel.visible = false

func _on_end_run_pressed() -> void:
	revive_panel.visible = false
	GameManager.end_run("death")

# ---------------------------------------------------------------------------
# EventBus response handlers
# ---------------------------------------------------------------------------
func _on_hp_updated(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d" % [int(current), int(maximum)]
	# Colour shift based on HP fraction
	var fraction: float = current / max(maximum, 1.0)
	if fraction > 0.5:
		hp_bar.modulate = COLOR_HP_FULL
	elif fraction > 0.25:
		hp_bar.modulate = COLOR_HP_MID
	else:
		hp_bar.modulate = COLOR_HP_LOW

func _on_recruit_hp_updated(current: float, maximum: float, show: bool) -> void:
	recruit_hp_bar.visible = show
	recruit_hp_label.visible = show
	if show:
		recruit_hp_bar.max_value = maximum
		recruit_hp_bar.value = current
		recruit_hp_label.text = "Recruit: %d / %d" % [int(current), int(maximum)]
		var fraction: float = current / max(maximum, 1.0)
		recruit_hp_bar.modulate = COLOR_RECRUIT_HP if fraction > 0.3 else COLOR_HP_LOW

func _on_coins_updated(copper: int, silver: int, gold: int) -> void:
	copper_label.text = str(copper)
	silver_label.text = str(silver)
	gold_label.text = str(gold)

func _update_floor(floor_num: int) -> void:
	if floor_num == 666:
		floor_label.text = "FLOOR 666"
		floor_label.modulate = Color.RED
	else:
		floor_label.text = "Floor %d" % floor_num
		floor_label.modulate = Color.WHITE

func _on_combo_updated(multiplier: float) -> void:
	if multiplier > 1.05:
		combo_label.text = "x%.1f" % multiplier
		combo_label.visible = true
		# Scale label with combo intensity
		var scale_val: float = 1.0 + min((multiplier - 1.0) * 0.3, 0.6)
		combo_label.scale = Vector2(scale_val, scale_val)
		combo_label.modulate = Color(1.0, min(1.0, multiplier * 0.5), 0.2)
	else:
		combo_label.visible = false

func _on_rage_bar_changed(current: float, maximum: float) -> void:
	rage_bar_node.max_value = maximum
	rage_bar_node.value = current
	rage_bar_node.visible = current > 0.0
	btn_rage.visible = current >= maximum

func _on_ultimate_cooldown_updated(fraction: float) -> void:
	_ultimate_fraction = fraction
	# Draw arc overlay on ultimate button: fraction 0=empty, 1=ready
	ultimate_arc.queue_redraw()
	btn_ultimate.modulate = Color.WHITE if fraction >= 1.0 else Color(0.5, 0.5, 0.5)

func _on_player_died() -> void:
	revive_panel.visible = true
	revive_crystal_count_label.text = "Revive Crystals: %d" % _revive_crystals
	btn_revive.disabled = _revive_crystals <= 0

func _on_weapon_equipped(weapon: Resource) -> void:
	if weapon and weapon.has("icon") and weapon.icon != null:
		weapon_slot.texture = weapon.icon

func _on_artifact_equipped(artifact: Resource, slot: int) -> void:
	if slot < artifact_slots.size() and artifact_slots[slot] != null:
		if artifact and artifact.has("icon") and artifact.icon != null:
			artifact_slots[slot].texture = artifact.icon

func _on_pet_equipped(pet_data: Resource) -> void:
	if pet_data and pet_data.has("sprite") and pet_data.sprite != null:
		pet_icon.texture = pet_data.sprite
	pet_icon.visible = true

func _on_revive_crystal_collected() -> void:
	_revive_crystals += 1
	show_notification("Revive Crystal found! (%d)" % _revive_crystals, Color(0.4, 1.0, 0.6))

# ---------------------------------------------------------------------------
# Inventory panel toggle
# ---------------------------------------------------------------------------
func _toggle_inventory() -> void:
	_inventory_open = !_inventory_open
	var target_y: float = 0.0 if _inventory_open else inventory_panel.size.y
	var tween: Tween = create_tween()
	tween.tween_property(inventory_panel, "position:y",
		inventory_panel.position.y - target_y if _inventory_open else target_y,
		0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	inventory_panel.visible = true

# ---------------------------------------------------------------------------
# Notification toast
# ---------------------------------------------------------------------------
func show_notification(message: String, color: Color = Color.WHITE) -> void:
	notification_label.text = message
	notification_label.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.15)
	notification_timer.start(2.5)

func _hide_notification() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.4)

# ---------------------------------------------------------------------------
# Stance button visibility (shown only for stance-capable classes)
# ---------------------------------------------------------------------------
func set_stance_button_visible(visible_flag: bool) -> void:
	btn_stance.visible = visible_flag

# ---------------------------------------------------------------------------
# Scene transition (called by GameManager)
# ---------------------------------------------------------------------------
func fade_out() -> void:
	fade_anim.play("fade_out")

func fade_in() -> void:
	fade_anim.play("fade_in")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func register_player(player: Node) -> void:
	_player_node = player
	## Show stance button if player's class supports stances
	if player.has_method("toggle_stance"):
		var class_data: ClassData = player.class_controller.active_class_data
		if class_data and class_data.has_stances:
			set_stance_button_visible(true)

func _get_aim_target() -> Vector2:
	## Returns a world-space aim target based on joystick direction,
	## or the player's forward direction if joystick is at rest.
	if _player_node == null:
		return Vector2.ZERO
	var dir: Vector2 = joystick.get_direction()
	if dir.length() > 0.1:
		return _player_node.global_position + dir * 100.0
	# Default: aim in the direction the sprite is facing
	return _player_node.global_position + Vector2(
		-1.0 if _player_node.sprite.flip_h else 1.0, 0.0
	) * 80.0

func _refresh_coins() -> void:
	var display: Dictionary = Globals.coins_to_display(GameManager.run_coins_copper)
	_on_coins_updated(display["copper"], display["silver"], display["gold"])
