# Description
This mod adds some quality of life features to the sticker inventory and introduces a system to edit modifiers on your stickers.

# Features
* Recycle Locking
  * While interacting with your sticker collection you can choose to ```Lock``` that sticker to prevent it from being recycled individually or during ```Bulk Recycling```. The sticker can be unlocked manually at any time.
  * **Note**: The Locked status is automatically reset if the sticker attributes are modified.
* Attribute Filtering
  * When using ```Filters``` on your stickers, you can also choose to filter by specific ```Attribute Modifiers```.
  * Buffs/De-buffs are generalized under a single Buff/De-buff attribute, rather than specified by the specific status effect it has.
 * Sticker Attribute Editing
   * Using the new ```Attribute Core System```, the player is able to ```Add/Upgrade/Remove``` attributes from their stickers.
   * See details below.
 * Traveling Merchant
   * The ```max stack``` limit on purchasing for the Traveling Merchant has been increased from ```1,000``` to ```100,000``` to reduce the number of repeated button presses required to make a large purchase. 

# Attribute Core System
This system introduces new ```Attribute Core``` resources the player can collect by recycling ```Uncommon/Rare``` stickers. Each sticker attribute has its own Attribute Core to be used as a resource to be spent on adding/upgrading stickers with the relevant modifier.
### Collecting Attribute Cores
```Recycling``` stickers will always convert each attribute modifier found into an Attribute Core for that modifier. This is the only way to Collect Attribute Cores, as using the ```Remove Attribute``` action will only delete the attribute from the sticker.
### Applying Attribute Cores
When interacting with a sticker you can choose ```Apply Attributes``` to select from a list of compatible attribute modifiers the sticker can use _(if you own at least 1 Attribute Core for that attribute)_. Applying an attribute will cost ```resources``` to do and the cost will vary depending on the specific attribute being applied. 

Applying attributes is **not guaranteed**! Success rates depend on which attribute is being applied.
### Upgrading Existing Attributes
This action allows you to choose an _up-gradable_ attribute from your sticker to attempt a ```re-roll``` of its chance/stat value. There is also a ```resource``` cost to pay for this action, though it is at a ```reduced price```. 

While there is technically no _dice roll_ to succeed at upgrading, the system will only consider the upgrade a success if the new value rolled is **greater** than the existing value. Because of the way stats modifiers are generated, it will be significantly more difficult to upgrade your values beyond that attribute's _mode modifier_ value. 
### Removing Existing Attributes
This action is to ```Destroy``` an attribute modifier on a sticker. A reduced resource cost is paid for removal, but the cost does not include any Attribute Cores. 

This **will not** retrieve an Attribute Core for the destroyed attribute!
### Limitations
The system only allows sticker modifications within natural limits. This is defined as follows:
* You are only able to add as many attributes as a sticker can normally hold (2 uncommon + 1 rare).
* The values can only be within the attribute's set minimum and maximum value.
* Stickers can only hold attributes that are **compatible** with that sticker. If it can't be normally generated with the attribute, it cannot be applied by this system.

# Special Thanks
Thanks **Cirrus** for your all your work on refining the Attribute Core's resource system and help in maintaining balance with the vanilla game experience!

# FAQs
* Can the mod be safely removed?
  * Yes
* What happens to my modified stickers and attribute cores after removing the mod?
  * Stickers modified with this mod are still considered valid in vanilla game play so you will be able to keep using them. The Attribute Core resources will disappear from your inventory to allow the save file to load normally.
* Is there a way to increase success rates for Apply/Upgrades?
  * No, the rates for applying attributes are fixed and Upgrades are dependent on the vanilla attribute generation formulas. There's no adjusting these rates.
* Does the ```Merchant's Guild Discount``` apply to the resource costs of each attribute?
  * None of the game's discount effects currently affect the resource costs associated to using an ```Attribute Core```.

# Compatibility
* Tested on Cassette Beasts v1.5
* Safe to remove
