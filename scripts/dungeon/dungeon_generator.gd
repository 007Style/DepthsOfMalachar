## DungeonGenerator — Procedural dungeon floor generator.
## Uses BSP (Binary Space Partitioning) to place rooms on a grid.
## Assigns room types, carves corridors, and handles floor transitions.

class_name DungeonGenerator
extends Node2D

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var tile_map: TileMapLayer = $TileMapLayer

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
const GRID_WIDTH: int = 10
const GRID_HEIGHT: int = 10
const ROOM_MIN_SIZE: int = 2   # In grid cells
const ROOM_MAX_SIZE: int = 4

# Tile source IDs (match your TileSet)
const TILE_FLOOR: Vector2i = Vector2i(0, 0)
const TILE_WALL: Vector2i  = Vector2i(1, 0)
const TILE_DOOR: Vector2i  = Vector2i(2, 0)

# Room type weights (adjusted by floor)
const BASE_ROOM_WEIGHTS: Dictionary = {
	Globals.RoomType.COMBAT:    50,
	Globals.RoomType.EMPTY:     10,
	Globals.RoomType.CHEST:     8,
	Globals.RoomType.TOWN:      7,
	Globals.RoomType.PUZZLE:    5,
	Globals.RoomType.TRAP:      5,
	Globals.RoomType.CURSE:     4,
	Globals.RoomType.MIRROR:    3,
	Globals.RoomType.ARENA:     4,
	Globals.RoomType.SHRINE:    3,
	Globals.RoomType.FLOODED:   3,
	Globals.RoomType.SECRET:    2
}

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var rooms: Array = []       # Array of room Dictionaries {rect, type, node}
var player_node: Node = null
var current_biome: int = Globals.BiomeType.CATACOMBS
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_daily_mode: bool = false

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	var floor_num: int = GameManager.current_floor
	current_biome = Globals.get_biome_for_floor(floor_num)
	is_daily_mode = GameManager.current_state == Globals.GameState.RUN # Check daily elsewhere
	if is_daily_mode and DailyDungeon.get_today_seed() != 0:
		rng.seed = DailyDungeon.get_today_seed() + floor_num
	else:
		rng.randomize()
	generate_floor(floor_num)

# ---------------------------------------------------------------------------
# Floor Generation
# ---------------------------------------------------------------------------
func generate_floor(floor_num: int) -> void:
	rooms.clear()
	tile_map.clear()
	var room_rects: Array = _bsp_partition(Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT))
	for rect in room_rects:
		var room_type: int = _assign_room_type(floor_num, rooms.size(), room_rects.size())
		rooms.append({"rect": rect, "type": room_type, "node": null})
	_carve_rooms()
	_carve_corridors()
	_assign_boss_room_if_needed(floor_num)
	_spawn_room_scenes(floor_num)
	_spawn_player()
	_check_floor_666(floor_num)

# ---------------------------------------------------------------------------
# BSP Partitioning
# ---------------------------------------------------------------------------
func _bsp_partition(area: Rect2i, depth: int = 0) -> Array:
	var result: Array = []
	if depth >= 4 or (area.size.x <= ROOM_MIN_SIZE * 2 and area.size.y <= ROOM_MIN_SIZE * 2):
		if area.size.x >= ROOM_MIN_SIZE and area.size.y >= ROOM_MIN_SIZE:
			result.append(area)
		return result
	var split_horizontal: bool = area.size.y > area.size.x
	if split_horizontal and area.size.y >= ROOM_MIN_SIZE * 2:
		var split_y: int = rng.randi_range(
			area.position.y + ROOM_MIN_SIZE,
			area.position.y + area.size.y - ROOM_MIN_SIZE
		)
		result.append_array(_bsp_partition(Rect2i(area.position, Vector2i(area.size.x, split_y - area.position.y)), depth + 1))
		result.append_array(_bsp_partition(Rect2i(Vector2i(area.position.x, split_y), Vector2i(area.size.x, area.position.y + area.size.y - split_y)), depth + 1))
	elif not split_horizontal and area.size.x >= ROOM_MIN_SIZE * 2:
		var split_x: int = rng.randi_range(
			area.position.x + ROOM_MIN_SIZE,
			area.position.x + area.size.x - ROOM_MIN_SIZE
		)
		result.append_array(_bsp_partition(Rect2i(area.position, Vector2i(split_x - area.position.x, area.size.y)), depth + 1))
		result.append_array(_bsp_partition(Rect2i(Vector2i(split_x, area.position.y), Vector2i(area.position.x + area.size.x - split_x, area.size.y)), depth + 1))
	else:
		result.append(area)
	return result

