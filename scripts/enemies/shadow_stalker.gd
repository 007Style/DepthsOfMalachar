## ShadowStalker — Dark element assassin. Turns invisible, ambushes from stealth.
## Goes invisible when idle/retreating, decloaks briefly to attack.

class_name ShadowStalker
extends EnemyBase

const STEALTH_DELAY: float = 1.5    # Time before going invisible after last action
const STEALTH_APPROACH_RANGE: float = 80.0  # Decloak and attack when this close
const AMBUSH_DAMAGE_MULTIPLIER: float = 2.5

var is_stealthed: bool = false
var stealth_delay_timer: float = 0.0
var is_attacking_from_stealth: bool = false

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	# Manage stealth delay countdown
	if stealth_delay_timer > 0.0:
		stealth_delay_timer -= delta
		if stealth_delay_timer <= 0.0 and not is_stealthed:
			_enter_stealth()
	_run_ai(delta)

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			if distance < 400.0:
				ai_state = AIState.CHASE
				_enter_stealth()  # Stalk immediately
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= STEALTH_APPROACH_RANGE:
				_decloak_and_attack()
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
				# Re-enter stealth after attack
				stealth_delay_timer = STEALTH_DELAY
			if distance > enemy_data.attack_range * 2.0:
				ai_state = AIState.CHASE

func _enter_stealth() -> void:
	if is_stealthed:
		return
	is_stealthed = true
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.15), 0.4)

func _decloak_and_attack() -> void:
	is_stealthed = false
	stealth_delay_timer = 0.0
	is_attacking_from_stealth = true
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	ai_state = AIState.ATTACK

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	if is_attacking_from_stealth:
		dmg *= AMBUSH_DAMAGE_MULTIPLIER
		is_attacking_from_stealth = false
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.DARK)
