## BaseShop — Permanent base shop that rotates 4-6 artifacts per run.
## Sells permanent artifacts, consumables, and Revive Crystals using base coin pool.

class_name BaseShop
extends CanvasLayer

@onready var item_list: VBoxContainer = $Panel/ItemList
@onready var coins_label: Label       = $Panel/CoinsLabel
@onready var close_button: Button     = $Panel/CloseButton

const SHOP_ITEM_COUNT_MIN: int = 4
const SHOP_ITEM_COUNT_MAX: int = 6
const REVIVE_CRYSTAL_COST_GOLD: int = 1  # 1 Gold = Epic tier price

# ---------------------------------------------------------------------------
# Shop stock (rotates each run)
# ---------------------------------------------------------------------------
var shop_stock: Array = []  # Loaded from ProgressionManager

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	_generate_stock()
	_populate_ui()
	_update_coins_display()

func _generate_stock() -> void:
	shop_stock.clear()
	# Add Revive Crystal always
	shop_stock.append({
		"name": "Revive Crystal",
		"type": "consumable",
		"cost_gold": REVIVE_CRYSTAL_COST_GOLD,
		"cost_silver": 0,
		"description": "Revives Ethari or a fallen recruit.",
		"effect": "revive_crystal"
	})
	# Rotating artifact stock — placeholder items
	var artifact_names: Array = [
		"Ring of Embers", "Iron Resolve", "Shadow Cloak", "Storm Bracelet",
		"Soul Anchor", "Frost Heart", "Vine Pendant", "Dragon Scale Fragment",
		"Void Shard", "Aelion's Fragment"
	]
	var count: int = randi_range(SHOP_ITEM_COUNT_MIN, SHOP_ITEM_COUNT_MAX)
	var used: Array = []
	for _i in count:
		var idx: int = randi() % artifact_names.size()
		while idx in used:
			idx = randi() % artifact_names.size()
		used.append(idx)
		shop_stock.append({
			"name": artifact_names[idx],
			"type": "artifact",
			"cost_silver": randi_range(5, 30),
			"cost_gold": 0,
			"description": "A permanent artifact with lasting power.",
			"effect": "artifact_placeholder"
		})

func _populate_ui() -> void:
	if not item_list:
		return
	for child in item_list.get_children():
		child.queue_free()
	for item in shop_stock:
		var hbox: HBoxContainer = HBoxContainer.new()
		var name_lbl: Label = Label.new()
		name_lbl.text = item["name"]
		name_lbl.size_flags_horizontal = 3
		var price_lbl: Label = Label.new()
		if item["cost_gold"] > 0:
			price_lbl.text = "%d Gold" % item["cost_gold"]
		else:
			price_lbl.text = "%d Silver" % item["cost_silver"]
		var buy_btn: Button = Button.new()
		buy_btn.text = "Buy"
		var item_ref: Dictionary = item
		buy_btn.pressed.connect(func(): _buy_item(item_ref))
		hbox.add_child(name_lbl)
		hbox.add_child(price_lbl)
		hbox.add_child(buy_btn)
		item_list.add_child(hbox)

func _buy_item(item: Dictionary) -> void:
	var can_afford: bool = false
	if item["cost_gold"] > 0:
		can_afford = ProgressionManager.spend_base_coins(item["cost_gold"] * Globals.COPPER_PER_GOLD)
	else:
		can_afford = ProgressionManager.spend_base_coins(item["cost_silver"] * Globals.COPPER_PER_SILVER)
	if not can_afford:
		EventBus.notification_requested.emit("Not enough coins!", Color(1.0, 0.3, 0.3))
		return
	match item["effect"]:
		"revive_crystal":
			for player in get_tree().get_nodes_in_group("player"):
				if player.has_method("add_revive_crystal"):
					player.add_revive_crystal()
		"artifact_placeholder":
			EventBus.notification_requested.emit(item["name"] + " added to inventory!", Color(0.7, 0.5, 1.0))
	_update_coins_display()
	EventBus.notification_requested.emit("Purchased: " + item["name"], Color(0.5, 1.0, 0.5))

func _update_coins_display() -> void:
	if coins_label:
		var display: Dictionary = ProgressionManager.get_base_coins_display() if ProgressionManager.has_method("get_base_coins_display") else {}
		coins_label.text = "Gold: %d  Silver: %d  Copper: %d" % [
			display.get("gold", 0), display.get("silver", 0), display.get("copper", 0)
		]

func _close() -> void:
	visible = false
