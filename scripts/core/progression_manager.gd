## ProgressionManager — Persistent Meta-Progression
## Handles XP → upgrade points, upgrade tree state, base coins, recruit cap,
## permanent artifacts, weapon cabinet, class unlocks, mastery, legacy system.
## Registered as Autoload singleton "ProgressionManager".

extends Node

# ---------------------------------------------------------------------------
# Upgrade points & XP
# ---------------------------------------------------------------------------
var upgrade_points: int = 0
var lifetime_xp: int = 0  # Total XP earned across all runs

# ---------------------------------------------------------------------------
# Base coin pool (persists between runs)
# ---------------------------------------------------------------------------
var base_coins_copper: int = 0

# ---------------------------------------------------------------------------
# Base resources (materials from runs)
# ---------------------------------------------------------------------------
var base_resources: Dictionary = {}

# ---------------------------------------------------------------------------
# Recruit cap (starts at 50, upgradeable to 250)
# ---------------------------------------------------------------------------
var recruit_cap: int = 50
const RECRUIT_CAP_MAX: int = 250
const RECRUIT_CAP_UPGRADE_COST: int = 5  # upgrade points per +50 cap

# ---------------------------------------------------------------------------
# Companion slots (1 to 3)
# ---------------------------------------------------------------------------
var companion_slots: int = 1

# ---------------------------------------------------------------------------
# Upgrade tree — purchased node IDs
# ---------------------------------------------------------------------------
var purchased_upgrades: Array = []

# ---------------------------------------------------------------------------
# Class data
# ---------------------------------------------------------------------------
var unlocked_classes: Array = []       # ClassType ints
var class_mastery_counts: Dictionary = {}   # {ClassType: int}
var class_mastery_bonuses: Array = []  # ClassType ints that have mastery bonus unlocked
var class_quest_progress: Dictionary = {}   # {ClassType: int} progress toward class quest

# ---------------------------------------------------------------------------
# Weapon cabinet
# ---------------------------------------------------------------------------
var weapon_cabinet: Array = []     # Array of WeaponData resources
var equipped_start_weapon = null   # WeaponData or null

# ---------------------------------------------------------------------------
# Permanent artifacts
# ---------------------------------------------------------------------------
var permanent_artifacts: Array = []  # Array of ArtifactData resources

# ---------------------------------------------------------------------------
# Pets collected
# ---------------------------------------------------------------------------
var collected_pets: Array = []  # Array of PetData resources
var active_pet_index: int = -1

# ---------------------------------------------------------------------------
# Lore unlocks
# ---------------------------------------------------------------------------
var unlocked_lore_entries: Array = []  # Array of String entry IDs

# ---------------------------------------------------------------------------
# Legacy system
# ---------------------------------------------------------------------------
var legacy_generation: int = 0
var legacy_history: Array = []  # Array of run record Dictionaries
var ancestor_class_masteries: Dictionary = {}  # {ClassType: bonus_value}

# ---------------------------------------------------------------------------
# Pending funerals (recruits who died and need a funeral cutscene)
# ---------------------------------------------------------------------------
var pending_funerals: Array = []  # Array of RecruitData resources

# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------
var unlocked_achievements: Array = []  # Array of String achievement IDs
var achievement_progress: Dictionary = {}  # {achievement_id: current_value}

# ---------------------------------------------------------------------------
# Enemy evolution tracker
# ---------------------------------------------------------------------------
var enemy_death_counts: Dictionary = {}   # {enemy_type_id: times_killed}
var enemy_kill_causes: Dictionary = {}    # {enemy_type_id: how_many_times_killed_ethari}

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_init_default_unlocked_classes()
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.class_mastery_gained.connect(_on_class_mastery_gained)

func reset_progress() -> void:
	upgrade_points = 0
	lifetime_xp = 0
	base_coins_copper = 0
	base_resources = {}
	recruit_cap = 50
	companion_slots = 1
	purchased_upgrades = []
	unlocked_classes = []
	class_mastery_counts = {}
	class_mastery_bonuses = []
	class_quest_progress = {}
	unlocked_lore_entries = []
	legacy_generation = 0
	legacy_history = []
	ancestor_class_masteries = {}
	unlocked_achievements = []
	achievement_progress = {}
	enemy_death_counts = {}
	enemy_kill_causes = {}
	weapon_cabinet = []
	equipped_start_weapon = null
	permanent_artifacts = []
	collected_pets = []
	active_pet_index = -1
	pending_funerals = []
	_init_default_unlocked_classes()

