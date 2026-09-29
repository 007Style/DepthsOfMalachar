## PuzzleRoom — Room with a simple pressure-plate puzzle that unlocks the exit.
## Player must activate all plates to open the door.

class_name PuzzleRoom
extends Room

@export var plate_count: int = 3
var plates_activated: int = 0
var puzzle_solved: bool = false

func _ready() -> void:
	_unlock_doors()  # Doors accessible but exit is sealed separately
	_spawn_puzzle_plates()

func _spawn_puzzle_plates() -> void:
	for i in plate_count:
		var angle: float = (TAU / plate_count) * i
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * 120.0
		# Placeholder — actual plate nodes defined in scene
		pass

func activate_plate() -> void:
	plates_activated += 1
	if plates_activated >= plate_count and not puzzle_solved:
		puzzle_solved = true
		_on_puzzle_solved()

func _on_puzzle_solved() -> void:
	_unlock_doors()
	EventBus.room_cleared.emit(self)
	EventBus.notification_requested.emit("Puzzle solved!", Color(0.8, 1.0, 0.6))
	# Spawn bonus chest
	var loot_scene: PackedScene = load("res://scenes/items/Loot.tscn")
	if loot_scene:
		var loot: Node = loot_scene.instantiate()
		add_child(loot)
		loot.global_position = global_position
