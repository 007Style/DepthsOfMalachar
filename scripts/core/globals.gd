## Globals — Shared Enums and Constants
## All global enums used across the entire project are defined here.
## This script is registered as an Autoload singleton named "Globals".

extends Node

# ---------------------------------------------------------------------------
# Item Rarity
# ---------------------------------------------------------------------------
enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	MYTHICAL,
	LEGENDARY,
	SECRET
}

# ---------------------------------------------------------------------------
# Element Types
# ---------------------------------------------------------------------------
enum ElementType {
	NONE,
	FIRE,
	EARTH,
	AIR,
	WATER,
	LIGHTNING,
	POISON,
	ICE,
	DARK,
	LIGHT,
	ROCK,
	STEEL,
	LIFE_PLANT,
	LIFE_STEAL
}

# ---------------------------------------------------------------------------
# Coin Types
# ---------------------------------------------------------------------------
enum CoinType {
	COPPER,
	SILVER,
	GOLD
}

# Conversion rates
const COPPER_PER_SILVER: int = 100
const SILVER_PER_GOLD: int = 100
const COPPER_PER_GOLD: int = 10000

# ---------------------------------------------------------------------------
# Status Effects
# ---------------------------------------------------------------------------
enum StatusEffect {
	NONE,
	BURN,
	FREEZE,
	STUN,
	SLOW,
	POISON,
	BLEED,
	CURSE,
	CHARM,
	ELECTROCUTE,
	TOXIC_EXPLOSION,
	STEAM
}

# ---------------------------------------------------------------------------
# Biome Types
# ---------------------------------------------------------------------------
enum BiomeType {
	CATACOMBS,       # Floors 1-25
	VOLCANIC_CAVES,  # Floors 26-50
	FROZEN_DEPTHS,   # Floors 51-75
	SHADOW_REALM,    # Floors 76-99
	DEMON_SANCTUM    # Floors 100+
}

# ---------------------------------------------------------------------------
# Class Types
# ---------------------------------------------------------------------------
enum ClassType {
	WARRIOR,
	MAGE,
	ROGUE,
	NECROMANCER,
	PALADIN,
	ARCHER,
	DRUID,
	ASSASSIN,
	BERSERKER,
	ELEMENTALIST,
	MONK,
	BARD,
	SUMMONER,
	WITCH_HUNTER,
	KNIGHT,
	# Unlockable classes
	VAMPIRE,
	PIRATE,
	GUNSLINGER,
	TIME_MAGE,
	SHADOW_DANCER,
	ALCHEMIST,
	PYROMANCER,
	CRYOMANCER,
	STORM_CALLER,
	BLOOD_MAGE,
	TINKERER,
	BOUNTY_HUNTER,
	GLADIATOR,
	SHAPESHIFTER,
	SEER,
	# Special
	TRUE_FORM
}

# ---------------------------------------------------------------------------
# Trait Types
# ---------------------------------------------------------------------------
enum TraitType {
	# Positive traits
	LOYAL,       # +10% stats when fighting alongside Ethari
	BRAVE,       # +15% damage when HP below 50%
	TACTICAL,    # Provides hints on enemy weak points
	RESILIENT,   # +20% max HP
	SWIFT,       # +15% movement speed
	ARCANE,      # +10% ability damage
	MENTOR_BOND, # +20% XP gain from mentor
	# Negative traits
	COWARDLY,    # -5% damage when HP below 30%
	RECKLESS,    # -10% defence
	FRAGILE,     # -15% max HP
	LONE_WOLF,   # -10% stats when in party
	# Neutral / conditional
	DISCIPLE,    # Part of a mentor group
	VETERAN      # Earned through runs survived
}

# ---------------------------------------------------------------------------
# Game States
# ---------------------------------------------------------------------------
enum GameState {
	MENU,
	BASE,
	CLASS_SELECT,
	RUN,
	PAUSED,
	GAME_OVER,
	WEAPON_KEEP,
	FUNERAL,
	UPGRADE
}

# ---------------------------------------------------------------------------
# Room Types
# ---------------------------------------------------------------------------
enum RoomType {
	COMBAT,
	EMPTY,
	CHEST,
	TOWN,
	PUZZLE,
	TRAP,
	CURSE,
	MIRROR,
	ARENA,
	SHRINE,
	FLOODED,
	SECRET,
	CORRUPTED_TOWN,
	MINI_BOSS,
	MAJOR_BOSS,
	SECRET_BOSS
}

# ---------------------------------------------------------------------------
# Boss Tiers
# ---------------------------------------------------------------------------
enum BossTier {
	MINI,    # Every 10 floors
	MAJOR,   # Every 25 floors
	SECRET   # Every 100 floors
}

