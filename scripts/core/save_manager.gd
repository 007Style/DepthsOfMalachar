## SaveManager — Persistent Save/Load System
## Handles reading and writing all game state to disk.
## Registered as Autoload singleton "SaveManager".

extends Node

const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.json"
const LEGACY_SAVE_PATH: String   = "user://save_data.json"
const SAVE_VERSION: int = 1  # Increment when save schema changes
const MAX_SLOTS: int = 3

var current_slot: int = 1

# ---------------------------------------------------------------------------
# Recruit roster (stored here since recruits are complex objects)
# ---------------------------------------------------------------------------
var recruit_roster: Array = []       # Array of Dictionaries (serialised RecruitData)
var retired_recruits: Array = []     # Array of Dictionaries
var active_party: Array = []         # Array of recruit names in current party

# ---------------------------------------------------------------------------
# Pet roster
# ---------------------------------------------------------------------------
var pet_roster: Array = []           # Array of Dictionaries (serialised PetData)
var active_pet_name: String = ""

# ---------------------------------------------------------------------------
# Run journal / photo mode
# ---------------------------------------------------------------------------
var run_journal: Array = []          # Array of run summary Dictionaries

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"screen_shake": true,
	"auto_loot": false,
	"colorblind_mode": false,
	"larger_ui": false,
	"orientation": "sensor"
}

# ---------------------------------------------------------------------------
# Ready — auto-load on start
# ---------------------------------------------------------------------------
func _ready() -> void:
	load_game()

# ---------------------------------------------------------------------------
# Slot helpers
# ---------------------------------------------------------------------------
func get_save_path(slot: int = -1) -> String:
	var s: int = current_slot if slot <= 0 else slot
	return SAVE_PATH_TEMPLATE % s

func has_save(slot: int = -1) -> bool:
	var s: int = current_slot if slot <= 0 else slot
	var p: String = get_save_path(s)
	if FileAccess.file_exists(p):
		return true
	if s == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		return true
	return false

func get_slot_info(slot: int) -> Dictionary:
	var path: String = get_save_path(slot)
	if not FileAccess.file_exists(path):
		if slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
		else:
			return {"exists": false, "slot": slot}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"exists": false, "slot": slot}
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {"exists": true, "slot": slot, "corrupted": true}

	var data = json.get_data()
	if not data is Dictionary:
		return {"exists": true, "slot": slot, "corrupted": true}

	var prog: Dictionary = data.get("progression", {})
	var runs: int = prog.get("legacy_history", []).size()
	var gen: int = prog.get("legacy_generation", 0)
	var coins: int = prog.get("base_coins_copper", 0)
	var time_stamp: String = data.get("timestamp", "")
	var recruits: int = data.get("recruits", []).size()

	return {
		"exists": true,
		"slot": slot,
		"generation": gen,
		"runs": runs,
		"coins": coins,
		"recruits": recruits,
		"timestamp": time_stamp
	}

func select_slot(slot: int) -> void:
	current_slot = clamp(slot, 1, MAX_SLOTS)
	load_game()

func delete_save_slot(slot: int) -> void:
	var path: String = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(LEGACY_SAVE_PATH)
	if slot == current_slot:
		_reset_in_memory_state()

func _reset_in_memory_state() -> void:
	recruit_roster = []
	retired_recruits = []
	active_party = []
	pet_roster = []
	active_pet_name = ""
	run_journal = []
	ProgressionManager.reset_progress()

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
func save() -> void:
	var path: String = get_save_path()
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"slot": current_slot,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"progression": ProgressionManager.to_dict(),
		"recruits": recruit_roster,
		"retired_recruits": retired_recruits,
		"active_party": active_party,
		"pets": pet_roster,
		"active_pet": active_pet_name,
		"run_journal": run_journal,
		"settings": settings,
		"weapon_cabinet": _serialise_weapon_cabinet(),
		"permanent_artifacts": _serialise_permanent_artifacts()
	}
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("SaveManager: Failed to open save file for writing: " + path)

# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------
func load_game() -> void:
	var path: String = get_save_path()
	if not FileAccess.file_exists(path):
		# Check fallback for slot 1 migration
		if current_slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
		else:
			# Fresh game on this slot — reset in-memory state
			_reset_in_memory_state()
			return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file for reading: " + path)
		_reset_in_memory_state()
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: Save file is corrupted. Starting fresh. Error: " + str(json.get_error_message()))
		_reset_in_memory_state()
		return

	var data = json.get_data()
	if not data is Dictionary:
		push_error("SaveManager: Save data is not a valid Dictionary. Starting fresh.")
		_reset_in_memory_state()
		return

	# Version migration placeholder
	var version: int = data.get("version", 0)
	if version < SAVE_VERSION:
		_migrate_save(data, version)

	# Restore all systems
	if "progression" in data:
		ProgressionManager.from_dict(data["progression"])
	recruit_roster      = data.get("recruits", [])
	retired_recruits    = data.get("retired_recruits", [])
	active_party        = data.get("active_party", [])
	pet_roster          = data.get("pets", [])
	active_pet_name     = data.get("active_pet", "")
	run_journal         = data.get("run_journal", [])
	settings            = data.get("settings", settings)
	_deserialise_weapon_cabinet(data.get("weapon_cabinet", []))
	_deserialise_permanent_artifacts(data.get("permanent_artifacts", []))

