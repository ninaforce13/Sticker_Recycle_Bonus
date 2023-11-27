extends "res://menus/inventory/ItemInfoPanel.gd"

signal block_mouse
signal unblock_mouse
signal item_used(item_node, arg)
signal item_discarded(item_node, amount)
signal entering_recycle_mode(label_text)
signal exiting_recycle_mode
signal canceled

const DiscardButton = preload("res://menus/inventory/DiscardButton.tscn")

onready var buttons = find_node("Buttons")
onready var recycle_box = find_node("RecycleBox")

var item_node:Node setget set_item_node
var context = null setget set_context
var context_kind:int
var immediate_item_use:bool = true
var StickerCoreSystem = preload("res://mods/Sticker_Recycle_Bonus/StickerCoreSystem.tres")

func set_item_node(value):
	item_node = value
	item = item_node.item if item_node else null
	amount = item_node.amount if item_node else 0
	refresh()

func set_context(value):
	context = value
	if context is MonsterTape:
		context_kind = BaseItem.ContextKind.CONTEXT_TAPE
	elif context is Character:
		context_kind = BaseItem.ContextKind.CONTEXT_CHARACTER
	elif context is FighterNode:
		context_kind = BaseItem.ContextKind.CONTEXT_BATTLE
	elif context == null:
		context_kind = BaseItem.ContextKind.CONTEXT_WORLD
	refresh()

func refresh():
	.refresh()
	var had_focus = get_focus_owner() != null and is_a_parent_of(get_focus_owner())
	for button in buttons.get_children():
		buttons.remove_child(button)
		button.queue_free()
	if had_focus:
		grab_focus()

func should_have_focus():
	return buttons.get_child_count() > 0 or recycle_box.visible

func _on_use_button_pressed(button, arg):
	emit_signal("block_mouse")
	button.release_focus()
	buttons.visible = false
	
	
	
	yield (Co.next_frame(), "completed")
	yield (Co.next_frame(), "completed")
	
	arg = item_node.custom_use_menu(context_kind, context, arg)
	if arg is GDScriptFunctionState:
		arg = yield (arg, "completed")
		if arg == null:
			
			buttons.visible = true
			button.grab_focus()
			emit_signal("unblock_mouse")
			return 
	if immediate_item_use:
		var co = item_node.use(context_kind, context, arg)
		if co is GDScriptFunctionState:
			yield (co, "completed")
	buttons.visible = true
	button.grab_focus()
	emit_signal("unblock_mouse")
	emit_signal("item_used", item_node, arg)

func _on_discard_pressed():
	recycle_box.value = 1
	recycle_box.item_node = item_node
	recycle_box.visible = true
	recycle_box.grab_focus()
	buttons.visible = false

func _on_cancel_button_pressed():
	emit_signal("canceled")

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return 
	if get_focus_owner() != null and is_a_parent_of(get_focus_owner()):
		if event.is_action_pressed("ui_cancel"):
			_on_cancel_button_pressed()
			get_tree().set_input_as_handled()

func _on_RecycleBox_focus_exited():
	emit_signal("exiting_recycle_mode")

 