func _init_default_unlocked_classes() -> void:
	# All 15 starter classes are available from the start
	var starters: Array = [
		Globals.ClassType.WARRIOR, Globals.ClassType.MAGE, Globals.ClassType.ROGUE,
		Globals.ClassType.NECROMANCER, Globals.ClassType.PALADIN, Globals.ClassType.ARCHER,
		Globals.ClassType.DRUID, Globals.ClassType.ASSASSIN, Globals.ClassType.BERSERKER,
		Globals.ClassType.ELEMENTALIST, Globals.ClassType.MONK, Globals.ClassType.BARD,
		Globals.ClassType.SUMMONER, Globals.ClassType.WITCH_HUNTER, Globals.ClassType.KNIGHT
	]
	for c in starters:
		if c not in unlocked_classes:
			unlocked_classes.append(c)

# ---------------------------------------------------------------------------
# Upgrade points
# ---------------------------------------------------------------------------
func add_upgrade_points(amount: int) -> void:
	upgrade_points += amount
	EventBus.upgrade_point_gained.emit(upgrade_points)

func spend_upgrade_points(amount: int) -> bool:
	if upgrade_points >= amount:
		upgrade_points -= amount
		return true
	return false

# ---------------------------------------------------------------------------
# Upgrade tree
# ---------------------------------------------------------------------------
func purchase_upgrade(node_id: String, cost: int) -> bool:
	if node_id in purchased_upgrades:
		return false
	if not spend_upgrade_points(cost):
		return false
	purchased_upgrades.append(node_id)
	_apply_upgrade_effect(node_id)
	EventBus.upgrade_purchased.emit(node_id)
	SaveManager.save()
	return true

func has_upgrade(node_id: String) -> bool:
	return node_id in purchased_upgrades

func _apply_upgrade_effect(node_id: String) -> void:
	match node_id:
		"companion_slot_2":
			companion_slots = max(companion_slots, 2)
		"companion_slot_3":
			companion_slots = max(companion_slots, 3)
		"recruit_cap_100":
			recruit_cap = max(recruit_cap, 100)
		"recruit_cap_150":
			recruit_cap = max(recruit_cap, 150)
		"recruit_cap_200":
			recruit_cap = max(recruit_cap, 200)
		"recruit_cap_250":
			recruit_cap = max(recruit_cap, 250)

func _on_upgrade_purchased(_node_id: String) -> void:
	pass  # Additional side effects handled per system

# ---------------------------------------------------------------------------
# Base coins
# ---------------------------------------------------------------------------
func add_base_coins(copper_amount: int) -> void:
	base_coins_copper += copper_amount

func spend_base_coins(copper_amount: int) -> bool:
	if base_coins_copper >= copper_amount:
		base_coins_copper -= copper_amount
		return true
	return false

func get_base_coins_display() -> Dictionary:
	return Globals.coins_to_display(base_coins_copper)

# ---------------------------------------------------------------------------
# Base resources
# ---------------------------------------------------------------------------
func add_base_resources(resources: Dictionary) -> void:
	for key in resources:
		if key in base_resources:
			base_resources[key] += resources[key]
		else:
			base_resources[key] = resources[key]

func spend_resource(resource_id: String, amount: int) -> bool:
	if base_resources.get(resource_id, 0) >= amount:
		base_resources[resource_id] -= amount
		return true
	return false

func get_resource(resource_id: String) -> int:
	return base_resources.get(resource_id, 0)

# ---------------------------------------------------------------------------
# Weapon cabinet
# ---------------------------------------------------------------------------
func add_weapon_to_cabinet(weapon_data: Resource) -> void:
	weapon_cabinet.append(weapon_data)
	SaveManager.save()

func set_start_weapon(weapon_data: Resource) -> void:
	equipped_start_weapon = weapon_data
	SaveManager.save()

func get_start_weapon() -> Resource:
	return equipped_start_weapon

