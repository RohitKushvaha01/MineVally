local S = minetest.get_translator("sf_editor")

sf_editor = {}

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local playerstates = {}

minetest.register_tool("sf_editor:breaker", {
	description = S("Block Breaker"),
	wield_image = "sf_editor_breaker.png",
	inventory_image = "sf_editor_breaker.png",
	tool_capabilities = {
		groupcaps = {
			editor_breakable = {uses=0, times = { [1] = 0, [2] = 0, [3] = 0 }},
			dig_immediate = {uses=0, times = { [1] = 0, [2] = 0, [3] = 0 }},
		},
	},
	groups = { disable_repair = 1 },
})
minetest.register_tool("sf_editor:breaker_turbo", {
	description = S("Turbo Block Breaker"),
	wield_image = "sf_editor_breaker.png^[hsl:30:0:0",
	inventory_image = "sf_editor_breaker.png^[hsl:30:0:0",
	tool_capabilities = {
		groupcaps = {
			editor_breakable = {uses=0, times = { [1] = 0.01, [2] = 0.01, [3] = 0.01 }},
			dig_immediate = {uses=0, times = { [1] = 0.01, [2] = 0.01, [3] = 0.01 }},
		},
	},
	groups = { disable_repair = 1 },
})

local do_stuff_in_radius = function(center, radius, shape, func)
	for z = -radius, radius do
	for y = -radius, radius do
	for x = -radius, radius do
		if shape == "cube" or (shape == "sphere" and x*x + y*y + z*z <= radius*radius) then
			local pos = vector.add(vector.new(x,y,z), center)
			func(pos)
		end
	end
	end
	end
end

minetest.register_tool("sf_editor:breaker_mass", {
	description = S("Mass Block Breaker"),
	wield_image = "sf_editor_breaker.png^[hsl:60:0:0",
	inventory_image = "sf_editor_breaker.png^[hsl:60:0:0",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		radius = math.max(0, (radius + 1) % 11)
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not EDITOR then
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(), S("You can only use this in Editor Mode!"))
			end
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		do_stuff_in_radius(center, radius, "sphere", function(pos)
			local node = minetest.get_node(pos)
			local g1 = minetest.get_item_group(node.name, "editor_breakable")
			local g2 = minetest.get_item_group(node.name, "dig_immediate")
			if g1 == 1 or g2 == 2 or g2 == 3 then
				minetest.remove_node(pos)
			end
		end)
		return itemstack
	end,
})

minetest.register_tool("sf_editor:leveled_remover", {
	description = S("Leveled Node Remover"),
	wield_image = "sf_editor_leveled_remover.png",
	inventory_image = "sf_editor_leveled_remover.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		radius = math.max(0, (radius + 1) % 21)
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not EDITOR then
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(), S("You can only use this in Editor Mode!"))
			end
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		do_stuff_in_radius(center, radius, "sphere", function(pos)
			local node = minetest.get_node(pos)
			local g = minetest.get_item_group(node.name, "leveled_node")
			if g ~= 0 then
				minetest.remove_node(pos)
			end
		end)
		return itemstack
	end,
})

minetest.register_tool("sf_editor:leveled_filler", {
	description = S("Leveled Node Filler"),
	wield_image = "sf_editor_leveled_filler.png",
	inventory_image = "sf_editor_leveled_filler.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		radius = math.max(0, (radius + 1) % 21)
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not EDITOR then
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(), S("You can only use this in Editor Mode!"))
			end
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		do_stuff_in_radius(center, radius, "sphere", function(pos)
			local node = minetest.get_node(pos)
			local g = minetest.get_item_group(node.name, "leveled_node")
			if g ~= 0 then
				local def = minetest.registered_nodes[node.name]
				if def and def._sf_unleveled_node_variant then
					minetest.set_node(pos, {name=def._sf_unleveled_node_variant})
				end
			end
		end)
		return itemstack
	end,
})



