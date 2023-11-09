extends "res://menus/inventory/InventoryTab.gd"

func _is_filtered_out(item_node:Node)->bool:
	if context is MonsterTape:
		if not item_node.is_usable(BaseItem.ContextKind.CONTEXT_TAPE, context):
			return true
	if context is Character:
		if not item_node.is_usable(BaseItem.ContextKind.CONTEXT_CHARACTER, context):
			return true
	
	if user_filter.has("name"):
		var item_name = item_node.get_item_name()
		if item_node.item is StickerItem:
			item_name = item_node.item.battle_move.name
		if Strings.strip_diacritics(tr(item_name).to_lower()).find(user_filter.name) == - 1:
			return true
	
	if user_filter.has("rarity"):
		if item_node.item.get_rarity() != user_filter.rarity:
			return true
	
	if user_filter.has("category"):
		if not (item_node.item is StickerItem):
			return true
		if item_node.item.battle_move.category_name != user_filter.category:
			return true
	
	if user_filter.has("type"):
		if not (item_node.item is StickerItem):
			return true
		var move = item_node.item.battle_move
		if move.elemental_types.size() == 0:
			if user_filter.type != "typeless":
				return true
		else :
			if move.elemental_types[0].id != user_filter.type:
				return true
	
	if user_filter.has("attribute"):
		if not (item_node.item is StickerItem):
			return true
		var has_attribute:bool = false
		for attribute in item_node.item.attributes:
			if attribute.script == user_filter.attribute.script:				
				if user_filter.attribute.script == load("res://data/sticker_attribute_scripts/StatStickerAttribute.gd"):
					if attribute.get("stat_name") == user_filter.attribute.stat_name and attribute.get("multiply_empty_sticker_slots") == user_filter.attribute.multiply_empty_sticker_slots:						
						has_attribute = true
						break					
					continue
				elif user_filter.attribute.script == load("res://data/sticker_attribute_scripts/HealStickerAttribute.gd"):
					if attribute.script == load("res://data/sticker_attribute_scripts/HealStickerAttribute.gd") and attribute.get("multiply_empty_sticker_slots") == user_filter.attribute.multiply_empty_sticker_slots:						
						has_attribute = true
						break
					continue
				elif user_filter.attribute.script == load("res://data/sticker_attribute_scripts/AttackAfterUseStickerAttribute.gd"):
					if attribute.get("move_path") == user_filter.attribute.move_path:						
						has_attribute = true
						break
					continue
				elif user_filter.attribute.script == load("res://data/sticker_attribute_scripts/APRefundStickerAttribute.gd"):
					if attribute.get("amount") == user_filter.attribute.amount:						
						has_attribute = true
						break
					continue										
				elif attribute.get("stat_name") and user_filter.attribute.get("stat_name"):
					if attribute.stat_name == user_filter.attribute.stat_name:
						has_attribute = true
						break
					continue
				elif attribute.get("condition") and user_filter.attribute.get("condition"):
					if attribute.condition == user_filter.attribute.condition:
						has_attribute = true
						break
					continue
				
				has_attribute = true
				break
		if not has_attribute:
			return true
	
	return false

func bulk_recycle():
	var recyclables = []
	for item in filtered_items:
		if not vault_contains_sticker(item):
			for attribute in item.item.attributes:			
				if DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores.has(attribute.template_path):
					var core_id = DLC.mods_by_id["sticker_recycle_bonus"].searchable_cores[attribute.template_path]			
					recyclables.push_back({"item":DLC.mods_by_id["sticker_recycle_bonus"].core_dictionary[core_id],"amount":item.amount})
			item.recycle(null, recyclables)
			

	refresh()
	if recyclables.size() > 0:
		yield (MenuHelper.give_items(recyclables), "completed")
	grab_focus()

