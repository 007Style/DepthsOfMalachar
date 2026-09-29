## EnemyBase — Base class for all enemies.
## Handles HP, element, AI state machine, status effects, scaling, drops, evolution.

class_name EnemyBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal died(enemy_node: Node, position: Vector2)
signal took_damage(enemy_node: Node, amount: float)

# ---------------------------------------------------------------------------
# Nodes (assigned in scene)
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var status_timer: Timer = $StatusTimer
@onready var weak_point: Node2D = $WeakPoint  # Optional — enabled if has_weak_point
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------
@export var enemy_data: EnemyData = null

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var current_hp: float = 0.0
var max_hp: float = 0.0
var is_dead: bool = false
var floor_num: int = 1
var target: Node = null  # The player or player proxy
var active_status: int = Globals.StatusEffect.NONE
var status_duration: float = 0.0
var current_element_applied: int = Globals.ElementType.NONE  # Last element applied by attacker

# AI state machine
enum AIState { IDLE, CHASE, ATTACK, STUNNED, DEAD }
var ai_state: int = AIState.IDLE
var attack_cooldown_timer: float = 0.0

# Evolution tier bonuses
var evolution_tier: int = 0
const EVOLUTION_HP_BONUS: float = 0.2      # +20% HP per evolution tier
const EVOLUTION_DMG_BONUS: float = 0.15    # +15% damage per evolution tier
const EVOLUTION_SPEED_BONUS: float = 0.1   # +10% speed per evolution tier

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("enemies")
	if enemy_data:
		_initialise_from_data()
	hit_flash_timer.timeout.connect(func(): sprite.modulate = Color.WHITE)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Disable weak point if not applicable
	if weak_point and (not enemy_data or not enemy_data.has_weak_point):
		weak_point.hide()

func _initialise_from_data() -> void:
	evolution_tier = ProgressionManager.get_enemy_evolution_tier(enemy_data.enemy_id)
	max_hp = enemy_data.get_scaled_hp(floor_num)
	max_hp *= (1.0 + evolution_tier * EVOLUTION_HP_BONUS)
	current_hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func setup(data: EnemyData, floor_number: int, player_node: Node) -> void:
	enemy_data = data
	floor_num = floor_number
	target = player_node
	_initialise_from_data()

# ---------------------------------------------------------------------------
# Process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	_run_ai(delta)

func _physics_process(_delta: float) -> void:
	if is_dead or ai_state == AIState.STUNNED or ai_state == AIState.IDLE:
		return
	if ai_state == AIState.CHASE and nav_agent.is_navigation_finished() == false:
		var direction: Vector2 = nav_agent.get_next_path_position() - global_position
		direction = direction.normalized()
		var speed: float = enemy_data.move_speed * (1.0 + evolution_tier * EVOLUTION_SPEED_BONUS)
		if active_status == Globals.StatusEffect.SLOW or active_status == Globals.StatusEffect.FREEZE:
			speed *= 0.4
		velocity = direction * speed
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0

