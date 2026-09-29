## PetBase — Active pet companion that follows Ethari in dungeon runs.
## Auto-attacks nearby enemies (based on personality), heals player, and retreats when hurt.
## Cannot die — retreats and recovers instead.

class_name PetBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------
var pet_data: PetData = null
var player_node: Node = null

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
enum PetState { FOLLOW, ATTACK, HEAL, RETREATING }
var state: int = PetState.FOLLOW
var attack_cooldown: float = 0.0
var heal_cooldown: float = 0.0
var retreat_timer: float = 0.0
var current_target: Node = null

const FOLLOW_DISTANCE: float = 60.0
const ATTACK_RANGE: float = 70.0
const RETREAT_THRESHOLD: float = 0.25   # Retreat at 25% simulated HP (tracked as hit count)
const RETREAT_DURATION: float = 3.0
const HEAL_COOLDOWN: float = 10.0
const HEAL_AMOUNT_FRACTION: float = 0.08  # Heals 8% of player max HP

var hit_count: int = 0
const MAX_HIT_BEFORE_RETREAT: int = 5

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	add_to_group("pets")

func setup(data: PetData, player: Node) -> void:
	pet_data = data
	player_node = player
	if sprite and pet_data:
		var tex: Texture2D = pet_data.get_current_sprite()
		if tex:
			sprite.texture = tex
	# Update sprite for evolution stage
	_update_sprite_tint()

func _update_sprite_tint() -> void:
	if not pet_data or not sprite:
		return
	# Tint by element
	var element_tints: Dictionary = {
		Globals.ElementType.FIRE:       Color(1.3, 0.7, 0.4),
		Globals.ElementType.ICE:        Color(0.7, 0.9, 1.3),
		Globals.ElementType.LIGHTNING:  Color(1.2, 1.2, 0.4),
		Globals.ElementType.POISON:     Color(0.6, 1.2, 0.4),
		Globals.ElementType.DARK:       Color(0.7, 0.5, 1.2),
		Globals.ElementType.LIGHT:      Color(1.2, 1.2, 0.8),
	}
	sprite.modulate = element_tints.get(pet_data.element, Color.WHITE)

# ---------------------------------------------------------------------------
# Process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if heal_cooldown > 0.0:
		heal_cooldown -= delta
	if state == PetState.RETREATING:
		retreat_timer -= delta
		if retreat_timer <= 0.0:
			state = PetState.FOLLOW
			hit_count = 0
			if sprite:
				sprite.modulate.a = 1.0
		return
	_decide_state()

func _decide_state() -> void:
	if not player_node or not is_instance_valid(player_node):
		return
	# Check if player needs healing
	if heal_cooldown <= 0.0 and player_node.has_method("heal"):
		var hp_frac: float = player_node.stats.current_hp / player_node.stats.max_hp
		if hp_frac < 0.40:
			state = PetState.HEAL
			_heal_player()
			return
	# Aggressive: prefer attacking
	if pet_data and pet_data.personality == Globals.PetPersonality.AGGRESSIVE:
		_find_nearest_enemy()
		if current_target and is_instance_valid(current_target):
			state = PetState.ATTACK
			return
	# Defensive: prefer healing
	if pet_data and pet_data.personality == Globals.PetPersonality.DEFENSIVE:
		_find_nearest_enemy()
		# Only attack if no heal needed and enemy is very close
		var dist_to_player: float = global_position.distance_to(player_node.global_position)
		if current_target and dist_to_player < 100.0 and attack_cooldown <= 0.0:
			state = PetState.ATTACK
			return
	# Supportive: balance
	_find_nearest_enemy()
	if current_target and is_instance_valid(current_target):
		var dist_to_enemy: float = global_position.distance_to(current_target.global_position)
		if dist_to_enemy < ATTACK_RANGE * 1.5 and attack_cooldown <= 0.0:
			state = PetState.ATTACK
			return
	state = PetState.FOLLOW

func _physics_process(_delta: float) -> void:
	if state == PetState.RETREATING:
		return
	if not player_node or not is_instance_valid(player_node):
		return
	var target_pos: Vector2
	if state == PetState.FOLLOW or state == PetState.HEAL:
		target_pos = player_node.global_position + Vector2(FOLLOW_DISTANCE * 0.5, 0)
	elif state == PetState.ATTACK and current_target and is_instance_valid(current_target):
		target_pos = current_target.global_position
	else:
		target_pos = player_node.global_position
	nav_agent.target_position = target_pos
	if not nav_agent.is_navigation_finished():
		var dir: Vector2 = (nav_agent.get_next_path_position() - global_position).normalized()
		var spd: float = 120.0 if state == PetState.ATTACK else 100.0
		velocity = dir * spd
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0
	# Attack if close enough
	if state == PetState.ATTACK and current_target and is_instance_valid(current_target):
		if global_position.distance_to(current_target.global_position) <= ATTACK_RANGE and attack_cooldown <= 0.0:
			_attack_enemy(current_target)

# ---------------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------------
func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and not body.is_in_group("player") and not body.is_in_group("pets"):
		if attack_cooldown <= 0.0:
			_attack_enemy(body)

func _attack_enemy(enemy: Node) -> void:
	if not pet_data:
		return
	attack_cooldown = 1.5 / max(1.0, pet_data.bond_level * 0.1 + 1.0)
	var dmg: float = 10.0 + pet_data.damage_bonus + pet_data.bond_level * 2.0
	enemy.take_damage(dmg, pet_data.element)
	# Bond XP from fight
	pet_data.gain_bond_xp(1)

func _find_nearest_enemy() -> void:
	current_target = null
	var nearest_dist: float = 300.0  # Search range
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var d: float = global_position.distance_to(body.global_position)
		if d < nearest_dist:
			nearest_dist = d
			current_target = body

# ---------------------------------------------------------------------------
# Healing
# ---------------------------------------------------------------------------
func _heal_player() -> void:
	if not player_node or not is_instance_valid(player_node):
		return
	heal_cooldown = HEAL_COOLDOWN
	var heal_amount: float = player_node.stats.max_hp * HEAL_AMOUNT_FRACTION
	heal_amount += pet_data.hp_bonus * 0.1 if pet_data else 0.0
	player_node.heal(heal_amount)
	state = PetState.FOLLOW

# ---------------------------------------------------------------------------
# Taking hits (pet retreats but never dies)
# ---------------------------------------------------------------------------
func register_hit() -> void:
	hit_count += 1
	if hit_count >= MAX_HIT_BEFORE_RETREAT:
		_retreat()

func _retreat() -> void:
	state = PetState.RETREATING
	retreat_timer = RETREAT_DURATION
	# Fade out during retreat
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	EventBus.notification_requested.emit((pet_data.pet_name if pet_data else "Pet") + " is retreating!", Color(1.0, 0.7, 0.3))
