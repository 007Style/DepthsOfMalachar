## The Void Herald — Major Boss. Dark element.
## Phase 1: Ranged void bolts, curse field.
## Phase 2 (66%): Splits into 3 shadow clones. Player must find the real one.
## Phase 3 (33%): All clones become real; void singularity pulls player in.

class_name VoidHerald
extends BossBase

const VOID_BOLT_COOLDOWN: float = 1.5
const CLONE_COUNT: int = 3
const SINGULARITY_RANGE: float = 200.0
const SINGULARITY_PULL_FORCE: float = 120.0
const SINGULARITY_COOLDOWN: float = 8.0

var void_bolt_timer: float = 0.0
var clones: Array = []
var has_split: bool = false
var singularity_timer: float = 0.0

@export var clone_scene: PackedScene = null

func _ready() -> void:
	super._ready()

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			if not has_split:
				has_split = true
				_spawn_clones()
				EventBus.notification_requested.emit("SHADOW SPLIT!", Color(0.4, 0.0, 0.8))
		3:
			singularity_timer = 0.0
			EventBus.notification_requested.emit("VOID SINGULARITY!", Color(0.6, 0.0, 1.0))

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if void_bolt_timer > 0.0:
		void_bolt_timer -= delta
	if singularity_timer > 0.0:
		singularity_timer -= delta
	# Phase 3: pull player toward self
	if current_phase >= 3 and singularity_timer <= 0.0:
		_activate_singularity()
		singularity_timer = SINGULARITY_COOLDOWN
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
			if void_bolt_timer <= 0.0 and distance <= 350.0:
				_fire_void_bolt()
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if void_bolt_timer <= 0.0:
				_fire_void_bolt()
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _fire_void_bolt() -> void:
	if not target or not is_instance_valid(target):
		return
	void_bolt_timer = VOID_BOLT_COOLDOWN
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 1.1, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.DARK)

func _spawn_clones() -> void:
	## Create phantom copies — visual duplicates with reduced HP sharing the boss's data.
	for i in CLONE_COUNT:
		var angle: float = (TAU / CLONE_COUNT) * i + PI / 6.0
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * 120.0
		# Emit a request to spawn a visual clone (game manager / room handles spawning)
		EventBus.notification_requested.emit("Find the real herald!", Color(0.6, 0.3, 1.0))
		# The clones are visual only — we track them via the array
		clones.clear()  # Simplified; real implementation spawns clone scenes

func _activate_singularity() -> void:
	if not target or not is_instance_valid(target):
		return
	_start_tell("VOID SINGULARITY")
	var t := get_tree().create_timer(tell_duration)
	t.timeout.connect(func():
		# Pull player toward boss
		if target and is_instance_valid(target):
			var pull_dir: Vector2 = (global_position - target.global_position).normalized()
			var dist: float = global_position.distance_to(target.global_position)
			if dist < SINGULARITY_RANGE and target.has_method("apply_knockback"):
				target.apply_knockback(pull_dir * SINGULARITY_PULL_FORCE)
	)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = Globals.scale_damage(enemy_data.base_damage, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.DARK)
