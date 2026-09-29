## OrcShaman — Ranged fireball caster with Fire element.
## Keeps distance from player, launches fireballs that apply Burn status.

class_name OrcShaman
extends EnemyBase

const PREFERRED_RANGE: float = 250.0
const RETREAT_RANGE: float = 120.0
const FIREBALL_DAMAGE_MULTIPLIER: float = 1.4

@export var fireball_scene: PackedScene = null

func _ready() -> void:
	super._ready()

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
			# If too close, retreat
			if distance < RETREAT_RANGE:
				_move_away_from_target()
			else:
				nav_agent.target_position = target.global_position
			if distance <= PREFERRED_RANGE and distance > RETREAT_RANGE:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			# Maintain preferred range
			if distance < RETREAT_RANGE:
				_move_away_from_target()
				ai_state = AIState.CHASE
			elif distance > PREFERRED_RANGE * 1.3:
				ai_state = AIState.CHASE
			elif attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown

func _move_away_from_target() -> void:
	if not target or not is_instance_valid(target):
		return
	var away: Vector2 = (global_position - target.global_position).normalized()
	velocity = away * enemy_data.move_speed
	move_and_slide()
	sprite.flip_h = velocity.x < 0.0

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	_launch_fireball()

func _launch_fireball() -> void:
	if not target or not is_instance_valid(target):
		return
	# Spawn a projectile or directly apply damage after delay (simple version)
	var dmg: float = enemy_data.base_damage * FIREBALL_DAMAGE_MULTIPLIER
	dmg = Globals.scale_damage(dmg, floor_num)
	# Fire element always applies Burn
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.FIRE)
	EventBus.elemental_reaction_triggered.emit(Globals.StatusEffect.BURN, global_position)
