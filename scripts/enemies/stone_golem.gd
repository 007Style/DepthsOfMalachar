## StoneGolem — Slow Rock element tank with shockwave stomp attack.
## Massive HP, slow movement. Area stomp AoE at close range.

class_name StoneGolem
extends EnemyBase

const STOMP_RANGE: float = 100.0
const STOMP_DAMAGE_MULTIPLIER: float = 2.0
const STOMP_STUN_DURATION: float = 1.5
const STOMP_COOLDOWN: float = 4.0

var stomp_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if stomp_cooldown_timer > 0.0:
		stomp_cooldown_timer -= delta
	_run_ai(delta)

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			if distance < 350.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			# Stomp if really close
			if distance <= STOMP_RANGE and stomp_cooldown_timer <= 0.0:
				_perform_stomp()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _perform_stomp() -> void:
	stomp_cooldown_timer = STOMP_COOLDOWN
	if animation_player.has_animation("stomp"):
		animation_player.play("stomp")
	# Area damage — hit all players/recruits in radius
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= STOMP_RANGE:
			if body.has_method("take_damage"):
				var dmg: float = enemy_data.base_damage * STOMP_DAMAGE_MULTIPLIER
				dmg = Globals.scale_damage(dmg, floor_num)
				body.take_damage(dmg, Globals.ElementType.ROCK)
	# Signal for screen shake
	EventBus.enemy_stomp.emit(global_position, STOMP_RANGE)
