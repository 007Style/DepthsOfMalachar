## FriendSystem — In-Game Friend System
## Manages friend codes, friend lists, async co-op messages, and ghost runs.
## Friends-only visibility for ghost runs and async messages.
## Registered as Autoload singleton "FriendSystem".

extends Node

const FRIEND_CODE_LENGTH: int = 8
var my_friend_code: String = ""
var friend_list: Array = []  # Array of {name, code, online}

func _ready() -> void:
	_load_or_generate_friend_code()

func _load_or_generate_friend_code() -> void:
	my_friend_code = SaveManager.get_setting("friend_code", "")
	if my_friend_code == "":
		my_friend_code = _generate_code()
		SaveManager.set_setting("friend_code", my_friend_code)

func _generate_code() -> String:
	const CHARS: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code: String = ""
	for i in range(FRIEND_CODE_LENGTH):
		code += CHARS[randi() % CHARS.length()]
	return code

func add_friend(code: String) -> bool:
	code = code.to_upper().strip_edges()
	if code == my_friend_code:
		return false  # Cannot add yourself
	for f in friend_list:
		if f["code"] == code:
			return false  # Already a friend
	friend_list.append({"code": code, "name": "Unknown", "online": false})
	SaveManager.set_setting("friend_list", friend_list)
	return true

func remove_friend(code: String) -> void:
	friend_list = friend_list.filter(func(f): return f["code"] != code)
	SaveManager.set_setting("friend_list", friend_list)

func is_friend(code: String) -> bool:
	for f in friend_list:
		if f["code"] == code:
			return true
	return false

func get_friend_list() -> Array:
	return friend_list