func grab_focus():
	if recycle_box.visible:
		recycle_box.grab_focus()
		return 

	for button in buttons.get_children():
		buttons.remove_child(button)
		button.queue_free()

	if item_node != null and item_node.is_usable(context_kind, context):
		for option in item_node.get_use_options(context_kind, context):
			var button = Button.new()
			button.text = option.label
			button.disabled = option.get("disabled", false)
			button.connect("pressed", self, "_on_use_button_pressed", [button, option.arg])
			buttons.add_child(button)
	else :
		var button = Button.new()
		button.text = "ITEM_USE"
		button.set_disabled(true)
		buttons.add_child(button)


	var discard = DiscardButton.instance()
	discard.set_item(item_node)
	discard.connect("pressed", self, "_on_discard_pressed")			
	buttons.add_child(discard)

	if item_node.get_category() == "stickers":
		initialize_otherdata()	

		var bonus_button = Button.new()		
		var label = discard.get_node("Label").duplicate()
		bonus_button.add_child(label)
		var label_text = Loc.trf("NCRAFTERS_APPLY_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_placement_cost
		})
		label.bbcode_text = "[center]" + label_text + "[/center]"		
		bonus_button.connect("pressed", self, "_on_craft_button_pressed", [bonus_button])
		buttons.add_child(bonus_button)
		
		var upgrade_button = Button.new()		
		var upgrade_label = discard.get_node("Label").duplicate()
		upgrade_button.add_child(upgrade_label)
		var label_text_2 = Loc.trf("NCRAFTERS_UPGRADE_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_upgrade_cost
		})
		upgrade_label.bbcode_text = "[center]" + label_text_2 + "[/center]"		
		upgrade_button.connect("pressed", self, "_on_upgrade_button_pressed", [upgrade_button])
		buttons.add_child(upgrade_button)
		
		var remove_button = Button.new()		
		var remove_label = discard.get_node("Label").duplicate()
		remove_button.add_child(remove_label)
		var remove_label_text = Loc.trf("NCRAFTERS_REMOVE_EFFECT_UI",{
			"resource":"[font=res://addons/platform/input_icons/bbcode_img_font.tres][img=0x52.5]res://sprites/items/pulp.png[/img][/font]",
			"cost":StickerCoreSystem.core_removal_cost
		})
		remove_label.bbcode_text = "[center]" + remove_label_text + "[/center]"		
		remove_button.connect("pressed", self, "_on_remove_button_pressed", [remove_button])
		buttons.add_child(remove_button)		
		
		var deposit_button = Button.new()
		deposit_button.add_color_override("font_color", Color.gray)
		deposit_button.add_color_override("font_color_focus", Color.gray)
		deposit_button.text = "NCRAFTERS_UNLOCKED_STICKER_UI"				

		if vault_contains_sticker(item):
			deposit_button.text = "NCRAFTERS_LOCKED_STICKER_UI"
			deposit_button.add_color_override("font_color", Color.red)
			deposit_button.add_color_override("font_color_focus", Color.red)
		deposit_button.connect("pressed", self, "_on_deposit_button_pressed", [deposit_button])

		buttons.add_child(deposit_button)

	var cancel_button = Button.new()
	cancel_button.text = "UI_BUTTON_CANCEL"
	cancel_button.connect("pressed", self, "_on_cancel_button_pressed")
	buttons.add_child(cancel_button)

	buttons.visible = true
	buttons.setup_focus()
	buttons.get_child(0).grab_focus()

func initialize_otherdata():
	if not SaveState.other_data.has("stickervault"):
		SaveState.other_data.stickervault = []			
func _on_RecycleBox_focus_entered():
	if vault_contains_sticker(item) and item is StickerItem:
		yield (GlobalMessageDialog.show_message("NCRAFTERS_STICKER_LOCKED_ERROR", true, true), "completed")			
		_on_cancel_button_pressed()
		return			
	emit_signal("entering_recycle_mode", recycle_box.mode_label.text)

func _on_RecycleBox_value_chosen(amount):
	if amount == 0:
		buttons.visible = true
		buttons.grab_focus()
		return 
	
	var recyclables = item_node.recycle(amount)

	if item_node.get_category() == "stickers": 
		for attribute in item_node.item.attributes:			
			if DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores.has(attribute.template_path):
				var core_id = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[attribute.template_path]			
				recyclables.push_back({"item":DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[core_id],"amount":amount})
			
	emit_signal("block_mouse")
	yield (Co.wait_frames(2), "completed")
	emit_signal("unblock_mouse")
	
	if recyclables.size() > 0:
		yield (MenuHelper.give_items(recyclables), "completed")
	
	emit_signal("item_discarded", item_node, amount)	

