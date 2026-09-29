## Recruit — Companion AI node for use in dungeon runs.
## Follows Ethari, attacks enemies, levels up, and can be sent back to base.

class_name Recruit
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var hit_flash_timer: Timer = $HitFlashTimer

# ---------------------------------------------------------------------------
# Data & State
# ---------------------------------------------------------------------------
var recruit_data: RecruitData = null
var is_dead: bool = false
var player_node: Node = null
var current_target: Node = null  # Enemy to attack

# Disciple party boost
var disciple_boost_active: bool = false
const DISCIPLE_BOOST: float = 0.40  # +40%

enum AIState { FOLLOW, ATTACK, RETURNING }
var ai_state: int = AIState.FOLLOW
var attack_cooldown: float = 0.0
const FOLLOW_DISTANCE: float = 80.0   # Stay within this distance of player
const ATTACK_RANGE: float = 50.0

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	hit_flash_timer.timeout.connect(func(): sprite.modulate = Color.WHITE)

func setup(data: RecruitData, player: Node) -> void:
	recruit_data = data
	player_node = player
	if recruit_data.stats:
		health_bar.max_value = recruit_data.stats.max_hp
		health_bar.value = recruit_data.stats.current_hp

# ---------------------------------------------------------------------------
# Process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if is_dead:
		return
	attack_cooldown = max(0.0, attack_cooldown - delta)
	_find_nearest_enemy()
	_run_ai()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	if not nav_agent.is_navigation_finished():
		var dir: Vector2 = (nav_agent.get_next_path_position() - global_position).normalized()
		var speed: float = recruit_data.stats.move_speed if recruit_data.stats else 120.0
		if disciple_boost_active:
			speed *= (1.0 + DISCIPLE_BOOST)
		velocity = dir * speed
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0

func _run_ai() -> void:
	match ai_state:
		AIState.FOLLOW:
			if player_node and is_instance_valid(player_node):
				var dist: float = global_position.distance_to(player_node.global_position)
				if dist > FOLLOW_DISTANCE:
					nav_agent.target_position = player_node.global_position
		AIState.ATTACK:
			if current_target and is_instance_valid(current_target):
				nav_agent.target_position = current_target.global_position
				if global_position.distance_to(current_target.global_position) <= ATTACK_RANGE:
					_attack_target()
			else:
				current_target = null
				ai_state = AIState.FOLLOW

func _find_nearest_enemy() -> void:
	## Scan for enemies in a radius and set as attack target.
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 200.0
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 2  # Enemy layer
	var results: Array = space.intersect_shape(query, 5)
	var nearest: Node = null
	var nearest_dist: float = INF
	for result in results:
		var body: Node = result["collider"]
		if body.has_method("take_damage") and body != self:
			var d: float = global_position.distance_to(body.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = body
	if nearest:
		current_target = nearest
		ai_state = AIState.ATTACK

func _attack_target() -> void:
	if attack_cooldown > 0.0 or not current_target:
		return
	if current_target.has_method("take_damage"):
		var dmg: float = recruit_data.stats.base_damage if recruit_data.stats else 8.0
		if disciple_boost_active:
			dmg *= (1.0 + DISCIPLE_BOOST)
		current_target.take_damage(dmg, Globals.ElementType.NONE)
		# Gain XP from hits
		_gain_xp(2)
	attack_cooldown = 1.5

func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_attack_target()

# ---------------------------------------------------------------------------
# Damage & death
# ---------------------------------------------------------------------------
func take_damage(amount: float, _element: int = 0) -> void:
	if is_dead or not recruit_data or not recruit_data.stats:
		return
	recruit_data.stats.current_hp -= amount
	health_bar.value = recruit_data.stats.current_hp
	sprite.modulate = Color.RED
	hit_flash_timer.start(0.12)
	if recruit_data.stats.current_hp <= 0.0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	animation_player.play("death")
	EventBus.recruit_died.emit(recruit_data, global_position)
	# Add to pending funerals
	ProgressionManager.add_pending_funeral(recruit_data)
	# Remove from save roster
	SaveManager.remove_recruit(recruit_data.recruit_name)
	await animation_player.animation_finished
	queue_free()

# ---------------------------------------------------------------------------
# Send back to base (before death)
# ---------------------------------------------------------------------------
func send_to_base() -> void:
	if is_dead:
		return
	EventBus.recruit_sent_to_base.emit(recruit_data)
	# Save recruit state back to roster
	SaveManager.add_recruit(recruit_data.to_dict())
	queue_free()

# ---------------------------------------------------------------------------
# XP gain
# ---------------------------------------------------------------------------
func _gain_xp(amount: int) -> void:
	if not recruit_data:
		return
	var multiplier: float = 1.0
	# Mentor bonus
	if recruit_data.mentor_name != "" and not recruit_data.is_retired:
		multiplier = 1.5  # +50% XP when mentor is active
	if disciple_boost_active:
		multiplier += DISCIPLE_BOOST
	var leveled_up: bool = recruit_data.gain_xp(int(amount * multiplier))
	if leveled_up:
		EventBus.recruit_leveled_up.emit(recruit_data)

# ---------------------------------------------------------------------------
# Disciple boost (activated when all 4 disciples of same mentor are in party)
# ---------------------------------------------------------------------------
func activate_disciple_boost() -> void:
	disciple_boost_active = true
	EventBus.notification_requested.emit(
		recruit_data.recruit_name + " feels the mentor's bond!", Color.GOLD
	)
