## Stats — Resource holding all stat fields for a player, Ethari, or recruit.

class_name Stats
extends Resource

# ---------------------------------------------------------------------------
# Base stats
# ---------------------------------------------------------------------------
@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var move_speed: float = 150.0
@export var crit_chance: float = 0.05      # 0.0 to 1.0
@export var crit_multiplier: float = 2.0
@export var defence: float = 0.0           # Flat damage reduction

# ---------------------------------------------------------------------------
# Elemental bonuses (multiplicative)
# ---------------------------------------------------------------------------
@export var elemental_damage_bonus: Dictionary = {}  # {ElementType: float}
@export var elemental_resistance: Dictionary = {}    # {ElementType: float}

# ---------------------------------------------------------------------------
# Utility stats
# ---------------------------------------------------------------------------
@export var dodge_chance: float = 0.0
@export var lifesteal: float = 0.0         # Fraction of damage dealt restored as HP
@export var xp_multiplier: float = 1.0
@export var coin_multiplier: float = 1.0

func _init() -> void:
	current_hp = max_hp

## Apply flat bonus to a stat by name.
func add_flat(stat_name: String, value: float) -> void:
	match stat_name:
		"max_hp":          max_hp += value; current_hp = min(current_hp, max_hp)
		"base_damage":     base_damage += value
		"attack_speed":    attack_speed += value
		"move_speed":      move_speed += value
		"crit_chance":     crit_chance = clamp(crit_chance + value, 0.0, 1.0)
		"defence":         defence += value
		"dodge_chance":    dodge_chance = clamp(dodge_chance + value, 0.0, 0.9)
		"lifesteal":       lifesteal = clamp(lifesteal + value, 0.0, 1.0)
		"xp_multiplier":   xp_multiplier += value
		"coin_multiplier": coin_multiplier += value

## Apply percentage multiplier to a stat.
func multiply(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"max_hp":       max_hp *= multiplier
		"base_damage":  base_damage *= multiplier
		"attack_speed": attack_speed *= multiplier
		"move_speed":   move_speed *= multiplier

## Get elemental damage bonus for a given element.
func get_elemental_bonus(element: int) -> float:
	return elemental_damage_bonus.get(element, 0.0)

## Get elemental resistance for a given element (0.0 to 1.0 damage reduction).
func get_elemental_resistance(element: int) -> float:
	return elemental_resistance.get(element, 0.0)

func clone() -> Stats:
	var s: Stats = Stats.new()
	s.max_hp = max_hp
	s.current_hp = current_hp
	s.base_damage = base_damage
	s.attack_speed = attack_speed
	s.move_speed = move_speed
	s.crit_chance = crit_chance
	s.crit_multiplier = crit_multiplier
	s.defence = defence
	s.elemental_damage_bonus = elemental_damage_bonus.duplicate()
	s.elemental_resistance = elemental_resistance.duplicate()
	s.dodge_chance = dodge_chance
	s.lifesteal = lifesteal
	s.xp_multiplier = xp_multiplier
	s.coin_multiplier = coin_multiplier
	return s
