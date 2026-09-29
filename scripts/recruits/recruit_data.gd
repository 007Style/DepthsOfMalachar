## RecruitData — Resource defining a recruit's full profile.

class_name RecruitData
extends Resource

@export var recruit_name: String = ""
@export var class_type: int = Globals.ClassType.WARRIOR
@export var stats: Stats = null
@export var traits: Array = []           # Array of int (TraitType)
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 100
@export var backstory: String = ""
@export var birthday: Dictionary = {}    # {month, day}
@export var veteran_titles: Array = []   # Array of String title names
@export var runs_survived: int = 0

# Relationships
@export var bond_levels: Dictionary = {}        # {recruit_name: int 0-100}
@export var relationship_types: Dictionary = {} # {recruit_name: "friend"/"rival"/"romance"}

# Mentor/Disciple system
@export var mentor_name: String = ""     # Name of this recruit's mentor (if any)
@export var disciple_names: Array = []   # Array of String recruit names (max 4)
@export var is_retired: bool = false
@export var recall_count: int = 0        # How many times recalled from retirement (max 5)

# Grief state (after losing a bonded recruit)
@export var is_grieving: bool = false
@export var grieving_for: String = ""

# Lore
@export var portrait: Texture2D = null
@export var is_legendary: bool = false
@export var legendary_lore: String = ""

func get_bond_level(other_name: String) -> int:
	return bond_levels.get(other_name, 0)

func increase_bond(other_name: String, amount: int = 1) -> void:
	bond_levels[other_name] = min(100, bond_levels.get(other_name, 0) + amount)

func has_trait(trait_type: int) -> bool:
	return trait_type in traits

func add_veteran_title(title: String) -> void:
	if title not in veteran_titles:
		veteran_titles.append(title)

func gain_xp(amount: int) -> bool:
	## Returns true if leveled up.
	xp += amount
	if xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.3)
		_on_level_up()
		return true
	return false

func _on_level_up() -> void:
	if stats:
		stats.add_flat("max_hp", 8.0)
		stats.add_flat("base_damage", 2.0)
		stats.add_flat("move_speed", 3.0)
	# Veteran titles
	if runs_survived >= 5 and "Survivor" not in veteran_titles:
		add_veteran_title("Survivor")
	if runs_survived >= 20 and "Dungeon Veteran" not in veteran_titles:
		add_veteran_title("Dungeon Veteran")
	if level >= 10 and "Seasoned Fighter" not in veteran_titles:
		add_veteran_title("Seasoned Fighter")

func to_dict() -> Dictionary:
	return {
		"recruit_name": recruit_name,
		"class_type": class_type,
		"traits": traits,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level,
		"backstory": backstory,
		"birthday": birthday,
		"veteran_titles": veteran_titles,
		"runs_survived": runs_survived,
		"bond_levels": bond_levels,
		"relationship_types": relationship_types,
		"mentor_name": mentor_name,
		"disciple_names": disciple_names,
		"is_retired": is_retired,
		"recall_count": recall_count,
		"is_grieving": is_grieving,
		"grieving_for": grieving_for,
		"is_legendary": is_legendary
	}

static func from_dict(data: Dictionary) -> RecruitData:
	var r: RecruitData = RecruitData.new()
	r.recruit_name       = data.get("recruit_name", "Unknown")
	r.class_type         = data.get("class_type", Globals.ClassType.WARRIOR)
	r.traits             = data.get("traits", [])
	r.level              = data.get("level", 1)
	r.xp                 = data.get("xp", 0)
	r.xp_to_next_level   = data.get("xp_to_next_level", 100)
	r.backstory          = data.get("backstory", "")
	r.birthday           = data.get("birthday", {})
	r.veteran_titles     = data.get("veteran_titles", [])
	r.runs_survived      = data.get("runs_survived", 0)
	r.bond_levels        = data.get("bond_levels", {})
	r.relationship_types = data.get("relationship_types", {})
	r.mentor_name        = data.get("mentor_name", "")
	r.disciple_names     = data.get("disciple_names", [])
	r.is_retired         = data.get("is_retired", false)
	r.recall_count       = data.get("recall_count", 0)
	r.is_grieving        = data.get("is_grieving", false)
	r.grieving_for       = data.get("grieving_for", "")
	r.is_legendary       = data.get("is_legendary", false)
	r.stats              = Stats.new()
	return r
