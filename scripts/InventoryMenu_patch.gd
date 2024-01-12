static func patch():
	var script_path = "res://menus/inventory/InventoryMenu.gd"
	var patched_script : GDScript = preload("res://menus/inventory/InventoryMenu.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("Check that %s is included in Modified Files"% script_path)
			return
		patched_script.source_code = file.get_as_text()
		file.close()

	var code_lines:Array = patched_script.source_code.split("\n")

	var code_index:int = code_lines.find("""	var menu = preload("StickerFilterMenu.tscn").instance()""")
	if code_index >= 0:
		code_lines[code_index] = get_code()

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	var err = patched_script.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return

static func get_code()->String:
	return """
	var menu = preload("res://mods/Sticker_Recycle_Bonus/scenes/StickerFilterMenu.tscn").instance()
"""
