## TownUI — In-dungeon town interface panel.
## Contains: Shop, Artifact Vendor, Upgrade Station, Gambling Den, Black Market.
## Opened by interacting with town NPCs.

class_name TownUI
extends CanvasLayer

# ---------------------------------------------------------------------------
# Panels (scene nodes)
# ---------------------------------------------------------------------------
@onready var main_panel: Control       = $MainPanel
@onready var shop_panel: Control       = $ShopPanel
@onready var artifact_panel: Control   = $ArtifactPanel
@onready var upgrade_panel: Control    = $UpgradePanel
@onready var gambling_panel: Control   = $GamblingPanel
@onready var black_market_panel: Control = $BlackMarketPanel
@onready var lore_npc_label: Label     = $LoreLabel
@onready var close_button: Button      = $CloseButton

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var active_panel: Control = null
var floor_num: int = 1

# ---------------------------------------------------------------------------
# Weapon upgrade cost
# ---------------------------------------------------------------------------
const UPGRADE_COST_SILVER: int = 5
const GAMBLING_MIN_BET: int = 10
const GAMBLING_MAX_BET: int = 100

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_hide_all_panels()
	if close_button:
		close_button.pressed.connect(close)
	visible = false

func open(f: int, town_node: Town) -> void:
	floor_num = f
	visible = true
	_show_panel(main_panel)
	# Show lore
	if lore_npc_label and town_node:
		lore_npc_label.text = town_node.get_random_lore_fragment()

func close() -> void:
	visible = false
	_hide_all_panels()

func _hide_all_panels() -> void:
	for panel in [main_panel, shop_panel, artifact_panel, upgrade_panel, gambling_panel, black_market_panel]:
		if panel:
			panel.visible = false

func _show_panel(panel: Control) -> void:
	_hide_all_panels()
	active_panel = panel
	if panel:
		panel.visible = true

# ---------------------------------------------------------------------------
# Shop tab
# ---------------------------------------------------------------------------
func show_shop() -> void:
	_show_panel(shop_panel)

func buy_item(item: Resource, cost_silver: int) -> void:
	var player_coins: Dictionary = GameManager.get_run_coins() if GameManager.has_method("get_run_coins") else {}
	var silver: int = player_coins.get("silver", 0)
	if silver < cost_silver:
		EventBus.notification_requested.emit("Not enough Silver!", Color(1.0, 0.3, 0.3))
		return
	GameManager.spend_run_coins(Globals.CoinType.SILVER, cost_silver) if GameManager.has_method("spend_run_coins") else null
	EventBus.loot_collected.emit(item)
	EventBus.notification_requested.emit("Item purchased!", Color(0.5, 1.0, 0.5))

# ---------------------------------------------------------------------------
# Upgrade Station
# ---------------------------------------------------------------------------
func show_upgrade_station() -> void:
	_show_panel(upgrade_panel)

func upgrade_weapon() -> void:
	## Spends UPGRADE_COST_SILVER silver to upgrade equipped weapon +damage and optionally add element.
	if GameManager.has_method("spend_run_coins"):
		GameManager.spend_run_coins(Globals.CoinType.SILVER, UPGRADE_COST_SILVER)
	for player in get_tree().get_nodes_in_group("player"):
		if player.equipped_weapon:
			player.equipped_weapon.base_damage += 5.0
			EventBus.notification_requested.emit("Weapon upgraded! +5 damage.", Color(0.8, 0.8, 0.0))

# ---------------------------------------------------------------------------
# Gambling Den
# ---------------------------------------------------------------------------
func show_gambling_den() -> void:
	_show_panel(gambling_panel)

func gamble(bet_copper: int) -> void:
	if randf() < 0.5:
		# Win
		EventBus.coin_collected.emit(Globals.CoinType.COPPER, bet_copper * 2)
		EventBus.notification_requested.emit("You WON %d copper!" % (bet_copper * 2), Color(1.0, 1.0, 0.0))
	else:
		# Lose — coins already deducted by caller
		EventBus.notification_requested.emit("You lost %d copper. Better luck next time." % bet_copper, Color(0.8, 0.3, 0.3))

# ---------------------------------------------------------------------------
# Black Market
# ---------------------------------------------------------------------------
func show_black_market() -> void:
	_show_panel(black_market_panel)
	EventBus.notification_requested.emit("The Black Market whispers... cursed goods await.", Color(0.6, 0.0, 0.6))

# ---------------------------------------------------------------------------
# Artifact Vendor
# ---------------------------------------------------------------------------
func show_artifact_vendor() -> void:
	_show_panel(artifact_panel)
