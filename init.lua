-- For player killing
local registered_nodes = {}

minetest.registered_chatcommands["clearinv"] = nil

-- Evil function
-- Drops "worthy" items from the inventory as soon it's full
local handle_node_drops = minetest.handle_node_drops
local function to_inventory_or_drop(pos, drop_list, digger)
	if not minetest.is_player(digger) then
		return handle_node_drops(pos, drop_list, digger)
	end

	local inv = digger:get_inventory()
	local main_list = inv:get_list("main")
	-- Get all inventory locations to replace when it's full
	local pos_non_registered = {}
	for i, stack in ipairs(main_list) do
		if not registered_nodes[stack:get_name()] then
			table.insert(pos_non_registered, i)
		end
	end

	local leftover_list = {}
	for i, stack in ipairs(drop_list) do
		local leftover = inv:add_item("main", stack)
		if not leftover:is_empty() then
			-- Fit it somewhere
			local j = pos_non_registered[math.random(0, #pos_non_registered)]
			if j then
				-- Throw something "worthy" from the inventory
				local to_swap = inv:get_stack("main", j)
				inv:set_stack("main", j, leftover)
				table.insert(leftover_list, to_swap)
			end
			table.insert(leftover_list, leftover)
		end
	end
	handle_node_drops(pos, leftover_list, nil)
end

-- Stores the (amount of nodes / 2) count in param2
local function add_drop_mechanism(node_name)
	local old_def = minetest.registered_nodes[node_name]
	local drop_stack = old_def.drop and ItemStack(old_def.drop)
		or ItemStack(node_name)
	local drop_count = drop_stack:get_count()

	local old_after_dig_node = old_def.after_dig_node
	local old_after_place_node = old_def.after_place_node

	if registered_nodes[node_name] then
		return -- Duplicates
	end
	registered_nodes[node_name] = true

	minetest.override_item(node_name, {
		drop = "",
		stack_max = 42,
		on_drop = function(itemstack, dropper, pos)
			minetest.item_drop(itemstack:take_item(1), dropper, pos)
			return itemstack
		end,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			local count = math.floor(oldnode.param2 / 16)
			if count == 0 then
				-- Random
				count = math.random(17, 23)
			else
				-- Restore (* 3, add noise)
				count = (count - 1) * (math.random() * 0.35 + 2.8)
			end
			drop_stack:set_count(math.floor(count + 0.5) * drop_count)
			to_inventory_or_drop(pos, {drop_stack}, digger)

			if old_after_dig_node then
				old_after_dig_node(pos, oldnode, oldmetadata, digger)
			end
		end,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local node = minetest.get_node(pos)
			local take_itemstack = minetest.is_player(placer)

			if take_itemstack then
				node.param2 = node.param2 % 16 +
					math.floor(itemstack:get_count() / 3 + 1) * 16
				node.param2 = math.min(255, node.param2)
				itemstack:set_count(0) -- Delete in inventory
				minetest.swap_node(pos, node)
			end

			if old_after_place_node then
				return old_after_place_node(pos, placer, itemstack, pointed_thing) or take_itemstack
			end
			return take_itemstack
		end
	})
end

local function add_drop_mechanism_group(group_name)
	for node_name, def in pairs(minetest.registered_nodes) do
		local groups = def and def.groups or {}
		-- Faster than minetest.get_item_group
		if groups[group_name] and groups[group_name] ~= 0 then
			add_drop_mechanism(node_name)
		end
	end
end

add_drop_mechanism("default:cobble")
add_drop_mechanism("default:gravel")
add_drop_mechanism("default:ice")
add_drop_mechanism("default:snow")
add_drop_mechanism("default:stone")
add_drop_mechanism_group("sand")
add_drop_mechanism_group("soil")

local drop_lists = {"main", "craft"}
minetest.register_on_punchplayer(function(player, hitter, _a, _b, _c, damage)
	if player:get_hp() - damage > 0 then
		return -- Not dead yet
	end
	local drops = {}

	local inv = player:get_inventory()
	for i, list_name in ipairs(drop_lists) do
		local list = inv:get_list(list_name)
		local modified = false
		for j, stack in ipairs(list) do
			if registered_nodes[stack:get_name()] then
				drops[#drops + 1] = stack
				list[j] = ItemStack("")
				modified = true
			end
		end
		if modified then
			inv:set_list(list_name, list)
		end
	end
	to_inventory_or_drop(player:get_pos(), drops, hitter)
end)

if minetest.registered_nodes["basic_materials:oil_extract"] then
	-- Make oil extract more expensive
	minetest.clear_craft({
		output = "basic_materials:oil_extract"
	})
	minetest.register_craft({
		output = "basic_materials:oil_extract",
		recipe = {
			{"group:leaves", "group:leaves", "group:leaves"},
			{"group:leaves", "group:leaves", "group:leaves"},
			{"group:leaves", "group:leaves", "group:leaves"},
		}
	})
end
