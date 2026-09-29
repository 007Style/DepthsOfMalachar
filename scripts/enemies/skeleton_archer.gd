## SkeletonArcher — Dark element ranged attacker firing bone arrows.
## Keeps distance, fires in bursts of 2-3 arrows.

class_name SkeletonArcher
extends EnemyBase

const PREFERRED_RANGE: float = 240.0
const BURST_COUNT: int = 3
const BURST_INTERVAL: float = 0.3

var burst_remaining: int = 0
var burst_timer: float = 0.0

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	_update_burst(delta)
	_run_ai(delta)

func _update_burst(delta: float) -> void:
	if burst_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			_fire_arrow()
			burst_remaining -= 1
			burst_timer = BURST_INTERVAL

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
			if distance < 100.0:
				_strafe_away()
			else:
				nav_agent.target_position = target.global_position
			if distance <= PREFERRED_RANGE and distance > 100.0:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if distance < 100.0:
				_strafe_away()
				ai_state = AIState.CHASE
			elif distance > PREFERRED_RANGE * 1.4:
				ai_state = AIState.CHASE
			elif attack_cooldown_timer <= 0.0 and burst_remaining == 0:
				burst_remaining = BURST_COUNT
				burst_timer = 0.0
				attack_cooldown_timer = enemy_data.attack_cooldown

func _strafe_away() -> void:
	if not target or not is_instance_valid(target):
		return
	var away: Vector2 = (global_position - target.global_position).normalized()
	velocity = away * enemy_data.move_speed * 0.8
	move_and_slide()

func perform_attack() -> void:
	pass  # Handled by burst system

func _fire_arrow() -> void:
	if not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * 0.85
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.DARK)
