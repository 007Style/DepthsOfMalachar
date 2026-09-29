## PetData — Resource defining a pet's stats and abilities.

class_name PetData
extends Resource

@export var pet_name: String = ""          # Player-assigned name
@export var species_name: String = ""      # Display name for species
@export var element: int = Globals.ElementType.NONE
@export var personality: int = Globals.PetPersonality.SUPPORTIVE
@export var is_legendary: bool = false

# Stat boosts applied to Ethari passively
@export var hp_bonus: float = 0.0
@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var xp_bonus: float = 0.0

# Bond system
@export var bond_xp: int = 0
@export var bond_level: int = 1           # 1-10

# Evolution
@export var evolution_stage: int = 1      # 1-3
@export var evolution_treat_xp: int = 0   # XP from treats toward next evolution
@export var evolution_threshold: int = 100

# Lore
@export var lore_text: String = ""
@export var sprite: Texture2D = null
@export var sprite_stage_2: Texture2D = null
@export var sprite_stage_3: Texture2D = null

func gain_bond_xp(amount: int) -> bool:
	## Returns true if bond level increased.
	bond_xp += amount
	var threshold: int = bond_level * 50
	if bond_xp >= threshold and bond_level < 10:
		bond_xp -= threshold
		bond_level += 1
		_on_bond_level_up()
		EventBus.pet_bond_leveled_up.emit(self, bond_level)
		return true
	return false

func _on_bond_level_up() -> void:
	## Increase stat boosts as bond grows.
	hp_bonus      += 5.0
	damage_bonus  += 1.0
	speed_bonus   += 3.0

func apply_treat(treat_data: Resource) -> void:
	if not treat_data:
		return
	evolution_treat_xp += treat_data.effect_value if treat_data.has("effect_value") else 10
	# Apply treat elemental effect
	if treat_data.has("effect_type"):
		match treat_data.effect_type:
			"fire_bonus":      damage_bonus += 3.0
			"frost_bonus":     speed_bonus += 2.0
			"vitality_bonus":  hp_bonus += 10.0
			"bond_bonus":      gain_bond_xp(20)
			"stat_all":        hp_bonus += 5.0; damage_bonus += 2.0; speed_bonus += 2.0
	# Check evolution
	if evolution_treat_xp >= evolution_threshold and evolution_stage < 3:
		evolution_stage += 1
		evolution_treat_xp = 0
		evolution_threshold = int(evolution_threshold * 1.5)
		EventBus.pet_evolved.emit(self, evolution_stage)

func get_current_sprite() -> Texture2D:
	match evolution_stage:
		2: return sprite_stage_2 if sprite_stage_2 else sprite
		3: return sprite_stage_3 if sprite_stage_3 else sprite
		_: return sprite

func to_dict() -> Dictionary:
	return {
		"pet_name": pet_name,
		"species_name": species_name,
		"element": element,
		"personality": personality,
		"is_legendary": is_legendary,
		"hp_bonus": hp_bonus,
		"damage_bonus": damage_bonus,
		"speed_bonus": speed_bonus,
		"xp_bonus": xp_bonus,
		"bond_xp": bond_xp,
		"bond_level": bond_level,
		"evolution_stage": evolution_stage,
		"evolution_treat_xp": evolution_treat_xp
	}
