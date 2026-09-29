## LoreLog — Full lore log UI with tabs for Story, Bestiary, Classes, Ethari's Journal.
## Displays all unlocked lore entries from ProgressionManager.

class_name LoreLog
extends CanvasLayer

@onready var tab_bar: TabContainer = $TabContainer
@onready var story_list: VBoxContainer   = $TabContainer/Story/ScrollContainer/List
@onready var bestiary_list: VBoxContainer = $TabContainer/Bestiary/ScrollContainer/List
@onready var journal_list: VBoxContainer = $TabContainer/Journal/ScrollContainer/List
@onready var close_button: Button = $CloseButton

# ---------------------------------------------------------------------------
# Lore entry bank — all known lore IDs with full text
# ---------------------------------------------------------------------------
const LORE_ENTRIES: Dictionary = {
	# Story lore
	"kingdom_fall_1": {"tab":"story","title":"The Fall — Part 1","text":"The Aurelian Kingdom stood for a thousand years. Its golden spires reached the heavens. Its magic was the finest in the world. All of this ended in a season."},
	"kingdom_fall_2": {"tab":"story","title":"The Fall — Part 2","text":"Malachar did not conquer with armies first. He conquered with whispers. The king's court fell before a single soldier arrived."},
	"the_eighth_priest": {"tab":"story","title":"The Eighth Priest","text":"They say seven priests performed the Rite of the Eternal Call. The histories are wrong. There were eight. Only seven wanted Aelion to answer."},
	"the_imprisoned_king": {"tab":"story","title":"The King's Secret","text":"The king is imprisoned. But he chose it. If he leaves, the seal breaks. Something older than Malachar stirs beneath the dungeon."},
	"aelion_last_breath": {"tab":"story","title":"Aelion's Last Breath","text":"He forged you from his final divine power. He said only: 'The king still lives. Find him. Free him. End this.' Then he was gone."},
	"malachar_true_nature": {"tab":"story","title":"Malachar's True Nature (NG+)","text":"He was not always this. A god like Aelion, once. The Ancient corrupted him. His hatred for the world is grief wearing armour."},
	# Malachar's journal
	"malchar_journal_1": {"tab":"story","title":"Malachar's Journal: Entry 1","text":"\"They named me demon. I was born as they were. They simply could not see what was already inside them.\""},
	"malachar_journal_2": {"tab":"story","title":"Malachar's Journal: Entry 4","text":"\"The priests thought they were summoning a saviour. They were right to. They summoned me — and I saved them from hope.\""},
	"malachar_journal_3": {"tab":"story","title":"Malachar's Journal: Entry 8","text":"\"The Eternal Call was meant to bind me. Instead it freed something older. I am not the danger here, little flame. I am the warning.\""},
	# Rival journals
	"rival_aldric_journal": {"tab":"story","title":"Aldric's Journal","text":"\"I went down to find the king. I found something else. Something in the depths knows my name. It says I'm already its. I think it might be right.\""},
	# Ancient lore
	"the_ancient_truth": {"tab":"story","title":"What Lies Before","text":"It does not have a name. It predates names. It predates gods. It is the silence before the first word. Malachar calls it the Shaper. The priests called it the Origin. You will call it The Ancient. You were warned."},
	"the_ancient_phase2": {"tab":"story","title":"The Ancient — Second Sight","text":"\"You found me. Most do not even know to look. Are you the one Aelion made? Good. I have waited for you specifically.\""},
	"the_ancient_truth_fragment": {"tab":"story","title":"The Ancient — Truth","text":"\"You think the king is a prisoner. You think Malachar is the enemy. You are a child who has only read the first page. There are no more pages. Only depths.\""},
	# Enemy bestiary
	"bestiary_orc_grunt": {"tab":"bestiary","title":"Orc Grunt","text":"Once miners and labourers under the Kingdom's employ, the orc clans were corrupted by Malachar's taint. They remember nothing of who they were."},
	"bestiary_orc_shaman": {"tab":"bestiary","title":"Orc Shaman","text":"Shamans who once healed their clans now channel demon-fire. Their prayers are answered — just not by anything merciful."},
	"bestiary_skeleton_warrior": {"tab":"bestiary","title":"Skeleton Warrior","text":"The Kingdom's fallen soldiers. Malachar promised them eternal rest. He kept only the eternal part."},
	"bestiary_frost_wraith": {"tab":"bestiary","title":"Frost Wraith","text":"Ghosts of those who died in the Frozen Depths — still searching for warmth they'll never find. They try to find it in Ethari's body heat."},
	"bestiary_stone_golem": {"tab":"bestiary","title":"Stone Golem","text":"Constructs of the Kingdom's engineers, now serving the dungeon's will. Their eyes remember their makers but their fists do not."},
	"bestiary_earth_elemental": {"tab":"bestiary","title":"Earth Elemental","text":"The ley lines are broken. Magic pools underground and forms. The Earth Elementals are not summoned — they are formed from the dungeon's grief."},
	"bestiary_cursed_knight": {"tab":"bestiary","title":"Cursed Knight","text":"The most loyal of the Kingdom's knights. Malachar didn't break their loyalty — he redirected it. They still serve a king. Just not yours."},
	"bestiary_the_ancient": {"tab":"bestiary","title":"The Ancient","text":"Floor 666. Some say it only appears when it wants to be found. My grandfather found it. He said it was beautiful. He never explained what he meant."},
	# Mirror room
	"mirror_room_revelation": {"tab":"journal","title":"The Mirror Room","text":"The reflection fought like me. Hit like me. Bled like me. And when it died, I could not shake the feeling that something had ended inside me too."},
	# Journal entries
	"ethari_journal_first_boss": {"tab":"journal","title":"First Boss","text":"I killed it. My hands are still shaking. Aelion's gift — this body, these abilities — they work. I don't know what I am. But I know what I can do."},
	"ethari_journal_first_recruit_death": {"tab":"journal","title":"Their Name","text":"They followed me and I could not protect them. I will write their name here, where it will not be forgotten."},
	"ethari_journal_floor_100": {"tab":"journal","title":"Floor 100","text":"A hundred floors. The dungeon goes on. The king is down here somewhere. I can feel it. Like a thread between us."},
	"rival_saved_aldric": {"tab":"journal","title":"Aldric — Saved","text":"I didn't kill him. I don't know if I made the right choice. He said thank you and wept. The corruption leaves marks. We'll see if it leaves him."},
}

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_close)
	_populate_logs()

func _close() -> void:
	GameManager.go_to_base()

func _populate_logs() -> void:
	var unlocked: Array = ProgressionManager.unlocked_lore_entries
	for entry_id in LORE_ENTRIES:
		if entry_id not in unlocked:
			continue
		var entry: Dictionary = LORE_ENTRIES[entry_id]
		var container: VBoxContainer = _get_tab_list(entry["tab"])
		if not container:
			continue
		_add_entry_to_list(container, entry["title"], entry["text"])

func _add_entry_to_list(container: VBoxContainer, title: String, text: String) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.modulate = Color(1.0, 0.9, 0.5)
	var text_lbl: Label = Label.new()
	text_lbl.text = text
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(title_lbl)
	vbox.add_child(text_lbl)
	vbox.add_child(sep)
	container.add_child(vbox)

func _get_tab_list(tab_name: String) -> VBoxContainer:
	match tab_name:
		"story":    return story_list
		"bestiary": return bestiary_list
		"journal":  return journal_list
		_:          return story_list
