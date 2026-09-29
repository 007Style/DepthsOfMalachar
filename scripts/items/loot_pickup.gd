## LootPickup — World pickup node for weapons and artifacts.
## Auto-collected when player overlaps. Supports unknown/unidentified items.

class_name LootPickup
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var glow: PointLight2D = $Glow

@export var item_data: Resource = null  # WeaponData or ArtifactData
var is_identified: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_display()
	_start_glow_pulse()

func _physics_process(delta: float) -> void:
	# Auto-loot magnetise towards player when auto_loot is enabled in settings
	if SaveManager.get_setting("auto_loot", false):
		for player in get_tree().get_nodes_in_group("player"):
			var dist: float = global_position.distance_to(player.global_position)
			if dist <= 120.0:
				global_position = global_position.move_toward(player.global_position, 140.0 * delta)
				break

func _start_glow_pulse() -> void:
	if not sprite:
		return
	var orig_scale: Vector2 = sprite.scale
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "scale", orig_scale * 1.15, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", orig_scale, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func setup(item: Resource, identified: bool = true) -> void:
	item_data = item
	is_identified = identified
	_update_display()

func _update_display() -> void:
	if not item_data:
		return
	if label:
		label.text = item_data.item_name if is_identified else "??? Unknown Item"
	# Glow colour by rarity
	if glow and item_data is ItemData:
		var rarity_color: Color = Globals.RARITY_COLORS.get(item_data.rarity, Color.WHITE)
		glow.color = rarity_color
		glow.energy = 1.0 + item_data.rarity * 0.4

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if is_identified:
			EventBus.loot_collected.emit(item_data)
		else:
			# Unidentified — prompt player to identify
			EventBus.notification_requested.emit("Unknown Item found! Identify it at a Town.", Color(0.8, 0.6, 0.0))
			EventBus.loot_collected.emit(item_data)  # Picked up but flagged unidentified
		queue_free()
