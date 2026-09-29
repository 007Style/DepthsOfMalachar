## RotttingWarlord — Mini Boss. Steel/Dark. Summons skeleton adds in Phase 2.
## Phase 1: Melee charge + spin attack.
## Phase 2 (66%): Summons 3 SkeletonWarriors. Faster attacks.
## Phase 3 (33%): Enrages — constant aura damage, massive spin.

class_name RottingWarlord
extends BossBase

const SUMMON_COUNT: int = 3
const SPIN_RANGE: float = 120.0
const SPIN_DAMAGE_MULTIPLIER: float = 1.6
const SPIN_COOLDOWN: float = 6.0
const CHARGE_SPEED_MULT: float = 3.5

var spin_cooldown_timer: float = 0.0
var is_spinning: bool = false
var spin_timer: float = 0.0
var has_summoned_phase2: bool = false

@export var skeleton_warrior_scene: PackedScene = null

func _ready() -> void:
	super._ready()

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			# Summon skeleton warriors
			if not has_summoned_phase2:
				has_summoned_phase2 = true
				_summon_skeletons()
		3:
			# Enrage — increase attack speed
			enemy_data.attack_cooldown *= 0.5

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if spin_cooldown_timer > 0.0:
		spin_cooldown_timer -= delta
	if is_spinning:
		spin_timer -= delta
		_spin_damage()
		if spin_timer <= 0.0:
			is_spinning = false
	_run_ai(delta)

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target) or phase_transitioning:
		return
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			pass
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
			# Spin if in range
			if distance <= SPIN_RANGE and spin_cooldown_timer <= 0.0:
				_start_tell("SPIN ATTACK")
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if spin_cooldown_timer <= 0.0 and not is_spinning:
				_start_tell("SPIN ATTACK")
			if distance > enemy_data.attack_range * 2.0:
				ai_state = AIState.CHASE
		AIState.STUNNED:
			# After tell wind-up, execute spin
			if _update_tell(_get_process_delta_time()):
				_start_spin()

func _start_spin() -> void:
	is_spinning = true
	spin_timer = 1.2
	spin_cooldown_timer = SPIN_COOLDOWN
	ai_state = AIState.ATTACK

func _spin_damage() -> void:
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= SPIN_RANGE:
			if body.has_method("take_damage"):
				var dmg: float = Globals.scale_damage(enemy_data.base_damage * SPIN_DAMAGE_MULTIPLIER, floor_num)
				body.take_damage(dmg, Globals.ElementType.STEEL)

func _summon_skeletons() -> void:
	if not skeleton_warrior_scene:
		return
	for i in SUMMON_COUNT:
		var skel: Node = skeleton_warrior_scene.instantiate()
		get_parent().add_child(skel)
		var angle: float = (TAU / SUMMON_COUNT) * i
		skel.global_position = global_position + Vector2(cos(angle), sin(angle)) * 100.0
		if skel.has_method("setup"):
			skel.setup(null, floor_num, target)

func _get_process_delta_time() -> float:
	return get_process_delta_time() if has_method("get_process_delta_time") else 0.016