minetest.register_tool("sf_editor:leaves_protruder", {
	description = S("Leaves Protruder"),
	wield_image = "sf_editor_leaves_protruder.png",
	inventory_image = "sf_editor_leaves_protruder.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		radius = math.max(0, (radius + 1) % 21)
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not EDITOR then
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(), S("You can only use this in Editor Mode!"))
			end
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		local ctrl = user:get_player_control()
		local sneak_pressed = ctrl.sneak
		do_stuff_in_radius(center, radius, "sphere", function(pos)
			if math.random(1,10) < 10 then
				return
			end
			local node = minetest.get_node(pos)
			local offsets = {
				vector.new(-1, 0, 0),
				vector.new(1, 0, 0),
				vector.new(0, -1, 0),
				vector.new(0, 1, 0),
				vector.new(0, 0, -1),
				vector.new(0, 0, 1),
			}
			for o=1, #offsets do
				local offset = offsets[o]
				local offset_inverted = vector.multiply(offset, -1)
				local wallmounted = minetest.dir_to_wallmounted(offset_inverted)
				local opos = vector.add(pos, offset)
				local onode = minetest.get_node(opos)
				if sneak_pressed then
					if minetest.get_item_group(onode.name, "leaves_protrusion") == 1 then
						minetest.remove_node(opos)
					end
				else
					if onode.name == "air" then
						if (node.name == "sf_nodes:leaves") then
							minetest.set_node(opos, {name="sf_nodes:leaves_protrusion",param2=wallmounted})
						elseif (node.name == "sf_nodes:conifer_needles") then
							minetest.set_node(opos, {name="sf_nodes:conifer_needles_protrusion",param2=wallmounted})
						elseif (node.name == "sf_nodes:spikeplant") then
							minetest.set_node(opos, {name="sf_nodes:spikeplant_protrusion",param2=wallmounted})
						elseif (node.name == "sf_nodes:bush") then
							minetest.set_node(opos, {name="sf_nodes:bush_protrusion",param2=wallmounted})
						end
					end
				end
			end
		end)
		return itemstack
	end,
})



minetest.register_tool("sf_editor:mass_block_spawner", {
	description = S("Mass Block Spawner"),
	wield_image = "sf_editor_mass_block_spawner.png",
	inventory_image = "sf_editor_mass_block_spawner.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		radius = math.max(1, (radius + 1) % 11)
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not EDITOR then
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(), S("You can only use this in Editor Mode!"))
			end
			return itemstack
		end
		if not user and not user:is_player() then
			return itemstack
		end
		local inv = user:get_inventory()
		local idx = user:get_wield_index()
		local next_item = inv:get_stack(user:get_wield_list(), idx+1)
		local place_name = next_item:get_name()
		local def = minetest.registered_nodes[place_name]
		if not def then
			minetest.chat_send_player(user:get_player_name(), S("Put a node in the next inventory slot first!"))
			return itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		local leveled
		if def._sf_leveled_node_variant then
			leveled = def._sf_leveled_node_variant
		end

		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)
		do_stuff_in_radius(center, radius, "sphere", function(pos)
			local node = minetest.get_node(pos)
			if node.name == "air" then
				minetest.set_node(pos, {name=place_name})
			end
			local below = vector.offset(pos, 0, -1, 0)
			local bnode = minetest.get_node(below)
			if bnode.name == leveled then
				minetest.set_node(below, {name=place_name})
			end
		end)
		return itemstack
	end,
})

minetest.register_tool("sf_editor:reverber", {
	description = S("Reverber"),
	wield_image = "sf_editor_reverber.png",
	inventory_image = "sf_editor_reverber.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		if def._sf_reverb then
			node.name = def._sf_reverb
			minetest.swap_node(pos, node)
		elseif def._sf_unreverb then
			node.name = def._sf_unreverb
			minetest.swap_node(pos, node)
		end
		return itemstack
	end,
})

minetest.register_tool("sf_editor:state_changer", {
	description = S("State Changer"),
	wield_image = "sf_editor_state_changer.png",
	inventory_image = "sf_editor_state_changer.png",
	groups = { disable_repair = 1 },
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local node = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(node.name, "tree") == 1 then
			if node.param2 == 0 then
				node.param2 = 7
			elseif node.param2 == 7 then
				node.param2 = 12
			else
				node.param2 = 0
			end
			minetest.swap_node(pointed_thing.under, node)
			return itemstack
		end
		if minetest.get_item_group(node.name, "leveled_node") == 1 then
			node.param2 = (node.param2 + 4) % 64
			if node.param2 % 4 ~= 0 then
				node.param2 = node.param2 - (node.param2 % 4)
			end
			if node.param2 < 4 then
				node.param2 = 4
			end
			minetest.set_node(pointed_thing.under, node)
			local above = vector.offset(pointed_thing.under, 0, 1, 0)
			sf_nodes.update_plantlike_offset_node(above)
			return itemstack
		end
		local def = minetest.registered_nodes[node.name]
		if def and def.paramtype2 == "4dir" then
			node.param2 = (node.param2 + 1) % 4
			minetest.set_node(pointed_thing.under, node)
			local above = vector.offset(pointed_thing.under, 0, 1, 0)
			sf_nodes.update_plantlike_offset_node(above)
			return itemstack
		end
		return itemstack
	end,
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local node = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(node.name, "leveled_node") == 1 then
			node.param2 = (node.param2 - 4) % 64
			if node.param2 % 4 ~= 0 then
				node.param2 = node.param2 - (node.param2 % 4)
			end
			if node.param2 < 4 then
				node.param2 = 60
			end
			minetest.set_node(pointed_thing.under, node)
			local above = vector.offset(pointed_thing.under, 0, 1, 0)
			sf_nodes.update_plantlike_offset_node(above)
			return itemstack
		end
		local def = minetest.registered_nodes[node.name]
		if def and def.paramtype2 == "4dir" then
			node.param2 = (node.param2 - 1) % 4
			minetest.set_node(pointed_thing.under, node)
			local above = vector.offset(pointed_thing.under, 0, 1, 0)
			sf_nodes.update_plantlike_offset_node(above)
			return itemstack
		end
		return itemstack
	end,
})

