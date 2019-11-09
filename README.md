# item_party

The probably worst economic Minetest mod.
Various common nodes have an unusual behaviour:

* Node digging
	* If naturally generated: drops ~20x the regular ItemStack
	* If player-placed: drops approximately the placed count
* Node placing
	* It takes the entire stock (STONKS!) from your inventory
	* Changes the node so that diggers will get this stack back
* Node dropping
	* You can only drop one node at once
* Player killing
	* You get all special nodes from the killed player

Warning! As soon your inventory is full, "random" items will be taken and
dropped to free space.

There is no `/clearinv`, so you need to find a way how to get rid of the
huge node quantities.

## Mod combinations

`item_drop` is a nice addition to this annoying mod. You can prevent players
from doing something serious by feeding them useless items.


## Licensing

Code: CC0/WTFPL

Credits and PRs are welcome.