extends "res://menus/BaseMenu.gd"

onready var input_container = find_node("InputContainer")
onready var name_input = find_node("NameInput")
onready var rarity_input = find_node("RarityInput")
onready var category_input = find_node("CategoryInput")
onready var type_input = find_node("TypeInput")
onready var reset_button = find_node("ResetButton")
onready var attribute_input = find_node("AttributeInput")


var filter: = {} setget set_filter

func _ready():
	refresh()

func set_filter(value:Dictionary):
	filter = value
	if is_inside_tree():
		refresh()

func refresh():
	name_input.text = filter.get("name", "")
	rarity_input.selected_value = filter.get("rarity")
	category_input.selected_value = filter.get("category")
	type_input.selected_value = filter.get("type")
	attribute_input.selected_value = filter.get("attribute")

func grab_focus():
	input_container.grab_focus()

func _on_SaveButton_pressed():
	filter = {}
	
	if name_input.text != "":
		filter.name = Strings.strip_diacritics(name_input.text.to_lower())
	
	if rarity_input.selected_value != null:
		filter.rarity = rarity_input.selected_value
	
	if category_input.selected_value != null:
		filter.category = category_input.selected_value
	
	if type_input.selected_value != null:
		filter.type = type_input.selected_value
	
	if attribute_input.selected_value != null:
		filter.attribute = attribute_input.selected_value
	
	choose_option(filter)

func _on_NameInput_focus_entered():
	reset_button.disabled = true

func _on_NameInput_focus_exited():
	reset_button.disabled = false

func _on_ResetButton_pressed():
	name_input.text = ""
	rarity_input.selected_value = null
	category_input.selected_value = null
	type_input.selected_value = null
	attribute_input.selected_value = null