minetest.register_tool("sf_editor:terrain_height_changer", {
	description = S("Terrain Height Changer"),
	wield_image = "sf_editor_terrain_height_changer.png",
	inventory_image = "sf_editor_terrain_height_changer.png",
	groups = { disable_repair = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local imeta = itemstack:get_meta()
		local ctrl = user:get_player_control()
		local radius = imeta:get_int("radius") or 1
		local super = imeta:get_int("super")
		if ctrl.aux1 then
			if super == 1 then
				imeta:set_string("inventory_image", "")
				imeta:set_string("wield_image", "")
				super = 0
				imeta:set_int("super", 0)
			else
				imeta:set_string("inventory_image", "sf_editor_terrain_height_changer.png^[hsl:60:0:0")
				imeta:set_string("wield_image", "sf_editor_terrain_height_changer.png^[hsl:60:0:0")
				super = 1
			end
			imeta:set_int("super", super)
		else
			radius = (radius + 1) % 11
		end
		local count_meta = tostring(radius)
		if super == 1 then
			count_meta = count_meta .. "+"
		end
		imeta:set_int("radius", radius)
		imeta:set_string("count_meta", count_meta)
		imeta:set_string("count_alignment", 1)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local node = minetest.get_node(pointed_thing.under)
		local def = minetest.registered_nodes[node.name]
		if not def then
			return itemstack
		end

		local center = pointed_thing.under
		local imeta = itemstack:get_meta()
		local radius = imeta:get_int("radius") or 1
		imeta:set_string("count_meta", radius)
		imeta:set_string("count_alignment", 1)

		local go_up = true
		local ctrl = user:get_player_control()
		if ctrl.sneak then
			go_up = false
		end

		local stepsize
		if imeta:get_int("super") == 1 then
			stepsize = 16
		else
			stepsize = 1
		end

		do_stuff_in_radius(center, radius, "sphere", function(pos)
			local above = table.copy(pos)
			above.y = above.y + 1
			local node_above = minetest.get_node(above)
			if node_above.name ~= "air" and minetest.get_item_group(node_above.name, "plantlike_offset") == 0 then
				return
			end
			local plant_node
			if minetest.get_item_group(node_above.name, "plantlike_offset") ~= 0 then
				plant_node = node_above
			end

			local node = minetest.get_node(pos)
			local def = minetest.registered_nodes[node.name]
			if not def then
				return
			end

			if minetest.get_item_group(node.name, "leveled_node") == 1 then
				if go_up then
					node.param2 = node.param2 + 4 * stepsize
				else
					node.param2 = node.param2 - 4 * stepsize
				end
				if node.param2 >= 64 then
					node.param2 = 0
					local def = minetest.registered_nodes[node.name]
					if not def._sf_unleveled_node_variant then
						return
					end
					node.name = def._sf_unleveled_node_variant
					minetest.set_node(pos, node)
				elseif node.param2 <= 0 then
					local below = table.copy(pos)
					below.y = below.y - 1
					local node_below = minetest.get_node(below)
					local def_below = minetest.registered_nodes[node_below.name]
					if def_below and def_below._sf_leveled_node_variant then
						node.name = def_below._sf_leveled_node_variant
						node.param2 = 60
						minetest.set_node(below, node)
					end
					minetest.remove_node(pos)
				else
					minetest.set_node(pos, node)
				end
			elseif def._sf_leveled_node_variant then
				if go_up then
					minetest.set_node(above, {name=def._sf_leveled_node_variant, param2=4})
					if plant_node then
						local above2 = table.copy(above)
						above2.y = above2.y + 1
						local above2_node = minetest.get_node(above2)
						if above2_node.name == "air" then
							minetest.set_node(above2, plant_node)
						end
					end
				else
					minetest.set_node(pos, {name=def._sf_leveled_node_variant, param2=60})
				end
			end
			sf_nodes.update_plantlike_offset_node(above)
		end)
		return itemstack
	end,
})

function sf_editor.fill_covered_leveled_nodes(pos1, pos2)
	local cpos1 = table.copy(pos1)
	local cpos2 = table.copy(pos2)
	local spos1, spos2 = sf_util.sort_positions(cpos1, cpos2)

	local leveled_nodes = minetest.find_nodes_in_area(spos1, spos2, "group:leveled_node")

	for l=1, #leveled_nodes do
		local npos = leveled_nodes[l]
		local apos = vector.offset(npos, 0, 1, 0)
		local nnode = minetest.get_node(npos)
		local anode = minetest.get_node(apos)
		local ndef = minetest.registered_nodes[nnode.name]
		local adef = minetest.registered_nodes[anode.name]
		if adef.walkable and ndef and ndef._sf_unleveled_node_variant then
			minetest.set_node(npos, {name=ndef._sf_unleveled_node_variant})
		end
	end
end



-- Make a slope between pos1 and pos2, moving upwards the X axis.
-- Supports leveled nodes.
-- NOTE: The area MUST have already been emerged.
-- TODO: Generalize this function for corner slopes.
function sf_editor.make_slope(pos1, pos2, nodename)
	local cpos1 = table.copy(pos1)
	local cpos2 = table.copy(pos2)
	local spos1, spos2 = sf_util.sort_positions(cpos1, cpos2)

	local leveled_node
	local def = minetest.registered_nodes[nodename]
	if def and def._sf_leveled_node_variant then
		leveled_node = def._sf_leveled_node_variant
	end

	for z=spos1.z, spos2.z do
		local xfrac = (spos2.z-z) / (spos2.z - spos1.z)
		local xstart = spos1.x + (1-xfrac) * (spos2.x - spos1.x)

		for x=spos1.x, spos2.x do
			local yfrac = (spos2.x-x) / (spos2.x - spos1.x)
			local y = spos1.y + (1-yfrac) * (spos2.y - spos1.y)
			sf_util.set_xz_nodes({x=x,y=y,z=z}, spos1.y, nodename, leveled_node)
		end
	end
end

-- Export nodes between pos1 and pos2 into mapblock-sized schematics to the world dir
function sf_editor.export_world(pos1, pos2)
	local block_start = sf_util.nodepos_to_blockpos(pos1)
	local real_pos1 = sf_util.get_blockpos_bounds(block_start)
	local block_end = sf_util.nodepos_to_blockpos(pos2)
	local _, real_pos2 = sf_util.get_blockpos_bounds(block_end)

	minetest.chat_send_all(S("Exporting world between @1 and @2 ...", minetest.pos_to_string(real_pos1), minetest.pos_to_string(real_pos2)))
	minetest.log("action", "[sf_editor] Exporting the world into schematics ...")

	local dir = minetest.get_worldpath().."/schems/worldexport"
	minetest.mkdir(dir)
	local total_schematics = 0
	for bx=block_start.x, block_end.x do
	for by=block_start.y, block_end.y do
	for bz=block_start.z, block_end.z do
		local fbx = bx - block_start.x
		local fby = by - block_start.y
		local fbz = bz - block_start.z
		-- file name format: <x>_<y>_<z>.mts
		-- where <x>, <y> and <z> are mapblock coordinates starting at (0,0,0)
		local filename = tostring(fbx) .. "_"..tostring(fby).."_"..tostring(fbz)..".mts"
		local fullpath = dir .. "/" .. filename
		local blockpos = vector.new(bx, by, bz)
		local spos1, spos2 = sf_util.get_blockpos_bounds(blockpos)
		minetest.create_schematic(spos1, spos2, {}, fullpath, {})
		total_schematics = total_schematics + 1
		if total_schematics % 250 == 0 then
			minetest.chat_send_all(S("World export in progress ... (@1 schematic(s) exported)", total_schematics))
		end
	end
	end
	end
	minetest.chat_send_all(S("World export complete. @1 schematic(s) exported to @2.", total_schematics, dir))
	minetest.log("action", "[sf_editor] " .. total_schematics.." schematic(s) exported to "..dir)
end

minetest.register_on_joinplayer(function(player)
	if EDITOR then
		minetest.chat_send_player(player:get_player_name(), S("Editor Mode is active."))
	end
	playerstates[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
	playerstates[player:get_player_name()] = nil
end)

-- Infinite node placement in editor mode
minetest.register_on_placenode(function()
	if EDITOR then
		return true
	end
end)
