## OrcGrunt — Melee charger with Steel element.
## Enters a charge state at medium range, dealing bonus damage on impact.

class_name OrcGrunt
extends EnemyBase

const CHARGE_RANGE: float = 200.0
const CHARGE_SPEED_MULTIPLIER: float = 3.0
const CHARGE_DAMAGE_MULTIPLIER: float = 1.8
const CHARGE_DURATION: float = 0.5

var is_charging: bool = false
var charge_timer: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()

func _run_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)

	# Handle active charge
	if is_charging:
		charge_timer -= delta
		if charge_timer <= 0.0:
			is_charging = false
			velocity = Vector2.ZERO
		return

	match ai_state:
		AIState.IDLE:
			if distance < 450.0:
				ai_state = AIState.CHASE
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			# Initiate charge at mid-range
			if distance < CHARGE_RANGE and attack_cooldown_timer <= 0.0:
				_start_charge()
			elif distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _physics_process(delta: float) -> void:
	if is_dead or ai_state == AIState.STUNNED or ai_state == AIState.IDLE:
		return
	if is_charging:
		velocity = charge_direction * enemy_data.move_speed * CHARGE_SPEED_MULTIPLIER
		move_and_slide()
		# Charge hit detection
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			var collider := col.get_collider()
			if collider and collider.has_method("take_damage") and collider != self:
				var dmg: float = enemy_data.base_damage * CHARGE_DAMAGE_MULTIPLIER
				dmg = Globals.scale_damage(dmg, floor_num)
				collider.take_damage(dmg, enemy_data.element)
				is_charging = false
	elif ai_state == AIState.CHASE and not nav_agent.is_navigation_finished():
		var direction: Vector2 = (nav_agent.get_next_path_position() - global_position).normalized()
		var spd: float = enemy_data.move_speed * (1.0 + evolution_tier * EVOLUTION_SPEED_BONUS)
		if active_status in [Globals.StatusEffect.SLOW, Globals.StatusEffect.FREEZE]:
			spd *= 0.4
		velocity = direction * spd
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0

func _start_charge() -> void:
	if not target or not is_instance_valid(target):
		return
	is_charging = true
	charge_timer = CHARGE_DURATION
	charge_direction = (target.global_position - global_position).normalized()
	attack_cooldown_timer = enemy_data.attack_cooldown * 2.0
	if animation_player.has_animation("charge"):
		animation_player.play("charge")
