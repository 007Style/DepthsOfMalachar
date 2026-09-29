## Town — Surviving town room script.
## Auto-heals player on entry, manages NPC interactions, shop, raid events,
## and world-state-reactive dialogue.

class_name Town
extends Node2D

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
const RAID_CHANCE: float = 0.20
const RAID_WAVE_COUNT: int = 3
const RAID_ENEMIES_PER_WAVE: int = 4

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var floor_num: int = 1
var biome: int = Globals.BiomeType.CATACOMBS
var raid_in_progress: bool = false
var raid_wave: int = 0
var raid_enemies_alive: int = 0

# ---------------------------------------------------------------------------
# World state tracking
# ---------------------------------------------------------------------------
var bosses_defeated: int = 0  # Read from GameManager

# ---------------------------------------------------------------------------
# Lore fragments (20+ lines)
# ---------------------------------------------------------------------------
const LORE_FRAGMENTS: Array = [
	"An old soldier whispers: \"They say the king still lives, somewhere below.\"",
	"A weeping woman: \"My children were taken by the Frost Wraiths. Please — find them.\"",
	"A merchant, haunted: \"I fled from the Volcanic Caves. Something followed me home.\"",
	"A scholar: \"The Aurelian Kingdom had seven high priests. We thought only seven.\"",
	"An innkeeper: \"Malachar's voice echoes in my dreams. He calls it 'his dungeon'.\"",
	"A child drawing on the floor: \"My drawing is the golden city. Daddy says it was real.\"",
	"A guard: \"The dungeon never ends. Every map we've made has been wrong.\"",
	"A wounded archer: \"The Shadow Stalkers — they were once like us.\"",
	"A priest, kneeling: \"Aelion sacrificed himself. Whatever came after is not divine.\"",
	"An elder: \"The ley lines are still broken. Magic is wrong here.\"",
	"A refugee: \"Floor 666 — my grandfather described it. He never came back from it.\"",
	"A blacksmith: \"The Steel Cursed Knights were the king's own guard. Look at them now.\"",
	"A healer: \"LifePlant essence keeps the light in their eyes a little longer.\"",
	"A gambler: \"I lost three runs' worth of gold betting against a Blood Bat race. Never again.\"",
	"A bard, quietly: \"I wrote a song about Ethari. You look more tired than the stories say.\"",
	"A scout: \"The Demon Sanctum is where Malachar sleeps. He is NOT fully awake. Not yet.\"",
	"An alchemist: \"Combine Fire and Ice essences. Something interesting happens.\"",
	"A young girl: \"Will you find my father? He went into the dungeon three weeks ago.\"",
	"A nervous monk: \"The Mirror Room showed me myself as I could have been. I almost didn't leave.\"",
	"A veteran survivor: \"Every time you die, something in the dungeon remembers.\"",
	"A mysterious stranger: \"The eighth priest... I knew them. I will not speak that name here.\"",
]

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_auto_heal_player()
	_check_raid()
	_apply_world_state_visuals()

func setup(f: int, b: int, _p: Node = null, _rtype: int = Globals.RoomType.TOWN) -> void:
	floor_num = f
	biome = b
	bosses_defeated = GameManager.get_world_bosses_defeated() if GameManager.has_method("get_world_bosses_defeated") else 0

# ---------------------------------------------------------------------------
# Auto-heal
# ---------------------------------------------------------------------------
func _auto_heal_player() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("heal"):
			player.heal(player.stats.max_hp)
	EventBus.notification_requested.emit("Town — HP fully restored.", Color(0.4, 1.0, 0.4))
	EventBus.town_entered.emit(self)

# ---------------------------------------------------------------------------
# Raid
# ---------------------------------------------------------------------------
func _check_raid() -> void:
	if randf() < RAID_CHANCE:
		var delay := get_tree().create_timer(3.0)
		delay.timeout.connect(_start_raid)

func _start_raid() -> void:
	raid_in_progress = true
	raid_wave = 0
	EventBus.town_raid_started.emit(self)
	EventBus.notification_requested.emit("RAID! Defend the town!", Color(1.0, 0.3, 0.3))
	_start_raid_wave()

func _start_raid_wave() -> void:
	if raid_wave >= RAID_WAVE_COUNT:
		_raid_victory()
		return
	raid_wave += 1
	raid_enemies_alive = 0
	EventBus.notification_requested.emit("Raid Wave %d/%d!" % [raid_wave, RAID_WAVE_COUNT], Color(1.0, 0.5, 0.0))
	for _i in RAID_ENEMIES_PER_WAVE:
		_spawn_raid_enemy()

func _spawn_raid_enemy() -> void:
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
	var edge_offset: Vector2 = Vector2(randf_range(-220.0, 220.0), 220.0)
	enemy.global_position = global_position + edge_offset
	if enemy.has_signal("died"):
		enemy.died.connect(_on_raid_enemy_died)
	raid_enemies_alive += 1

func _on_raid_enemy_died(_enemy_node: Node, _pos: Vector2) -> void:
	raid_enemies_alive = max(0, raid_enemies_alive - 1)
	if raid_enemies_alive == 0:
		var delay := get_tree().create_timer(1.0)
		delay.timeout.connect(_start_raid_wave)

func _raid_victory() -> void:
	raid_in_progress = false
	EventBus.town_raid_won.emit(null)  # Reward TBD by caller
	EventBus.notification_requested.emit("Raid defeated! Bonus reward dropped!", Color(1.0, 1.0, 0.0))
	EventBus.coin_collected.emit(Globals.CoinType.SILVER, randi_range(2, 6))

# ---------------------------------------------------------------------------
# World state visuals
# ---------------------------------------------------------------------------
func _apply_world_state_visuals() -> void:
	## Make town feel more lively as more bosses are defeated.
	var hope_level: int = mini(bosses_defeated, 4)
	# hop_level 0: dark and fearful, 4: bustling and bright
	# Visuals handled by TileMap palette swaps and NPC count in scene
	EventBus.notification_requested.emit(
		["A desperate survivors' camp.", "Hope is flickering here.", "People are beginning to smile again.", "This town feels almost like the old days.", "The light has returned to their eyes."][hope_level],
		Color(0.8, 0.9, 1.0)
	)

# ---------------------------------------------------------------------------
# Lore NPC
# ---------------------------------------------------------------------------
func get_random_lore_fragment() -> String:
	return LORE_FRAGMENTS[randi() % LORE_FRAGMENTS.size()]

# ---------------------------------------------------------------------------
# Shop interactions (delegated to TownUI)
# ---------------------------------------------------------------------------
func open_shop() -> void:
	EventBus.notification_requested.emit("Shop opened.", Color(0.9, 0.8, 0.4))

func open_gambling_den() -> void:
	## 50% chance: player's bet is doubled. 50%: lost.
	EventBus.notification_requested.emit("Gambling Den — Risk your coins!", Color(0.8, 0.6, 0.0))

func get_black_market_chance() -> bool:
	## Black Market appears rarely — 8% chance.
	return randf() < 0.08
