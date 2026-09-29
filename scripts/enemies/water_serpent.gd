## WaterSerpent — Water element. Floods the area, slows all movement.
## Activates a flood zone that slows anyone walking through it.

class_name WaterSerpent
extends EnemyBase

const FLOOD_COOLDOWN: float = 7.0
const FLOOD_DURATION: float = 5.0
const FLOOD_RADIUS: float = 140.0
const FLOOD_SLOW_MULTIPLIER: float = 0.45
const BITE_DAMAGE_MULTIPLIER: float = 1.2
const SPIT_RANGE: float = 220.0

var flood_cooldown_timer: float = 0.0
var flood_active: bool = false
var flood_timer: float = 0.0

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if flood_cooldown_timer > 0.0:
		flood_cooldown_timer -= delta
	if flood_active:
		flood_timer -= delta
		_apply_flood_slow()
		if flood_timer <= 0.0:
			flood_active = false
	_run_ai(delta)

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		ai_state = AIState.IDLE
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			if distance < 380.0:
				ai_state = AIState.CHASE
				if flood_cooldown_timer <= 0.0:
					_activate_flood()
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= SPIT_RANGE and attack_cooldown_timer <= 0.0:
				_spit_water()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if flood_cooldown_timer <= 0.0:
				_activate_flood()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _activate_flood() -> void:
	flood_cooldown_timer = FLOOD_COOLDOWN
	flood_active = true
	flood_timer = FLOOD_DURATION
	if animation_player.has_animation("flood"):
		animation_player.play("flood")

func _apply_flood_slow() -> void:
	# Apply slow to all players in radius every frame
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= FLOOD_RADIUS:
			if body.has_method("apply_status_effect"):
				body.apply_status_effect(Globals.StatusEffect.SLOW, 0.2)

func _spit_water() -> void:
	if not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * 0.7
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.WATER)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * BITE_DAMAGE_MULTIPLIER * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.WATER)
