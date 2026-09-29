## ThunderHawk — Lightning aerial enemy. Dive bombs player, area shock on impact.
## Only hittable by ranged or jump attacks (aerial flag set in EnemyData).

class_name ThunderHawk
extends EnemyBase

const DIVE_RANGE: float = 300.0
const DIVE_SPEED_MULTIPLIER: float = 4.0
const DIVE_DAMAGE_MULTIPLIER: float = 2.2
const DIVE_COOLDOWN: float = 3.5
const SHOCK_RADIUS: float = 90.0
const CIRCLE_RADIUS: float = 160.0
const CIRCLE_SPEED: float = 110.0

var is_diving: bool = false
var dive_target_pos: Vector2 = Vector2.ZERO
var dive_cooldown_timer: float = 0.0
var circle_angle: float = 0.0

func _ready() -> void:
	super._ready()
	circle_angle = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if dive_cooldown_timer > 0.0:
		dive_cooldown_timer -= delta
	_run_ai(delta)

func _physics_process(delta: float) -> void:
	if is_dead or ai_state == AIState.STUNNED or ai_state == AIState.IDLE:
		return
	if is_diving:
		var dir: Vector2 = (dive_target_pos - global_position).normalized()
		velocity = dir * enemy_data.move_speed * DIVE_SPEED_MULTIPLIER
		move_and_slide()
		if global_position.distance_to(dive_target_pos) < 20.0:
			_complete_dive()
	elif ai_state == AIState.CHASE and target and is_instance_valid(target):
		# Circle above the player
		circle_angle += delta * (CIRCLE_SPEED / CIRCLE_RADIUS)
		var circle_center: Vector2 = target.global_position
		var desired_pos: Vector2 = circle_center + Vector2(cos(circle_angle), sin(circle_angle)) * CIRCLE_RADIUS
		var dir: Vector2 = (desired_pos - global_position).normalized()
		velocity = dir * enemy_data.move_speed
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	if is_diving:
		return
	match ai_state:
		AIState.IDLE:
			if distance < 450.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			if distance <= DIVE_RANGE and dive_cooldown_timer <= 0.0:
				_start_dive()
		AIState.ATTACK:
			pass  # handled by diving

func _start_dive() -> void:
	if not target or not is_instance_valid(target):
		return
	is_diving = true
	dive_cooldown_timer = DIVE_COOLDOWN
	dive_target_pos = target.global_position
	if animation_player.has_animation("dive"):
		animation_player.play("dive")

func _complete_dive() -> void:
	is_diving = false
	ai_state = AIState.CHASE
	# Shock AoE
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= SHOCK_RADIUS:
			if body.has_method("take_damage"):
				var dmg: float = enemy_data.base_damage * DIVE_DAMAGE_MULTIPLIER
				dmg = Globals.scale_damage(dmg, floor_num)
				body.take_damage(dmg, Globals.ElementType.LIGHTNING)
	EventBus.enemy_stomp.emit(global_position, SHOCK_RADIUS)
