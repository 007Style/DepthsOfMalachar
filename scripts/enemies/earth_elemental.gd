## EarthElemental — Earth element. Burrows underground, surfaces for surprise attack.
## Spends time underground (invulnerable), pops up under the player.

class_name EarthElemental
extends EnemyBase

const BURROW_COOLDOWN: float = 5.0
const BURROW_DURATION: float = 2.0   # Time spent underground
const SURFACE_DAMAGE_MULTIPLIER: float = 2.0
const SURFACE_RADIUS: float = 60.0

var is_burrowed: bool = false
var burrow_timer: float = 0.0
var burrow_cooldown_timer: float = 0.0
var burrow_target_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return
	if is_burrowed:
		burrow_timer -= delta
		if burrow_timer <= 0.0:
			_surface()
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if burrow_cooldown_timer > 0.0:
		burrow_cooldown_timer -= delta
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
			# Burrow when in range and cooldown ready
			if distance <= 220.0 and burrow_cooldown_timer <= 0.0:
				_start_burrow()
			elif distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _start_burrow() -> void:
	if not target or not is_instance_valid(target):
		return
	is_burrowed = true
	burrow_timer = BURROW_DURATION
	burrow_cooldown_timer = BURROW_COOLDOWN
	# Record target position to surface at
	burrow_target_pos = target.global_position
	# Become invisible
	if sprite:
		sprite.visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if animation_player.has_animation("burrow"):
		animation_player.play("burrow")

func _surface() -> void:
	is_burrowed = false
	# Teleport to recorded target position
	global_position = burrow_target_pos
	if sprite:
		sprite.visible = true
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	if animation_player.has_animation("surface"):
		animation_player.play("surface")
	# Surface damage AoE
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= SURFACE_RADIUS:
			if body.has_method("take_damage"):
				var dmg: float = enemy_data.base_damage * SURFACE_DAMAGE_MULTIPLIER
				dmg = Globals.scale_damage(dmg, floor_num)
				body.take_damage(dmg, Globals.ElementType.EARTH)
	EventBus.enemy_stomp.emit(global_position, SURFACE_RADIUS)
	ai_state = AIState.ATTACK
