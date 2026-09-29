## RecruitManager — Manages the recruit roster, morale, mentorship, and relationships.
## Autoload-style helper (not an autoload, used by base and dungeon systems).

class_name RecruitManager
extends Node

# ---------------------------------------------------------------------------
# Morale system
# ---------------------------------------------------------------------------
const MORALE_MAX: float = 100.0
const MORALE_MIN: float = 0.0
const MORALE_RECRUIT_DEATH_PENALTY: float = -15.0
const MORALE_VICTORY_BONUS: float = 8.0
const MORALE_FESTIVAL_BONUS: float = 20.0
const MORALE_RAID_PENALTY: float = -10.0

var base_morale: float = 70.0

func change_morale(delta: float) -> void:
	base_morale = clamp(base_morale + delta, MORALE_MIN, MORALE_MAX)
	EventBus.notification_requested.emit(
		"Morale: %.0f%%" % base_morale,
		Color(0.8, 0.8, 0.4) if delta > 0 else Color(0.9, 0.4, 0.4)
	)

func get_morale_stat_multiplier() -> float:
	## Morale below 30 = -15% stats. Above 80 = +10% stats.
	if base_morale < 30.0:
		return 0.85
	elif base_morale > 80.0:
		return 1.10
	return 1.0

# ---------------------------------------------------------------------------
# Relationship system
# ---------------------------------------------------------------------------
## Relationships stored as Dictionary keyed by "name1_name2" alphabetically sorted.
var relationships: Dictionary = {}  # {pair_key: {type, level, child_born}}

enum RelationshipType { NEUTRAL, FRIEND, RIVAL, ROMANCE }

func record_interaction(name1: String, name2: String, positive: bool) -> void:
	var key: String = _pair_key(name1, name2)
	var rel: Dictionary = relationships.get(key, {"type": RelationshipType.NEUTRAL, "level": 0, "child_born": false})
	rel["level"] += 1 if positive else -1
	rel["level"] = clamp(rel["level"], -10, 10)
	# Determine type from level
	if rel["level"] >= 8:
		rel["type"] = RelationshipType.ROMANCE
		_check_child_birth(name1, name2, rel)
	elif rel["level"] >= 4:
		rel["type"] = RelationshipType.FRIEND
	elif rel["level"] <= -4:
		rel["type"] = RelationshipType.RIVAL
	else:
		rel["type"] = RelationshipType.NEUTRAL
	relationships[key] = rel

func _check_child_birth(name1: String, name2: String, rel: Dictionary) -> void:
	if rel.get("child_born", false):
		return
	if rel["level"] >= 10 and randf() < 0.15:
		rel["child_born"] = true
		EventBus.notification_requested.emit(
			name1 + " and " + name2 + " welcome a new child to the base!",
			Color(1.0, 0.8, 0.9)
		)
		# Request child creation via SaveManager
		var child_name: String = _generate_child_name(name1, name2)
		EventBus.recruit_joined_party.emit(null)  # Placeholder for child recruit creation

func _generate_child_name(p1: String, _p2: String) -> String:
	var suffixes: Array = ["jr.", "the Younger", "Dawn", "Hope"]
	return p1.split(" ")[0] + " " + suffixes[randi() % suffixes.size()]

func _pair_key(a: String, b: String) -> String:
	return (a if a < b else b) + "_" + (b if a < b else a)

func get_relationship(name1: String, name2: String) -> Dictionary:
	return relationships.get(_pair_key(name1, name2), {"type": RelationshipType.NEUTRAL, "level": 0})

# ---------------------------------------------------------------------------
# Veteran titles
# ---------------------------------------------------------------------------
const VETERAN_TITLE_THRESHOLDS: Array = [
	{"runs": 1, "title": "Novice"},
	{"runs": 5, "title": "Survivor"},
	{"runs": 10, "title": "Veteran"},
	{"runs": 25, "title": "Champion"},
	{"runs": 50, "title": "Legend"},
	{"runs": 100, "title": "Immortal"},
]

func get_veteran_title(runs_survived: int) -> String:
	var title: String = "Novice"
	for threshold in VETERAN_TITLE_THRESHOLDS:
		if runs_survived >= threshold["runs"]:
			title = threshold["title"]
	return title

# ---------------------------------------------------------------------------
# Recruit council (5 most senior recruits give hint)
# ---------------------------------------------------------------------------
func get_council_hint() -> String:
	var hints: Array = [
		"There is a weakness in this floor's boss. Watch for the tell.",
		"A town lies two rooms ahead. Conserve your resources.",
		"The Cursed Knight will mirror whatever element you use against it.",
		"The Ancient does not appear unless you search for it.",
		"LifePlant Petals can be traded for Revive Crystals at the Forge.",
		"Shadow Stalkers are weak to Light attacks — illuminate them.",
		"The Water Serpent floods the room. Stay near the edges.",
		"Completing the Arena Room nets triple loot. Worth the risk.",
		"The Rotting Warlord will summon skeletons at half health. Kill them fast.",
		"Malachar watches from beyond. He is amused by your struggles.",
	]
	return hints[randi() % hints.size()]

# ---------------------------------------------------------------------------
# Disciple party detection
# ---------------------------------------------------------------------------
func check_disciple_party_bonus(party: Array) -> bool:
	## Returns true if all 4 slots are disciples of the same mentor.
	if party.size() < 4:
		return false
	var mentor_name: String = ""
	for r in party:
		if not r is Dictionary:
			return false
		var mentor: String = r.get("mentor_name", "")
		if mentor == "":
			return false
		if mentor_name == "":
			mentor_name = mentor
		elif mentor_name != mentor:
			return false
	return true
