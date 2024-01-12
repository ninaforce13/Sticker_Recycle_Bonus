static func patch():
	var script_path = "res://menus/party_tape/PartyTapeUI.gd"
	var patched_script : GDScript = preload("res://menus/party_tape/PartyTapeUI.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("Check that %s is included in Modified Files"% script_path)
			return
		patched_script.source_code = file.get_as_text()
		file.close()

	var code_lines:Array = patched_script.source_code.split("\n")

	var code_index:int = code_lines.find("var current_sprite_tape = null")
	if code_index >= 0:
		code_lines.insert(code_index+1,get_code("core_declaration"))

	code_index = code_lines.find("	var buttons = PartyStickerActionButtons.instance()")
	if code_index >= 0:
		code_lines[code_index] = get_code("replace_party_stickers")

	code_index = code_lines.find("	stickers.focus_on_hover = true")
	if code_index >= 0:
		code_lines.insert(code_index-1,get_code("_on_ActionButtons_option_chosen"))

	code_lines.insert(code_lines.size() - 1,get_code("new_functions"))

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	var err = patched_script.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return

static func get_code(block:String)->String:
	var code_blocks:Dictionary = {}
	code_blocks["core_declaration"] = """
const PartyStickerActionButtonsExt = preload("res://mods/Sticker_Recycle_Bonus/scenes/PartyStickerActionButtons_Ext.tscn")
var StickerCoreSystem = DLC.mods_by_id["sticker_recycle_bonus"].StickerCoreSystem
	"""
	code_blocks["replace_party_stickers"] = """
	var buttons = PartyStickerActionButtonsExt.instance()
	"""
	code_blocks["new_functions"] = """
func apply_effect(index:int):
	if index < tape.stickers.size() and tape.stickers[index] != null:
		var effect = yield (StickerCoreSystem.choose_effect(tape.stickers[index]),"completed")
		var fail_msg:String
		var success_msg:String
		var retrying:bool = false
		var materials_cost

		if effect != null:
			if StickerCoreSystem.has_core(effect) and StickerCoreSystem.has_material_cost(effect):
				materials_cost = StickerCoreSystem.get_material_cost(effect)
				var cost_paid_msg = Loc.trf("NCRAFTERS_COST_PAID_COMPLETE", {
					"rarity":StickerCoreSystem.get_html_color(effect),
					"effect":effect.get_description(tape.stickers[index].battle_move),
					"core_name":StickerCoreSystem.get_core(effect).get_clean_name(Color.white.to_html()),
					"core_icon":StickerCoreSystem.get_core(effect).icon.resource_path,
					"core_cost":materials_cost.core_cost,
					"resource_icon":materials_cost.material.icon.resource_path,
					"resource_cost":materials_cost.cost,
					"resource_name":materials_cost.material.name,
					"application_name":materials_cost.application_material.name,
					"application_cost":materials_cost.application_cost,
					"application_icon":StickerCoreSystem.get_material_cost(effect).application_material.icon.resource_path,

				})
				if yield(StickerCoreSystem.confirm_action(cost_paid_msg, "NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
					if StickerCoreSystem.core_success_roll_v2(tape.stickers[index], effect):
						var new_sticker = tape.stickers[index].duplicate()
						StickerCoreSystem.apply_effect(new_sticker, effect)
						tape.stickers[index] = new_sticker
						StickerCoreSystem.pay_material_cost(effect)
						var new_effect = StickerCoreSystem.get_effect_from_sticker(tape.stickers[index], effect)
						success_msg = Loc.trf("NCRAFTERS_CORE_ATTACH_SUCCESSFUL",{
							"effect":new_effect.get_description(tape.stickers[index].battle_move),
							"rarity":StickerCoreSystem.get_html_color(effect)
						})
						yield(GlobalMessageDialog.show_message(success_msg),"completed")
					else:
						StickerCoreSystem.pay_material_cost(effect)

						if not StickerCoreSystem.has_material_cost(effect):
							yield(GlobalMessageDialog.show_message("NCRAFTERS_FAILED_CORE_ATTACH"),"completed")
							return
						materials_cost = StickerCoreSystem.get_material_cost(effect)
						fail_msg = Loc.trf("NCRAFTERS_RETRY_ATTACH",{
							"application_icon":materials_cost.application_material.icon.resource_path,
							"resource_icon":materials_cost.material.icon.resource_path,
							"resource_cost":StickerCoreSystem.get_material_cost(effect).cost,
							"core_icon":materials_cost.core.icon.resource_path,
							"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
							"application_cost":materials_cost.application_cost,
							"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
							"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
							"core_cost":StickerCoreSystem.get_material_cost(effect).core_cost
						})

						retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")
						while retrying:
							if StickerCoreSystem.core_success_roll_v2(tape.stickers[index], effect):
								var new_sticker = tape.stickers[index].duplicate()
								StickerCoreSystem.apply_effect(new_sticker, effect)
								tape.stickers[index] = new_sticker
								StickerCoreSystem.pay_material_cost(effect)
								var new_effect = StickerCoreSystem.get_effect_from_sticker(tape.stickers[index], effect)
								success_msg = Loc.trf("NCRAFTERS_CORE_ATTACH_SUCCESSFUL",{
									"effect":new_effect.get_description(tape.stickers[index].battle_move),
									"rarity":StickerCoreSystem.get_html_color(effect)
								})
								yield(GlobalMessageDialog.show_message(success_msg),"completed")
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
									"resource_cost":StickerCoreSystem.get_material_cost(effect).cost,
									"core_icon":materials_cost.core.icon.resource_path,
									"application_value":SaveState.inventory.get_item_amount(materials_cost.application_material),
									"application_cost":materials_cost.application_cost,
									"resource_value":SaveState.inventory.get_item_amount(materials_cost.material),
									"core_value":SaveState.inventory.get_item_amount(materials_cost.core),
									"core_cost":StickerCoreSystem.get_material_cost(effect).core_cost
								})
								retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")
			else:
				yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect)),"completed")
	update_ui()

func upgrade_effect(index:int):
	if index < tape.stickers.size() and tape.stickers[index] != null:
		var effect = yield (StickerCoreSystem.choose_editable_effect(tape.stickers[index], true),"completed")
		var fail_msg:String
		var new_value:String
		var old_value:String
		var effect_to_upgrade
		var upgrade
		var retrying:bool = false
		var materials_cost
		if effect != null:
			var potential_effect = StickerCoreSystem.get_max_potential_effect(tape.stickers[index],effect)
			if StickerCoreSystem.has_material_cost(effect, true):
				materials_cost = StickerCoreSystem.get_material_cost(effect, true)
				var cost_paid_msg = Loc.trf("NCRAFTERS_UPGRADE_COST_SUMMARY", {
					"rarity":StickerCoreSystem.get_html_color(effect),
					"effect":potential_effect.get_description(tape.stickers[index].battle_move),
					"core_name":StickerCoreSystem.get_core(effect).get_clean_name(Color.white.to_html()),
					"core_icon":StickerCoreSystem.get_core(effect).icon.resource_path,
					"core_cost":materials_cost.core_cost,
					"resource_icon":materials_cost.material.icon.resource_path,
					"resource_cost":materials_cost.cost,
					"resource_name":materials_cost.material.name,
					"application_name":materials_cost.application_material.name,
					"application_cost":materials_cost.application_cost,
					"application_icon":materials_cost.application_material.icon.resource_path,

				})
				if yield(StickerCoreSystem.confirm_action(cost_paid_msg,"NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
					upgrade = StickerCoreSystem.upgrade_roll(effect,tape.stickers[index].battle_move)

					for attr in tape.stickers[index].attributes:
						if StickerCoreSystem.attribute_matches(attr,upgrade):
							effect_to_upgrade = attr
							break
					old_value = effect_to_upgrade.get_description(tape.stickers[index].battle_move)
					new_value = upgrade.get_description(tape.stickers[index].battle_move)
					if StickerCoreSystem.is_effect_upgraded(upgrade, effect_to_upgrade):
						StickerCoreSystem.upgrade_effect(tape.stickers[index], upgrade)
						var sticker_change_msg = Loc.trf("NCRAFTERS_STICKER_UPGRADE_SUCCESS",{
							"old_effect":old_value,
							"new_effect":new_value
						})
						yield(GlobalMessageDialog.show_message(sticker_change_msg),"completed")
						StickerCoreSystem.pay_material_cost(effect, true)
					else:
						StickerCoreSystem.pay_material_cost(effect, true)

						if not StickerCoreSystem.has_material_cost(effect, true):
							fail_msg = Loc.trf("NCRAFTERS_FAILED_UPGRADE",{
								"roll_value":new_value
							})
							yield(GlobalMessageDialog.show_message(fail_msg),"completed")
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
							"core_cost":materials_cost.core_cost,
						})
						retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")

						while retrying:
							upgrade = StickerCoreSystem.upgrade_roll(effect,tape.stickers[index].battle_move)
							new_value = upgrade.get_description(tape.stickers[index].battle_move)

							if StickerCoreSystem.is_effect_upgraded(upgrade, effect_to_upgrade):
								StickerCoreSystem.upgrade_effect(tape.stickers[index], upgrade)
								var sticker_change_msg = Loc.trf("NCRAFTERS_STICKER_UPGRADE_SUCCESS",{
									"old_effect":old_value,
									"new_effect":new_value
								})
								yield(GlobalMessageDialog.show_message(sticker_change_msg),"completed")
								StickerCoreSystem.pay_material_cost(effect, true)
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
									"core_cost":materials_cost.core_cost,
								})
								retrying = yield(StickerCoreSystem.confirm_action(fail_msg),"completed")

			else:
				yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect, true)),"completed")
	update_ui()

func remove_effect(index:int):
	if index < tape.stickers.size() and tape.stickers[index] != null:
		var effect = yield (StickerCoreSystem.choose_editable_effect(tape.stickers[index]),"completed")
		if effect != null:
			if StickerCoreSystem.has_material_cost(effect, false, true):
				var material_costs = StickerCoreSystem.get_material_cost(effect,false,true)
				var cost_paid_msg = Loc.trf("NCRAFTERS_REMOVAL_COST_SUMMARY", {
						"attribute":effect.get_description(tape.stickers[index].battle_move),
						"application_cost":material_costs.application_cost,
						"application_name":material_costs.application_material.name,
						"application_icon":material_costs.application_material.icon.resource_path,
						"upgrade_cost":material_costs.cost,
						"upgrade_name":material_costs.material.name,
						"upgrade_icon":material_costs.material.icon.resource_path
					})
				if yield(StickerCoreSystem.confirm_action(cost_paid_msg,"NCRAFTERS_CONFIRM_UI","NCRAFTERS_CANCEL_UI"),"completed"):
					StickerCoreSystem.remove_effect(tape.stickers[index], effect)
					StickerCoreSystem.pay_material_cost(effect, false, true)
					yield(GlobalMessageDialog.show_message("NCRAFTERS_REMOVAL_SUCCESS"),"completed")

			else:
				yield(GlobalMessageDialog.show_message(StickerCoreSystem.get_insufficient_material_msg(effect,false,true)),"completed")
	update_ui()
	"""
	code_blocks["_on_ActionButtons_option_chosen"] = """
	if option == "apply_effect" and current_sticker_button:
		var co = apply_effect(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()
		return

	if option == "upgrade_effect" and current_sticker_button:
		var co = upgrade_effect(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()
		return

	if option == "remove_effect" and current_sticker_button:
		var co = remove_effect(current_sticker_button.get_index())
		if co is GDScriptFunctionState:
			yield (co, "completed")
		current_sticker_button.grab_focus()
		return
	"""

	return code_blocks[block]