# ---------------------------------------------------------------------------
# Pet Personality
# ---------------------------------------------------------------------------
enum PetPersonality {
	AGGRESSIVE,  # Prioritises attacking enemies
	DEFENSIVE,   # Stays near player, focuses on healing
	SUPPORTIVE   # Balances attack and healing
}

# ---------------------------------------------------------------------------
# Elemental Weakness Table
# Key: element being hit, Value: dict of {attacker_element: multiplier}
# ---------------------------------------------------------------------------
const ELEMENTAL_MATRIX: Dictionary = {
	ElementType.FIRE:       { ElementType.ICE: 0.5,   ElementType.WATER: 0.5,  ElementType.FIRE: 0.25 },
	ElementType.ICE:        { ElementType.FIRE: 0.5,  ElementType.LIGHTNING: 0.5 },
	ElementType.WATER:      { ElementType.LIGHTNING: 2.0, ElementType.ICE: 0.5 },
	ElementType.LIGHTNING:  { ElementType.EARTH: 0.5, ElementType.WATER: 2.0 },
	ElementType.DARK:       { ElementType.LIGHT: 2.0, ElementType.DARK: 0.25 },
	ElementType.LIGHT:      { ElementType.DARK: 2.0,  ElementType.LIGHT: 0.25 },
	ElementType.POISON:     { ElementType.FIRE: 2.0 },
	ElementType.ROCK:       { ElementType.WATER: 2.0, ElementType.LIGHTNING: 0.5 },
	ElementType.STEEL:      { ElementType.FIRE: 1.5,  ElementType.LIGHTNING: 1.5 },
	ElementType.EARTH:      { ElementType.WATER: 1.5, ElementType.AIR: 0.5 },
	ElementType.AIR:        { ElementType.LIGHTNING: 2.0, ElementType.EARTH: 2.0 },
	ElementType.LIFE_PLANT: { ElementType.FIRE: 2.0,  ElementType.ICE: 1.5 },
	ElementType.LIFE_STEAL: { ElementType.LIGHT: 2.0 }
}

# ---------------------------------------------------------------------------
# Elemental Reaction Combos
# {[element_a, element_b]: reaction_status_effect}
# ---------------------------------------------------------------------------
const ELEMENTAL_REACTIONS: Array = [
	{ "elements": [ElementType.FIRE, ElementType.ICE],       "reaction": StatusEffect.STEAM },
	{ "elements": [ElementType.LIGHTNING, ElementType.WATER], "reaction": StatusEffect.ELECTROCUTE },
	{ "elements": [ElementType.POISON, ElementType.FIRE],    "reaction": StatusEffect.TOXIC_EXPLOSION }
]

# ---------------------------------------------------------------------------
# Rarity colours for UI display
# ---------------------------------------------------------------------------
const RARITY_COLORS: Dictionary = {
	ItemRarity.COMMON:    Color(0.8, 0.8, 0.8),   # Grey
	ItemRarity.UNCOMMON:  Color(0.3, 0.8, 0.3),   # Green
	ItemRarity.RARE:      Color(0.3, 0.5, 1.0),   # Blue
	ItemRarity.EPIC:      Color(0.6, 0.2, 0.9),   # Purple
	ItemRarity.MYTHICAL:  Color(1.0, 0.5, 0.0),   # Orange
	ItemRarity.LEGENDARY: Color(1.0, 0.85, 0.0),  # Gold
	ItemRarity.SECRET:    Color(1.0, 0.1, 0.3)    # Red/pink
}

const RARITY_NAMES: Dictionary = {
	ItemRarity.COMMON:    "Common",
	ItemRarity.UNCOMMON:  "Uncommon",
	ItemRarity.RARE:      "Rare",
	ItemRarity.EPIC:      "Epic",
	ItemRarity.MYTHICAL:  "Mythical",
	ItemRarity.LEGENDARY: "Legendary",
	ItemRarity.SECRET:    "Secret"
}

# ---------------------------------------------------------------------------
# Floor scaling helpers
# ---------------------------------------------------------------------------
func scale_hp(base_hp: float, floor_num: int) -> float:
	return base_hp * (1.0 + floor_num * 0.08)

func scale_damage(base_damage: float, floor_num: int) -> float:
	return base_damage * (1.0 + floor_num * 0.06)

func get_biome_for_floor(floor_num: int) -> BiomeType:
	if floor_num <= 25:
		return BiomeType.CATACOMBS
	elif floor_num <= 50:
		return BiomeType.VOLCANIC_CAVES
	elif floor_num <= 75:
		return BiomeType.FROZEN_DEPTHS
	elif floor_num <= 99:
		return BiomeType.SHADOW_REALM
	else:
		return BiomeType.DEMON_SANCTUM

