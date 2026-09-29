## GameManager — Central Game State Machine
## Manages the overall game state, scene transitions, and run lifecycle.
## Registered as Autoload singleton "GameManager".

extends Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_state: int = Globals.GameState.MENU
var current_floor: int = 0
var run_xp: int = 0
var run_coins_copper: int = 0
var run_resources: Dictionary = {}  # resources collected during run
var active_class: int = Globals.ClassType.WARRIOR
var ng_plus_tier: int = 0  # 0 = base game, 1 = NG+, 2 = NG++ etc.
var is_ironman: bool = false
var is_speedrun: bool = false
var speedrun_time: float = 0.0
var player_death_count_this_run: int = 0

# Run stats tracked for end screen
var run_stats: Dictionary = {
	"floors_reached": 0,
	"enemies_killed": 0,
	"bosses_killed": 0,
	"coins_collected": 0,
	"loot_collected": 0,
	"recruits_lost": [],
	"time_elapsed": 0.0,
	"class_used": Globals.ClassType.WARRIOR,
	"ng_plus_tier": 0
}

# Scene paths
const SCENE_MAIN_MENU: String    = "res://scenes/ui/MainMenu.tscn"
const SCENE_BASE: String         = "res://scenes/base/Base.tscn"
const SCENE_CLASS_SELECT: String = "res://scenes/ui/ClassSelect.tscn"
const SCENE_DUNGEON: String      = "res://scenes/rooms/DungeonGenerator.tscn"
const SCENE_GAME_OVER: String    = "res://scenes/ui/GameOver.tscn"
const SCENE_WEAPON_KEEP: String  = "res://scenes/ui/WeaponKeepScreen.tscn"
const SCENE_FUNERAL: String      = "res://scenes/ui/FuneralCutscene.tscn"
const SCENE_UPGRADE: String      = "res://scenes/ui/UpgradeTree.tscn"
const SCENE_TUTORIAL: String     = "res://scenes/ui/Tutorial.tscn"
const SCENE_SAVE_SLOTS: String   = "res://scenes/ui/SaveSlotScreen.tscn"

