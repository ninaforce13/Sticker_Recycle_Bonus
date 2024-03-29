extends ContentInfo

var core_dictionary:Dictionary
var searchable_cores:Dictionary
var attribute_dictionary:Dictionary
var StickerCoreSystem = preload("res://mods/Sticker_Recycle_Bonus/StickerCoreSystem.tres")
var inventorydetailpanel_patch = preload("res://mods/Sticker_Recycle_Bonus/scripts/InventoryDetailPanel_patch.gd")
var inventorymenu_patch = preload("res://mods/Sticker_Recycle_Bonus/scripts/InventoryMenu_patch.gd")
var partytapeui_patch = preload("res://mods/Sticker_Recycle_Bonus/scripts/PartyTapeUI_patch.gd")
var randomexchangemenu_patch = preload("res://mods/Sticker_Recycle_Bonus/scripts/RandomExchangeMenu_patch.gd")
var inventorytab_patch = preload("res://mods/Sticker_Recycle_Bonus/scripts/InventoryTab_patch.gd")

export (Array, PackedScene) var title_popups:Array
export (String) var title_popup_flag:String

func on_title_screen():
	if title_popups.size() > 0 and not UserSettings.misc_data.has(title_popup_flag):
		yield (MenuHelper.show_tutorial_box(name, title_popups), "completed")
		UserSettings.misc_data[title_popup_flag] = true
		UserSettings.save_settings()

func init_content():
	if DLC.has_mod("cat_modutils", 15):
		DLC.mods_by_id.cat_modutils.trans_patch.add_translation(preload("res://mods/Sticker_Recycle_Bonus/translations/mod_strings.en.translation"))
	else:
		rebuild_translations()

func _init():
	inventorytab_patch.patch()
	inventorymenu_patch.patch()
	inventorydetailpanel_patch.patch()
	partytapeui_patch.patch()
	randomexchangemenu_patch.patch()

	register_commands()

	yield(SceneManager.preloader, "singleton_setup_completed")

	core_dictionary = Datatables.load("res://mods/Sticker_Recycle_Bonus/items/").table
	attribute_dictionary = build_sticker_attribute_list()
	for core in core_dictionary.keys():
		searchable_cores[core_dictionary[core].template_path] = core

func register_commands():
	Console.register("fix_amount_stacks", {
			"description":"Adjusts the buff/debuff amount stacks to their correct values.",
			"args":[],
			"target":[self, "fix_amount_stacks"]
		})
#	Console.register("debug_attribute_cores", {
#			"description":"Adds all attribute cores to inventory for debugging.",
#			"args":[],
#			"target":[self, "debug_attribute_cores"]
#		})
func fix_amount_stacks():
	var buffs = load("res://data/sticker_attributes/buff_user.tres").buffs.duplicate()
	var debuffs = load("res://data/sticker_attributes/debuff_target.tres").debuffs.duplicate()
	var item_collection = SaveState.inventory.get_snapshot()
	var corrections:Array = []
	for item in item_collection.items:
		if item.has("sticker"):
			for attribute in item.attributes:
				if attribute.get("buff") != null:
					var template = load(attribute.template_path).instance()
					for buff in buffs:
						if attribute.buff == buff.resource_path:
							var buff_index:int = 0
							for indexed_buff in template.buffs:
								if indexed_buff.resource_path == buff.resource_path:
									break
								buff_index += 1
							var correct_amount:int
							if buff_index < template.varied_amounts.size():
								correct_amount = template.varied_amounts[buff_index]
							else :
								correct_amount = template.default_amount
							if correct_amount != attribute.amount:
								attribute.amount = correct_amount
								corrections.push_back("Corrected: " + attribute.buff + " with amount " + str(attribute.amount))
				if attribute.get("debuff") != null:
					var template = load(attribute.template_path).instance()
					for debuff in debuffs:
						if attribute.debuff == debuff.resource_path:
							var debuff_index:int = 0
							for indexed_debuff in template.debuffs:
								if indexed_debuff.resource_path == debuff.resource_path:
									break
								debuff_index += 1
							var correct_amount:int
							if debuff_index < template.varied_amounts.size():
								correct_amount = template.varied_amounts[debuff_index]
							else :
								correct_amount = template.default_amount
							if correct_amount != attribute.amount:
								attribute.amount = correct_amount
								corrections.push_back("Corrected: " + attribute.debuff + " with amount " + str(attribute.amount))
	SaveState.inventory.set_snapshot(item_collection, 1)

	var party_snap = SaveState.party.get_snapshot()

	for tape in party_snap.player.tapes:
		for sticker in tape.stickers:
			if sticker == null:
				continue
			if not sticker.get("attributes"):
				continue
			for attribute in sticker.attributes:
				if attribute.get("buff") != null:
					var template = load(attribute.template_path).instance()
					for buff in buffs:
						if attribute.buff == buff.resource_path:
							var buff_index:int = 0
							for indexed_buff in template.buffs:
								if indexed_buff.resource_path == buff.resource_path:
									break
								buff_index += 1
							var correct_amount:int
							if buff_index < template.varied_amounts.size():
								correct_amount = template.varied_amounts[buff_index]
							else :
								correct_amount = template.default_amount
							if correct_amount != attribute.amount:
								attribute.amount = correct_amount
								corrections.push_back("Corrected Inventory Attribute: " + attribute.buff + " with amount " + str(attribute.amount))
				if attribute.get("debuff") != null:
					var template = load(attribute.template_path).instance()
					for debuff in debuffs:
						if attribute.debuff == debuff.resource_path:
							var debuff_index:int = 0
							for indexed_debuff in template.debuffs:
								if indexed_debuff.resource_path == debuff.resource_path:
									break
								debuff_index += 1
							var correct_amount:int
							if debuff_index < template.varied_amounts.size():
								correct_amount = template.varied_amounts[debuff_index]
							else :
								correct_amount = template.default_amount
							if correct_amount != attribute.amount:
								attribute.amount = correct_amount
								corrections.push_back("Corrected Inventory Attribute: " + attribute.debuff + " with amount " + str(attribute.amount))

	for partner in party_snap.partners.values():
		for tape in partner.tapes:
			for sticker in tape.stickers:
				if sticker == null:
					continue
				if not sticker.get("attributes"):
					continue
				for attribute in sticker.attributes:
					if attribute.get("buff") != null:
						var template = load(attribute.template_path).instance()
						for buff in buffs:
							if attribute.buff == buff.resource_path:
								var buff_index:int = 0
								for indexed_buff in template.buffs:
									if indexed_buff.resource_path == buff.resource_path:
										break
									buff_index += 1
								var correct_amount:int
								if buff_index < template.varied_amounts.size():
									correct_amount = template.varied_amounts[buff_index]
								else :
									correct_amount = template.default_amount
								if correct_amount != attribute.amount:
									attribute.amount = correct_amount
									corrections.push_back("Corrected Partner Sticker Attribute: " + attribute.buff + " with amount " + str(attribute.amount))
					if attribute.get("debuff") != null:
						var template = load(attribute.template_path).instance()
						for debuff in debuffs:
							if attribute.debuff == debuff.resource_path:
								var debuff_index:int = 0
								for indexed_debuff in template.debuffs:
									if indexed_debuff.resource_path == debuff.resource_path:
										break
									debuff_index += 1
								var correct_amount:int
								if debuff_index < template.varied_amounts.size():
									correct_amount = template.varied_amounts[debuff_index]
								else :
									correct_amount = template.default_amount
								if correct_amount != attribute.amount:
									attribute.amount = correct_amount
									corrections.push_back("Corrected Partner Sticker Attribute: " + attribute.debuff + " with amount " + str(attribute.amount))

	return corrections