func get_rarity_weight_for_floor(floor_num: int) -> Dictionary:
	## Returns weighted rarity pool adjusted for floor depth.
	## Higher floors have better chances at rarer items.
	var base: Dictionary = {
		ItemRarity.COMMON:    50,
		ItemRarity.UNCOMMON:  25,
		ItemRarity.RARE:      13,
		ItemRarity.EPIC:      7,
		ItemRarity.MYTHICAL:  3,
		ItemRarity.LEGENDARY: 1,
		ItemRarity.SECRET:    0
	}
	# Every 25 floors, shift weights toward rarer items
	var tier: int = floor_num / 25
	base[ItemRarity.COMMON]    = max(10, 50 - tier * 8)
	base[ItemRarity.UNCOMMON]  = max(10, 25 - tier * 2)
	base[ItemRarity.RARE]      = min(30, 13 + tier * 3)
	base[ItemRarity.EPIC]      = min(25, 7 + tier * 3)
	base[ItemRarity.MYTHICAL]  = min(15, 3 + tier * 2)
	base[ItemRarity.LEGENDARY] = min(8, 1 + tier)
	base[ItemRarity.SECRET]    = min(3, tier / 3)
	return base

func check_elemental_reaction(element_a: ElementType, element_b: ElementType) -> StatusEffect:
	## Check if two elements produce a reaction. Returns NONE if no reaction.
	for reaction in ELEMENTAL_REACTIONS:
		var elems: Array = reaction["elements"]
		if (elems[0] == element_a and elems[1] == element_b) or \
		   (elems[0] == element_b and elems[1] == element_a):
			return reaction["reaction"]
	return StatusEffect.NONE

func get_elemental_multiplier(defender_element: ElementType, attacker_element: ElementType) -> float:
	## Returns the damage multiplier when attacking an element with another element.
	if defender_element in ELEMENTAL_MATRIX:
		var weaknesses: Dictionary = ELEMENTAL_MATRIX[defender_element]
		if attacker_element in weaknesses:
			return weaknesses[attacker_element]
	return 1.0

func coins_to_display(copper: int) -> Dictionary:
	## Convert a raw copper amount into gold/silver/copper for display.
	var gold: int = copper / COPPER_PER_GOLD
	var remainder: int = copper % COPPER_PER_GOLD
	var silver: int = remainder / COPPER_PER_SILVER
	var cop: int = remainder % COPPER_PER_SILVER
	return { "gold": gold, "silver": silver, "copper": cop }

const CLASS_NAMES: Dictionary = {
	ClassType.WARRIOR:      "Warrior",
	ClassType.MAGE:         "Mage",
	ClassType.ROGUE:        "Rogue",
	ClassType.NECROMANCER:  "Necromancer",
	ClassType.PALADIN:      "Paladin",
	ClassType.ARCHER:       "Archer",
	ClassType.DRUID:        "Druid",
	ClassType.ASSASSIN:     "Assassin",
	ClassType.BERSERKER:    "Berserker",
	ClassType.ELEMENTALIST: "Elementalist",
	ClassType.MONK:         "Monk",
	ClassType.BARD:         "Bard",
	ClassType.SUMMONER:     "Summoner",
	ClassType.WITCH_HUNTER: "Witch Hunter",
	ClassType.KNIGHT:       "Knight",
	ClassType.VAMPIRE:      "Vampire",
	ClassType.PIRATE:       "Pirate",
	ClassType.GUNSLINGER:   "Gunslinger",
	ClassType.TIME_MAGE:    "Time Mage",
	ClassType.SHADOW_DANCER:"Shadow Dancer",
	ClassType.ALCHEMIST:    "Alchemist",
	ClassType.PYROMANCER:   "Pyromancer",
	ClassType.CRYOMANCER:   "Cryomancer",
	ClassType.STORM_CALLER: "Storm Caller",
	ClassType.BLOOD_MAGE:   "Blood Mage",
	ClassType.TINKERER:     "Tinkerer",
	ClassType.BOUNTY_HUNTER:"Bounty Hunter",
	ClassType.GLADIATOR:    "Gladiator",
	ClassType.SHAPESHIFTER: "Shapeshifter",
	ClassType.SEER:         "Seer",
	ClassType.TRUE_FORM:    "True Form"
}

func class_type_to_name(class_type: int) -> String:
	return CLASS_NAMES.get(class_type, "Unknown")
