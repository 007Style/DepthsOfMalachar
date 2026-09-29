## ClassController — Loads and applies a ClassData to Ethari.
## Manages abilities, stances, ultimate cooldown.

class_name ClassController
extends Node

signal ultimate_ready()
signal ultimate_used(cooldown: float)
signal stance_changed(stance_index: int)  # 0 = A, 1 = B

var active_class_data: ClassData = null
var current_stance: int = 0  # 0 = A, 1 = B
var ultimate_timer: float = 0.0
var is_ultimate_ready: bool = true

# Loaded ability nodes
var _ability_1_node: Node = null
var _ability_2_node: Node = null
var _ultimate_node: Node = null

func _process(delta: float) -> void:
	if not is_ultimate_ready and active_class_data != null:
		ultimate_timer -= delta
		var cooldown: float = max(0.001, active_class_data.ultimate_cooldown)
		EventBus.hud_update_ultimate_cooldown.emit(
			clamp(1.0 - (ultimate_timer / cooldown), 0.0, 1.0)
		)
		if ultimate_timer <= 0.0:
			is_ultimate_ready = true
			ultimate_timer = 0.0
			EventBus.hud_update_ultimate_cooldown.emit(1.0)
			ultimate_ready.emit()

## Load a class and apply it to the parent entity.
func load_class(class_data: ClassData) -> void:
	active_class_data = class_data
	current_stance = 0
	is_ultimate_ready = true
	ultimate_timer = 0.0
	_unload_abilities()
	_load_abilities()

func _unload_abilities() -> void:
	if _ability_1_node and is_instance_valid(_ability_1_node):
		_ability_1_node.queue_free()
	if _ability_2_node and is_instance_valid(_ability_2_node):
		_ability_2_node.queue_free()
	if _ultimate_node and is_instance_valid(_ultimate_node):
		_ultimate_node.queue_free()
	_ability_1_node = null
	_ability_2_node = null
	_ultimate_node = null

func _load_abilities() -> void:
	if not active_class_data:
		return
	if active_class_data.ability_1_scene != "":
		_ability_1_node = load(active_class_data.ability_1_scene).instantiate()
		get_parent().add_child(_ability_1_node)
	if active_class_data.ability_2_scene != "":
		_ability_2_node = load(active_class_data.ability_2_scene).instantiate()
		get_parent().add_child(_ability_2_node)
	if active_class_data.ultimate_scene != "":
		_ultimate_node = load(active_class_data.ultimate_scene).instantiate()
		get_parent().add_child(_ultimate_node)

## Use primary attack (routes to current weapon + class passive).
func use_primary(target_position: Vector2) -> void:
	# Handled in ethari.gd using equipped weapon
	pass

## Use ability 1.
func use_ability_1(target_position: Vector2) -> void:
	if _ability_1_node and _ability_1_node.has_method("activate"):
		_ability_1_node.activate(target_position)

## Use ability 2.
func use_ability_2(target_position: Vector2) -> void:
	if _ability_2_node and _ability_2_node.has_method("activate"):
		_ability_2_node.activate(target_position)

## Use ultimate if ready.
func use_ultimate(target_position: Vector2) -> bool:
	if not is_ultimate_ready:
		return false
	if _ultimate_node and _ultimate_node.has_method("activate"):
		_ultimate_node.activate(target_position)
	is_ultimate_ready = false
	ultimate_timer = active_class_data.ultimate_cooldown
	ultimate_used.emit(active_class_data.ultimate_cooldown)
	return true

## Toggle stance (for classes with has_stances = true).
func toggle_stance() -> void:
	if not active_class_data or not active_class_data.has_stances:
		return
	current_stance = 1 - current_stance
	stance_changed.emit(current_stance)
	# Notify abilities of stance change
	if _ability_1_node and _ability_1_node.has_method("on_stance_changed"):
		_ability_1_node.on_stance_changed(current_stance)
	if _ability_2_node and _ability_2_node.has_method("on_stance_changed"):
		_ability_2_node.on_stance_changed(current_stance)

## Apply all stat bonuses from the active class to a Stats resource.
func apply_class_stats(stats: Stats) -> void:
	if not active_class_data or not active_class_data.base_stats:
		return
	var base: Stats = active_class_data.base_stats
	stats.max_hp = base.max_hp
	stats.base_damage = base.base_damage
	stats.attack_speed = base.attack_speed
	stats.move_speed = base.move_speed
	stats.crit_chance = base.crit_chance
	stats.defence = base.defence

func has_active_class() -> bool:
	return active_class_data != null
