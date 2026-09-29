## Base — The player's home base between dungeon runs.
## A walkable ruined temple of Aelion that grows as the player progresses.
## All interactive buildings are accessible via Area2D interaction zones.

class_name Base
extends Node2D

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var player: CharacterBody2D = $PlayerCharacter
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var festival_timer: Timer = $FestivalTimer
@onready var ambient_audio: AudioStreamPlayer = $AmbientAudio

# ---------------------------------------------------------------------------
# Building interaction zones — each is an Area2D with a label
# ---------------------------------------------------------------------------
@onready var altar_zone:         Area2D = $Buildings/AltarZone
@onready var weapon_cabinet_zone: Area2D = $Buildings/WeaponCabinetZone
@onready var recruit_quarters_zone: Area2D = $Buildings/RecruitQuartersZone
@onready var shop_zone:          Area2D = $Buildings/ShopZone
@onready var forge_zone:         Area2D = $Buildings/ForgeZone
@onready var library_zone:       Area2D = $Buildings/LibraryZone
@onready var tavern_zone:        Area2D = $Buildings/TavernZone
@onready var training_zone:      Area2D = $Buildings/TrainingGroundsZone
@onready var gardens_zone:       Area2D = $Buildings/GardensZone
@onready var dungeon_map_zone:   Area2D = $Buildings/DungeonMapZone
@onready var spy_network_zone:   Area2D = $Buildings/SpyNetworkZone
@onready var monument_zone:      Area2D = $Buildings/MonumentZone
@onready var hall_of_legends_zone: Area2D = $Buildings/HallOfLegendsZone
@onready var dungeon_entrance:   Area2D = $DungeonEntrance

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var progress_level: int = 0
var festival_active: bool = false
var buildings_damaged: Dictionary = {}  # building_name -> damage_level (0-3)

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_connect_zones()
	_apply_progress_visuals()
	_check_festival_trigger()
	_check_dream_sequence()
	_start_entrance_pulse()

