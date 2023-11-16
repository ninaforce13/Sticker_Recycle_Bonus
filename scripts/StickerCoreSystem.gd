extends Resource

export var core_placement_cost:int = 2000
export var core_upgrade_cost:int = 1000
export var core_removal_cost:int = 1500
export var merchant_max_purchase:int = 10000

func pay_material_cost(effect, upgrade:bool = false, removal:bool = false):
	var payment = get_material_cost(effect, upgrade, removal)
	SaveState.inventory.consume_item(payment.material,payment.cost)
	SaveState.inventory.consume_item(payment.application_material,payment.application_cost)
	if not removal:
		SaveState.inventory.consume_item(get_core(effect),payment.core_cost)	

func get_material_cost(effect, upgrade:bool = false, removal:bool = false)->Dictionary:
	var core = get_core(effect)
	var cost = core.attach_cost
	var application_material = load("res://data/items/pulp.tres")
	var application_cost = core_placement_cost	
	var core_cost = core.core_cost if not removal else 0 
	var material = core.get_attach_resource() 
	
	if upgrade or removal:
		cost = core.upgrade_cost
		material = core.get_upgrade_resource()
		application_cost = core_upgrade_cost if upgrade else core_removal_cost
	if core.buffs.size() > 0:
		cost = get_buff_cost(core.buffs, effect).cost
		material = get_buff_cost(core.buffs, effect).material
		if upgrade or removal:
			cost = get_buff_cost(core.buffs, effect, true).cost
			material = get_buff_cost(core.buffs, effect, true).material

	return {"material":material,
			"cost":cost,
			"application_material":application_material,
			"application_cost":application_cost,
			"core_cost":core_cost,
			"core":core}
			
func get_core(effect)->BaseItem:
	var required_core_name = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[effect.template_path]
	var required_core = DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[required_core_name]
	return required_core

func get_buff_cost(buff_array, effect, upgrade:bool = false, _removal:bool = false)->Dictionary:
	for buff_data in buff_array:
		if effect.get("buffs"):
			if buff_data.buff == effect.buff:
				return {"material":buff_data.resource,"cost":buff_data.cost if not upgrade else buff_data.upgrade_cost}
		if effect.get("debuffs"):
			if buff_data.buff == effect.debuff:
				return {"material":buff_data.resource,"cost":buff_data.cost if not upgrade else buff_data.upgrade_cost}			
	return {"material":null,"cost":0}

func has_material_cost(effect, upgrade:bool = false, removal:bool = false)->bool:
	var validation:Dictionary = {"standard_cost":false,"variable_cost":false,"core_cost":false}
	if get_core(effect) == null and not removal:
		return false
	var payment:Dictionary = get_material_cost(effect, upgrade, removal)
	if payment.application_material != null:
		validation.standard_cost = SaveState.inventory.has_item(payment.application_material,payment.application_cost)
	else:
		validation.standard_cost = true
	
	if payment.material != null:
		validation.variable_cost = SaveState.inventory.has_item(payment.material,payment.cost)
	else:
		validation.variable_cost = true
		
	if payment.core != null and payment.core_cost > 0:
		validation.core_cost = SaveState.inventory.has_item(payment.core,payment.core_cost)
	else:
		validation.core_cost = true
	return validation.standard_cost and validation.core_cost and validation.variable_cost

func confirm_action(message:String,confirm_msg="NCRAFTERS_RETRY_CONFIRMED_UI", reject_msg="NCRAFTERS_RETRY_REJECT_UI", default_index:int = 1, initial_index:int = 0):
	GlobalMessageDialog.clear_state()
	yield (GlobalMessageDialog.show_message(message, false, false), "completed")
	var result = yield (GlobalMenuDialog.show_menu([confirm_msg, reject_msg], default_index, initial_index), "completed")
	yield (GlobalMessageDialog.hide(), "completed")
	return result == 0
	
func get_html_color(effect)->int:
	var rare_color = "2b9aeb"
	var uncommon_color = "1fba33"		
	return rare_color if effect.rarity == BaseItem.Rarity.RARITY_RARE else uncommon_color
	
func upgrade_roll(effect:StickerAttribute, move):
	var potential_upgrade:StickerAttribute = effect.duplicate()
	potential_upgrade.template_path = effect.template_path
	potential_upgrade.generate(move, Random.new())
	if potential_upgrade.template_path == "res://data/sticker_attributes/buff_user.tres":
		potential_upgrade.buff = effect.buff	
	if potential_upgrade.template_path == "res://data/sticker_attributes/debuff_target.tres":
		potential_upgrade.debuff = effect.debuff	
	return potential_upgrade

func upgrade_effect(sticker, upgrade):
	for attribute in sticker.attributes:		
		if attribute_matches(attribute, upgrade):
			if attribute.get("stat_value"):
				attribute.stat_value = upgrade.stat_value
			elif attribute.get("chance"):
				attribute.chance = upgrade.chance
			break
			
