## PetFusion — Combines two pets into a hybrid with merged abilities.
## Called from base Forge or PetManagement UI.

class_name PetFusion
extends RefCounted

## Fuse two PetData resources into a new hybrid PetData.
static func fuse(pet_a: PetData, pet_b: PetData) -> PetData:
	var hybrid: PetData = PetData.new()
	hybrid.species_name = pet_a.species_name + "-" + pet_b.species_name + " Hybrid"
	hybrid.pet_name = "Unnamed Hybrid"
	# Average stats
	hybrid.hp_bonus     = (pet_a.hp_bonus + pet_b.hp_bonus) * 0.6
	hybrid.damage_bonus = (pet_a.damage_bonus + pet_b.damage_bonus) * 0.6
	hybrid.speed_bonus  = (pet_a.speed_bonus + pet_b.speed_bonus) * 0.6
	hybrid.xp_bonus     = (pet_a.xp_bonus + pet_b.xp_bonus) * 0.6
	# Inherit dominant element (higher damage bonus wins)
	hybrid.element = pet_a.element if pet_a.damage_bonus >= pet_b.damage_bonus else pet_b.element
	# Bond level starts at average of parent bond levels, minimum 1
	hybrid.bond_level = max(1, (pet_a.bond_level + pet_b.bond_level) / 2)
	# Personality: higher bond wins
	hybrid.personality = pet_a.personality if pet_a.bond_level >= pet_b.bond_level else pet_b.personality
	# Evolution starts at 1 but with higher threshold
	hybrid.evolution_stage = 1
	hybrid.evolution_threshold = 150  # Harder to evolve hybrids
	# Lore
	hybrid.lore_text = "A fusion of " + pet_a.species_name + " and " + pet_b.species_name + ". Two souls, one form."
	EventBus.pet_evolved.emit(hybrid, 1)
	return hybrid
