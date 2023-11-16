extends RandomExchangeMenuAction
 
var StickerCoreSystem = DLC.mods_by_id["sticker_recycle_bonus"].StickerCoreSystem
func generate_exchange(item:BaseItem, rand:Random)->Exchange:
	var merchant_max_purchase = StickerCoreSystem.merchant_max_purchase
	var result = SimpleExchange.new()
	result.max_amount = merchant_max_purchase
	result.item = item
	var estimated_value = result.get_value()
	
	var currency = choose_currency(rand, estimated_value, item)
	if currency == null:
		return null
	
	result.currency = currency
	return result
