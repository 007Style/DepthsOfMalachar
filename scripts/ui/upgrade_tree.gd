## UpgradeTree — Visual node graph for the meta-progression upgrade tree.
## Shows all upgrade nodes with connections, costs, and lock states.
## Player spends upgrade points at the Altar to purchase nodes.

class_name UpgradeTree
extends CanvasLayer

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------
@onready var tree_container: Control = $ScrollContainer/TreeContainer
@onready var points_label: Label     = $PointsPanel/PointsLabel
@onready var close_button: Button    = $CloseButton

# ---------------------------------------------------------------------------
# Upgrade tree definition
# All nodes: {id, label, category, cost, prereqs, effect_desc, x, y}
# ---------------------------------------------------------------------------
const UPGRADE_NODES: Array = [
	# COMBAT
	{"id":"hp_1",    "label":"HP +20",       "category":"combat",    "cost":1, "prereqs":[],        "desc":"+20 Max HP",               "x":50,  "y":100},
	{"id":"hp_2",    "label":"HP +30",       "category":"combat",    "cost":2, "prereqs":["hp_1"],  "desc":"+30 Max HP",               "x":50,  "y":180},
	{"id":"hp_3",    "label":"HP +50",       "category":"combat",    "cost":3, "prereqs":["hp_2"],  "desc":"+50 Max HP",               "x":50,  "y":260},
	{"id":"dmg_1",   "label":"Damage +3",    "category":"combat",    "cost":1, "prereqs":[],        "desc":"+3 Base Damage",           "x":150, "y":100},
	{"id":"dmg_2",   "label":"Damage +5",    "category":"combat",    "cost":2, "prereqs":["dmg_1"], "desc":"+5 Base Damage",           "x":150, "y":180},
	{"id":"crit_1",  "label":"Crit +5%",     "category":"combat",    "cost":2, "prereqs":["dmg_1"], "desc":"+5% Crit Chance",          "x":150, "y":260},
	# MOBILITY
	{"id":"spd_1",   "label":"Speed +15",    "category":"mobility",  "cost":1, "prereqs":[],        "desc":"+15 Move Speed",           "x":280, "y":100},
	{"id":"spd_2",   "label":"Speed +20",    "category":"mobility",  "cost":2, "prereqs":["spd_1"], "desc":"+20 Move Speed",           "x":280, "y":180},
	# COMPANIONS
	{"id":"companion_slot_2", "label":"2nd Companion", "category":"companions", "cost":3, "prereqs":[], "desc":"Unlock Companion Slot 2", "x":400, "y":100},
	{"id":"companion_slot_3", "label":"3rd Companion", "category":"companions", "cost":5, "prereqs":["companion_slot_2"], "desc":"Unlock Companion Slot 3", "x":400, "y":180},
	{"id":"recruit_cap_100", "label":"Recruits +50", "category":"companions", "cost":3, "prereqs":[], "desc":"Recruit Cap: 100",         "x":400, "y":260},
	{"id":"recruit_cap_150", "label":"Recruits +50", "category":"companions", "cost":5, "prereqs":["recruit_cap_100"], "desc":"Recruit Cap: 150", "x":400, "y":340},
	{"id":"recruit_cap_200", "label":"Recruits +50", "category":"companions", "cost":7, "prereqs":["recruit_cap_150"], "desc":"Recruit Cap: 200", "x":400, "y":420},
	{"id":"recruit_cap_250", "label":"Recruits +50", "category":"companions", "cost":10, "prereqs":["recruit_cap_200"], "desc":"Recruit Cap: 250", "x":400, "y":500},
	# INVENTORY
	{"id":"artifact_slot_5", "label":"Artifact Slot 5", "category":"inventory", "cost":4, "prereqs":[], "desc":"5th Artifact Slot",     "x":520, "y":100},
	# ECONOMY
	{"id":"coin_bonus_1", "label":"Coin Rate +10%", "category":"economy", "cost":2, "prereqs":[], "desc":"+10% Coin Drop Rate",        "x":650, "y":100},
	{"id":"shop_discount", "label":"Shop -10%",   "category":"economy",  "cost":3, "prereqs":[], "desc":"Town Shop -10% prices",       "x":650, "y":180},
	# DUNGEON
	{"id":"chest_rate_1",  "label":"Chest +5%",   "category":"dungeon",  "cost":2, "prereqs":[], "desc":"+5% Chest Room Frequency",   "x":780, "y":100},
	{"id":"secret_room_1", "label":"Secret +3%",  "category":"dungeon",  "cost":3, "prereqs":[], "desc":"+3% Secret Room Chance",     "x":780, "y":180},
	{"id":"town_freq_1",   "label":"Town +3%",    "category":"dungeon",  "cost":2, "prereqs":[], "desc":"+3% Town Room Frequency",    "x":780, "y":260},
]

