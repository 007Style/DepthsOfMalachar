## BloodBat — LifeSteal aerial enemy. Heals itself from damage dealt to player.
## Aerial — only hittable by ranged attacks. Swoops in then flees.

class_name BloodBat
extends EnemyBase

const SWOOP_SPEED_MULTIPLIER: float = 3.0
const SWOOP_COOLDOWN: float = 3.0
const HEAL_FRACTION: float = 0.4   # Heals 40% of damage dealt
const RETREAT_RANGE: float = 180.0

var is_swooping: bool = false
var swoop_target_pos: Vector2 = Vector2.ZERO
var swoop_cooldown_timer: float = 0.0
var float_angle: float = 0.0

func _ready() -> void:
	super._ready()
	float_angle = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if swoop_cooldown_timer > 0.0:
		swoop_cooldown_timer -= delta
	_run_ai(delta)

func _physics_process(delta: float) -> void:
	if is_dead or ai_state == AIState.STUNNED or ai_state == AIState.IDLE:
		return
	if is_swooping:
		var dir: Vector2 = (swoop_target_pos - global_position).normalized()
		velocity = dir * enemy_data.move_speed * SWOOP_SPEED_MULTIPLIER
		move_and_slide()
		if global_position.distance_to(swoop_target_pos) < 24.0:
			_complete_swoop()
	else:
		# Hovering float pattern above player
		if target and is_instance_valid(target):
			float_angle += delta * 1.2
			var hover_offset: Vector2 = Vector2(cos(float_angle) * 80.0, sin(float_angle) * 40.0 - 40.0)
			var desired: Vector2 = target.global_position + hover_offset
			var dir: Vector2 = (desired - global_position).normalized()
			var dist_to_desired: float = global_position.distance_to(desired)
			velocity = dir * min(dist_to_desired * 2.0, enemy_data.move_speed)
			move_and_slide()
			sprite.flip_h = velocity.x < 0.0

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	if is_swooping:
		return
	match ai_state:
		AIState.IDLE:
			if distance < 420.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			if distance <= 220.0 and swoop_cooldown_timer <= 0.0:
				_start_swoop()
		AIState.ATTACK:
			pass  # Handled by swoop

func _start_swoop() -> void:
	if not target or not is_instance_valid(target):
		return
	is_swooping = true
	swoop_cooldown_timer = SWOOP_COOLDOWN
	swoop_target_pos = target.global_position

func _complete_swoop() -> void:
	is_swooping = false
	ai_state = AIState.CHASE
	# Deal damage and heal
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
		dmg = Globals.scale_damage(dmg, floor_num)
		target.take_damage(dmg, Globals.ElementType.LIFE_STEAL)
		# Heal self
		var heal_amount: float = dmg * HEAL_FRACTION
		current_hp = min(current_hp + heal_amount, max_hp)
		if health_bar:
			health_bar.value = current_hp
