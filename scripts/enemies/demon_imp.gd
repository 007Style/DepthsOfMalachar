## DemonImp — Fast erratic Fire element swarmer.
## Moves unpredictably, attacks in bursts, deals fire damage.
## Very fast but low HP.

class_name DemonImp
extends EnemyBase

const ERRATIC_CHANGE_INTERVAL_MIN: float = 0.3
const ERRATIC_CHANGE_INTERVAL_MAX: float = 0.9
const DASH_SPEED_MULTIPLIER: float = 2.5

var erratic_timer: float = 0.0
var erratic_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	_randomise_erratic()

func _run_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	erratic_timer -= delta
	if erratic_timer <= 0.0:
		_randomise_erratic()

	match ai_state:
		AIState.IDLE:
			if distance < 380.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			# Erratic movement — steer toward player + random offset
			var base_dir: Vector2 = (target.global_position + erratic_offset - global_position).normalized()
			var spd: float = enemy_data.move_speed * DASH_SPEED_MULTIPLIER
			if active_status in [Globals.StatusEffect.SLOW, Globals.StatusEffect.FREEZE]:
				spd *= 0.4
			velocity = base_dir * spd
			move_and_slide()
			sprite.flip_h = velocity.x < 0.0
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown * 0.6  # Fast attacks
			if distance > enemy_data.attack_range * 2.0:
				ai_state = AIState.CHASE

func _randomise_erratic() -> void:
	erratic_offset = Vector2(
		randf_range(-80.0, 80.0),
		randf_range(-80.0, 80.0)
	)
	erratic_timer = randf_range(ERRATIC_CHANGE_INTERVAL_MIN, ERRATIC_CHANGE_INTERVAL_MAX)
