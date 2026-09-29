## ItemData — Base Resource for all items.
## Extend this class for Weapon, Artifact, PetTreat, etc.

class_name ItemData
extends Resource

@export var item_name: String = ""
@export var rarity: int = Globals.ItemRarity.COMMON
@export var description: String = ""
@export var lore_text: String = ""
@export var icon: Texture2D = null

func get_rarity_color() -> Color:
	return Globals.RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name() -> String:
	return Globals.RARITY_NAMES.get(rarity, "Unknown")

func to_dict() -> Dictionary:
	return {
		"item_name": item_name,
		"rarity": rarity,
		"description": description,
		"lore_text": lore_text
	}
