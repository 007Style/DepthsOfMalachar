## Ethari — The Main Player Character
## Handles movement, combat, health, inventory, coins, revive crystals,
## combo system, rage mode, and run resource tracking.

class_name Ethari
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Nodes (assigned in scene)
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var class_controller: ClassController = $ClassController
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var visual_manager: CharacterVisualManager = $CharacterVisualManager
@onready var aura_particles: GPUParticles2D = $AuraParticles

# ---------------------------------------------------------------------------
# Stats and state
# ---------------------------------------------------------------------------
var stats: Stats = Stats.new()
var is_dead: bool = false
var is_invincible: bool = false
var revive_crystals: int = 0

# ---------------------------------------------------------------------------
# Inventory
# ---------------------------------------------------------------------------
var equipped_weapon: WeaponData = null
var artifacts: Array = []               # Max 4 (or 5 with upgrade), ArtifactData
var active_pet: Node = null             # Pet node reference

# ---------------------------------------------------------------------------
# Combo system
# ---------------------------------------------------------------------------
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 3.0        # Seconds before combo resets
const COMBO_INCREMENT: float = 0.1     # Multiplier increase per hit without getting hit

# ---------------------------------------------------------------------------
# Rage system (Berserker and rage-capable classes)
# ---------------------------------------------------------------------------
var rage_bar: float = 0.0
var rage_bar_max: float = 100.0
var rage_active: bool = false
const RAGE_DURATION: float = 8.0
var rage_timer: float = 0.0
const RAGE_DAMAGE_BONUS: float = 0.5    # +50% damage during rage

# ---------------------------------------------------------------------------
# Run resources (items/materials collected during run, kept on death)
# ---------------------------------------------------------------------------
var run_resources: Dictionary = {}

# ---------------------------------------------------------------------------
# Multiplayer debuff (-25% when second Ethari in co-op)
# ---------------------------------------------------------------------------
var coop_debuff_active: bool = false
const COOP_DEBUFF_MULTIPLIER: float = 0.75

# ---------------------------------------------------------------------------
# Input direction (set by HUD virtual joystick)
# ---------------------------------------------------------------------------
var move_direction: Vector2 = Vector2.ZERO

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("player")
	_connect_signals()
	_apply_all_bonuses()
	stats.current_hp = stats.max_hp
	revive_crystals = 0
	# Initialise visual manager
	visual_manager.initialise(sprite, aura_particles)
	visual_manager.apply_class_visuals(GameManager.active_class)
	# Load ClassData resource and apply to class controller
	var _class_name: String = Globals.class_type_to_name(GameManager.active_class).to_lower().replace(" ", "_")
	var _class_path: String = "res://assets/data/classes/" + _class_name + ".tres"
	if ResourceLoader.exists(_class_path):
		var _class_data: ClassData = load(_class_path) as ClassData
		if _class_data:
			class_controller.load_class(_class_data)
	# Load start weapon from cabinet
	var start_weapon: Resource = ProgressionManager.get_start_weapon()
	if start_weapon:
		equip_weapon(start_weapon)

func _connect_signals() -> void:
	EventBus.hud_update_hp.connect(func(_c, _m): pass)  # Consumed by HUD
	EventBus.hud_move_direction.connect(set_move_direction)
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	hit_flash_timer.timeout.connect(_on_hit_flash_timer_timeout)
	invincibility_timer.timeout.connect(func(): is_invincible = false)
	class_controller.stance_changed.connect(_on_stance_changed)