# Transition overlay node (set by Main scene on ready)
var _transition_overlay: CanvasLayer = null
var _pending_scene: String = ""
var _transitioning: bool = false

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	EventBus.dungeon_run_ended.connect(_on_run_ended)
	EventBus.player_died.connect(_on_player_died)
	EventBus.floor_changed.connect(_on_floor_changed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.boss_died.connect(_on_boss_died)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.recruit_died.connect(_on_recruit_died)

func _process(delta: float) -> void:
	if current_state == Globals.GameState.RUN and is_speedrun:
		speedrun_time += delta

# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------
func change_state(new_state: int) -> void:
	current_state = new_state

func go_to_main_menu() -> void:
	change_state(Globals.GameState.MENU)
	_transition_to_scene(SCENE_MAIN_MENU)

func go_to_base() -> void:
	change_state(Globals.GameState.BASE)
	_check_pending_funerals()
	_transition_to_scene(SCENE_BASE)

func start_class_select() -> void:
	change_state(Globals.GameState.CLASS_SELECT)
	_transition_to_scene(SCENE_CLASS_SELECT)

func start_run(class_type: int, ironman: bool = false, speedrun: bool = false) -> void:
	active_class = class_type
	is_ironman = ironman
	is_speedrun = speedrun
	speedrun_time = 0.0
	current_floor = 0
	run_xp = 0
	run_coins_copper = 0
	run_resources = {}
	player_death_count_this_run = 0
	_reset_run_stats(class_type)
	change_state(Globals.GameState.RUN)
	EventBus.dungeon_run_started.emit(current_floor)
	_transition_to_scene(SCENE_DUNGEON)

func end_run(reason: String) -> void:
	run_stats["time_elapsed"] = speedrun_time
	# Transfer run coins to base pool
	ProgressionManager.add_base_coins(run_coins_copper)
	# Transfer resources collected on death to base
	ProgressionManager.add_base_resources(run_resources)
	# Convert run XP to upgrade points
	var points_earned: int = run_xp / 1000
	if points_earned > 0:
		ProgressionManager.add_upgrade_points(points_earned)
	EventBus.dungeon_run_ended.emit(reason, run_stats)
	if reason == "death" and is_ironman:
		# Ironman: full permadeath — no weapon keep
		SaveManager.save()
		change_state(Globals.GameState.GAME_OVER)
		_transition_to_scene(SCENE_GAME_OVER)
	else:
		change_state(Globals.GameState.WEAPON_KEEP)
		_transition_to_scene(SCENE_WEAPON_KEEP)

func proceed_to_upgrade_screen() -> void:
	change_state(Globals.GameState.UPGRADE)
	_transition_to_scene(SCENE_UPGRADE)

# ---------------------------------------------------------------------------
# Run event handlers
# ---------------------------------------------------------------------------
func _on_player_died() -> void:
	player_death_count_this_run += 1
	# Resources already collected are flagged for base transfer in ethari.gd
	# GameManager handles ending the run if no revive crystal is available
	# (The actual revive crystal check is handled in ethari.gd)

func _on_floor_changed(new_floor: int) -> void:
	current_floor = new_floor
	run_stats["floors_reached"] = new_floor

func _on_enemy_died(_enemy_node: Node, _position: Vector2) -> void:
	run_stats["enemies_killed"] += 1

func _on_boss_died(_boss_node: Node) -> void:
	run_stats["bosses_killed"] += 1

func _on_coin_collected(coin_type: int, amount: int) -> void:
	# Convert to copper and add to run total
	var copper_value: int = amount
	match coin_type:
		Globals.CoinType.SILVER: copper_value = amount * Globals.COPPER_PER_SILVER
		Globals.CoinType.GOLD:   copper_value = amount * Globals.COPPER_PER_GOLD
	run_coins_copper += copper_value
	run_stats["coins_collected"] += copper_value

func _on_recruit_died(recruit_data: Resource, _position: Vector2) -> void:
	run_stats["recruits_lost"].append(recruit_data.recruit_name)

func _on_run_ended(_reason: String, _stats: Dictionary) -> void:
	SaveManager.save()

# ---------------------------------------------------------------------------
# Funeral check
# ---------------------------------------------------------------------------
func _check_pending_funerals() -> void:
	var pending: Array = ProgressionManager.get_pending_funerals()
	if pending.size() > 0:
		change_state(Globals.GameState.FUNERAL)
		# FuneralCutscene will call go_to_base() when done

# ---------------------------------------------------------------------------
# Scene transition (fade out → change → fade in)
# ---------------------------------------------------------------------------
func register_transition_overlay(overlay: CanvasLayer) -> void:
	_transition_overlay = overlay

## Public alias — use this from outside GameManager (base.gd etc.)
func transition_to_scene(scene_path: String) -> void:
	_transition_to_scene(scene_path)

func _transition_to_scene(scene_path: String) -> void:
	if _transitioning:
		_pending_scene = scene_path
		return
	_transitioning = true
	_pending_scene = scene_path
	if _transition_overlay and is_instance_valid(_transition_overlay):
		# Trigger fade-out animation; scene change happens in _on_fade_out_complete
		_transition_overlay.fade_out()
	else:
		# No overlay registered — change scene immediately and reset flag
		_do_scene_change()
		_transitioning = false

func on_fade_out_complete() -> void:
	_do_scene_change()

func on_fade_in_complete() -> void:
	_transitioning = false

func _do_scene_change() -> void:
	if _pending_scene != "":
		get_tree().change_scene_to_file(_pending_scene)
		_pending_scene = ""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func add_run_xp(amount: int) -> void:
	run_xp += amount
	EventBus.player_xp_gained.emit(amount)

func add_run_resource(resource_id: String, amount: int) -> void:
	if resource_id in run_resources:
		run_resources[resource_id] += amount
	else:
		run_resources[resource_id] = amount

func _reset_run_stats(class_type: int) -> void:
	run_stats = {
		"floors_reached": 0,
		"enemies_killed": 0,
		"bosses_killed": 0,
		"coins_collected": 0,
		"loot_collected": 0,
		"recruits_lost": [],
		"time_elapsed": 0.0,
		"class_used": class_type,
		"ng_plus_tier": ng_plus_tier
	}

func get_ng_plus_damage_multiplier() -> float:
	return 1.0 + ng_plus_tier * 0.25

func get_ng_plus_hp_multiplier() -> float:
	return 1.0 + ng_plus_tier * 0.3
