## PoisonCrawler — Poison element. Leaves a poison trail as it moves.
## Slow but persistent; the trail lingers and damages anyone who walks through it.

class_name PoisonCrawler
extends EnemyBase

const TRAIL_INTERVAL: float = 0.5
const TRAIL_DURATION: float = 4.0
const TRAIL_DAMAGE_PER_SEC: float = 5.0
const TRAIL_RADIUS: float = 22.0

var trail_timer: float = 0.0

@export var poison_pool_scene: PackedScene = null

func _process(delta: float) -> void:
	if is_dead:
		return
	_update_status_effect(delta)
	_update_attack_cooldown(delta)
	trail_timer -= delta
	if trail_timer <= 0.0:
		_drop_poison_pool()
		trail_timer = TRAIL_INTERVAL
	_run_ai(delta)

func _drop_poison_pool() -> void:
	if poison_pool_scene:
		var pool: Node = poison_pool_scene.instantiate()
		get_parent().add_child(pool)
		pool.global_position = global_position
		if pool.has_method("setup"):
			pool.setup(TRAIL_DAMAGE_PER_SEC, TRAIL_DURATION, TRAIL_RADIUS, floor_num)
	# Emit event for VFX even without scene
	EventBus.poison_pool_spawned.emit(global_position, TRAIL_RADIUS, TRAIL_DURATION) if \
		EventBus.has_signal("poison_pool_spawned") else null

func perform_attack() -> void:
	if is_dead or not target or not is_instance_valid(target):
		return
	animation_player.play("attack")
	var dmg: float = enemy_data.base_damage * (1.0 + evolution_tier * EVOLUTION_DMG_BONUS)
	dmg = Globals.scale_damage(dmg, floor_num)
	if target.has_method("take_damage"):
		target.take_damage(dmg, Globals.ElementType.POISON)