func _on_craft_button_pressed(_button):
	var effect = yield (StickerCoreSystem.choose_effect(item_node.item),"completed")
	var fail_msg:String
	var retrying:bool = false
	var materials_cost	
	if effect != null:
		if StickerCoreSystem.has_core(effect) and StickerCoreSystem.has_material_cost(effect):		
			materials_cost = StickerCoreSystem.get_material_cost(effect)					
			var cost_paid_msg = Loc.trf("NCRAFTERS_COST_PAID_COMPLETE", {
				"rarity":StickerCoreSystem.get_html_color(effect),
				"effect":effect.get_description(item_node.item.battle_move),
				"core_name":materials_cost.core.get_clean_name(Color.white.to_html()),
				"core_icon":materials_cost.core.icon.resource_path,
				"core_cost":materials_cost.core_cost,
				"resource_icon":materials_cost.material.icon.resource_path,
				"resource_cost":materials_cost.cost,
				"resource_name":materials_cost.material.name,
				"application_name":materials_cost.application_material.name,
				"application_cost":materials_cost.application_cost,
				"application_icon":materials_cost.application_material.icon.resource_path,
				
			})
			if yield(StickerCoreSystem.confirm_action(cost_paid_msg, "NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
				if StickerCoreSystem.core_success_roll_v2(item_node.item, effect):								
					var new_sticker = ItemFactory.create_sticker(item_node.item.battle_move,null,0)
					new_sticker.set_attributes(item_node.item.attributes.duplicate())
					StickerCoreSystem.apply_effect(new_sticker, effect)
					yield(MenuHelper.give_item(new_sticker,1,false),"completed")
					SaveState.inventory.consume_item(item_node.item,1)
					StickerCoreSystem.pay_material_cost(effect)
					emit_signal("item_discarded", item_node, 1)
				else:
					StickerCoreSystem.pay_material_cost(effect)
					
					if not StickerCoreSystem.has_material_cost(effect):
						yield(GlobalMessageDialog.show_message("NCRAFTERS_FAILED_CORE_ATTACH"),"completed")
						_on_cancel_button_pressed()
						return
					materials_cost = StickerCoreSystem.get_material_cost(effect)	
					fail_msg = Loc.trf("NCRAFTERS_RETRY_ATTACH",{
						"application_icon":materials_cost.application_material.icon.resource_path,
						"resource_icon":materials_cost.material.icon.resource_path,
						"resource_cost":materials_cost.cost,
						"core_icon":materials_cost.core.icon.resource_path,
						"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
						"application_cost":materials_cost.application_cost,
						"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
						"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
						"core_cost":materials_cost.core_cost
					})					
					
					retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")
					while retrying:						
						if StickerCoreSystem.core_success_roll_v2(item_node.item, effect):								
							var new_sticker = ItemFactory.create_sticker(item_node.item.battle_move,null,0)
							new_sticker.set_attributes(item_node.item.attributes.duplicate())
							StickerCoreSystem.apply_effect(new_sticker, effect)
							yield(MenuHelper.give_item(new_sticker,1,false),"completed")
							SaveState.inventory.consume_item(item_node.item,1)
							StickerCoreSystem.pay_material_cost(effect)
							emit_signal("item_discarded", item_node, 1)
							retrying = false
							break
						else:
							StickerCoreSystem.pay_material_cost(effect)
							if not StickerCoreSystem.has_material_cost(effect):
								yield(GlobalMessageDialog.show_message("NCRAFTERS_FAILED_CORE_ATTACH"),"completed")
								retrying = false
								break
							materials_cost = StickerCoreSystem.get_material_cost(effect)	
							fail_msg = Loc.trf("NCRAFTERS_RETRY_ATTACH",{
								"application_icon":materials_cost.application_material.icon.resource_path,
								"resource_icon":materials_cost.material.icon.resource_path,
								"resource_cost":materials_cost.cost,
								"core_icon":materials_cost.core.icon.resource_path,
								"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
								"application_cost":materials_cost.application_cost,
								"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
								"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
								"core_cost":materials_cost.core_cost
							})
							retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")
		else:
			yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect)),"completed")		
	_on_cancel_button_pressed()

