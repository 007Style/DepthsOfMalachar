## CursedKnight — Steel element. Observes then mirrors the player's attack patterns.
## After watching for a moment, copies the player's last used element type.

class_name CursedKnight
extends EnemyBase

const OBSERVE_DURATION: float = 2.0
const MIMIC_COOLDOWN: float = 3.5

var mimic_element: int = Globals.ElementType.STEEL
var observe_timer: float = 0.0
var is_observing: bool = false
var mimic_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Subscribe to player damage events to learn element
	EventBus.enemy_took_damage.connect(_on_enemy_took_damage)

func _on_enemy_took_damage(enemy_node: Node, _amount: float) -> void:
	# Learn from the element that just hit us
	if enemy_node == self and not is_observing:
		# Mirror the last incoming element
		# We can read from current_element_applied which is set in take_damage
		mimic_element = current_element_applied if current_element_applied != Globals.ElementType.NONE else Globals.ElementType.STEEL

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if observe_timer > 0.0:
		observe_timer -= delta
		if observe_timer <= 0.0:
			is_observing = false
	if mimic_cooldown_timer > 0.0:
		mimic_cooldown_timer -= delta
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
				_begin_observe()
		AIState.CHASE:
			nav_agent.target_position = target.global_position
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE
				_begin_observe()

func _begin_observe() -> void:
	is_observing = true
	observe_timer = OBSERVE_DURATION
	ai_state = AIState.IDLE  # Pause briefly to "observe"
	var timer := get_tree().create_timer(OBSERVE_DURATION)
	timer.timeout.connect(func():
		is_observing = false
		ai_state = AIState.CHASE
	)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		# Attack with mirrored element
		target.take_damage(dmg, mimic_element)