func attribute_matches(attribute_a, attribute_b)->bool:

	if attribute_a.script == attribute_b.script:
		if attribute_a.script == load("res://data/sticker_attribute_scripts/StatStickerAttribute.gd"):
			return attribute_a.stat_name == attribute_b.stat_name and attribute_a.multiply_empty_sticker_slots == attribute_b.multiply_empty_sticker_slots
		
		if attribute_a.script == load("res://data/sticker_attribute_scripts/HealStickerAttribute.gd"):
			return attribute_a.multiply_empty_sticker_slots == attribute_b.multiply_empty_sticker_slots						

		if attribute_a.template_path == "res://data/sticker_attributes/buff_user.tres" and attribute_b.template_path == "res://data/sticker_attributes/buff_user.tres":
			return attribute_a.buff == attribute_b.buff
			
		if attribute_a.template_path == "res://data/sticker_attributes/debuff_target.tres" and attribute_b.template_path == "res://data/sticker_attributes/debuff_target.tres":
			return attribute_a.debuff == attribute_b.debuff		
			
		if attribute_a.get("amount") and attribute_b.get("amount"):
			return attribute_a.amount == attribute_b.amount
		
		if attribute_a.get("condition") and attribute_b.get("condition"):
			return attribute_a.condition == attribute_b.condition
			
		if attribute_a.get("move_path") and attribute_b.get("move_path"):
			return attribute_a == attribute_b.move_path
		
		return true
	return false
	
func get_sticker_potential(sticker)->Dictionary:
	var potential:Dictionary = {"rare_full":false,"uncommon_full":false,"empty":false}
	var rare_count:int = 0
	var uncommon_count:int = 0
	for attribute in sticker.attributes:
		if attribute.rarity == BaseItem.Rarity.RARITY_UNCOMMON:
			uncommon_count += 1
		if attribute.rarity == BaseItem.Rarity.RARITY_RARE:
			rare_count += 1		
	potential.rare_full = rare_count >= ItemFactory.MAX_ATTRIBUTES[BaseItem.Rarity.RARITY_RARE]
	potential.uncommon_full = uncommon_count >= ItemFactory.MAX_ATTRIBUTES[BaseItem.Rarity.RARITY_UNCOMMON]
	potential.empty = rare_count == 0 and uncommon_count == 0
	return potential
	
func has_core(effect)->bool:
	var required_core_name = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[effect.template_path]
	var required_core = DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[required_core_name]	
	if required_core:
		return SaveState.inventory.has_item(required_core,1)
	return false

func apply_effect(sticker, effect):
	var new_instance = effect.duplicate()
	new_instance.template_path = effect.template_path
	new_instance.generate(sticker.battle_move, Random.new())
	sticker.attributes.push_back(new_instance)
	sticker.set_attributes(sticker.attributes)

func show_options(message:String, options:Array, default_index:int = 0, initial_index:int = 0):
	GlobalMessageDialog.clear_state()
	yield (GlobalMessageDialog.show_message(message, false, false), "completed")
	var result = yield (GlobalMenuDialog.show_menu(options, default_index, initial_index), "completed")
	yield (GlobalMessageDialog.hide(), "completed")
	return result
	
func is_upgradable(attribute)->bool:
	if attribute.get("chance"):
		return attribute.chance < attribute.chance_max					
	if attribute.get("stat_value"):
		return attribute.stat_value < attribute.stat_value_max

	return false

func get_max_potential_effect(sticker, effect):
	var potential_effect = effect.duplicate()
	potential_effect.template_path = effect.template_path	
	potential_effect.generate(sticker.battle_move, Random.new())
	if potential_effect.template_path == "res://data/sticker_attributes/buff_user.tres":
		potential_effect.buff = effect.buff	
	if potential_effect.template_path == "res://data/sticker_attributes/debuff_target.tres":
		potential_effect.debuff = effect.debuff
	if potential_effect.get("chance"):
		potential_effect.chance = potential_effect.chance_max
	if potential_effect.get("stat_value"):
		potential_effect.stat_value = potential_effect.stat_value_max	
	return potential_effect
func exists_onsticker(sticker, expected_attr)->bool:
	for attribute in sticker.attributes:
		if attribute_matches(attribute, expected_attr):
			return true
	return false
	
func get_effect_from_sticker(sticker, effect_to_get):
	for attribute in sticker.attributes:
		if attribute_matches(attribute, effect_to_get):
			return attribute
	
func remove_effect(sticker, effect):
	var index:int = 0
	for attribute in sticker.attributes:
		if attribute_matches(attribute, effect):
			sticker.attributes.remove(index)
		index += 1
	sticker.set_attributes(sticker.attributes)
	
func choose_editable_effect(sticker, upgradable_only:bool = false):
	var msg_prompt = "NCRAFTERS_EFFECT_PROMPT"
	var attributes = sticker.attributes
	var battle_move = sticker.battle_move
	var readable_options:Array = ["None"]
	var applicable_effects:Array =[null]
	var rare_color = "2b9aeb"
	var uncommon_color = "1fba33"	
	
	for mod_attribute in attributes:			
		if upgradable_only and not is_upgradable(mod_attribute):
			continue	
		var html_color = rare_color if mod_attribute.rarity == BaseItem.Rarity.RARITY_RARE else uncommon_color
		readable_options.push_back("[color=#"+str(html_color)+"]"+Loc.tr(mod_attribute.get_description(battle_move))+ "[/color]")
		applicable_effects.push_back(mod_attribute)
	var result = yield (show_options(msg_prompt,readable_options), "completed")
		
	if result > 0:
		return applicable_effects[result]
	return null
	
