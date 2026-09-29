## ClassData — Resource defining a class's stats, abilities, and lore.

class_name ClassData
extends Resource

@export var class_type: int = Globals.ClassType.WARRIOR
@export var class_name_text: String = "Warrior"
@export var base_stats: Stats = null
@export var passive_description: String = ""
@export var ability_1_name: String = ""
@export var ability_1_description: String = ""
@export var ability_1_scene: String = ""      # Path to ability scene
@export var ability_2_name: String = ""
@export var ability_2_description: String = ""
@export var ability_2_scene: String = ""
@export var ultimate_name: String = ""
@export var ultimate_description: String = ""
@export var ultimate_scene: String = ""
@export var ultimate_cooldown: float = 30.0

# Stance system
@export var has_stances: bool = false
@export var stance_a_name: String = ""
@export var stance_b_name: String = ""
@export var stance_a_description: String = ""
@export var stance_b_description: String = ""

# Unlock
@export var is_locked: bool = false
@export var unlock_condition: String = ""     # Human-readable unlock condition
@export var unlock_cost: int = 0              # Upgrade points to unlock

# Mastery
@export var mastery_quest_description: String = ""
@export var mastery_quest_goal: int = 0       # Target number for the quest

# Prestige
@export var prestige_class: ClassData = null  # Unlocked after mastering this class

# Lore
@export var lore_text: String = ""
@export var class_icon: Texture2D = null
