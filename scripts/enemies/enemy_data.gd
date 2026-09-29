## EnemyData — Resource defining an enemy's properties.

class_name EnemyData
extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var display_name: String = ""
@export var element: int = Globals.ElementType.NONE
@export var base_hp: float = 50.0
@export var base_damage: float = 8.0
@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var is_aerial: bool = false          # Only hittable by ranged/jump attacks
@export var has_weak_point: bool = false     # Has a glowing weak spot for bonus damage
@export var weak_point_multiplier: float = 2.0

# Loot
@export var loot_table: LootTable = null
@export var coin_drop_min: int = 1
@export var coin_drop_max: int = 10
@export var coin_type: int = Globals.CoinType.COPPER
@export var revive_crystal_drop_chance: float = 0.01  # Very rare

# Evolution (enemy learns from killing player)
@export var can_evolve: bool = true

# XP
@export var xp_reward: int = 10

# Lore
@export var lore_text: String = ""
@export var bestiary_description: String = ""
@export var sprite: Texture2D = null

func get_scaled_hp(floor_num: int) -> float:
	var scaled: float = Globals.scale_hp(base_hp, floor_num)
	scaled *= GameManager.get_ng_plus_hp_multiplier()
	return scaled

func get_scaled_damage(floor_num: int) -> float:
	var scaled: float = Globals.scale_damage(base_damage, floor_num)
	scaled *= GameManager.get_ng_plus_damage_multiplier()
	return scaled
