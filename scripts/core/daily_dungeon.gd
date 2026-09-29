## DailyDungeon — Daily Dungeon Mode
## Generates a consistent daily seed, tracks completion, manages scoring.
## Registered as Autoload singleton "DailyDungeon".

extends Node

var today_seed: int = 0
var completed_today: bool = false
var todays_score: int = 0
var personal_best: int = 0

func _ready() -> void:
	_update_daily_seed()
	personal_best = SaveManager.get_setting("daily_best", 0)
	var last_date: String = SaveManager.get_setting("daily_last_date", "")
	completed_today = (last_date == _get_today_string())

func _update_daily_seed() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	# Combine year, month, day into a unique integer seed
	today_seed = date["year"] * 10000 + date["month"] * 100 + date["day"]

func _get_today_string() -> String:
	var date: Dictionary = Time.get_date_dict_from_system()
	return "%d-%02d-%02d" % [date["year"], date["month"], date["day"]]

func get_today_seed() -> int:
	return today_seed

func is_completed_today() -> bool:
	_update_daily_seed()  # Refresh in case day changed
	var last_date: String = SaveManager.get_setting("daily_last_date", "")
	completed_today = (last_date == _get_today_string())
	return completed_today

func submit_score(score: int) -> void:
	todays_score = score
	completed_today = true
	SaveManager.set_setting("daily_last_date", _get_today_string())
	SaveManager.set_setting("daily_last_score", score)
	if score > personal_best:
		personal_best = score
		SaveManager.set_setting("daily_best", personal_best)
	EventBus.daily_dungeon_score_submitted.emit(score)

func calculate_score(floors: int, enemies: int, bosses: int, time_seconds: float) -> int:
	var base_score: int = floors * 100 + enemies * 10 + bosses * 500
	# Time bonus: faster = more points (cap bonus at 10000)
	var time_bonus: int = min(10000, int(10000.0 / max(1.0, time_seconds / 60.0)))
	return base_score + time_bonus
