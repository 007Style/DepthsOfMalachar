## WeaponData — Resource defining a weapon's properties.

class_name WeaponData
extends ItemData

@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0        # Attacks per second
@export var element: int = Globals.ElementType.NONE
@export var special_effect: String = ""       # Description of special on-hit effect
@export var class_restriction: int = -1       # -1 = no restriction, else ClassType
@export var is_blueprint: bool = false        # Must be crafted at Forge
@export var is_cursed: bool = false
@export var curse_description: String = ""    # What the curse does
@export var rune_slots: int = 1               # Number of rune sockets
@export var equipped_runes: Array = []        # Array of rune resource paths

# Set name for set bonuses (empty = no set)
@export var set_name: String = ""

func get_damage_with_runes() -> float:
	var bonus: float = 0.0
	for rune in equipped_runes:
		if rune != null:
			bonus += rune.damage_bonus
	return base_damage + bonus

func can_be_used_by_class(class_type: int) -> bool:
	return class_restriction == -1 or class_restriction == class_type

func to_dict() -> Dictionary:
	var d: Dictionary = super.to_dict()
	d["base_damage"] = base_damage
	d["attack_speed"] = attack_speed
	d["element"] = element
	d["special_effect"] = special_effect
	d["class_restriction"] = class_restriction
	d["is_blueprint"] = is_blueprint
	d["is_cursed"] = is_cursed
	d["curse_description"] = curse_description
	d["set_name"] = set_name
	return d