func _on_remove_button_pressed(_button):
	var effect = yield (StickerCoreSystem.choose_editable_effect(item_node.item),"completed")
	if effect != null:
		if StickerCoreSystem.has_material_cost(effect, false, true):
			var material_costs = StickerCoreSystem.get_material_cost(effect,false,true)
			var cost_paid_msg = Loc.trf("NCRAFTERS_REMOVAL_COST_SUMMARY", {
					"attribute":effect.get_description(item_node.item.battle_move),
					"application_cost":material_costs.application_cost,
					"application_name":material_costs.application_material.name,
					"application_icon":material_costs.application_material.icon.resource_path,
					"upgrade_cost":material_costs.cost,
					"upgrade_name":material_costs.material.name,
					"upgrade_icon":material_costs.material.icon.resource_path
				})
			if yield(StickerCoreSystem.confirm_action(cost_paid_msg,"NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
				var new_sticker = item_node.item.duplicate()				
				StickerCoreSystem.remove_effect(new_sticker, effect)
				yield(MenuHelper.give_item(new_sticker,1,false),"completed")
				SaveState.inventory.consume_item(item_node.item,1)													
				StickerCoreSystem.pay_material_cost(effect,false,true)
				yield(GlobalMessageDialog.show_message("NCRAFTERS_REMOVAL_SUCCESS"),"completed")
				emit_signal("item_discarded", item_node, 1) #Forces a refresh but doesnt actually remove the item
				
		else:
			yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect,false,true)),"completed")
	_on_cancel_button_pressed()

func _on_upgrade_button_pressed(_button):
	var effect = yield (StickerCoreSystem.choose_editable_effect(item_node.item, true),"completed")
	var fail_msg:String
	var new_value:String
	var old_value:String
	var effect_to_upgrade
	var upgrade
	var retrying:bool = false
	var materials_cost
	
	if effect != null:
		if StickerCoreSystem.has_material_cost(effect, true):
			var potential_effect = StickerCoreSystem.get_max_potential_effect(item_node.item,effect)
			materials_cost = StickerCoreSystem.get_material_cost(effect,true)
			var cost_paid_msg = Loc.trf("NCRAFTERS_UPGRADE_COST_SUMMARY", {
				"rarity":StickerCoreSystem.get_html_color(effect),
				"effect":potential_effect.get_description(item_node.item.battle_move),
				"core_name":StickerCoreSystem.get_core(effect).get_clean_name(Color.white.to_html()),
				"core_icon":StickerCoreSystem.get_core(effect).icon.resource_path,
				"core_cost":materials_cost.core_cost,
				"resource_icon":materials_cost.material.icon.resource_path,
				"resource_cost":materials_cost.cost,
				"resource_name":materials_cost.material.name,
				"application_name":materials_cost.application_material.name,
				"application_cost":materials_cost.application_cost,
				"application_icon":materials_cost.application_material.icon.resource_path
				
			})
			if yield(StickerCoreSystem.confirm_action(cost_paid_msg,"NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
				upgrade = StickerCoreSystem.upgrade_roll(effect,item_node.item.battle_move)
	
				for attr in item_node.item.attributes:
					if StickerCoreSystem.attribute_matches(attr,upgrade):
						effect_to_upgrade = attr
						break
				old_value = effect_to_upgrade.get_description(item_node.item.battle_move)
				new_value = upgrade.get_description(item_node.item.battle_move)
				if StickerCoreSystem.is_effect_upgraded(upgrade, effect_to_upgrade):					
					var new_sticker = item_node.item.duplicate()
					StickerCoreSystem.upgrade_effect(new_sticker, upgrade)
					yield(MenuHelper.give_item(new_sticker,1,false),"completed")
					SaveState.inventory.consume_item(item_node.item,1)					
					var sticker_change_msg = Loc.trf("NCRAFTERS_STICKER_UPGRADE_SUCCESS",{
						"old_effect":old_value,
						"new_effect":new_value
					})
					yield(GlobalMessageDialog.show_message(sticker_change_msg),"completed")
					StickerCoreSystem.pay_material_cost(effect, true)
					emit_signal("item_discarded", item_node, 1)
				else:
					StickerCoreSystem.pay_material_cost(effect, true)														
						
					if not StickerCoreSystem.has_material_cost(effect, true):
						fail_msg = Loc.trf("NCRAFTERS_FAILED_UPGRADE",{
							"roll_value":new_value
						})
						yield(GlobalMessageDialog.show_message(fail_msg),"completed")
						_on_cancel_button_pressed()
						return
					materials_cost = StickerCoreSystem.get_material_cost(effect, true)	
					fail_msg = Loc.trf("NCRAFTERS_RETRY_UPGRADE",{
						"roll_value":new_value,
						"application_icon":materials_cost.application_material.icon.resource_path,
						"application_cost":materials_cost.application_cost,
						"resource_icon":materials_cost.material.icon.resource_path,
						"resource_cost":materials_cost.cost,
						"core_icon":materials_cost.core.icon.resource_path,
						"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
						"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
						"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
						"core_cost":materials_cost.core_cost
					})
					retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")					
					
					while retrying:
						upgrade = StickerCoreSystem.upgrade_roll(effect,item_node.item.battle_move)
						new_value = upgrade.get_description(item_node.item.battle_move)
						
						if StickerCoreSystem.is_effect_upgraded(upgrade, effect_to_upgrade):	
							var new_sticker = item_node.item.duplicate()
							StickerCoreSystem.upgrade_effect(new_sticker, upgrade)
							yield(MenuHelper.give_item(new_sticker,1,false),"completed")
							SaveState.inventory.consume_item(item_node.item,1)					
							var sticker_change_msg = Loc.trf("NCRAFTERS_STICKER_UPGRADE_SUCCESS",{
								"old_effect":old_value,
								"new_effect":new_value
							})
							yield(GlobalMessageDialog.show_message(sticker_change_msg),"completed")
							StickerCoreSystem.pay_material_cost(effect, true)
							emit_signal("item_discarded", item_node, 1)
							retrying = false
							break
						else:
							StickerCoreSystem.pay_material_cost(effect, true)							
							if not StickerCoreSystem.has_material_cost(effect, true):
								retrying = false
								fail_msg = Loc.trf("NCRAFTERS_FAILED_UPGRADE",{
									"roll_value":new_value
								})
								yield(GlobalMessageDialog.show_message(fail_msg),"completed")
								break
							materials_cost = StickerCoreSystem.get_material_cost(effect, true)
							fail_msg = Loc.trf("NCRAFTERS_RETRY_UPGRADE",{
								"roll_value":new_value,
								"application_icon":materials_cost.application_material.icon.resource_path,
								"application_cost":materials_cost.application_cost,
								"resource_icon":materials_cost.material.icon.resource_path,
								"resource_cost":materials_cost.cost,
								"core_icon":materials_cost.core.icon.resource_path,
								"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
								"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
								"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
								"core_cost":materials_cost.core_cost
							})
							retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")
							
		else:
			yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect, true)),"completed")
	_on_cancel_button_pressed()

