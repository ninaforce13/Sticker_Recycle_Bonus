static func patch():
	var script_path = "res://menus/inventory/InventoryDetailPanel.gd"
	var patched_script : GDScript = preload("res://menus/inventory/InventoryDetailPanel.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("Check that %s is included in Modified Files"% script_path)
			return
		patched_script.source_code = file.get_as_text()
		file.close()

	var code_lines:Array = patched_script.source_code.split("\n")

	var code_index:int = code_lines.find("var immediate_item_use:bool = true")
	if code_index >= 0:
		code_lines.insert(code_index+1,get_code("core_declaration"))

	code_index = code_lines.find("	buttons.add_child(discard)")
	if code_index >= 0:
		code_lines.insert(code_index+1,get_code("grab_focus"))

	code_index = code_lines.find("func _on_RecycleBox_focus_entered():")
	if code_index >= 0:
		code_lines.insert(code_index+1,get_code("on_RecycleBox_focus_entered"))

	code_index = code_lines.find("	var recyclables = item_node.recycle(amount)")
	if code_index >= 0:
		code_lines.insert(code_index+1,get_code("on_RecycleBox_value_chosen"))

	code_lines.insert(code_lines.size() - 1,get_code("new_functions"))

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	var err = patched_script.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return


static func get_code(block_name:String)->String:
	var blocks:Dictionary = {}
	blocks["core_declaration"] = """
var StickerCoreSystem = preload("res://mods/Sticker_Recycle_Bonus/StickerCoreSystem.tres")
	"""

	blocks["grab_focus"] = """
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
"""
	blocks["on_RecycleBox_focus_entered"] = """
	if vault_contains_sticker(item) and item is StickerItem:
		yield (GlobalMessageDialog.show_message("NCRAFTERS_STICKER_LOCKED_ERROR", true, true), "completed")
		_on_cancel_button_pressed()
		return
	"""
	blocks["on_RecycleBox_value_chosen"] = """
	if item_node.get_category() == "stickers":
		for attribute in item_node.item.attributes:
			if DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores.has(attribute.template_path):
				var core_id = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[attribute.template_path]
				recyclables.push_back({"item":DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[core_id],"amount":amount})

	"""
	blocks["new_functions"] = """
func initialize_otherdata():
	if not SaveState.other_data.has("stickervault"):
		SaveState.other_data.stickervault = []

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
	"""

	return blocks[block_name]