func choose_effect(sticker,upgradable_effects:bool = false): 
	var msg_prompt = "NCRAFTERS_EFFECT_VALUES_CLARIFICATION"
	var attributes = DLC.mods_by_id["sticker_recycle_bonus"].attribute_dictionary
	var battle_move = sticker.battle_move
	var attribute_profile = battle_move.attribute_profile
	var readable_options:Array = ["None"]
	var unfiltered_attributes:Array = attributes[attribute_profile]
	var modded_attributes:Array = []
	var applicable_effects:Array = [null]
	var rare_color = "2b9aeb"
	var uncommon_color = "1fba33"
	for attr in unfiltered_attributes:
		if upgradable_effects and exists_onsticker(sticker, attr):
			for sticker_attr in sticker.attributes:
				if attribute_matches(sticker_attr,attr) and is_upgradable(sticker_attr) and has_core(attr):
					modded_attributes.push_back(attr)
		if not upgradable_effects and not exists_onsticker(sticker,attr):
			if attr.rarity == BaseItem.Rarity.RARITY_RARE and get_sticker_potential(sticker).rare_full:
				continue
			if attr.rarity == BaseItem.Rarity.RARITY_UNCOMMON and get_sticker_potential(sticker).uncommon_full:
				continue			
			if attr.is_applicable_to(battle_move) and has_core(attr):
				modded_attributes.push_back(attr)		
	
	for mod_attribute in modded_attributes:					
		var attach_rate = get_core(mod_attribute).drop_chance 
		var display_rate = " ("+str(attach_rate-5) +"%"+ ")" if not upgradable_effects else ""
		var html_color = rare_color if mod_attribute.rarity == BaseItem.Rarity.RARITY_RARE else uncommon_color
		if mod_attribute.has_method("generate"):
			mod_attribute.generate(battle_move, Random.new())
			if mod_attribute.get("chance") != null:
				mod_attribute.chance = mod_attribute.chance_max
			if mod_attribute.get("stat_value") != null:
				mod_attribute.stat_value = mod_attribute.stat_value_max

		readable_options.push_back("[color=#"+str(html_color)+"]"+Loc.tr(mod_attribute.get_description(battle_move))+ "[/color]" + display_rate)
		applicable_effects.push_back(mod_attribute)
	var result = yield (show_options(msg_prompt,readable_options), "completed")
	
	
	if result > 0:
		return applicable_effects[result]
	return null
	
func is_effect_upgraded(upgrade, effect)->bool:
	if upgrade.get("stat_value"):
		return upgrade.stat_value > effect.stat_value
	if upgrade.get("chance"):
		return upgrade.chance > effect.chance
	return false
	
func get_insufficient_material_msg(effect, upgrade:bool = false, removal:bool = false)->String:
	var effect_BOM = get_material_cost(effect, upgrade, removal)
	var current_app_material_amt = SaveState.inventory.get_item_amount(effect_BOM.application_material)
	var current_resource_amt = SaveState.inventory.get_item_amount(effect_BOM.material)
	var current_core_amt = SaveState.inventory.get_item_amount(effect_BOM.core)
	var msg_string = "NCRAFTERS_MISSING_REMOVAL_COST" if removal else "NCRAFTERS_MISSING_COST" 
	var insufficient_msg:String = Loc.trf(msg_string,{
		"application_icon":effect_BOM.application_material.icon.resource_path,
		"application_cost":effect_BOM.application_cost,
		"application_name":effect_BOM.application_material.name,
		"application_status": Color.green.to_html() if current_app_material_amt >= effect_BOM.application_cost else Color.red.to_html(),
		"resource_icon":effect_BOM.material.icon.resource_path,
		"resource_name":effect_BOM.material.name,
		"resource_cost":effect_BOM.cost,
		"resource_status": Color.green.to_html() if current_resource_amt >= effect_BOM.cost else Color.red.to_html(),
		"core_icon":effect_BOM.core.icon.resource_path,
		"application_value":SaveState.inventory.get_item_amount(effect_BOM.application_material),
		"resource_value":SaveState.inventory.get_item_amount(effect_BOM.material),
		"core_value":SaveState.inventory.get_item_amount(effect_BOM.core),
		"core_status":Color.green.to_html() if current_core_amt >= effect_BOM.core_cost else Color.red.to_html(),
		"core_cost":effect_BOM.core_cost,				
		"core_name":effect_BOM.core.get_clean_name(Color.white.to_html())
	})	
	return insufficient_msg
	
func core_success_roll_v2(_sticker, attribute)->bool:
	var core_id = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[attribute.template_path]
	var drop_rate = DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[core_id].drop_chance
	return randi() % 100 < drop_rate
