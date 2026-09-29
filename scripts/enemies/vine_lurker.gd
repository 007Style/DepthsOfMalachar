## VineLurker — LifePlant element. Roots player in place; ranged vine whip.
## Immobilises player with vine roots, then lashes with whip attacks.

class_name VineLurker
extends EnemyBase

const VINE_ROOT_RANGE: float = 200.0
const VINE_ROOT_DURATION: float = 2.5
const VINE_ROOT_COOLDOWN: float = 6.0
const WHIP_RANGE: float = 150.0

var vine_root_cooldown: float = 0.0

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if vine_root_cooldown > 0.0:
		vine_root_cooldown -= delta
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
			# Try to root if in range
			if distance <= VINE_ROOT_RANGE and vine_root_cooldown <= 0.0:
				_launch_vine_root()
			if distance <= WHIP_RANGE:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			# Root if available
			if distance <= VINE_ROOT_RANGE and vine_root_cooldown <= 0.0:
				_launch_vine_root()
			if distance > WHIP_RANGE * 1.5:
				ai_state = AIState.CHASE

func _launch_vine_root() -> void:
	if not target or not is_instance_valid(target):
		return
	vine_root_cooldown = VINE_ROOT_COOLDOWN
	# Apply slow/root to target via status effect signal
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(Globals.StatusEffect.SLOW, VINE_ROOT_DURATION)
	EventBus.status_effect_applied.emit(target, Globals.StatusEffect.SLOW, VINE_ROOT_DURATION)
	if animation_player.has_animation("vine_root"):
		animation_player.play("vine_root")

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.LIFE_PLANT)
