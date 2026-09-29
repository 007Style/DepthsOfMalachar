## SkeletonWarrior — Dark element melee fighter that revives once after death.
## On first death, regains 30% HP and briefly stuns nearby enemies.

class_name SkeletonWarrior
extends EnemyBase

var has_revived: bool = false
const REVIVE_HP_FRACTION: float = 0.30
const REVIVE_STUN_RADIUS: float = 80.0

func _ready() -> void:
	super._ready()

func _die() -> void:
	if is_dead:
		return
	# First death — revive
	if not has_revived:
		has_revived = true
		current_hp = max_hp * REVIVE_HP_FRACTION
		if health_bar:
			health_bar.value = current_hp
		_play_revive_effect()
		ai_state = AIState.CHASE
		return
	# Second death — actually die
	super._die()

func _play_revive_effect() -> void:
	# Flash purple to indicate revival
	sprite.modulate = Color(0.8, 0.2, 1.0)
	if animation_player.has_animation("revive"):
		animation_player.play("revive")
	else:
		# Brief stagger then recover
		ai_state = AIState.STUNNED
		var timer := get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			sprite.modulate = Color.WHITE
			ai_state = AIState.CHASE
		)
	# Small AoE knock on revival
	var bodies := []
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) < REVIVE_STUN_RADIUS:
			bodies.append(body)
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(enemy_data.base_damage * 0.5, Globals.ElementType.DARK)
