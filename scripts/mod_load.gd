extends ContentInfo

var core_dictionary:Dictionary
var searchable_cores:Dictionary		
var attribute_dictionary:Dictionary
var StickerCoreSystem = preload("res://mods/Sticker_Recycle_Bonus/StickerCoreSystem.tres")

export (Array, PackedScene) var title_popups:Array
export (String) var title_popup_flag:String
export var disable_in_editor:bool = false
func on_title_screen():
	if OS.has_feature("editor") and disable_in_editor: 
		return	
	if title_popups.size() > 0 and not UserSettings.misc_data.has(title_popup_flag):
		yield (MenuHelper.show_tutorial_box(name, title_popups), "completed")
		UserSettings.misc_data[title_popup_flag] = true
		UserSettings.save_settings()

func init_content():
	if OS.has_feature("editor") and disable_in_editor: 
		return	 
	if DLC.has_mod("cat_modutils", 15):
		DLC.mods_by_id.cat_modutils.trans_patch.add_translation(preload("res://mods/Sticker_Recycle_Bonus/translations/mod_strings.en.translation"))
	else:
		rebuild_translations()

	var inventory_tabscript: Resource = preload("res://mods/Sticker_Recycle_Bonus/scripts/InventoryTab.gd")
	inventory_tabscript.take_over_path("res://menus/inventory/InventoryTab.gd")
	var filter_menu:Resource = preload("res://mods/Sticker_Recycle_Bonus/scenes/StickerFilterMenu.tscn")
	filter_menu.take_over_path("res://menus/inventory/StickerFilterMenu.tscn")
	var detail_panel:Resource = preload("res://mods/Sticker_Recycle_Bonus/scenes/InventoryDetailPanel.tscn")
	detail_panel.take_over_path("res://menus/inventory/InventoryDetailPanel.tscn")
	var partytapeui_ext:Resource = preload("res://mods/Sticker_Recycle_Bonus/scripts/PartyTapeUI_Ext.gd")
	partytapeui_ext.take_over_path("res://menus/party_tape/PartyTapeUI.gd")
	var randomexchangemenu:Resource = preload("res://mods/Sticker_Recycle_Bonus/scripts/RandomExchangeMenuAction_Ext.gd")
	randomexchangemenu.take_over_path("res://nodes/actions/RandomExchangeMenuAction.gd")
	
	yield(SceneManager.preloader, "singleton_setup_completed")

	core_dictionary = Datatables.load("res://mods/Sticker_Recycle_Bonus/items/").table
	attribute_dictionary = build_sticker_attribute_list()
	for core in core_dictionary.keys():
		searchable_cores[core_dictionary[core].template_path] = core

func rebuild_translations():	
	var translation_files:Array = [load("res://translation/1.1_demo.en.translation"),
									load("res://translation/1.1_release.en.translation"),
									load("res://translation/dialogue_demo.en.translation"),
									load("res://translation/dialogue_release.en.translation"),
									load("res://translation/strings_demo.en.translation"),
									load("res://translation/strings_release.en.translation")
									]	
	var csvFile:File = File.new()		
	var output:File = File.new()
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
						new_instance.buffs = []
						new_instance.buffs.push_back(effect)
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			if att_instance.get("debuffs") != null:
				for effect in debuffs:
					if effect.is_debuff:
						var new_instance = attribute.instance()
						new_instance.debuffs = []
						new_instance.debuffs.push_back(effect)
						new_instance.chance = new_instance.chance_max
						attribute_dictionary[profile].push_back(new_instance)
				continue
			attribute_dictionary[profile].push_back(att_instance)
	return attribute_dictionary	
