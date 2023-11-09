# Description
This mod adds some quality of life features to the sticker inventory and introduces a system to edit modifiers on your stickers.

# Features
* Recycle Locking
  * While interacting with your sticker collection you can choose to ```Lock``` that sticker to prevent it from being recycled individually or in bulk recycling. The sticker can be unlocked manually at any time.
  * **Note**: The Locked status is automatically reset if the sticker attributes are modified.
* Attribute Filtering
  * When using Filters on your stickers, you can also choose to filter by specific Attribute modifiers.
  * Buffs/Debuffs are generalized under a single Buff/Debuff attribute, rather than specified by the specific status effect it has.
 * Sticker Attribute Editing
   * Using the new Attribute Core system, the player is able to add/upgrade/remove attributes from their stickers.
   * See details below.
 * Traveling Merchant
   * The ```max stack``` limit on purchasing for the Traveling Merchant has been increased from ```1,000``` to ```100,000``` to reduce the number of repeated button presses required to make a large purchase. 

# Attribute Core System
This system introduces new ```Attribute Core``` resources the player can collect by recycling Uncommon/Rare stickers. Each sticker attribute has its own ```Attribute Core``` to be used as a resource to be spent on adding/upgrading stickers with the relevant modifier.
### Collecting Attribute Cores
Recycling a sticker will always convert each attribute modifier found into an ```Attribute Core``` for that modifier. This is the only way to collect ```Attribute Cores```, as using the ```Remove Attribute``` action will only delete the attribute from the sticker.
### Applying Attribute Cores
When interacting with a sticker you can choose ```Apply Attributes``` to select from a list of compatible attribute modifiers the sticker can use _(if you own at least 1 ```Attribute Core``` for that attribute)_. Applying an attribute will cost resources to do and the cost will vary depending on the specific attribute being applied. Applying the attribute is also **not guaranteed**, success will depend on which attribute you are trying to apply.
### Upgrading Existing Attributes
This action allows you to choose an _upgradable_ attribute from your sticker to attempt a re-roll of its chance/stat value. There is also a resource cost to pay for this action, though it is at a reduced price. While there is technically no _dice roll_ to succeed at upgrading, the system will only consider the upgrade a success if the new value rolled is **greater** than the existing value. Because of the way stats modifiers are generated, it will be significantly more difficult to upgrade your values beyond that attribute's _mode modifier_ value. 
### Removing Existing Attributes
This action allows you to delete an attribute modifier from your sticker. You still need to pay a resource cost for the action, but that cost does not include any ```Attribute Core```. Doing this **will not** retrieve an ```Attribute Core``` from the sticker. 
### Limitations
The system will not allow the creation of _unnatural_ stickers. These are defined as follows:
* You are only able to add as many attributes as a sticker can normally hold (2 uncommon + 1 rare).
* The values can only be within the attribute's set minimum and maximum value.
* Stickers can only hold attributes that are **compatible** with that sticker. If it can't be normally generated with the attribute, it cannot be applied by this system.

# FAQs
* Can the mod be safely removed?
  * Yes
* What happens to my modified stickers and attribute cores after removing the mod?
  * Stickers modified with this mod are still considered valid in vanilla gameplay so you will be able to keep using them. The Attribute Core resources will dissappear from your inventory to allow the save file to load normally.
* Is there a way to increase success rates for Apply/Upgrades?
  * No, the rates for applying attributes are fixed and Upgrades are dependent on the vanilla attribute generation formulas. There's no adjusting these rates.
* Does the ```Merchant's Guild Discount``` apply to the resource costs of each attribute?
  * None of the game's discount effects currently affect the resource costs associated to using an ```Attribute Core```.  