# ---------------------------------------------------------------------------
# Room type assignment
# ---------------------------------------------------------------------------
func _assign_room_type(floor_num: int, room_index: int, total_rooms: int) -> int:
	# First room is always empty (player start)
	if room_index == 0:
		return Globals.RoomType.EMPTY
	# Last room is the floor exit (combat leading to stairs)
	if room_index == total_rooms - 1:
		return Globals.RoomType.COMBAT
	# Boss rooms override
	if _is_boss_floor(floor_num) and room_index == total_rooms - 2:
		return _get_boss_room_type(floor_num)
	# Weighted random for all other rooms
	return _weighted_room_type(floor_num)

func _weighted_room_type(floor_num: int) -> int:
	var weights: Dictionary = BASE_ROOM_WEIGHTS.duplicate()
	# Increase town frequency slightly on deeper floors
	if floor_num > 20:
		weights[Globals.RoomType.TOWN] += 3
	var total: int = 0
	for w in weights.values():
		total += w
	var roll: int = rng.randi() % total
	var cumulative: int = 0
	for room_type in weights:
		cumulative += weights[room_type]
		if roll < cumulative:
			return room_type
	return Globals.RoomType.COMBAT

func _is_boss_floor(floor_num: int) -> bool:
	return floor_num % 10 == 0 and floor_num > 0

func _get_boss_room_type(floor_num: int) -> int:
	if floor_num % 100 == 0:
		return Globals.RoomType.SECRET_BOSS
	elif floor_num % 25 == 0:
		return Globals.RoomType.MAJOR_BOSS
	else:
		return Globals.RoomType.MINI_BOSS

func _assign_boss_room_if_needed(floor_num: int) -> void:
	if _is_boss_floor(floor_num) and rooms.size() > 0:
		rooms[rooms.size() - 1]["type"] = _get_boss_room_type(floor_num)

# ---------------------------------------------------------------------------
# Tile carving
# ---------------------------------------------------------------------------
func _carve_rooms() -> void:
	for room_data in rooms:
		var rect: Rect2i = room_data["rect"]
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for y in range(rect.position.y, rect.position.y + rect.size.y):
				tile_map.set_cell(Vector2i(x, y), 0, TILE_FLOOR)

func _carve_corridors() -> void:
	## Connect each room to the next with an L-shaped corridor.
	for i in range(rooms.size() - 1):
		var a_center: Vector2i = _room_center(rooms[i]["rect"])
		var b_center: Vector2i = _room_center(rooms[i + 1]["rect"])
		# Horizontal then vertical
		var x: int = a_center.x
		while x != b_center.x:
			tile_map.set_cell(Vector2i(x, a_center.y), 0, TILE_FLOOR)
			x += sign(b_center.x - x)
		var y: int = a_center.y
		while y != b_center.y:
			tile_map.set_cell(Vector2i(b_center.x, y), 0, TILE_FLOOR)
			y += sign(b_center.y - y)

func _room_center(rect: Rect2i) -> Vector2i:
	return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