func drop_item(sticker, attribute)->bool:
	var profile = sticker.battle_move.attribute_profile
	var rand = Random.new()
	var valid_attributes = profile.get_applicable_attributes(sticker.rarity, sticker.battle_move)
	for _i in range(sticker.attributes.size()):
		var attr = rand.weighted_choice(valid_attributes)
		if attr == null:
			break		
		if attribute.template_path == attr.resource_path:
			return true
		valid_attributes.erase(attr)		
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
	var item_key = str(sticker.item.name) + str(sticker.item.value)
	for attr in sticker.item.attributes:
		 item_key = item_key + attr.template_path	
	return item_key
	
func refresh(reapply_filter:bool = true):
	if reapply_filter:
		filtered_count = 0
		filtered_stacks = 0
		filtered_items.clear()
		filtered_item_indices.clear()
		var incompatible_items = []
		for item in items.get_children():
			if not _is_filtered_out(item):
				if item.item is StickerItem:
					if not vault_contains_sticker(item):
						filtered_count += item.amount
						filtered_stacks += 1
				else:
					filtered_count += item.amount
					filtered_stacks += 1
				if not _is_compatible(item):
					incompatible_items.push_back(item)
				else :
					filtered_items.push_back(item)
					filtered_item_indices[item.get_index()] = filtered_items.size() - 1
		compat_count = filtered_items.size()
		for item in incompatible_items:
			filtered_items.push_back(item)
			filtered_item_indices[item.get_index()] = filtered_items.size() - 1
	
	_reset_page()
	
	var v_scroll = scroll_container.get_v_scroll()
	
	next_page_btn.visible = paginated and page_index < page_count - 1
	prev_page_btn.visible = paginated and page_index > 0
	
	focus_index = 0
	
	var btn_index = 0
	
	buttons.left_right_as_page_up_down = not paginated
	
	if SaveState.inventory.CATEGORY_SIZE_LIMIT.has(items.name):
		category_size_limit_label.text = Loc.trf("UI_INVENTORY_TAB_CATEGORY_SIZE_LIMIT", {
			stacks = items.get_child_count(), 
			maximum = SaveState.inventory.CATEGORY_SIZE_LIMIT[items.name]
		})
	else :
		category_size_limit_label.text = ""
	
	for i in range(page_start_index, page_end_index):
		var item = filtered_items[i]
		var compat = _is_compatible(item)
		assert ( not _is_filtered_out(item))
		
		if item.amount <= 0:
			continue
		
		var button = _get_btn(btn_index)
		assert (btn_index == button.get_index())
		button.inventory_index = item.get_index()
		button.set_item_node(item, items_in_use)
		button.focus_mode = Control.FOCUS_ALL
		if compat:
			button.modulate.a = 1.0
			button.disabled = false
			button.aux_text_override = ""
		else :
			button.modulate.a = 0.5
			button.disabled = true
			button.aux_text_override = "INVENTORY_INCOMPATIBLE"
		
		if item.get_index() == inventory_index:
			focus_index = btn_index
		btn_index += 1
	
	while buttons.get_child_count() > btn_index:
		var button = buttons.get_child(buttons.get_child_count() - 1)
		buttons.remove_child(button)
		button.queue_free()
	
	var category_name = "ITEM_CATEGORY_" + items.name
	
	if paginated:
		title_label.text = Loc.trf("UI_INVENTORY_TAB_TITLE_PAGED", {
			category = category_name, 
			page = page_index + 1, 
			page_count = page_count
		})
	else :
		title_label.text = Loc.trf("UI_INVENTORY_TAB_TITLE", {
			category = category_name
		})
	
	if context is MonsterTape and items.name == "stickers":
		empty_label.visible = compat_count == 0
		empty_label.text = "INVENTORY_NO_COMPATIBLE_STICKERS"
	else :
		empty_label.visible = btn_index == 0
		empty_label.text = "INVENTORY_EMPTY"
	
	buttons.setup_focus()
	scroll_container.set_v_scroll(v_scroll)	
