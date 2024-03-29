static func patch():
	var script_path = "res://nodes/actions/RandomExchangeMenuAction.gd"
	var patched_script : GDScript = preload("res://nodes/actions/RandomExchangeMenuAction.gd")

	if !patched_script.has_source_code():
		var file : File = File.new()
		var err = file.open(script_path, File.READ)
		if err != OK:
			push_error("Check that %s is included in Modified Files"% script_path)
			return
		patched_script.source_code = file.get_as_text()
		file.close()

	var code_lines:Array = patched_script.source_code.split("\n")

	var class_name_index = code_lines.find("class_name RandomExchangeMenuAction")
	if class_name_index >= 0:
		code_lines.remove(class_name_index)

	var code_index:int = code_lines.find("""	var result = SimpleExchange.new()""")
	if code_index >= 0:
		code_lines[code_index] = get_code()

	patched_script.source_code = ""
	for line in code_lines:
		patched_script.source_code += line + "\n"
	RandomExchangeMenuAction.source_code = patched_script.source_code
	var err = RandomExchangeMenuAction.reload()
	if err != OK:
		push_error("Failed to patch %s." % script_path)
		return

static func get_code()->String:
	return """
	var StickerCoreSystem = DLC.mods_by_id["sticker_recycle_bonus"].StickerCoreSystem
	var merchant_max_purchase = StickerCoreSystem.merchant_max_purchase
	var result = SimpleExchange.new()
	result.max_amount = merchant_max_purchase
	"""