# ---------------------------------------------------------------------------
# Permanent artifacts
# ---------------------------------------------------------------------------
func add_permanent_artifact(artifact_data: Resource) -> void:
	permanent_artifacts.append(artifact_data)
	SaveManager.save()

func get_permanent_artifacts() -> Array:
	return permanent_artifacts

# ---------------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------------
func unlock_class(class_type: int) -> void:
	if class_type not in unlocked_classes:
		unlocked_classes.append(class_type)
		EventBus.class_unlocked.emit(class_type)
		SaveManager.save()

func is_class_unlocked(class_type: int) -> bool:
	return class_type in unlocked_classes

func record_class_run(class_type: int) -> void:
	if class_type not in class_mastery_counts:
		class_mastery_counts[class_type] = 0
	class_mastery_counts[class_type] += 1
	var count: int = class_mastery_counts[class_type]
	EventBus.class_mastery_gained.emit(class_type, count)
	# Check mastery bonus threshold (10 runs with same class = mastery bonus)
	if count == 10 and class_type not in class_mastery_bonuses:
		class_mastery_bonuses.append(class_type)
	# Check True Form unlock (all classes mastered)
	_check_true_form_unlock()

func has_class_mastery(class_type: int) -> bool:
	return class_type in class_mastery_bonuses

func _check_true_form_unlock() -> void:
	if Globals.ClassType.TRUE_FORM in unlocked_classes:
		return
	# True Form requires all other classes mastered
	for c in unlocked_classes:
		if c == Globals.ClassType.TRUE_FORM:
			continue
		if c not in class_mastery_bonuses:
			return
	unlock_class(Globals.ClassType.TRUE_FORM)

func _on_class_mastery_gained(_class_type: int, _count: int) -> void:
	SaveManager.save()

func get_class_mastery_bonus(class_type: int) -> float:
	## Returns a flat stat multiplier bonus for having mastered this class.
	if class_type in class_mastery_bonuses:
		return 0.05  # +5% to all stats when playing mastered class
	return 0.0

# ---------------------------------------------------------------------------
# Progress level — overall base development level (0–10)
# Derived from how many boss kills / upgrades have been made.
# ---------------------------------------------------------------------------
func get_progress_level() -> int:
	## Returns a 0–10 score reflecting overall meta-progression.
	## Based on total upgrade points ever earned (lifetime_xp / 1000),
	## number of class masteries unlocked, and legacy generation.
	var score: int = 0
	score += mini(class_mastery_bonuses.size(), 5)          # 0–5 from masteries
	score += mini(legacy_generation, 3)                      # 0–3 from legacy gens
	score += mini(purchased_upgrades.size() / 3, 2)         # 0–2 from upgrade tree
	return mini(score, 10)

# ---------------------------------------------------------------------------
# Class quest progress
# ---------------------------------------------------------------------------
func update_class_quest(class_type: int, amount: int) -> void:
	if class_type not in class_quest_progress:
		class_quest_progress[class_type] = 0
	class_quest_progress[class_type] += amount

func get_class_quest_progress(class_type: int) -> int:
	return class_quest_progress.get(class_type, 0)

# ---------------------------------------------------------------------------
# Lore entries
# ---------------------------------------------------------------------------
func unlock_lore_entry(entry_id: String) -> void:
	if entry_id not in unlocked_lore_entries:
		unlocked_lore_entries.append(entry_id)
		EventBus.lore_entry_unlocked.emit(entry_id)
		SaveManager.save()

func is_lore_unlocked(entry_id: String) -> bool:
	return entry_id in unlocked_lore_entries

# ---------------------------------------------------------------------------
# Funerals
# ---------------------------------------------------------------------------
func add_pending_funeral(recruit_data: Resource) -> void:
	pending_funerals.append(recruit_data)

func get_pending_funerals() -> Array:
	return pending_funerals

func clear_pending_funerals() -> void:
	pending_funerals.clear()

# ---------------------------------------------------------------------------
# Legacy system
# ---------------------------------------------------------------------------
func begin_legacy_run(previous_run_record: Dictionary) -> void:
	legacy_generation += 1
	legacy_history.append(previous_run_record)
	# Extract ancestor class mastery bonuses from previous Ethari
	var prev_masteries = previous_run_record.get("class_masteries", {})
	for class_type in prev_masteries:
		if class_type not in ancestor_class_masteries:
			ancestor_class_masteries[class_type] = 0.0
		ancestor_class_masteries[class_type] += 0.01  # +1% per generation for mastered class
	EventBus.legacy_run_started.emit(legacy_generation)
	SaveManager.save()

