## AirDjinn — Air element aerial. Pushes player back with gusts, tornado spin AoE.
## Aerial — only hittable by ranged attacks. Stays airborne, pushes player.

class_name AirDjinn
extends EnemyBase

const GUST_RANGE: float = 200.0
const GUST_PUSH_FORCE: float = 300.0
const GUST_COOLDOWN: float = 2.5
const TORNADO_RANGE: float = 120.0
const TORNADO_COOLDOWN: float = 5.0
const TORNADO_DAMAGE_MULTIPLIER: float = 1.8
const TORNADO_RADIUS: float = 80.0

var gust_cooldown_timer: float = 0.0
var tornado_cooldown_timer: float = 0.0
var drift_angle: float = 0.0

func _ready() -> void:
	super._ready()
	drift_angle = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if gust_cooldown_timer > 0.0:
		gust_cooldown_timer -= delta
	if tornado_cooldown_timer > 0.0:
		tornado_cooldown_timer -= delta
	_run_ai(delta)

func _physics_process(delta: float) -> void:
	if is_dead or ai_state == AIState.STUNNED or ai_state == AIState.IDLE:
		return
	if target and is_instance_valid(target):
		drift_angle += delta * 0.8
		var drift_offset: Vector2 = Vector2(cos(drift_angle) * 120.0, sin(drift_angle) * 60.0 - 30.0)
		var desired: Vector2 = target.global_position + drift_offset
		var dir: Vector2 = (desired - global_position).normalized()
		var dist: float = global_position.distance_to(desired)
		velocity = dir * min(dist * 2.0, enemy_data.move_speed)
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			if distance < 400.0:
				ai_state = AIState.CHASE
		AIState.CHASE, AIState.ATTACK:
			if distance <= GUST_RANGE and gust_cooldown_timer <= 0.0:
				_perform_gust()
			if distance <= TORNADO_RANGE and tornado_cooldown_timer <= 0.0:
				_perform_tornado()

func _perform_gust() -> void:
	if not target or not is_instance_valid(target):
		return
	gust_cooldown_timer = GUST_COOLDOWN
	# Push the player away
	if target.has_method("apply_knockback"):
		var push_dir: Vector2 = (target.global_position - global_position).normalized()
		target.apply_knockback(push_dir * GUST_PUSH_FORCE)
	if animation_player.has_animation("gust"):
		animation_player.play("gust")

func _perform_tornado() -> void:
	tornado_cooldown_timer = TORNADO_COOLDOWN
	if animation_player.has_animation("tornado"):
		animation_player.play("tornado")
	# AoE spin damage
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= TORNADO_RADIUS:
			if body.has_method("take_damage"):
				var dmg: float = enemy_data.base_damage * TORNADO_DAMAGE_MULTIPLIER
				dmg = Globals.scale_damage(dmg, floor_num)
				body.take_damage(dmg, Globals.ElementType.AIR)
			if body.has_method("apply_knockback"):
				var push_dir: Vector2 = (body.global_position - global_position).normalized()
				body.apply_knockback(push_dir * GUST_PUSH_FORCE * 0.6)
	EventBus.enemy_stomp.emit(global_position, TORNADO_RADIUS)
