## Malachar, Demon King — Secret Final Boss. All elements. 5 phases.
## The true final battle. Each phase introduces new mechanics.
## Phase 1: Fire/Dark attacks, summons imps.
## Phase 2 (80%): Ice/Lightning — freezes arena sections.
## Phase 3 (60%): Void/Dark — splits, void zones.
## Phase 4 (40%): Earth/LifeSteal — regenerates HP, buries and bursts.
## Phase 5 (20%): ALL ELEMENTS — absolute fury, reveals true form.

class_name Malachar
extends BossBase

# Phase thresholds overriding base class
const PHASE_2_HP: float = 0.80
const PHASE_3_HP: float = 0.60
const PHASE_4_HP: float = 0.40
const PHASE_5_HP: float = 0.20

const REGEN_PER_SEC: float = 0.005  # 0.5% max HP/sec in phase 4

var malachar_phase: int = 1
var regen_active: bool = false
var true_form_active: bool = false

# Attack timers
var primary_attack_timer: float = 0.0
var special_attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	boss_name = "Malachar, Demon King"
	boss_title = "He Who Drowned the Kingdom"
	boss_lore_quote = "\"You think yourself worthy of my depths? Ethari — a fragment of a dead god. How… quaint.\""
	malachar_taunt = "The demon king has fallen. But remember — I am eternal."
	# Override phase thresholds — Malachar has 5 phases
	PHASE_2_THRESHOLD  # Unused — custom logic below

func _check_phase_transition() -> void:
	# Override to use 5-phase system
	var hp: float = get_hp_fraction()
	if malachar_phase == 1 and hp <= PHASE_2_HP:
		_enter_malachar_phase(2)
	elif malachar_phase == 2 and hp <= PHASE_3_HP:
		_enter_malachar_phase(3)
	elif malachar_phase == 3 and hp <= PHASE_4_HP:
		_enter_malachar_phase(4)
	elif malachar_phase == 4 and hp <= PHASE_5_HP:
		_enter_malachar_phase(5)

func _enter_malachar_phase(new_phase: int) -> void:
	if malachar_phase >= new_phase:
		return
	malachar_phase = new_phase
	current_phase = new_phase  # Keep base class in sync
	phase_transitioning = true
	ai_state = AIState.STUNNED
	var phase_messages: Dictionary = {
		2: "\"You've barely scratched me. Let me show you the cold of the void!\"",
		3: "\"Still standing? The void claims all things!\"",
		4: "\"Impressive. You may actually die fighting me.\"",
		5: "\"ENOUGH! WITNESS MY TRUE POWER!\"",
	}
	EventBus.notification_requested.emit(phase_messages.get(new_phase, ""), Color(0.8, 0.0, 1.0))
	EventBus.boss_phase_changed.emit(self, new_phase)
	# Phase 4: start regen
	if new_phase == 4:
		regen_active = true
	# Phase 5: true form transformation
	if new_phase == 5:
		true_form_active = true
		regen_active = false
		if sprite:
			var tween := create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 1.0)
	var delay := get_tree().create_timer(2.0)
	delay.timeout.connect(func():
		phase_transitioning = false
		ai_state = AIState.CHASE
	)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if primary_attack_timer > 0.0:
		primary_attack_timer -= delta
	if special_attack_timer > 0.0:
		special_attack_timer -= delta
	# Phase 4 HP regen
	if regen_active:
		current_hp = min(max_hp, current_hp + max_hp * REGEN_PER_SEC * delta)
		if health_bar:
			health_bar.value = current_hp
	_run_ai(delta)

func _run_ai(_delta: float) -> void:
	if not target or not is_instance_valid(target) or phase_transitioning:
		return
	_check_phase_transition()
	var distance: float = global_position.distance_to(target.global_position)
	match ai_state:
		AIState.IDLE:
			pass
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if primary_attack_timer <= 0.0 and distance <= 280.0:
				_fire_phase_ranged()
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown * (0.6 if true_form_active else 1.0)
			if special_attack_timer <= 0.0 and distance <= 200.0:
				_perform_phase_special()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _fire_phase_ranged() -> void:
	if not target or not is_instance_valid(target):
		return
	primary_attack_timer = 1.4
	animation_player.play("attack")
	var element: int = _get_phase_element()
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.3, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, element)

func _perform_phase_special() -> void:
	special_attack_timer = 5.0
	var element: int = _get_phase_element()
	_start_tell("MALACHAR SPECIAL: " + Globals.ElementType.keys()[element])
	var t := get_tree().create_timer(tell_duration)
	t.timeout.connect(func():
		if target and is_instance_valid(target):
			# AoE special
			for body in get_tree().get_nodes_in_group("player"):
				if global_position.distance_to(body.global_position) <= 160.0:
					if body.has_method("take_damage"):
						var dmg: float = Globals.scale_damage(enemy_data.base_damage * 2.8, floor_num)
						body.take_damage(dmg, element)
			EventBus.enemy_stomp.emit(global_position, 160.0)
	)

func _get_phase_element() -> int:
	match malachar_phase:
		1: return Globals.ElementType.FIRE
		2: return Globals.ElementType.ICE
		3: return Globals.ElementType.DARK
		4: return Globals.ElementType.LIFE_STEAL
		5:
			# Cycle all elements
			return [
				Globals.ElementType.FIRE,
				Globals.ElementType.ICE,
				Globals.ElementType.LIGHTNING,
				Globals.ElementType.DARK,
				Globals.ElementType.POISON,
			][randi() % 5]
		_: return Globals.ElementType.DARK

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var element: int = _get_phase_element()
	var dmg_mult: float = 1.8 if true_form_active else 1.2
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * dmg_mult, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, element)

func take_damage(amount: float, attacker_element: int = Globals.ElementType.NONE) -> void:
	super.take_damage(amount, attacker_element)
	# Override to use custom phase check
	_check_phase_transition()