func get_ancestor_bonus(class_type: int) -> float:
	return ancestor_class_masteries.get(class_type, 0.0)

func get_legacy_history() -> Array:
	return legacy_history

# ---------------------------------------------------------------------------
# Enemy evolution
# ---------------------------------------------------------------------------
func record_enemy_kill(enemy_type_id: String) -> void:
	enemy_death_counts[enemy_type_id] = enemy_death_counts.get(enemy_type_id, 0) + 1

func record_enemy_killed_player(enemy_type_id: String) -> void:
	enemy_kill_causes[enemy_type_id] = enemy_kill_causes.get(enemy_type_id, 0) + 1

func get_enemy_evolution_tier(enemy_type_id: String) -> int:
	## Returns 0, 1, or 2 depending on how many times this enemy type has killed the player.
	var kill_count: int = enemy_kill_causes.get(enemy_type_id, 0)
	if kill_count >= 10:
		return 2
	elif kill_count >= 5:
		return 1
	return 0

# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------
func unlock_achievement(achievement_id: String) -> void:
	if achievement_id not in unlocked_achievements:
		unlocked_achievements.append(achievement_id)
		EventBus.achievement_unlocked.emit(achievement_id)
		SaveManager.save()

func increment_achievement_progress(achievement_id: String, amount: int = 1) -> void:
	achievement_progress[achievement_id] = achievement_progress.get(achievement_id, 0) + amount

func get_achievement_progress(achievement_id: String) -> int:
	return achievement_progress.get(achievement_id, 0)

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

# ---------------------------------------------------------------------------
# Serialisation (called by SaveManager)
# ---------------------------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"upgrade_points": upgrade_points,
		"lifetime_xp": lifetime_xp,
		"base_coins_copper": base_coins_copper,
		"base_resources": base_resources,
		"recruit_cap": recruit_cap,
		"companion_slots": companion_slots,
		"purchased_upgrades": purchased_upgrades,
		"unlocked_classes": unlocked_classes,
		"class_mastery_counts": class_mastery_counts,
		"class_mastery_bonuses": class_mastery_bonuses,
		"class_quest_progress": class_quest_progress,
		"unlocked_lore_entries": unlocked_lore_entries,
		"legacy_generation": legacy_generation,
		"legacy_history": legacy_history,
		"ancestor_class_masteries": ancestor_class_masteries,
		"unlocked_achievements": unlocked_achievements,
		"achievement_progress": achievement_progress,
		"enemy_death_counts": enemy_death_counts,
		"enemy_kill_causes": enemy_kill_causes
	}

func from_dict(data: Dictionary) -> void:
	upgrade_points          = data.get("upgrade_points", 0)
	lifetime_xp             = data.get("lifetime_xp", 0)
	base_coins_copper       = data.get("base_coins_copper", 0)
	base_resources          = data.get("base_resources", {})
	recruit_cap             = data.get("recruit_cap", 50)
	companion_slots         = data.get("companion_slots", 1)
	purchased_upgrades      = data.get("purchased_upgrades", [])
	unlocked_classes        = data.get("unlocked_classes", [])
	class_mastery_counts    = data.get("class_mastery_counts", {})
	class_mastery_bonuses   = data.get("class_mastery_bonuses", [])
	class_quest_progress    = data.get("class_quest_progress", {})
	unlocked_lore_entries   = data.get("unlocked_lore_entries", [])
	legacy_generation       = data.get("legacy_generation", 0)
	legacy_history          = data.get("legacy_history", [])
	ancestor_class_masteries = data.get("ancestor_class_masteries", {})
	unlocked_achievements   = data.get("unlocked_achievements", [])
	achievement_progress    = data.get("achievement_progress", {})
	enemy_death_counts      = data.get("enemy_death_counts", {})
	enemy_kill_causes       = data.get("enemy_kill_causes", {})
	# Ensure starter classes are always present even on legacy data
	_init_default_unlocked_classes()
