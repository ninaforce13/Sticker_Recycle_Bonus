extends "res://nodes/menus/AutoFocusConnector.gd"

signal option_chosen(option)

onready var apply_sticker_btn = $ApplyStickerBtn
onready var peel_sticker_btn = $PeelStickerBtn
onready var move_sticker_btn = $MoveStickerBtn
onready var apply_effect_btn = $ApplyEffect
onready var upgrade_effect_btn = $UpgradeEffect
onready var remove_effect_btn = $RemoveEffect
onready var apply_effect_lbl = $ApplyEffect/Label
onready var upgrade_effect_lbl = $UpgradeEffect/Label
onready var remove_effect_lbl = $RemoveEffect/Label
onready var cancel_btn = $CancelBtn

var applying_sticker:StickerItem = null
var tape:MonsterTape
var sticker_index:int
var StickerCoreSystem = DLC.mods_by_id["sticker_recycle_bonus"].StickerCoreSystem
func _ready():
	assert (tape != null)
	var sticker = get_sticker()
	assert (sticker == null or sticker is BattleMove or sticker is StickerItem)

	if sticker == null or applying_sticker != null:
		remove_child(peel_sticker_btn)
		peel_sticker_btn.queue_free()
		remove_child(move_sticker_btn)
		move_sticker_btn.queue_free()

	if sticker != null:
		apply_sticker_btn.text = "UI_PARTY_REPLACE_STICKER"
		if not tape.sticker_can_be_replaced(sticker_index):
			apply_sticker_btn.disabled = true
	
	if apply_effect_lbl != null:
		apply_effect_lbl.text = Loc.trf("NCRAFTERS_APPLY_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_placement_cost
		})
		apply_effect_lbl.bbcode_text = "[center]" + apply_effect_lbl.text + "[/center]"		
	
	if upgrade_effect_lbl != null:
		upgrade_effect_lbl.text = Loc.trf("NCRAFTERS_UPGRADE_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_upgrade_cost
		})
		upgrade_effect_lbl.bbcode_text = "[center]" + upgrade_effect_lbl.text + "[/center]"		
		
	if remove_effect_lbl != null:
		remove_effect_lbl.text = Loc.trf("NCRAFTERS_REMOVE_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_removal_cost
		})
		remove_effect_lbl.bbcode_text = "[center]" + remove_effect_lbl.text + "[/center]"					
	setup_focus()

func get_sticker()->Resource:
	if sticker_index < tape.stickers.size():
		return tape.stickers[sticker_index]
	return null

func _process(_delta):
	if not get_focus_owner() or not is_a_parent_of(get_focus_owner()):
		choose_option(null)

func choose_option(option):
	emit_signal("option_chosen", option)
	get_parent().remove_child(self)
	queue_free()

func _on_CancelBtn_pressed():
	choose_option(null)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		_on_CancelBtn_pressed()

func _on_ApplyStickerBtn_pressed():
	choose_option("apply_sticker")

func _on_PeelStickerBtn_pressed():
	choose_option("peel_sticker")

func _on_MoveStickerBtn_pressed():
	choose_option("move_sticker")

func _on_ApplyEffect_pressed():
	choose_option("apply_effect")

func _on_UpgradeEffect_pressed():
	choose_option("upgrade_effect")

func _on_RemoveEffect_pressed():
	choose_option("remove_effect")