const CATEGORY_COLORS: Dictionary = {
	"combat":     Color(0.9, 0.3, 0.3),
	"mobility":   Color(0.3, 0.9, 0.5),
	"companions": Color(0.3, 0.6, 1.0),
	"inventory":  Color(0.8, 0.7, 0.3),
	"economy":    Color(1.0, 0.8, 0.2),
	"dungeon":    Color(0.6, 0.4, 0.9),
}

var node_buttons: Dictionary = {}  # {node_id: Button}

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	_build_tree()
	_update_points_display()
	EventBus.upgrade_purchased.connect(func(_id): _refresh_all_nodes())
	EventBus.upgrade_point_gained.connect(func(_total): _update_points_display())

func _close() -> void:
	GameManager.go_to_base()

# ---------------------------------------------------------------------------
# Build visual tree
# ---------------------------------------------------------------------------
func _build_tree() -> void:
	if not tree_container:
		return
	# Draw connections first (as lines)
	for node_def in UPGRADE_NODES:
		for prereq_id in node_def["prereqs"]:
			var prereq_def: Dictionary = _get_node_def(prereq_id)
			if prereq_def.is_empty():
				continue
			var line: Line2D = Line2D.new()
			line.points = [
				Vector2(node_def["x"] + 45, node_def["y"] + 20),
				Vector2(prereq_def["x"] + 45, prereq_def["y"] + 20)
			]
			line.width = 2.0
			line.default_color = Color(0.5, 0.5, 0.5, 0.7)
			tree_container.add_child(line)
	# Build node buttons
	for node_def in UPGRADE_NODES:
		var btn: Button = Button.new()
		btn.position = Vector2(node_def["x"], node_def["y"])
		btn.size = Vector2(90, 36)
		btn.text = node_def["label"] + "\n(%d pts)" % node_def["cost"]
		var nid: String = node_def["id"]
		btn.pressed.connect(func(): _try_purchase(nid))
		tree_container.add_child(btn)
		node_buttons[node_def["id"]] = btn
	_refresh_all_nodes()

func _refresh_all_nodes() -> void:
	for node_def in UPGRADE_NODES:
		var nid: String = node_def["id"]
		var btn: Button = node_buttons.get(nid)
		if not btn:
			continue
		var owned: bool = ProgressionManager.has_upgrade(nid)
		var unlocked: bool = _prereqs_met(node_def)
		var can_afford: bool = ProgressionManager.upgrade_points >= node_def["cost"]
		var cat_color: Color = CATEGORY_COLORS.get(node_def["category"], Color.WHITE)
		if owned:
			btn.modulate = cat_color
			btn.disabled = true
		elif unlocked and can_afford:
			btn.modulate = Color.WHITE
			btn.disabled = false
		else:
			btn.modulate = Color(0.4, 0.4, 0.4)
			btn.disabled = true

func _prereqs_met(node_def: Dictionary) -> bool:
	for prereq in node_def["prereqs"]:
		if not ProgressionManager.has_upgrade(prereq):
			return false
	return true

func _get_node_def(nid: String) -> Dictionary:
	for n in UPGRADE_NODES:
		if n["id"] == nid:
			return n
	return {}

func _try_purchase(node_id: String) -> void:
	var node_def: Dictionary = _get_node_def(node_id)
	if node_def.is_empty():
		return
	if ProgressionManager.purchase_upgrade(node_id, node_def["cost"]):
		EventBus.notification_requested.emit("Upgrade purchased: " + node_def["label"], Color(0.5, 1.0, 0.5))
	else:
		EventBus.notification_requested.emit("Not enough upgrade points!", Color(1.0, 0.4, 0.4))

func _update_points_display() -> void:
	if points_label:
		points_label.text = "Upgrade Points: %d" % ProgressionManager.upgrade_points