func debug_attribute_cores():
	var cores:Dictionary = Datatables.load("res://mods/Sticker_Recycle_Bonus/items/").table
	var items:Array = []
	for core in cores.values():
		items.push_back({"item":core, "amount":10})
	yield(MenuHelper.give_items(items),"completed")

func rebuild_translations():
	var translation_files:Array = [load("res://translation/1.1_demo.en.translation"),
									load("res://translation/1.1_release.en.translation"),
									load("res://translation/dialogue_demo.en.translation"),
									load("res://translation/dialogue_release.en.translation"),
									load("res://translation/strings_demo.en.translation"),
									load("res://translation/strings_release.en.translation")
									]
	var csvFile:File = File.new()
	var datafiles:Array = []
	var import_translations:Array = []

	csvFile.open("res://mods/Sticker_Recycle_Bonus/translations/mod_strings.csv", File.READ)
	Datatables.list_dir(datafiles,"res://.import/","res")
	for file in datafiles:
		var loaded_file = load(file)
		if loaded_file.get("translations"):
			import_translations.append(loaded_file)

	for translation in translation_files:
		TranslationServer.remove_translation(translation)

	while !csvFile.eof_reached():
		var row = csvFile.get_csv_line()
		if row[0] != "":
			for translation in import_translations:
				if translation.translations["en"].get_message(row[0]) != "":
					if translation.translations["en"].get_message(row[0]) != row[1].c_unescape():
						translation.translations["en"].erase_message(row[0])
						translation.translations["en"].add_message(row[0], row[1].c_unescape())

	for translation in import_translations:
		TranslationServer.add_translation(translation.translations["en"])

func build_sticker_attribute_list()->Dictionary:

	var attribute_profiles = Datatables.load("res://data/sticker_attribute_profiles").table.values().duplicate()
	var buffs = load("res://data/sticker_attributes/buff_user.tres").buffs.duplicate()
	var debuffs = load("res://data/sticker_attributes/debuff_target.tres").debuffs.duplicate()
	var attribute_dictionary:Dictionary = {}
	for profile in attribute_profiles:
		attribute_dictionary[profile] = []
		for attribute in profile.attributes:
			var att_instance = attribute.instance()
			if att_instance.get("buffs") != null:
				for effect in buffs:
					if effect.is_buff and effect.script != load("res://data/status_effect_scripts/DamageOnContact.gd"):
						var new_instance = attribute.instance()
						new_instance.buff = effect
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			if att_instance.get("debuffs") != null:
				for effect in debuffs:
					if effect.is_debuff:
						var new_instance = attribute.instance()
						new_instance.debuff = effect
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			attribute_dictionary[profile].push_back(att_instance)
	return attribute_dictionary
