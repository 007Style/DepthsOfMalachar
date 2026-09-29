## LootTable — Weighted random item and coin selection.
## Used by enemies, chests, and bosses to determine drops.

class_name LootTable
extends Resource

## A single entry in the loot table.
class LootEntry:
	var item_path: String = ""   # Path to ItemData resource
	var weight: int = 10         # Relative weight (higher = more common)
	var min_floor: int = 0       # Only drops on floors >= this value

	func _init(path: String, w: int, min_f: int = 0) -> void:
		item_path = path
		weight = w
		min_floor = min_f

@export var coin_drop_min: int = 1
@export var coin_drop_max: int = 5
@export var coin_type: int = Globals.CoinType.COPPER
@export var item_drop_chance: float = 0.3    # 0.0 to 1.0
@export var entries: Array = []              # Array of LootEntry (set in code or subclass)

## Roll for coins. Returns {coin_type, amount}.
func roll_coins() -> Dictionary:
	return {
		"coin_type": coin_type,
		"amount": randi_range(coin_drop_min, coin_drop_max)
	}

## Roll for an item drop. Returns a loaded ItemData resource or null.
func roll_item(floor_num: int) -> Resource:
	if randf() > item_drop_chance:
		return null

	# Filter entries valid for this floor
	var valid: Array = entries.filter(func(e): return e.min_floor <= floor_num)
	if valid.is_empty():
		return null

	# Build weighted pool using floor-adjusted rarity weights
	var rarity_weights: Dictionary = Globals.get_rarity_weight_for_floor(floor_num)
	var total_weight: int = 0
	for entry in valid:
		total_weight += entry.weight

	if total_weight == 0:
		return null

	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for entry in valid:
		cumulative += entry.weight
		if roll < cumulative:
			if entry.item_path != "":
				return load(entry.item_path)
			return null

	return null

## Static helper: roll a rarity from the floor-adjusted table.
static func roll_rarity(floor_num: int) -> int:
	var weights: Dictionary = Globals.get_rarity_weight_for_floor(floor_num)
	var total: int = 0
	for w in weights.values():
		total += w

	var roll: int = randi() % total
	var cumulative: int = 0
	for rarity in weights:
		cumulative += weights[rarity]
		if roll < cumulative:
			return rarity
	return Globals.ItemRarity.COMMON
