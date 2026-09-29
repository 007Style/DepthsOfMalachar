## FrostWraith — Ice element ghost. Slows on hit, teleports when threatened.
## Teleports behind the player, hits then retreats via teleport.

class_name FrostWraith
extends EnemyBase

const TELEPORT_COOLDOWN: float = 4.0
const TELEPORT_BEHIND_DISTANCE: float = 60.0
const SAFE_DISTANCE: float = 80.0

var teleport_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Wraith should look semi-transparent
	if sprite:
		sprite.modulate = Color(0.8, 0.9, 1.0, 0.75)

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	if teleport_cooldown_timer > 0.0:
		teleport_cooldown_timer -= delta
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
		AIState.CHASE:
			# Teleport behind player when close enough
			if distance < 180.0 and teleport_cooldown_timer <= 0.0:
				_teleport_behind_target()
			else:
				nav_agent.target_position = target.global_position
			if distance <= enemy_data.attack_range:
				ai_state = AIState.ATTACK
		AIState.ATTACK:
			if attack_cooldown_timer <= 0.0:
				perform_attack()
				attack_cooldown_timer = enemy_data.attack_cooldown
				# Teleport away after attacking
				if teleport_cooldown_timer <= 0.0:
					_teleport_away_from_target()
			if distance > enemy_data.attack_range * 2.0:
				ai_state = AIState.CHASE

func _teleport_behind_target() -> void:
	if not target or not is_instance_valid(target):
		return
	teleport_cooldown_timer = TELEPORT_COOLDOWN
	var dir_away_from_target: Vector2 = (global_position - target.global_position).normalized()
	# Teleport to the other side of the player
	global_position = target.global_position + (-dir_away_from_target) * TELEPORT_BEHIND_DISTANCE
	_teleport_flash()

func _teleport_away_from_target() -> void:
	if not target or not is_instance_valid(target):
		return
	teleport_cooldown_timer = TELEPORT_COOLDOWN
	var away: Vector2 = (global_position - target.global_position).normalized()
	global_position = target.global_position + away * (enemy_data.attack_range * 3.0)
	_teleport_flash()

func _teleport_flash() -> void:
	if sprite:
		sprite.modulate = Color(0.5, 0.8, 1.0, 0.5)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(0.8, 0.9, 1.0, 0.75), 0.3)

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		# Ice applies Slow
		target.take_damage(dmg, Globals.ElementType.ICE)