# ---------------------------------------------------------------------------
# AI State Machine
# ---------------------------------------------------------------------------
func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			if distance < 400.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _update_attack_cooldown(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

## Override in subclasses for unique attack behaviour.
func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	if target.has_method("take_damage"):
		var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
		dmg = Globals.scale_damage(dmg, floor_num)
		target.take_damage(dmg, enemy_data.element)

func _on_attack_area_body_entered(body: Node) -> void:
	## For melee enemies, deal damage when body enters attack area.
	if body.has_method("take_damage") and body != self:
		perform_attack()

# ---------------------------------------------------------------------------
# Damage & Health
# ---------------------------------------------------------------------------
func take_damage(amount: float, attacker_element: int = Globals.ElementType.NONE) -> void:
	if is_dead:
		return
	# Elemental modifier
	var multiplier: float = Globals.get_elemental_multiplier(enemy_data.element, attacker_element)
	var final_damage: float = amount * multiplier
	# Weak point check (handled by caller passing weak_point_hit = true)
	current_hp -= final_damage
	if health_bar:
		health_bar.value = current_hp
	# Check elemental reaction
	var reaction: int = Globals.check_elemental_reaction(current_element_applied, attacker_element)
	if reaction != Globals.StatusEffect.NONE:
		_apply_status(reaction, 3.0)
		EventBus.elemental_reaction_triggered.emit(reaction, global_position)
	current_element_applied = attacker_element
	# Status from element
	match attacker_element:
		Globals.ElementType.FIRE:      _apply_status(Globals.StatusEffect.BURN, 3.0)
		Globals.ElementType.ICE:       _apply_status(Globals.StatusEffect.SLOW, 3.0)
		Globals.ElementType.LIGHTNING: _apply_status(Globals.StatusEffect.STUN, 1.0)
		Globals.ElementType.POISON:    _apply_status(Globals.StatusEffect.POISON, 5.0)
		Globals.ElementType.DARK:      _apply_status(Globals.StatusEffect.CURSE, 4.0)
	# Hit flash
	sprite.modulate = Color.RED
	hit_flash_timer.start(0.12)
	EventBus.enemy_took_damage.emit(self, final_damage)
	took_damage.emit(self, final_damage)
	if current_hp <= 0.0:
		_die()

func take_weak_point_damage(amount: float, attacker_element: int) -> void:
	take_damage(amount * enemy_data.weak_point_multiplier, attacker_element)

func get_hp_fraction() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	ai_state = AIState.DEAD
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	# Record kill for evolution tracking
	if enemy_data:
		ProgressionManager.record_enemy_kill(enemy_data.enemy_id)
	# Award XP to player
	if enemy_data:
		var xp: int = enemy_data.xp_reward
		GameManager.add_run_xp(xp)
		ProgressionManager.increment_achievement_progress("enemies_killed")
	# Drop loot and coins
	_spawn_drops()
	EventBus.enemy_died.emit(self, global_position)
	died.emit(self, global_position)
	# Wait for death animation then remove
	if animation_player and animation_player.is_playing():
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout
	queue_free()

func _spawn_drops() -> void:
	if not enemy_data:
		return
	# Coin drop
	var coin_amount: int = randi_range(enemy_data.coin_drop_min, enemy_data.coin_drop_max)
	EventBus.coin_collected.emit(enemy_data.coin_type, coin_amount)
	# Item drop
	if enemy_data.loot_table:
		var item: Resource = enemy_data.loot_table.roll_item(floor_num)
		if item:
			_spawn_loot_pickup(item)
	# Revive crystal rare drop
	if randf() < enemy_data.revive_crystal_drop_chance:
		EventBus.revive_crystal_collected.emit()

func _spawn_loot_pickup(item: Resource) -> void:
	## Instantiate a Loot pickup at the enemy's position.
	var loot_scene: PackedScene = load("res://scenes/items/Loot.tscn")
	if loot_scene:
		var loot: Node = loot_scene.instantiate()
		get_parent().add_child(loot)
		loot.global_position = global_position
		if loot.has_method("setup"):
			loot.setup(item)

# ---------------------------------------------------------------------------
# Status Effects
# ---------------------------------------------------------------------------
func _apply_status(effect: int, duration: float) -> void:
	active_status = effect
	status_duration = duration
	EventBus.status_effect_applied.emit(self, effect, duration)

func _update_status_effect(delta: float) -> void:
	if active_status == Globals.StatusEffect.NONE:
		return
	status_duration -= delta
	match active_status:
		Globals.StatusEffect.BURN:
			current_hp -= enemy_data.base_damage * 0.1 * delta  # 10% dmg/sec
			if health_bar: health_bar.value = current_hp
			if current_hp <= 0.0: _die()
		Globals.StatusEffect.STUN:
			ai_state = AIState.STUNNED
		Globals.StatusEffect.FREEZE:
			ai_state = AIState.STUNNED
		Globals.StatusEffect.POISON:
			current_hp -= enemy_data.base_damage * 0.05 * delta  # 5% dmg/sec
			if health_bar: health_bar.value = current_hp
			if current_hp <= 0.0: _die()
		Globals.StatusEffect.CHARM:
			# Charmed enemies attack each other — target swapped in _run_ai
			pass
	if status_duration <= 0.0:
		active_status = Globals.StatusEffect.NONE
		if ai_state == AIState.STUNNED:
			ai_state = AIState.CHASE
