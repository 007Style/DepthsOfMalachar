## Room — Base room script for The Depths of Malachar.
## Handles enemy spawning, door locking, floor completion detection,
## flashback triggers, and room-type specific logic dispatch.

class_name Room
extends Node2D

# ---------------------------------------------------------------------------
# Nodes (scene-assigned)
# ---------------------------------------------------------------------------
@onready var enemy_spawner: Node2D   = $EnemySpawner
@onready var door_north: Node2D      = $DoorNorth
@onready var door_south: Node2D      = $DoorSouth
@onready var door_east: Node2D       = $DoorEast
@onready var door_west: Node2D       = $DoorWest
@onready var flashback_trigger: Area2D = $FlashbackTrigger  # Optional
@onready var loot_spawner: Node2D    = $LootSpawner
@onready var floor_exit: Area2D      = get_node_or_null("FloorExit")

# ---------------------------------------------------------------------------
# Configuration (set by DungeonGenerator via setup())
# ---------------------------------------------------------------------------
var floor_num: int = 1
var biome: int = Globals.BiomeType.CATACOMBS
var room_type: int = Globals.RoomType.COMBAT
var is_cleared: bool = false
var enemies_alive: int = 0

# ---------------------------------------------------------------------------
# Enemy scene pool (set from BiomeManager)
# ---------------------------------------------------------------------------
var enemy_pool: Array = []

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup(f: int, b: int, p: Node, rtype: int = Globals.RoomType.COMBAT) -> void:
	floor_num = f
	biome = b
	room_type = rtype
	# Get enemy pool for biome
	var bm: BiomeManager = get_parent().get_node_or_null("BiomeManager")
	if not bm:
		bm = get_parent().get_parent().get_node_or_null("BiomeManager") if get_parent().get_parent() else null
	if bm:
		for _i in range(_get_enemy_count()):
			enemy_pool.append(bm.get_random_enemy_scene(biome, RandomNumberGenerator.new()))

## Return how many enemies to spawn based on floor and room type.
func _get_enemy_count() -> int:
	match room_type:
		Globals.RoomType.COMBAT: return randi_range(2, 4) + int(floor_num / 10)
		Globals.RoomType.ARENA:  return randi_range(5, 8)
		_:                       return 0

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_lock_doors()
	_spawn_enemies()
	if flashback_trigger and flashback_trigger.has_signal("body_entered"):
		flashback_trigger.body_entered.connect(_on_flashback_trigger)
	if floor_exit:
		floor_exit.body_entered.connect(_on_floor_exit_entered)
		var exit_spr: Sprite2D = floor_exit.get_node_or_null("FloorExitSprite")
		if exit_spr:
			var tw := create_tween().set_loops()
			tw.tween_property(exit_spr, "scale", Vector2(0.95, 0.95), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(exit_spr, "scale", Vector2(0.80, 0.80), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------------------------------------------------------------------------
# Enemy spawning
# ---------------------------------------------------------------------------
func _spawn_enemies() -> void:
	if room_type == Globals.RoomType.EMPTY or room_type == Globals.RoomType.TOWN:
		_unlock_doors()
		return
	for scene_path in enemy_pool:
		if scene_path == "":
			continue
		var packed: PackedScene = load(scene_path)
		if not packed:
			continue
		var enemy: Node = packed.instantiate()
		add_child(enemy)
		# Random position within spawner bounds
		var spawn_offset: Vector2 = Vector2(
			randf_range(-80.0, 80.0),
			randf_range(-60.0, 60.0)
		)
		enemy.global_position = global_position + spawn_offset
		# Wire death signal
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		enemies_alive += 1
	if enemies_alive == 0:
		# No enemies — room is immediately cleared
		is_cleared = true
		_unlock_doors()

func _on_enemy_died(_enemy_node: Node, _pos: Vector2) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive == 0 and not is_cleared:
		_clear_room()

# ---------------------------------------------------------------------------
# Door management
# ---------------------------------------------------------------------------
func _lock_doors() -> void:
	for door in [door_north, door_south, door_east, door_west]:
		if door and door.has_method("seal"):
			door.seal()

func _unlock_doors() -> void:
	for door in [door_north, door_south, door_east, door_west]:
		if door and door.has_method("unseal"):
			door.unseal()
	EventBus.room_cleared.emit(self)

# ---------------------------------------------------------------------------
# Room cleared
# ---------------------------------------------------------------------------
func _clear_room() -> void:
	is_cleared = true
	_unlock_doors()
	_spawn_loot()

func _spawn_loot() -> void:
	## Spawn a loot pickup with 30% base chance (more in deeper floors).
	var chance: float = 0.3 + floor_num * 0.002
	if randf() < chance:
		var loot_scene: PackedScene = load("res://scenes/items/Loot.tscn")
		if loot_scene:
			var loot: Node = loot_scene.instantiate()
			add_child(loot)
			loot.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20))

# ---------------------------------------------------------------------------
# Flashback trigger (environmental storytelling)
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Floor exit trigger
# ---------------------------------------------------------------------------
func _on_floor_exit_entered(body: Node) -> void:
	if body.is_in_group("player") and is_cleared:
		var dungeon: Node = get_parent()
		if dungeon and dungeon.has_method("advance_floor"):
			dungeon.advance_floor()

func _on_flashback_trigger(body: Node) -> void:
	if body.is_in_group("player"):
		EventBus.flashback_triggered.emit(global_position)
		# Disable after first trigger
		if flashback_trigger:
			flashback_trigger.set_deferred("monitoring", false)
