static func patch():
	var script_path = "res://menus/inventory/InventoryTab.gd"
	var patched_script : GDScript = preload("res://menus/inventory/InventoryTab.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("Check that %s is included in Modified Files"% script_path) 
			return
		patched_script.source_code = file.get_as_text()
		file.close()
	
	var code_lines:Array = patched_script.source_code.split("\n")	
	
	var code_index:int = code_lines.find("""	if user_filter.has("type"):""")
	if code_index >= 0:
		code_lines.insert(code_index-1,get_code("is_filtered_out"))
	
	code_index = code_lines.find("		item.recycle(null, recyclables)")
	if code_index >= 0:
		code_lines[code_index] = get_code("bulk_recycle")
	
	code_index = code_lines.find("			if not _is_filtered_out(item):")
	if code_index >= 0:
		code_lines.remove(code_index+2)
		code_lines[code_index+1] = get_code("refresh")
	
	code_lines.insert(code_lines.size() - 1,get_code("new_functions"))

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	var err = patched_script.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return
	print("Patched %s successfully." % script_path)	
	
static func get_code(block:String)->String:
	var code_blocks:Dictionary = {}
	
	code_blocks["is_filtered_out"] = """
	if user_filter.has("attribute"):
		if typeof(user_filter.attribute) != TYPE_STRING:
			return true	
		if not (item_node.item is StickerItem):
			return true
		var has_attribute:bool = false
		for attribute in item_node.item.attributes:					
			if attribute.template_path == user_filter.attribute:				
				has_attribute = true
				break
		if not has_attribute:
			return true
	"""	
	
	code_blocks["bulk_recycle"] = """
		if not vault_contains_sticker(item):
			for attribute in item.item.attributes:			
				if DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores.has(attribute.template_path):
					var core_id = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[attribute.template_path]			
					recyclables.push_back({"item":DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[core_id],"amount":item.amount})
			item.recycle(null, recyclables)
				
	"""
	
	code_blocks["refresh"] = """
				if item.item is StickerItem:
					if not vault_contains_sticker(item):
						filtered_count += item.amount
						filtered_stacks += 1
				else:
					filtered_count += item.amount
					filtered_stacks += 1
	"""	
	
	code_blocks["new_functions"] = """
func vault_contains_sticker(sticker)->bool:
	if not SaveState.other_data.has("stickervault"):
		return false 
	var item_key = get_item_key(sticker)
	for item in SaveState.other_data.stickervault:
		if str(item) == item_key:	
			return true
	return false
	
func get_item_key(sticker):
	var item_key = str(sticker.item.name) + str(sticker.item.value)
	for attr in sticker.item.attributes:
		 item_key = item_key + attr.template_path	
	return item_key	
	"""
	
	return code_blocks[block]