func _start_entrance_pulse() -> void:
	var entrance_border: ColorRect = get_node_or_null("DungeonEntranceBorder")
	var entrance_label: Label = get_node_or_null("DungeonEntranceLabel")
	if entrance_border:
		var tw := create_tween().set_loops()
		tw.tween_property(entrance_border, "color", Color(0.8, 0.2, 1.0, 0.9), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(entrance_border, "color", Color(0.4, 0.0, 0.8, 0.4), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if entrance_label:
		var tw_lbl := create_tween().set_loops()
		tw_lbl.tween_property(entrance_label, "modulate", Color(1.0, 0.8, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_lbl.tween_property(entrance_label, "modulate", Color(0.7, 0.4, 0.9, 0.7), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	EventBus.base_raid_started.connect(_on_base_raid_started)
	EventBus.boss_died.connect(_on_boss_defeated)
	progress_level = ProgressionManager.get_progress_level() if ProgressionManager.has_method("get_progress_level") else 0

func _connect_zones() -> void:
	var zone_map: Dictionary = {
		altar_zone:          "open_altar",
		weapon_cabinet_zone: "open_weapon_cabinet",
		recruit_quarters_zone: "open_recruit_quarters",
		shop_zone:           "open_shop",
		forge_zone:          "open_forge",
		library_zone:        "open_library",
		tavern_zone:         "open_tavern",
		training_zone:       "open_training",
		gardens_zone:        "open_gardens",
		dungeon_map_zone:    "open_dungeon_map",
		spy_network_zone:    "open_spy_network",
		monument_zone:       "open_monument",
		hall_of_legends_zone: "open_hall_of_legends",
		dungeon_entrance:    "enter_dungeon",
	}
	for zone in zone_map:
		if zone:
			var method_name: String = zone_map[zone]
			zone.body_entered.connect(func(_body): _on_zone_entered(method_name))

func _on_zone_entered(action: String) -> void:
	match action:
		"open_altar":          _open_altar()
		"open_weapon_cabinet": _open_weapon_cabinet()
		"open_recruit_quarters": _open_recruit_quarters()
		"open_shop":           _open_shop()
		"open_forge":          _open_forge()
		"open_library":        _open_library()
		"open_tavern":         _open_tavern()
		"open_training":       EventBus.notification_requested.emit("Training Grounds — Recruits train here.", Color(0.7, 1.0, 0.5))
		"open_gardens":        EventBus.notification_requested.emit("Gardens — Grow ingredients for treats and crafting.", Color(0.4, 1.0, 0.4))
		"open_dungeon_map":    EventBus.notification_requested.emit("Dungeon Map — Next floor more revealed.", Color(0.7, 0.7, 1.0))
		"open_spy_network":    EventBus.notification_requested.emit("Spy Network — Scout enemy types ahead.", Color(0.5, 0.8, 0.5))
		"open_monument":       EventBus.notification_requested.emit("Monument Area — Great victories remembered.", Color(1.0, 0.9, 0.5))
		"open_hall_of_legends": _open_hall_of_legends()
		# Don't call start_run() here — class type must be chosen first.
		# Route through ClassSelect so the player picks a class before the run starts.
		"enter_dungeon":       GameManager.start_class_select()

# ---------------------------------------------------------------------------
# Building openers
# ---------------------------------------------------------------------------
func _open_altar() -> void:
	EventBus.notification_requested.emit("Altar of Aelion — Spend upgrade points.", Color(0.7, 0.9, 1.0))
	GameManager.proceed_to_upgrade_screen()

func _open_weapon_cabinet() -> void:
	EventBus.notification_requested.emit("Weapon Cabinet — Choose your starting weapon.", Color(0.8, 0.8, 0.4))

func _open_recruit_quarters() -> void:
	EventBus.notification_requested.emit("Recruit Quarters — Manage your companions.", Color(0.7, 0.8, 1.0))

func _open_shop() -> void:
	EventBus.notification_requested.emit("Base Shop — Permanent artifacts for sale.", Color(0.9, 0.8, 0.4))

func _open_forge() -> void:
	EventBus.notification_requested.emit("Forge — Craft weapons and brew potions.", Color(1.0, 0.6, 0.2))

func _open_library() -> void:
	EventBus.notification_requested.emit("Library — All discovered lore entries.", Color(0.6, 0.8, 1.0))
	if ResourceLoader.exists("res://scenes/ui/LoreLog.tscn"):
		GameManager.transition_to_scene("res://scenes/ui/LoreLog.tscn")
	else:
		EventBus.notification_requested.emit("Library not yet built.", Color(0.5, 0.5, 0.5))

func _open_tavern() -> void:
	base_morale_boost()

func _open_hall_of_legends() -> void:
	EventBus.notification_requested.emit("Hall of Legends — The story of all who came before.", Color(1.0, 0.85, 0.0))

# ---------------------------------------------------------------------------
# Progress visuals
# ---------------------------------------------------------------------------
func _apply_progress_visuals() -> void:
	## Lighter ambient colour as progress increases (base feels more hopeful).
	var brightness: float = 0.5 + progress_level * 0.08
	if canvas_modulate:
		canvas_modulate.color = Color(brightness, brightness * 0.95, brightness * 0.9, 1.0)

# ---------------------------------------------------------------------------
# Festival
# ---------------------------------------------------------------------------
func _check_festival_trigger() -> void:
	if ProgressionManager.has_method("has_new_boss_kill") and ProgressionManager.has_new_boss_kill():
		_trigger_festival()

func _trigger_festival() -> void:
	festival_active = true
	EventBus.base_festival_started.emit()
	EventBus.notification_requested.emit("🎉 Festival! Morale boosted. Special merchant in town!", Color(1.0, 0.9, 0.3))
	if festival_timer:
		festival_timer.start(30.0)

func base_morale_boost() -> void:
	EventBus.notification_requested.emit("Tavern night! Recruit morale boosted.", Color(0.9, 0.7, 0.4))

# ---------------------------------------------------------------------------
# Base raid
# ---------------------------------------------------------------------------
func _on_base_raid_started() -> void:
	EventBus.notification_requested.emit("BASE UNDER RAID! Defend your home!", Color(1.0, 0.2, 0.2))

func damage_building(building_name: String) -> void:
	buildings_damaged[building_name] = buildings_damaged.get(building_name, 0) + 1
	EventBus.base_building_damaged.emit(building_name)
	EventBus.notification_requested.emit(building_name + " damaged! Repair at the Forge.", Color(1.0, 0.4, 0.2))

func repair_building(building_name: String) -> void:
	buildings_damaged.erase(building_name)
	EventBus.base_building_repaired.emit(building_name)

# ---------------------------------------------------------------------------
# Boss defeated — progress update
# ---------------------------------------------------------------------------
func _on_boss_defeated(_boss_node: Node) -> void:
	progress_level = min(progress_level + 1, 10)
	_apply_progress_visuals()

# ---------------------------------------------------------------------------
# Dream sequence
# ---------------------------------------------------------------------------
func _check_dream_sequence() -> void:
	if randf() < 0.12:  # 12% chance each time base is loaded
		var delay := get_tree().create_timer(randf_range(5.0, 15.0))
		delay.timeout.connect(func():
			EventBus.dream_sequence_triggered.emit()
		)
