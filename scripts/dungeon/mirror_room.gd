## MirrorRoom — Shows Ethari a vision of themselves — a reflection fight or revelation.
## Phase 1: Combat with a mirror-image of current class (same stats as player).
## Victory: Unlock lore about Ethari's nature.

class_name MirrorRoom
extends Room

var mirror_enemy: Node = null
var vision_triggered: bool = false

func _ready() -> void:
	_lock_doors()
	_spawn_mirror_enemy()

func _spawn_mirror_enemy() -> void:
	## Instantiate a corrupted version of the player's class as the mirror fight.
	var rival_scene: PackedScene = load("res://scenes/bosses/MajorBoss/RivalAdventurer.tscn")
	if not rival_scene:
		# Fallback — just unlock
		is_cleared = true
		_unlock_doors()
		return
	mirror_enemy = rival_scene.instantiate()
	add_child(mirror_enemy)
	mirror_enemy.global_position = global_position + Vector2(0, -60)
	if mirror_enemy.has_signal("died"):
		mirror_enemy.died.connect(_on_mirror_defeated)
	if mirror_enemy.has_method("setup"):
		var data: EnemyData = EnemyData.new()
		data.enemy_id = "mirror_reflection"
		data.enemy_name = "Mirror Reflection"
		data.element = Globals.ElementType.DARK
		data.base_hp = 80.0
		data.base_damage = 12.0
		mirror_enemy.setup(data, floor_num, null)

func _on_mirror_defeated(_enemy: Node, _pos: Vector2) -> void:
	is_cleared = true
	_unlock_doors()
	EventBus.lore_entry_unlocked.emit("mirror_room_revelation")
	EventBus.notification_requested.emit("The reflection dissolves. What are you?", Color(0.7, 0.7, 1.0))
