## CurseRoom — Room that applies a curse or offers a deal: take curse for powerful reward.
## Player chooses: enter and be cursed, or skip.

class_name CurseRoom
extends Room

const CURSE_REWARD_CHOICES: Array = ["extra_artifact", "max_hp_boost", "coin_windfall"]
@export var curse_element: int = Globals.ElementType.DARK

var player_entered: bool = false
var curse_accepted: bool = false

func _ready() -> void:
	_unlock_doors()  # Curse room doors always open

func _on_player_enter_curse_zone(body: Node) -> void:
	if body.is_in_group("player") and not player_entered:
		player_entered = true
		_present_curse_choice(body)

func _present_curse_choice(_player: Node) -> void:
	## Show UI choice: Accept curse for reward, or pass.
	EventBus.notification_requested.emit("A cursed aura fills the room. Accept its power?", Color(0.5, 0.0, 0.5))
	# UI handles the actual choice; on accept call accept_curse(), on decline call decline_curse()

func accept_curse(player: Node) -> void:
	curse_accepted = true
	# Apply curse status
	if player.has_method("apply_status_effect"):
		player.apply_status_effect(Globals.StatusEffect.CURSE, 999.0)  # Until floor end
	# Give reward
	var reward: String = CURSE_REWARD_CHOICES[randi() % CURSE_REWARD_CHOICES.size()]
	_give_reward(player, reward)
	EventBus.notification_requested.emit("Curse accepted. Power flows...", Color(0.7, 0.0, 1.0))

func _give_reward(player: Node, reward: String) -> void:
	match reward:
		"extra_artifact":
			EventBus.notification_requested.emit("An artifact appears!", Color(0.8, 0.3, 1.0))
		"max_hp_boost":
			if player.has_method("heal"):
				player.heal(player.stats.max_hp * 0.3)
		"coin_windfall":
			EventBus.coin_collected.emit(Globals.CoinType.GOLD, randi_range(1, 3))

func decline_curse() -> void:
	EventBus.notification_requested.emit("You leave the cursed power behind.", Color(0.7, 0.7, 0.7))
