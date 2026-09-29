## BossBase — Base class for all bosses in The Depths of Malachar.
## Extends EnemyBase with multi-phase fights, cinematic name card intro,
## artifact drop, lore unlock, boss tell system, and Malachar voice taunts.

class_name BossBase
extends EnemyBase

# ---------------------------------------------------------------------------
# Boss configuration
# ---------------------------------------------------------------------------
@export var boss_name: String = "Unknown Boss"
@export var boss_lore_quote: String = ""
@export var boss_tier: int = 0  # 0=Mini, 1=Major, 2=Secret
@export var lore_unlock_id: String = ""
@export var malachar_taunt: String = ""
@export var artifact_drop: ArtifactData = null
@export var boss_title: String = ""

# Phase thresholds
const PHASE_2_THRESHOLD: float = 0.66  # Transition at 66% HP
const PHASE_3_THRESHOLD: float = 0.33  # Transition at 33% HP

var current_phase: int = 1
var phase_transitioning: bool = false

# Boss tell system
var tell_active: bool = false
var tell_timer: float = 0.0
var tell_duration: float = 1.2  # Wind-up duration before big attack

# Door sealing
var room_doors: Array = []

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal boss_intro_finished()
signal boss_phase_transition(new_phase: int)
signal boss_tell_started(attack_name: String)

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	# Override health bar scale — bosses use a wider bar
	if health_bar:
		health_bar.offset_left = -48.0
		health_bar.offset_right = 48.0

func start_boss_encounter(doors: Array) -> void:
	## Called when the player enters the boss room.
	room_doors = doors
	_seal_doors()
	_play_intro()

# ---------------------------------------------------------------------------
# Intro Sequence
# ---------------------------------------------------------------------------
func _play_intro() -> void:
	## Freeze the boss briefly, display name card, then start the fight.
	ai_state = AIState.IDLE
	# Emit to UI system to show name card
	EventBus.boss_room_entered.emit(boss_tier)
	# Package intro data in a dictionary for the UI
	var intro_data: Dictionary = {
		"name": boss_name,
		"title": boss_title,
		"quote": boss_lore_quote,
		"tier": boss_tier,
	}
	if EventBus.has_signal("boss_intro_requested"):
		EventBus.boss_intro_requested.emit(intro_data)
	# Wait for intro duration then start fight
	var intro_timer := get_tree().create_timer(3.0)
	intro_timer.timeout.connect(_on_intro_finished)

func _on_intro_finished() -> void:
	ai_state = AIState.CHASE
	boss_intro_finished.emit()

# ---------------------------------------------------------------------------
# Phase system
# ---------------------------------------------------------------------------
func _check_phase_transition() -> void:
	if phase_transitioning:
		return
	var hp_frac: float = get_hp_fraction()
	if current_phase == 1 and hp_frac <= PHASE_2_THRESHOLD:
		_transition_to_phase(2)
	elif current_phase == 2 and hp_frac <= PHASE_3_THRESHOLD:
		_transition_to_phase(3)

func _transition_to_phase(new_phase: int) -> void:
	if current_phase >= new_phase:
		return
	phase_transitioning = true
	current_phase = new_phase
	ai_state = AIState.STUNNED
	# Visual: flash the boss and shake camera
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	EventBus.boss_phase_changed.emit(self, current_phase)
	boss_phase_transition.emit(current_phase)
	_on_phase_changed(new_phase)
	var delay := get_tree().create_timer(1.0)
	delay.timeout.connect(func():
		phase_transitioning = false
		ai_state = AIState.CHASE
	)

## Override in subclasses to define phase-specific behaviour changes.
func _on_phase_changed(_new_phase: int) -> void:
	pass

# ---------------------------------------------------------------------------
# Override take_damage to check phase transitions
# ---------------------------------------------------------------------------
func take_damage(amount: float, attacker_element: int = Globals.ElementType.NONE) -> void:
	super.take_damage(amount, attacker_element)
	_check_phase_transition()

# ---------------------------------------------------------------------------
# Override death to drop artifact, unlock lore, taunt
# ---------------------------------------------------------------------------
func _die() -> void:
	if is_dead:
		return
	_unseal_doors()
	# Drop guaranteed artifact
	if artifact_drop:
		_spawn_loot_pickup(artifact_drop)
	# Unlock lore entry
	if lore_unlock_id != "":
		EventBus.lore_entry_unlocked.emit(lore_unlock_id)
	# Malachar taunts
	if malachar_taunt != "":
		if EventBus.has_signal("malachar_voice_taunt"):
			EventBus.malachar_voice_taunt.emit(malachar_taunt)
	EventBus.boss_died.emit(self)
	super._die()

# ---------------------------------------------------------------------------
# Boss Tell system
# ---------------------------------------------------------------------------
func _start_tell(attack_name: String) -> void:
	## Show wind-up indicator. Call this before a big attack.
	tell_active = true
	tell_timer = tell_duration
	boss_tell_started.emit(attack_name)
	# Visual cue — pulse red outline or particle
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 0.5), tell_duration * 0.5)
	tween.tween_property(sprite, "modulate", Color.WHITE, tell_duration * 0.5)

func _update_tell(delta: float) -> bool:
	## Returns true when tell wind-up is complete (attack can fire).
	if not tell_active:
		return false
	tell_timer -= delta
	if tell_timer <= 0.0:
		tell_active = false
		return true
	return false

# ---------------------------------------------------------------------------
# Door management
# ---------------------------------------------------------------------------
func _seal_doors() -> void:
	for door in room_doors:
		if is_instance_valid(door) and door.has_method("seal"):
			door.seal()

func _unseal_doors() -> void:
	for door in room_doors:
		if is_instance_valid(door) and door.has_method("unseal"):
			door.unseal()
