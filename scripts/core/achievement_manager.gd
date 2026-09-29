## AchievementManager — Tracks and unlocks achievements.
## All achievement definitions and tracking logic in one place.

extends Node

# ---------------------------------------------------------------------------
# Achievement definitions {id, title, desc, condition_type, target, reward}
# ---------------------------------------------------------------------------
const ACHIEVEMENTS: Array = [
	{"id":"first_kill",          "title":"First Blood",           "desc":"Kill your first enemy.",           "condition":"enemies_killed",       "target":1,    "reward":""},
	{"id":"kill_100",            "title":"Veteran Slayer",        "desc":"Kill 100 enemies.",                "condition":"enemies_killed",       "target":100,  "reward":""},
	{"id":"kill_1000",           "title":"Mass Execution",        "desc":"Kill 1,000 enemies.",              "condition":"enemies_killed",       "target":1000, "reward":""},
	{"id":"first_boss",          "title":"Boss Slayer",           "desc":"Defeat your first boss.",          "condition":"bosses_killed",        "target":1,    "reward":""},
	{"id":"floor_10",            "title":"Descending",            "desc":"Reach Floor 10.",                  "condition":"deepest_floor",        "target":10,   "reward":""},
	{"id":"floor_50",            "title":"Deep Diver",            "desc":"Reach Floor 50.",                  "condition":"deepest_floor",        "target":50,   "reward":""},
	{"id":"floor_100",           "title":"Century Delver",        "desc":"Reach Floor 100.",                 "condition":"deepest_floor",        "target":100,  "reward":""},
	{"id":"floor_666",           "title":"The Devil's Floor",     "desc":"Reach Floor 666.",                 "condition":"deepest_floor",        "target":666,  "reward":"secret_artifact"},
	{"id":"first_recruit_death", "title":"A Name on the Wall",    "desc":"Lose a recruit.",                  "condition":"recruits_lost",        "target":1,    "reward":""},
	{"id":"all_starter_classes", "title":"Shape of Many",         "desc":"Play all 15 starter classes.",     "condition":"classes_played",       "target":15,   "reward":""},
	{"id":"class_mastery_1",     "title":"Master of One",         "desc":"Master one class.",                "condition":"class_mastery_count",  "target":1,    "reward":""},
	{"id":"class_mastery_all",   "title":"The True Form",         "desc":"Master all 15 classes.",           "condition":"class_mastery_count",  "target":15,   "reward":"true_form_unlock"},
	{"id":"first_revive",        "title":"Not Yet",               "desc":"Use a Revive Crystal.",            "condition":"revives_used",         "target":1,    "reward":""},
	{"id":"first_run_complete",  "title":"They Made It",          "desc":"Complete a full run to Malachar.", "condition":"malachar_defeated",    "target":1,    "reward":""},
	{"id":"defeat_malachar",     "title":"Demon King Slain",      "desc":"Defeat Malachar.",                 "condition":"malachar_defeated",    "target":1,    "reward":"ng_plus_unlock"},
	{"id":"daily_first",         "title":"Daily Delver",          "desc":"Complete a Daily Dungeon.",        "condition":"daily_completions",    "target":1,    "reward":""},
	{"id":"daily_streak_7",      "title":"Consistent Caller",     "desc":"Complete 7 Daily Dungeons.",       "condition":"daily_completions",    "target":7,    "reward":""},
	{"id":"lore_10",             "title":"Scholar",               "desc":"Unlock 10 lore entries.",          "condition":"lore_unlocked",        "target":10,   "reward":""},
	{"id":"lore_all",            "title":"Full Truth",            "desc":"Unlock all lore entries.",         "condition":"lore_unlocked",        "target":50,   "reward":"hidden_ending"},
	{"id":"ancient_defeated",    "title":"Before All Things",     "desc":"Defeat The Ancient (Floor 666).",  "condition":"ancient_defeated",     "target":1,    "reward":"secret_artifact"},
	{"id":"run_no_damage",       "title":"Ghost Run",             "desc":"Complete a floor without being hit.", "condition":"floor_no_damage",  "target":1,    "reward":""},
	{"id":"10_runs",             "title":"Habitual Descender",    "desc":"Complete 10 runs.",                "condition":"runs_completed",       "target":10,   "reward":""},
	{"id":"50_runs",             "title":"Eternal Return",        "desc":"Complete 50 runs.",                "condition":"runs_completed",       "target":50,   "reward":""},
	{"id":"first_legacy",        "title":"The Line Continues",    "desc":"Begin a Legacy Run.",              "condition":"legacy_generations",   "target":1,    "reward":""},
]

# ---------------------------------------------------------------------------
# Check and unlock
# ---------------------------------------------------------------------------
func check_all(player: Node = null) -> void:
	for ach in ACHIEVEMENTS:
		if ach["id"] in ProgressionManager.unlocked_achievements:
			continue
		var progress: int = ProgressionManager.achievement_progress.get(ach["condition"], 0)
		if progress >= ach["target"]:
			_unlock(ach, player)

func _unlock(ach: Dictionary, _player: Node) -> void:
	ProgressionManager.unlocked_achievements.append(ach["id"])
	EventBus.achievement_unlocked.emit(ach["id"])
	EventBus.notification_requested.emit("Achievement: " + ach["title"], Color(1.0, 0.85, 0.0))
	# Apply reward
	if ach["reward"] != "":
		_apply_reward(ach["reward"])
	SaveManager.save()

func _apply_reward(reward: String) -> void:
	match reward:
		"ng_plus_unlock":
			EventBus.notification_requested.emit("New Game+ Unlocked!", Color(1.0, 0.7, 0.0))
		"true_form_unlock":
			if Globals.ClassType.TRUE_FORM not in ProgressionManager.unlocked_classes:
				ProgressionManager.unlocked_classes.append(Globals.ClassType.TRUE_FORM)
			EventBus.class_unlocked.emit(Globals.ClassType.TRUE_FORM)
		"hidden_ending":
			EventBus.lore_entry_unlocked.emit("the_eighth_priest")
		_:
			pass
