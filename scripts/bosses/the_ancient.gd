## The Ancient — Floor 666 Secret Boss. Dark/LifeSteal. Pre-cosmic entity.
## Phase 1: Reality tear attacks, life-drain field.
## Phase 2 (66%): Multiplies — all eyes open, multi-directional void beams.
## Phase 3 (33%): True ascension — pulls entire room inward, hidden lore unlocked.
## Unique: Defeating The Ancient without taking damage unlocks hidden ending fragment.

class_name TheAncient
extends BossBase

const DRAIN_FIELD_RADIUS: float = 240.0
const DRAIN_RATE: float = 15.0  # HP/sec drained from player
const TENTACLE_ATTACK_COOLDOWN: float = 1.8
const REALITY_TEAR_COOLDOWN: float = 4.0
const VOID_BEAM_COUNT: int = 8  # Phase 2+

var tentacle_timer: float = 0.0
var reality_tear_timer: float = 0.0
var drain_field_active: bool = true  # Always active
var is_ascending: bool = false

func _ready() -> void:
	super._ready()
	boss_name = "The Ancient"
	boss_title = "That Which Was Before"
	boss_lore_quote = "\"You should not have found this place. You will not leave it.\""
	lore_unlock_id = "the_ancient_truth"

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			EventBus.notification_requested.emit("ALL EYES OPEN.", Color(0.3, 0.0, 0.3))
			EventBus.lore_entry_unlocked.emit("the_ancient_phase2")
		3:
			EventBus.notification_requested.emit("REALITY FRACTURES.", Color(0.1, 0.0, 0.1))
			EventBus.lore_entry_unlocked.emit("the_ancient_truth_fragment")
			is_ascending = true

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if tentacle_timer > 0.0:
		tentacle_timer -= delta
	if reality_tear_timer > 0.0:
		reality_tear_timer -= delta
	# Drain field — always active
	if drain_field_active and target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		if dist < DRAIN_FIELD_RADIUS:
			var drain_amount: float = DRAIN_RATE * delta * (1.0 - dist / DRAIN_FIELD_RADIUS)
			if target.has_method("take_damage"):
				target.take_damage(drain_amount, Globals.ElementType.LIFE_STEAL)
			# Heal self from drain
			current_hp = min(max_hp, current_hp + drain_amount * 0.5)
			if health_bar:
				health_bar.value = current_hp
	# Phase 3: room-pull
	if is_ascending and target and is_instance_valid(target):
		var pull_dir: Vector2 = (global_position - target.global_position).normalized()
		if target.has_method("apply_knockback"):
			target.apply_knockback(pull_dir * 40.0)
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
			if tentacle_timer <= 0.0:
				_tentacle_strike()
			if reality_tear_timer <= 0.0 and distance <= 280.0:
				_reality_tear()
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if tentacle_timer <= 0.0:
				_tentacle_strike()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _tentacle_strike() -> void:
	if not target or not is_instance_valid(target):
		return
	tentacle_timer = TENTACLE_ATTACK_COOLDOWN
	animation_player.play("attack")
	# Strike in multiple directions in phase 2+
	var beam_count: int = VOID_BEAM_COUNT if current_phase >= 2 else 1
	for i in beam_count:
		var angle: float = (TAU / beam_count) * i
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		for body in get_tree().get_nodes_in_group("player"):
			if (body.global_position - global_position).normalized().dot(dir) > 0.8:
				if body.has_method("take_damage"):
					var dmg: float = Globals.scale_damage(enemy_data.base_damage, floor_num)
					body.take_damage(dmg, Globals.ElementType.DARK)

func _reality_tear() -> void:
	reality_tear_timer = REALITY_TEAR_COOLDOWN
	_start_tell("REALITY TEAR")
	var t := get_tree().create_timer(tell_duration)
	t.timeout.connect(func():
		for body in get_tree().get_nodes_in_group("player"):
			if global_position.distance_to(body.global_position) <= 200.0:
				if body.has_method("take_damage"):
					var dmg: float = Globals.scale_damage(enemy_data.base_damage * 3.0, floor_num)
					body.take_damage(dmg, Globals.ElementType.LIFE_STEAL)
		EventBus.enemy_stomp.emit(global_position, 200.0)
	)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.4, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.DARK)