#
func _on_deposit_button_pressed(button):
	var matching_stickers = []
	matching_stickers.append({node = item_node, item = item})

	for sticker_dict in matching_stickers:			
		if vault_contains_sticker(sticker_dict.item):
			if remove_sticker_from_vault(sticker_dict.item):
				button.text = "NCRAFTERS_UNLOCKED_STICKER_UI"				
				button.add_color_override("font_color_focus", Color.gray)
				button.add_color_override("font_color", Color.gray)				
				break

		add_to_vault(sticker_dict.item)
		button.text = "NCRAFTERS_LOCKED_STICKER_UI"
		button.add_color_override("font_color", Color.red)
		button.add_color_override("font_color_focus", Color.red)
		break
	emit_signal("block_mouse")
	yield (Co.wait_frames(2), "completed")
	emit_signal("unblock_mouse")

func add_to_vault(sticker):		
	SaveState.other_data.stickervault.append(get_item_key(sticker))	

func remove_sticker_from_vault(sticker)->bool:
	if not SaveState.other_data.has("stickervault"):
		return false
	var item_key = get_item_key(sticker)
	var index = 0
	for item in SaveState.other_data.stickervault:
		if item == item_key:
			SaveState.other_data.stickervault.remove(index)
			return true
		index += 1					
	return false

func vault_contains_sticker(sticker)->bool:
	if not SaveState.other_data.has("stickervault"):
		return false 
	var item_key = get_item_key(sticker)
	for item in SaveState.other_data.stickervault:
		if str(item) == item_key:	
			return true
	return false

func get_item_key(sticker):
	if not sticker is StickerItem:
		return
	var item_key = str(sticker.name) + str(sticker.value)
	for attr in sticker.attributes:
		 item_key = item_key + attr.template_path	
	return item_key