# ---------------------------------------------------------------------------
# Room scene spawning
# ---------------------------------------------------------------------------
func _spawn_room_scenes(floor_num: int) -> void:
	for room_data in rooms:
		var scene_path: String = _get_room_scene_path(room_data["type"])
		if scene_path == "":
			continue
		var packed: PackedScene = load(scene_path)
		if not packed:
			continue
		var room_node: Node = packed.instantiate()
		add_child(room_node)
		var center: Vector2i = _room_center(room_data["rect"])
		room_node.position = Vector2(center.x * 64, center.y * 64)  # 64px tiles
		# Pass room_type so the room knows whether to spawn enemies, loot, etc.
		if room_node.has_method("setup"):
			room_node.setup(floor_num, current_biome, player_node, room_data["type"])
		room_data["node"] = room_node

func _get_room_scene_path(room_type: int) -> String:
	match room_type:
		Globals.RoomType.COMBAT:       return "res://scenes/rooms/Room.tscn"
		Globals.RoomType.TOWN:         return "res://scenes/rooms/TownRoom.tscn"
		Globals.RoomType.MINI_BOSS:    return "res://scenes/bosses/BossRoom.tscn"
		Globals.RoomType.MAJOR_BOSS:   return "res://scenes/bosses/BossRoom.tscn"
		Globals.RoomType.SECRET_BOSS:  return "res://scenes/bosses/BossRoom.tscn"
		Globals.RoomType.PUZZLE:       return "res://scenes/rooms/PuzzleRoom.tscn"
		Globals.RoomType.ARENA:        return "res://scenes/rooms/ArenaRoom.tscn"
		Globals.RoomType.CURSE:        return "res://scenes/rooms/CurseRoom.tscn"
		Globals.RoomType.MIRROR:       return "res://scenes/rooms/MirrorRoom.tscn"
		_:                             return "res://scenes/rooms/Room.tscn"

# ---------------------------------------------------------------------------
# Player spawn
# ---------------------------------------------------------------------------
func _spawn_player() -> void:
	# Remove old player if re-generating on floor advance
	if is_instance_valid(player_node):
		player_node.queue_free()
		player_node = null
	var player_scene: PackedScene = load("res://scenes/player/Ethari.tscn")
	if not player_scene:
		push_error("DungeonGenerator: Could not load Ethari.tscn")
		return
	player_node = player_scene.instantiate()
	add_child(player_node)
	if rooms.size() > 0:
		var start_center: Vector2i = _room_center(rooms[0]["rect"])
		player_node.position = Vector2(start_center.x * 64, start_center.y * 64)
	# Add dynamic Camera2D follower with smooth position smoothing
	var cam: Camera2D = Camera2D.new()
	cam.name = "PlayerCamera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player_node.add_child(cam)
	# Register player with HUD so buttons work
	var hud: Node = get_node_or_null("HUD")
	if hud and hud.has_method("register_player"):
		hud.register_player(player_node)

# ---------------------------------------------------------------------------
# Floor 666 special rule
# ---------------------------------------------------------------------------
func _check_floor_666(floor_num: int) -> void:
	if floor_num == 666:
		## Override the last room with the Floor 666 secret boss room.
		if rooms.size() > 0:
			rooms[rooms.size() - 1]["type"] = Globals.RoomType.SECRET_BOSS
		EventBus.notification_requested.emit("Floor 666 — Something stirs in the dark.", Color.RED)

# ---------------------------------------------------------------------------
# Floor transition (called when player reaches exit)
# ---------------------------------------------------------------------------
func advance_floor() -> void:
	var next_floor: int = GameManager.current_floor + 1
	# Update GameManager first so generate_floor() reads the correct floor
	GameManager.current_floor = next_floor
	EventBus.floor_changed.emit(next_floor)
	# Re-generate the floor in-place instead of reloading the full scene.
	# This avoids bypassing the GameManager transition system.
	current_biome = Globals.get_biome_for_floor(next_floor)
	# Re-seed RNG for new floor (daily mode uses deterministic seed)
	if is_daily_mode and DailyDungeon.get_today_seed() != 0:
		rng.seed = DailyDungeon.get_today_seed() + next_floor
	else:
		rng.randomize()
	generate_floor(next_floor)
