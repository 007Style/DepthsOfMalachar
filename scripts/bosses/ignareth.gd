## Ignareth the Flame Titan — Mini Boss. Fire element.
## Phase 1: Fireballs + melee slam.
## Phase 2 (66%): Floor becomes lava — lava tiles deal constant burn damage.
## Phase 3 (33%): Ignites self — melee contact burns player; frenzy mode.

class_name Ignareth
extends BossBase

const SLAM_RANGE: float = 130.0
const SLAM_DAMAGE_MULTIPLIER: float = 2.5
const SLAM_COOLDOWN: float = 4.0
const FIREBALL_COOLDOWN: float = 2.2
const LAVA_FLOOR_DAMAGE_PER_SEC: float = 12.0

var slam_cooldown_timer: float = 0.0
var fireball_cooldown_timer: float = 0.0
var lava_floor_active: bool = false
var phase3_self_burn: bool = false

func _ready() -> void:
	super._ready()

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			lava_floor_active = true
			EventBus.notification_requested.emit("THE FLOOR IS LAVA!", Color(1.0, 0.4, 0.0))
		3:
			phase3_self_burn = true
			# Increase speed dramatically
			enemy_data.move_speed *= 1.6

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if slam_cooldown_timer > 0.0:
		slam_cooldown_timer -= delta
	if fireball_cooldown_timer > 0.0:
		fireball_cooldown_timer -= delta
	# Lava floor damage
	if lava_floor_active and target and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(LAVA_FLOOR_DAMAGE_PER_SEC * delta, Globals.ElementType.FIRE)
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
			if distance <= SLAM_RANGE and slam_cooldown_timer <= 0.0:
				_start_tell("LAVA SLAM")
				ai_state = AIState.STUNNED
			elif fireball_cooldown_timer <= 0.0 and distance <= 320.0:
				_fire_fireball()
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE
		AIState.STUNNED:
			if _update_tell(get_physics_process_delta_time()):
				_slam()
				ai_state = AIState.CHASE

func _slam() -> void:
	slam_cooldown_timer = SLAM_COOLDOWN
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= SLAM_RANGE:
			if body.has_method("take_damage"):
				var dmg: float = Globals.scale_damage(enemy_data.base_damage * SLAM_DAMAGE_MULTIPLIER, floor_num)
				body.take_damage(dmg, Globals.ElementType.FIRE)
	EventBus.enemy_stomp.emit(global_position, SLAM_RANGE)

func _fire_fireball() -> void:
	if not target or not is_instance_valid(target):
		return
	fireball_cooldown_timer = FIREBALL_COOLDOWN
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.2, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.FIRE)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage, floor_num)
	if phase3_self_burn:
		dmg *= 1.5
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.FIRE)
