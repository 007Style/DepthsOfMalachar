## ArenaRoom — Wave-survival arena. Survive N waves of increasingly tough enemies for big loot.

class_name ArenaRoom
extends Room

const WAVE_COUNT: int = 3
const WAVE_BASE_ENEMIES: int = 3

var current_wave: int = 0
var wave_in_progress: bool = false

func _ready() -> void:
	_lock_doors()
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= WAVE_COUNT:
		_arena_complete()
		return
	current_wave += 1
	wave_in_progress = true
	enemies_alive = 0
	EventBus.notification_requested.emit("Wave %d/%d!" % [current_wave, WAVE_COUNT], Color(1.0, 0.7, 0.0))
	var enemy_count: int = WAVE_BASE_ENEMIES + current_wave
	for _i in enemy_count:
		_spawn_wave_enemy()

func _spawn_wave_enemy() -> void:
	var bm: BiomeManager = get_parent().get_node_or_null("BiomeManager")
	if not bm:
		bm = get_parent().get_parent().get_node_or_null("BiomeManager") if get_parent().get_parent() else null
	if not bm:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var scene_path: String = bm.get_random_enemy_scene(biome, rng)
	if scene_path == "":
		return
	var packed: PackedScene = load(scene_path)
	if not packed:
		return
	var enemy: Node = packed.instantiate()
	add_child(enemy)
	var offset: Vector2 = Vector2(randf_range(-100.0, 100.0), randf_range(-80.0, 80.0))
	enemy.global_position = global_position + offset
	if enemy.has_signal("died"):
		enemy.died.connect(_on_arena_enemy_died)
	enemies_alive += 1

func _on_arena_enemy_died(_enemy_node: Node, _pos: Vector2) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive == 0 and wave_in_progress:
		wave_in_progress = false
		var delay := get_tree().create_timer(1.5)
		delay.timeout.connect(_start_next_wave)

func _arena_complete() -> void:
	is_cleared = true
	_unlock_doors()
	# Drop extra loot — arena reward
	for _i in 3:
		var loot_scene: PackedScene = load("res://scenes/items/Loot.tscn")
		if loot_scene:
			var loot: Node = loot_scene.instantiate()
			add_child(loot)
			loot.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-30, 30))
	EventBus.coin_collected.emit(Globals.CoinType.SILVER, randi_range(3, 8))
	EventBus.notification_requested.emit("Arena cleared! Rewards dropped.", Color(1.0, 0.85, 0.0))