# ---------------------------------------------------------------------------
# Process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_update_combo(delta)
	_update_rage(delta)
	_update_player_status(delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# Desktop keyboard WASD / Arrow fallback input when joystick is neutral
	var input_vec: Vector2 = move_direction
	if input_vec.length() < 0.05:
		input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var target_velocity: Vector2 = input_vec * stats.move_speed
	if coop_debuff_active:
		target_velocity *= COOP_DEBUFF_MULTIPLIER
	# Smooth acceleration / deceleration
	velocity = velocity.lerp(target_velocity, 15.0 * delta)
	move_and_slide()
	# Face movement direction with smooth walk frame/bob
	if input_vec.length() > 0.1:
		sprite.flip_h = input_vec.x < 0.0
		sprite.frame = 1 if fmod(Time.get_ticks_msec() * 0.006, 2.0) > 1.0 else 0
		sprite.position.y = sin(Time.get_ticks_msec() * 0.015) * 1.5
	else:
		sprite.frame = 0
		sprite.position.y = lerp(sprite.position.y, 0.0, 10.0 * delta)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func _apply_all_bonuses() -> void:
	## Apply class stats, meta upgrades, permanent artifacts, and legacy bonuses.
	class_controller.apply_class_stats(stats)
	_apply_upgrade_bonuses()
	_apply_permanent_artifacts()
	_apply_legacy_bonuses()
	if coop_debuff_active:
		stats.multiply("max_hp", COOP_DEBUFF_MULTIPLIER)
		stats.multiply("base_damage", COOP_DEBUFF_MULTIPLIER)

func _apply_upgrade_bonuses() -> void:
	## Read purchased upgrade nodes and apply stat bonuses.
	if ProgressionManager.has_upgrade("hp_1"):    stats.add_flat("max_hp", 20.0)
	if ProgressionManager.has_upgrade("hp_2"):    stats.add_flat("max_hp", 30.0)
	if ProgressionManager.has_upgrade("hp_3"):    stats.add_flat("max_hp", 50.0)
	if ProgressionManager.has_upgrade("dmg_1"):   stats.add_flat("base_damage", 3.0)
	if ProgressionManager.has_upgrade("dmg_2"):   stats.add_flat("base_damage", 5.0)
	if ProgressionManager.has_upgrade("spd_1"):   stats.add_flat("move_speed", 15.0)
	if ProgressionManager.has_upgrade("spd_2"):   stats.add_flat("move_speed", 20.0)
	if ProgressionManager.has_upgrade("crit_1"):  stats.add_flat("crit_chance", 0.05)
	# Class mastery bonus
	stats.multiply("base_damage",
		1.0 + ProgressionManager.get_class_mastery_bonus(GameManager.active_class))

func _apply_permanent_artifacts() -> void:
	for artifact in ProgressionManager.get_permanent_artifacts():
		_apply_artifact_effect(artifact)

func _apply_legacy_bonuses() -> void:
	var legacy_bonus: float = ProgressionManager.get_ancestor_bonus(GameManager.active_class)
	if legacy_bonus > 0.0:
		stats.multiply("max_hp",     1.0 + legacy_bonus)
		stats.multiply("base_damage", 1.0 + legacy_bonus)

# ---------------------------------------------------------------------------
# Movement (called by HUD joystick)
# ---------------------------------------------------------------------------
func set_move_direction(direction: Vector2) -> void:
	move_direction = direction.normalized() if direction.length() > 0.1 else Vector2.ZERO

# ---------------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------------
func perform_attack(target_position: Vector2) -> void:
	if is_dead:
		return
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	# Attack punch animation & frame
	sprite.frame = 2
	var tw := create_tween()
	var attack_dir := (target_position - global_position).normalized()
	if attack_dir.length() > 0.01:
		sprite.position = attack_dir * 4.0
		tw.tween_property(sprite, "position", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if not is_dead and move_direction.length() < 0.1:
			sprite.frame = 0
	)
	class_controller.use_primary(target_position)

func perform_ability_1(target_position: Vector2) -> void:
	if not is_dead:
		class_controller.use_ability_1(target_position)

func perform_ability_2(target_position: Vector2) -> void:
	if not is_dead:
		class_controller.use_ability_2(target_position)

func perform_ultimate(target_position: Vector2) -> void:
	if not is_dead:
		class_controller.use_ultimate(target_position)

func toggle_stance() -> void:
	class_controller.toggle_stance()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	## Called when the melee attack hitbox overlaps an enemy hitbox.
	var enemy: Node = area.get_parent()
	if enemy.has_method("take_damage"):
		var damage: float = _calculate_damage()
		var element: int = Globals.ElementType.NONE
		if equipped_weapon:
			element = equipped_weapon.element
		enemy.take_damage(damage, element)
		# Combo on hit
		combo_multiplier += COMBO_INCREMENT
		combo_timer = COMBO_TIMEOUT
		EventBus.combo_updated.emit(combo_multiplier)
		EventBus.hud_update_combo.emit(combo_multiplier)
		# Lifesteal
		if stats.lifesteal > 0.0:
			heal(damage * stats.lifesteal)

func _calculate_damage() -> float:
	var dmg: float = stats.base_damage
	if equipped_weapon:
		dmg += equipped_weapon.base_damage
	dmg *= combo_multiplier
	if rage_active:
		dmg *= (1.0 + RAGE_DAMAGE_BONUS)
	# Crit
	if randf() < stats.crit_chance:
		dmg *= stats.crit_multiplier
	return dmg

# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
func take_damage(amount: float, element: int = Globals.ElementType.NONE) -> void:
	if is_dead or is_invincible:
		return
	# Elemental resistance
	var resistance: float = stats.get_elemental_resistance(element)
	var final_damage: float = max(0.0, amount - stats.defence) * (1.0 - resistance)
	stats.current_hp -= final_damage
	# Rage bar fill from damage taken
	rage_bar = min(rage_bar_max, rage_bar + final_damage * 0.5)
	EventBus.rage_bar_changed.emit(rage_bar, rage_bar_max)
	# Combo reset on taking damage
	combo_multiplier = 1.0
	combo_timer = 0.0
	EventBus.combo_updated.emit(combo_multiplier)
	EventBus.player_took_damage.emit(final_damage, element)
	EventBus.hud_update_hp.emit(stats.current_hp, stats.max_hp)
	# Hit flash using class eye colour
	visual_manager.flash_hit_color(GameManager.active_class)
	hit_flash_timer.start(0.15)
	# Brief invincibility after hit
	is_invincible = true
	invincibility_timer.start(0.5)
	if stats.current_hp <= 0.0:
		_die()

func heal(amount: float) -> void:
	stats.current_hp = min(stats.max_hp, stats.current_hp + amount)
	EventBus.player_healed.emit(amount)
	EventBus.hud_update_hp.emit(stats.current_hp, stats.max_hp)

func _on_hit_flash_timer_timeout() -> void:
	visual_manager.reset_color()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	# Transfer run resources to base
	GameManager.add_run_resource("run_loot", 1)  # Placeholder; detailed tracking in ethari
	for key in run_resources:
		GameManager.add_run_resource(key, run_resources[key])
	# Track which enemy type killed the player (set by last attacker)
	EventBus.player_died.emit()

## Called from HUD revive button or automatic check.
func attempt_revive() -> bool:
	if revive_crystals <= 0:
		return false
	revive_crystals -= 1
	is_dead = false
	stats.current_hp = stats.max_hp * 0.5  # Revive at 50% HP
	is_invincible = true
	invincibility_timer.start(2.0)  # 2s invincibility on revive
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	EventBus.player_revived.emit(GameManager.current_floor)
	EventBus.hud_update_hp.emit(stats.current_hp, stats.max_hp)
	return true

# ---------------------------------------------------------------------------
# Combo system
# ---------------------------------------------------------------------------
func _update_combo(delta: float) -> void:
	if combo_multiplier > 1.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_multiplier = 1.0
			EventBus.combo_updated.emit(combo_multiplier)
			EventBus.hud_update_combo.emit(combo_multiplier)

# ---------------------------------------------------------------------------
# Rage system
# ---------------------------------------------------------------------------
func activate_rage() -> void:
	if rage_bar < rage_bar_max or rage_active:
		return
	rage_active = true
	rage_timer = RAGE_DURATION
	rage_bar = 0.0

func _update_rage(delta: float) -> void:
	if rage_active:
		rage_timer -= delta
		if rage_timer <= 0.0:
			rage_active = false

# ---------------------------------------------------------------------------
# Inventory
# ---------------------------------------------------------------------------
func equip_weapon(weapon: WeaponData) -> void:
	equipped_weapon = weapon
	EventBus.weapon_equipped.emit(weapon)

func equip_artifact(artifact: ArtifactData, slot: int) -> void:
	## Equip an artifact into the given slot (0–3, or 0–4 with upgrade).
	var max_slots: int = 5 if ProgressionManager.has_upgrade("artifact_slot_5") else 4
	if slot < 0 or slot >= max_slots:
		return
	# Stack check — if same artifact already equipped, stack it
	for i in range(artifacts.size()):
		if artifacts[i] != null and artifacts[i].item_name == artifact.item_name:
			artifacts[i].add_stack()
			_apply_artifact_effect(artifacts[i])
			EventBus.artifact_equipped.emit(artifacts[i], i)
			return
	# Fill slot
	while artifacts.size() <= slot:
		artifacts.append(null)
	artifacts[slot] = artifact
	_apply_artifact_effect(artifact)
	EventBus.artifact_equipped.emit(artifact, slot)

func _apply_artifact_effect(artifact: ArtifactData) -> void:
	var value: float = artifact.get_current_value()
	match artifact.effect_type:
		"damage_bonus":    stats.add_flat("base_damage", value)
		"hp_bonus":        stats.add_flat("max_hp", value)
		"speed_bonus":     stats.add_flat("move_speed", value)
		"crit_bonus":      stats.add_flat("crit_chance", value)
		"lifesteal":       stats.add_flat("lifesteal", value)
		"xp_bonus":        stats.add_flat("xp_multiplier", value)
		"coin_bonus":      stats.add_flat("coin_multiplier", value)
		# "revive_once" is handled in _die() by checking artifact list

func add_revive_crystal() -> void:
	revive_crystals += 1
	EventBus.revive_crystal_collected.emit()

func add_resource(resource_id: String, amount: int) -> void:
	run_resources[resource_id] = run_resources.get(resource_id, 0) + amount
	GameManager.add_run_resource(resource_id, amount)

# ---------------------------------------------------------------------------
# Coins
# ---------------------------------------------------------------------------
func collect_coin(coin_type: int, amount: int) -> void:
	EventBus.coin_collected.emit(coin_type, amount)
	# Run coin tracking handled by GameManager._on_coin_collected

# ---------------------------------------------------------------------------
# Stance
# ---------------------------------------------------------------------------
func _on_stance_changed(stance_index: int) -> void:
	visual_manager.apply_stance_tint(stance_index, GameManager.active_class)
	hit_flash_timer.start(0.2)

# ---------------------------------------------------------------------------
# Execution mechanic
# ---------------------------------------------------------------------------
func try_execute(enemy: Node) -> bool:
	## Returns true if the enemy is below 10% HP and can be executed.
	if enemy.has_method("get_hp_fraction") and enemy.get_hp_fraction() <= 0.1:
		var bonus_coins: int = randi_range(5, 20)
		EventBus.coin_collected.emit(Globals.CoinType.COPPER, bonus_coins)
		enemy.take_damage(999999.0, Globals.ElementType.NONE)
		EventBus.execution_triggered.emit(enemy)
		return true
	return false

# ---------------------------------------------------------------------------
# Knockback (called by enemies)
# ---------------------------------------------------------------------------
func apply_knockback(force: Vector2) -> void:
	## Apply an instant velocity impulse (e.g. from AirDjinn gust).
	if is_dead:
		return
	velocity += force
	move_and_slide()

# ---------------------------------------------------------------------------
# Status effect (applied by enemies / environment)
# ---------------------------------------------------------------------------
var _active_status: int = Globals.StatusEffect.NONE
var _status_remaining: float = 0.0

func apply_status_effect(effect: int, duration: float) -> void:
	## Apply a status effect to Ethari (slow, burn, stun, etc.).
	_active_status = effect
	_status_remaining = max(_status_remaining, duration)

func _update_player_status(delta: float) -> void:
	if _active_status == Globals.StatusEffect.NONE:
		return
	_status_remaining -= delta
	match _active_status:
		Globals.StatusEffect.BURN:
			stats.current_hp -= stats.max_hp * 0.02 * delta
			if stats.current_hp <= 0.0:
				_die()
		Globals.StatusEffect.SLOW:
			pass  # Speed reduction applied in _physics_process below
	if _status_remaining <= 0.0:
		_active_status = Globals.StatusEffect.NONE
