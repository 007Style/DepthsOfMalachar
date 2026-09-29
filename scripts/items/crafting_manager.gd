## CraftingManager — Handles alchemy, poison coating, scroll crafting, and blueprint crafting.
## Used by the Forge building at Base and in-dungeon upgrade stations.

class_name CraftingManager
extends Node

# ---------------------------------------------------------------------------
# Ingredient types
# ---------------------------------------------------------------------------
enum IngredientType {
	FIRE_ESSENCE,
	ICE_SHARD,
	POISON_SAC,
	LIGHTNING_CRYSTAL,
	SHADOW_DUST,
	LIFE_PLANT_PETAL,
	STONE_POWDER,
	WATER_VIAL,
	BONE_FRAGMENT,
	DEMON_CLAW
}

# ---------------------------------------------------------------------------
# Potion recipes  {ingredients: Array, result: Dictionary}
# ---------------------------------------------------------------------------
const POTION_RECIPES: Array = [
	{
		"name": "Health Potion",
		"ingredients": [IngredientType.LIFE_PLANT_PETAL, IngredientType.WATER_VIAL],
		"effect": "heal_50_percent",
		"description": "Restores 50% max HP.",
	},
	{
		"name": "Fire Flask",
		"ingredients": [IngredientType.FIRE_ESSENCE, IngredientType.BONE_FRAGMENT],
		"effect": "throw_fire_aoe",
		"description": "Throwable flask — AoE fire damage.",
	},
	{
		"name": "Frost Vial",
		"ingredients": [IngredientType.ICE_SHARD, IngredientType.WATER_VIAL],
		"effect": "throw_freeze_aoe",
		"description": "Throwable flask — freezes enemies in area.",
	},
	{
		"name": "Rage Tonic",
		"ingredients": [IngredientType.DEMON_CLAW, IngredientType.FIRE_ESSENCE],
		"effect": "instant_rage",
		"description": "Instantly fills rage bar.",
	},
	{
		"name": "Shadow Oil",
		"ingredients": [IngredientType.SHADOW_DUST, IngredientType.POISON_SAC],
		"effect": "poison_weapon_10_hits",
		"description": "Coats weapon in shadow poison for 10 attacks.",
	},
]

# ---------------------------------------------------------------------------
# Scroll recipes
# ---------------------------------------------------------------------------
const SCROLL_RECIPES: Array = [
	{
		"name": "Scroll of Teleport",
		"ingredients": [IngredientType.LIGHTNING_CRYSTAL, IngredientType.SHADOW_DUST],
		"effect": "teleport_to_exit",
		"description": "Instantly teleports Ethari to the floor exit.",
	},
	{
		"name": "Scroll of Invincibility",
		"ingredients": [IngredientType.LIFE_PLANT_PETAL, IngredientType.STONE_POWDER, IngredientType.WATER_VIAL],
		"effect": "invincible_5s",
		"description": "5 seconds of complete invincibility.",
	},
	{
		"name": "Scroll of Identify",
		"ingredients": [IngredientType.LIGHTNING_CRYSTAL, IngredientType.BONE_FRAGMENT],
		"effect": "identify_item",
		"description": "Identifies one unknown item.",
	},
]

# ---------------------------------------------------------------------------
# Player ingredient inventory (runtime)
# ---------------------------------------------------------------------------
var ingredient_inventory: Dictionary = {}  # IngredientType -> count

func add_ingredient(itype: int, amount: int = 1) -> void:
	ingredient_inventory[itype] = ingredient_inventory.get(itype, 0) + amount

func can_craft(recipe: Dictionary) -> bool:
	for ing in recipe["ingredients"]:
		if ingredient_inventory.get(ing, 0) < recipe["ingredients"].count(ing):
			return false
	return true

func craft(recipe: Dictionary, player: Node) -> bool:
	if not can_craft(recipe):
		EventBus.notification_requested.emit("Not enough ingredients!", Color(1.0, 0.3, 0.3))
		return false
	# Consume ingredients
	for ing in recipe["ingredients"]:
		ingredient_inventory[ing] = ingredient_inventory.get(ing, 1) - 1
	# Apply effect
	_apply_craft_effect(recipe["effect"], player)
	EventBus.notification_requested.emit("Crafted: " + recipe["name"] + "!", Color(0.6, 1.0, 0.6))
	return true

func _apply_craft_effect(effect: String, player: Node) -> void:
	match effect:
		"heal_50_percent":
			if player.has_method("heal"):
				player.heal(player.stats.max_hp * 0.5)
		"instant_rage":
			if player.has_method("activate_rage"):
				player.rage_bar = player.rage_bar_max
				player.activate_rage()
		"poison_weapon_10_hits":
			if player.equipped_weapon:
				player.equipped_weapon.poison_charges = 10
		"invincible_5s":
			if player.has_method("apply_status_effect"):
				player.is_invincible = true
				player.invincibility_timer.start(5.0)
		"identify_item":
			EventBus.notification_requested.emit("Next unknown item will be identified.", Color(0.9, 0.9, 0.0))
		_:
			push_warning("CraftingManager: Unknown effect: " + effect)

# ---------------------------------------------------------------------------
# Revive Crystal crafting (from LifePlant essence)
# ---------------------------------------------------------------------------
func craft_revive_crystal(player: Node) -> bool:
	const COST: int = 3  # 3 LifePlant petals
	if ingredient_inventory.get(IngredientType.LIFE_PLANT_PETAL, 0) < COST:
		EventBus.notification_requested.emit("Need 3 LifePlant Petals to craft a Revive Crystal.", Color(1.0, 0.3, 0.3))
		return false
	ingredient_inventory[IngredientType.LIFE_PLANT_PETAL] -= COST
	if player.has_method("add_revive_crystal"):
		player.add_revive_crystal()
	EventBus.notification_requested.emit("Revive Crystal crafted!", Color(0.5, 1.0, 0.5))
	return true