# ---------------------------------------------------------------------------
# Recruit roster management
# ---------------------------------------------------------------------------
func add_recruit(recruit_dict: Dictionary) -> void:
	if recruit_roster.size() < ProgressionManager.recruit_cap:
		recruit_roster.append(recruit_dict)
		save()

func remove_recruit(recruit_name: String) -> void:
	recruit_roster = recruit_roster.filter(func(r): return r.get("recruit_name", "") != recruit_name)
	save()

func retire_recruit(recruit_dict: Dictionary) -> void:
	remove_recruit(recruit_dict.get("recruit_name", ""))
	recruit_dict["recall_count"] = recruit_dict.get("recall_count", 0)
	retired_recruits.append(recruit_dict)
	save()

func recall_recruit(recruit_name: String) -> bool:
	for i in range(retired_recruits.size()):
		var r: Dictionary = retired_recruits[i]
		if r.get("recruit_name", "") == recruit_name:
			if r.get("recall_count", 0) >= 5:
				return false  # Max recalls reached
			r["recall_count"] = r.get("recall_count", 0) + 1
			retired_recruits[i] = r
			# Move back to active roster
			if recruit_roster.size() < ProgressionManager.recruit_cap:
				recruit_roster.append(r)
				retired_recruits.remove_at(i)
				save()
				return true
	return false

func get_recruit_count() -> int:
	return recruit_roster.size()

func is_roster_full() -> bool:
	return recruit_roster.size() >= ProgressionManager.recruit_cap

# ---------------------------------------------------------------------------
# Run journal
# ---------------------------------------------------------------------------
func add_run_journal_entry(entry: Dictionary) -> void:
	run_journal.append(entry)
	# Keep last 100 entries
	if run_journal.size() > 100:
		run_journal.pop_front()
	save()

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
func set_setting(key: String, value) -> void:
	settings[key] = value
	save()

func get_setting(key: String, default_value = null):
	return settings.get(key, default_value)

# ---------------------------------------------------------------------------
# Serialisation helpers for resources
# WeaponData and ArtifactData resources are stored as Dictionaries in JSON.
# ---------------------------------------------------------------------------
func _serialise_weapon_cabinet() -> Array:
	var result: Array = []
	for weapon in ProgressionManager.weapon_cabinet:
		if weapon != null and weapon.has_method("to_dict"):
			result.append(weapon.to_dict())
	return result

func _deserialise_weapon_cabinet(data: Array) -> void:
	# Weapons are loaded as plain dictionaries for now.
	# Full resource deserialisation done when WeaponData class is available.
	ProgressionManager.weapon_cabinet.clear()
	for d in data:
		# Placeholder: store as raw dict until WeaponData resource loader is wired
		ProgressionManager.weapon_cabinet.append(d)

func _serialise_permanent_artifacts() -> Array:
	var result: Array = []
	for artifact in ProgressionManager.permanent_artifacts:
		if artifact != null and artifact.has_method("to_dict"):
			result.append(artifact.to_dict())
	return result

func _deserialise_permanent_artifacts(data: Array) -> void:
	ProgressionManager.permanent_artifacts.clear()
	for d in data:
		ProgressionManager.permanent_artifacts.append(d)

# ---------------------------------------------------------------------------
# Weapon cabinet management (called by WeaponKeepScreen)
# ---------------------------------------------------------------------------
func add_weapon_to_cabinet(weapon: WeaponData) -> void:
	if weapon == null:
		return
	const MAX_CABINET_WEAPONS: int = 50
	if ProgressionManager.weapon_cabinet.size() >= MAX_CABINET_WEAPONS:
		push_warning("SaveManager: Weapon cabinet full (%d weapons)" % MAX_CABINET_WEAPONS)
	ProgressionManager.weapon_cabinet.append(weapon)
	save()

func get_weapon_cabinet() -> Array:
	return ProgressionManager.weapon_cabinet

# ---------------------------------------------------------------------------
# Save migration
# ---------------------------------------------------------------------------
func _migrate_save(data: Dictionary, from_version: int) -> void:
	# Future: handle schema changes between versions
	push_warning("SaveManager: Migrating save from version %d to %d" % [from_version, SAVE_VERSION])
