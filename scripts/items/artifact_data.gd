## ArtifactData — Resource defining an artifact's passive effect.
## Artifacts are stackable — equipping duplicates increases effect_value.

class_name ArtifactData
extends ItemData

@export var effect_type: String = ""           # e.g. "damage_bonus", "hp_bonus", "revive_once"
@export var effect_value: float = 0.0          # Base value of the effect
@export var is_stackable: bool = true          # Whether duplicates increase effect
@export var stack_increment: float = 0.0       # How much effect_value increases per stack
@export var current_stacks: int = 1            # Current stack count (runtime only)
@export var is_permanent: bool = false         # true = base shop artifact, false = run-only
@export var set_name: String = ""              # For set bonus detection
@export var is_temporary: bool = false         # Town artifact (run only, not kept)

func get_current_value() -> float:
	if is_stackable and current_stacks > 1:
		return effect_value + (stack_increment * (current_stacks - 1))
	return effect_value

func add_stack() -> void:
	if is_stackable:
		current_stacks += 1

func to_dict() -> Dictionary:
	var d: Dictionary = super.to_dict()
	d["effect_type"] = effect_type
	d["effect_value"] = effect_value
	d["is_stackable"] = is_stackable
	d["stack_increment"] = stack_increment
	d["is_permanent"] = is_permanent
	d["set_name"] = set_name
	return d
