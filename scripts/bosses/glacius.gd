## Glacius, Frozen Sovereign — Major Boss. Ice element.
## Phase 1: Ice lance barrage, freeze beams.
## Phase 2 (66%): Freezes arena — spawns ice pillars player must break.
## Phase 3 (33%): True blizzard — constant slow field, ice shards from all directions.

class_name Glacius
extends BossBase

const ICE_LANCE_COOLDOWN: float = 1.8
const FREEZE_BEAM_COOLDOWN: float = 4.0
const FREEZE_BEAM_DURATION: float = 1.5
const BLIZZARD_DAMAGE_PER_SEC: float = 8.0
const ICE_PILLAR_COUNT: int = 4

var ice_lance_timer: float = 0.0
var freeze_beam_timer: float = 0.0
var blizzard_active: bool = false
var ice_pillars_spawned: bool = false

func _ready() -> void:
	super._ready()

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			if not ice_pillars_spawned:
				ice_pillars_spawned = true
				EventBus.notification_requested.emit("THE ARENA FREEZES!", Color(0.6, 0.9, 1.0))
		3:
			blizzard_active = true
			EventBus.notification_requested.emit("BLIZZARD!", Color(0.4, 0.8, 1.0))

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if ice_lance_timer > 0.0:
		ice_lance_timer -= delta
	if freeze_beam_timer > 0.0:
		freeze_beam_timer -= delta
	# Blizzard passive slow
	if blizzard_active and target and is_instance_valid(target):
		if target.has_method("apply_status_effect"):
			target.apply_status_effect(Globals.StatusEffect.SLOW, 0.3)
		if target.has_method("take_damage"):
			target.take_damage(BLIZZARD_DAMAGE_PER_SEC * delta, Globals.ElementType.ICE)
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
			if ice_lance_timer <= 0.0 and distance <= 300.0:
				_fire_ice_lance()
			if freeze_beam_timer <= 0.0 and distance <= 200.0:
				_cast_freeze_beam()
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if ice_lance_timer <= 0.0:
				_fire_ice_lance()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _fire_ice_lance() -> void:
	if not target or not is_instance_valid(target):
		return
	ice_lance_timer = ICE_LANCE_COOLDOWN
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.3, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.ICE)

func _cast_freeze_beam() -> void:
	if not target or not is_instance_valid(target):
		return
	freeze_beam_timer = FREEZE_BEAM_COOLDOWN
	_start_tell("FREEZE BEAM")
	# Apply freeze after tell
	var t := get_tree().create_timer(tell_duration)
	t.timeout.connect(func():
		if target and is_instance_valid(target) and target.has_method("apply_status_effect"):
			target.apply_status_effect(Globals.StatusEffect.FREEZE, FREEZE_BEAM_DURATION)
	)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.1, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.ICE)
