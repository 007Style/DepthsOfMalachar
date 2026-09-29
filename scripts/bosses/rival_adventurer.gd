## RivalAdventurer — Major Boss (2 variants). Corrupted hero mirrors player class abilities.
## Phase 1: Standard corrupted hero attacks.
## Phase 2 (66%): Activates corruption power — uses player's own element type against them.
## Phase 3 (33%): Desperate burst — rapid multi-attack, pleads to be saved.
## Player choice at low HP: execute or purify (save).

class_name RivalAdventurer
extends BossBase

@export var rival_name: String = "Aldric"  # Second rival: "Seraphine"
@export var rival_backstory: String = ""
@export var can_be_saved: bool = true

var mirrored_element: int = Globals.ElementType.NONE
var burst_cooldown: float = 0.0
var has_begged: bool = false  # Plays save dialogue at low HP

const BURST_ATTACK_COUNT: int = 4
const BURST_INTERVAL: float = 0.25
var burst_remaining: int = 0
var burst_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Learn player's element at start
	EventBus.enemy_took_damage.connect(_on_took_damage_learn_element)

func _on_took_damage_learn_element(enemy_node: Node, _amount: float) -> void:
	if enemy_node == self:
		mirrored_element = current_element_applied

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		2:
			EventBus.notification_requested.emit(rival_name + " embraces the corruption!", Color(0.6, 0.0, 0.8))
		3:
			if can_be_saved and not has_begged:
				has_begged = true
				EventBus.notification_requested.emit(rival_name + ": \"Help me... please!\"", Color(0.9, 0.8, 0.6))
				# Emit save choice event
				if EventBus.has_signal("rival_save_choice_requested"):
					EventBus.rival_save_choice_requested.emit(self)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if burst_cooldown > 0.0:
		burst_cooldown -= delta
	if burst_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			_fire_burst_hit()
			burst_remaining -= 1
			burst_timer = BURST_INTERVAL
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
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0 and burst_remaining == 0:
				if current_phase >= 3 and burst_cooldown <= 0.0:
					burst_remaining = BURST_ATTACK_COUNT
					burst_timer = 0.0
					burst_cooldown = 5.0
				else:
					perform_attack()
					attack_cooldown_timer = enemy_data.attack_cooldown
			if distance > enemy_data.attack_range * 1.5:
				ai_state = AIState.CHASE

func _fire_burst_hit() -> void:
	if not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var element: int = mirrored_element if current_phase >= 2 else enemy_data.element
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * 0.7, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, element)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var element: int = mirrored_element if current_phase >= 2 and mirrored_element != Globals.ElementType.NONE else enemy_data.element
	var dmg: float = Globals.scale_damage(enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS), floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, element)

func save_rival() -> void:
	## Called if player chooses to purify/save the rival.
	EventBus.lore_entry_unlocked.emit("rival_saved_" + rival_name.to_lower())
	EventBus.recruit_joined_party.emit(null)  # Placeholder — rival joins as recruit
	queue_free()
