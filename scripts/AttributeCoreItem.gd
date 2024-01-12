extends BaseItem

enum resources {pulp, wood, plastic, metal, wheat, upgrape, fused_material, jelly, old_book,
				olive_up, tape_air, tape_astral, tape_basic, tape_beast, tape_chrome, tape_earth, tape_fire,
				tape_ice, tape_lightning, tape_metal, tape_plant, tape_plastic, tape_poison,
				tape_water, bootleg_ritual_candle, tape_optical_laser}

var items = Datatables.load("res://data/items/").table

export (Array, Dictionary) var buffs
export (String) var template_path
export (resources) var attach_resource
export (int) var attach_cost = 100
export (resources) var upgrade_resource
export (int) var upgrade_cost = 100
export (int) var drop_chance
export (int) var core_cost = 1

func get_template_rarity_color():
	var attribute:StickerAttribute = load(template_path)
	return RARITY_COLORS[attribute.rarity].to_html()

func get_name()->String:
	return Loc.trf(name, {
			"rarity":get_template_rarity_color()
		})

func get_clean_name(color)->String:
	return Loc.trf(name,{
		"rarity":color
	})

func get_description():
	return Loc.trf(description, {
		"material":get_attach_resource().icon.resource_path,
		"upgrade_material":get_upgrade_resource().icon.resource_path,
		"cost":attach_cost,
		"upgrade_cost":upgrade_cost,
		"core_cost":core_cost
	})

func get_attach_resource()->Resource:
	if attach_resource == resources.pulp:
		return items["pulp"]
	if attach_resource == resources.plastic:
		return items["plastic"]
	if attach_resource == resources.metal:
		return items["metal"]
	if attach_resource == resources.wood:
		return items["wood"]
	if attach_resource == resources.wheat:
		return items["wheat"]
	if attach_resource == resources.upgrape:
		return items["upgrape"]
	if attach_resource == resources.fused_material:
		return items["fused_material"]
	if attach_resource == resources.jelly:
		return items["jelly"]
	if attach_resource == resources.old_book:
		return items["old_book"]
	if attach_resource == resources.olive_up:
		return items["olive_up"]
	if attach_resource == resources.tape_air:
		return items["tape_air"]
	if attach_resource == resources.tape_astral:
		return items["tape_astral"]
	if attach_resource == resources.tape_basic:
		return items["tape_basic"]
	if attach_resource == resources.tape_beast:
		return items["tape_beast"]
	if attach_resource == resources.tape_chrome:
		return items["tape_chrome"]
	if attach_resource == resources.tape_earth:
		return items["tape_earth"]
	if attach_resource == resources.tape_fire:
		return items["tape_fire"]
	if attach_resource == resources.tape_ice:
		return items["tape_ice"]
	if attach_resource == resources.tape_lightning:
		return items["tape_lightning"]
	if attach_resource == resources.tape_metal:
		return items["tape_metal"]
	if attach_resource == resources.tape_plant:
		return items["tape_plant"]
	if attach_resource == resources.tape_plastic:
		return items["tape_plastic"]
	if attach_resource == resources.tape_poison:
		return items["tape_poison"]
	if attach_resource == resources.tape_water:
		return items["tape_water"]
	if attach_resource == resources.bootleg_ritual_candle:
		return items["bootleg_ritual_candle"]
	if attach_resource == resources.tape_optical_laser:
		return items["tape_optical_laser"]

	return items["pulp"]

func get_upgrade_resource()->Resource:
	if upgrade_resource == resources.pulp:
		return items["pulp"]
	if upgrade_resource == resources.plastic:
		return items["plastic"]
	if upgrade_resource == resources.metal:
		return items["metal"]
	if upgrade_resource == resources.wood:
		return items["wood"]
	if upgrade_resource == resources.wheat:
		return items["wheat"]
	if upgrade_resource == resources.upgrape:
		return items["upgrape"]
	if upgrade_resource == resources.fused_material:
		return items["fused_material"]
	if upgrade_resource == resources.jelly:
		return items["jelly"]
	if upgrade_resource == resources.old_book:
		return items["old_book"]
	if upgrade_resource == resources.olive_up:
		return items["olive_up"]
	if upgrade_resource == resources.tape_air:
		return items["tape_air"]
	if upgrade_resource == resources.tape_astral:
		return items["tape_astral"]
	if upgrade_resource == resources.tape_basic:
		return items["tape_basic"]
	if upgrade_resource == resources.tape_beast:
		return items["tape_beast"]
	if upgrade_resource == resources.tape_chrome:
		return items["tape_chrome"]
	if upgrade_resource == resources.tape_earth:
		return items["tape_earth"]
	if upgrade_resource == resources.tape_fire:
		return items["tape_fire"]
	if upgrade_resource == resources.tape_ice:
		return items["tape_ice"]
	if upgrade_resource == resources.tape_lightning:
		return items["tape_lightning"]
	if upgrade_resource == resources.tape_metal:
		return items["tape_metal"]
	if upgrade_resource == resources.tape_plant:
		return items["tape_plant"]
	if upgrade_resource == resources.tape_plastic:
		return items["tape_plastic"]
	if upgrade_resource == resources.tape_poison:
		return items["tape_poison"]
	if upgrade_resource == resources.tape_water:
		return items["tape_water"]
	if upgrade_resource == resources.bootleg_ritual_candle:
		return items["bootleg_ritual_candle"]
	if upgrade_resource == resources.tape_optical_laser:
		return items["tape_optical_laser"]

	return items["pulp"]

