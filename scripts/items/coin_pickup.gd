## CoinPickup — World pickup for coins (Copper, Silver, Gold).
## Auto-collected when player walks over it.

class_name CoinPickup
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

@export var coin_type: int = Globals.CoinType.COPPER
@export var amount: int = 1

const COIN_COLORS: Dictionary = {
	Globals.CoinType.COPPER: Color(0.8, 0.5, 0.2),
	Globals.CoinType.SILVER: Color(0.8, 0.8, 0.9),
	Globals.CoinType.GOLD:   Color(1.0, 0.85, 0.1),
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_display()
	_start_bounce_tween()

func _physics_process(delta: float) -> void:
	# Magnetise towards player if auto_loot is enabled or within vacuum range
	var auto_loot: bool = SaveManager.get_setting("auto_loot", false)
	var vacuum_dist: float = 160.0 if auto_loot else 64.0
	for player in get_tree().get_nodes_in_group("player"):
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= vacuum_dist:
			var pull_speed: float = (vacuum_dist - dist) * 4.0 + 80.0
			global_position = global_position.move_toward(player.global_position, pull_speed * delta)
			break

func _start_bounce_tween() -> void:
	if not sprite:
		return
	var orig_y: float = sprite.position.y
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", orig_y - 4.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", orig_y + 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func setup(c_type: int, c_amount: int) -> void:
	coin_type = c_type
	amount = c_amount
	_update_display()

func _update_display() -> void:
	if sprite:
		sprite.modulate = COIN_COLORS.get(coin_type, Color.WHITE)
	if label:
		label.text = str(amount)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		EventBus.coin_collected.emit(coin_type, amount)
		queue_free()
