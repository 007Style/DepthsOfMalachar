## SaveSlotScreen — Save / Load Profile Slot Manager
## Allows players to select, play, or delete from 3 save profiles.

class_name SaveSlotScreen
extends Control

@onready var slot_1_card: PanelContainer = $VBoxContainer/Slot1
@onready var slot_2_card: PanelContainer = $VBoxContainer/Slot2
@onready var slot_3_card: PanelContainer = $VBoxContainer/Slot3
@onready var back_button: Button          = $BackButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog

var _pending_delete_slot: int = -1

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if confirm_dialog:
		confirm_dialog.confirmed.connect(_on_delete_confirmed)
	_refresh_slots()

func _refresh_slots() -> void:
	_setup_slot_card(slot_1_card, 1)
	_setup_slot_card(slot_2_card, 2)
	_setup_slot_card(slot_3_card, 3)

func _setup_slot_card(card: PanelContainer, slot_num: int) -> void:
	if not card:
		return
	var info: Dictionary = SaveManager.get_slot_info(slot_num)
	var title_lbl: Label   = card.get_node_or_null("Margin/HBox/InfoVBox/TitleLabel")
	var desc_lbl: Label    = card.get_node_or_null("Margin/HBox/InfoVBox/DescLabel")
	var play_btn: Button   = card.get_node_or_null("Margin/HBox/ActionVBox/PlayButton")
	var delete_btn: Button = card.get_node_or_null("Margin/HBox/ActionVBox/DeleteButton")

	if info.get("exists", false):
		if title_lbl:
			title_lbl.text = "SLOT %d — Generation %d" % [slot_num, info.get("generation", 0)]
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		if desc_lbl:
			desc_lbl.text = "Runs: %d  •  Coins: %d  •  Recruits: %d" % [
				info.get("runs", 0),
				info.get("coins", 0),
				info.get("recruits", 0)
			]
		if play_btn:
			play_btn.text = "CONTINUE"
			play_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
			if play_btn.is_connected("pressed", _on_play_slot):
				play_btn.disconnect("pressed", _on_play_slot)
			play_btn.pressed.connect(_on_play_slot.bind(slot_num))
		if delete_btn:
			delete_btn.visible = true
			if delete_btn.is_connected("pressed", _on_delete_slot):
				delete_btn.disconnect("pressed", _on_delete_slot)
			delete_btn.pressed.connect(_on_delete_slot.bind(slot_num))
	else:
		if title_lbl:
			title_lbl.text = "SLOT %d — [EMPTY]" % slot_num
			title_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		if desc_lbl:
			desc_lbl.text = "Start a fresh adventure"
		if play_btn:
			play_btn.text = "NEW GAME"
			play_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
			if play_btn.is_connected("pressed", _on_play_slot):
				play_btn.disconnect("pressed", _on_play_slot)
			play_btn.pressed.connect(_on_play_slot.bind(slot_num))
		if delete_btn:
			delete_btn.visible = false

func _on_play_slot(slot_num: int) -> void:
	SaveManager.select_slot(slot_num)
	GameManager.go_to_base()

func _on_delete_slot(slot_num: int) -> void:
	_pending_delete_slot = slot_num
	if confirm_dialog:
		confirm_dialog.dialog_text = "Are you sure you want to delete Slot %d? This cannot be undone." % slot_num
		confirm_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	if _pending_delete_slot > 0:
		SaveManager.delete_save_slot(_pending_delete_slot)
		_pending_delete_slot = -1
		_refresh_slots()

func _on_back_pressed() -> void:
	GameManager.transition_to_scene(GameManager.SCENE_MAIN_MENU)
