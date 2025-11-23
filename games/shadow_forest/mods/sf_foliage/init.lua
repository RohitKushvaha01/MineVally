local S = minetest.get_translator("sf_foliage")
local SCHEM_PATH = minetest.get_modpath("sf_foliage").."/schems"

sf_foliage = {}
sf_foliage.trees = {
--[[
	-- Fir
	{ name = "fir_baby", level = 1, leaftype = "conifer" },
	{ name = "fir_youngling", level = 2, leaftype = "conifer" },
	{ name = "fir_growing", level = 3, leaftype = "conifer" },
	{ name = "fir_growing_2", level = 3, leaftype = "conifer" },
	{ name = "fir_adult_1", level = 4, leaftype = "conifer" },
	{ name = "fir_adult_2", level = 4, leaftype = "conifer" },
	{ name = "fir_elder", level = 5, leaftype = "conifer" },
]]

	-- Startree
	{ name = "startree_young", level = 4 },
	{ name = "startree_2_story_1", level = 5 },
	{ name = "startree_2_story_2", level = 5 },

	-- Asymmetrical tree
	{ name = "tree_asymmetrical_1", level = 3 },
	{ name = "tree_asymmetrical_2", level = 3 },
	{ name = "tree_asymmetrical_3", level = 3 },

	-- Bushlike tree
	{ name = "tree_bushlike_big", level = 3 },
	{ name = "tree_bushlike_small", level = 2 },

	-- Minitree
	{ name = "minitree1", level = 2 },
	{ name = "minitree2", level = 2 },
	{ name = "minitree3", level = 2 },

	-- Young tree
	{ name = "tree_baby_1", level = 1 },
	{ name = "tree_youngling", level = 2},

	--- Broad-leafed
	{ name = "broad_leafed_tree_1", level = 3 },

	-- Ball
	{ name = "tree_ball_medium", level = 3 },
	{ name = "tree_ball_small", level = 2 },

	-- Poplar
	{ name = "poplar", level = 3 },
}

sf_foliage.bushes = {
	{ name = "bush_baby", level = 1 },
	{ name = "bush_medium_1", level = 2 },
	{ name = "bush_big", level = 3 },
}

for t=1, #sf_foliage.trees do
	local hue = (t-1)*(360/#sf_foliage.trees)
	local tree = sf_foliage.trees[t]
	local id = tree.name
	local tiles
	if tree.level >= 5 then
		trunksize = 2
	else
		trunksize = 1
	end
	minetest.register_node("sf_foliage:tree_spawner_"..id, {
		description = S("Tree Spawner: @1", id),
		tiles = {
			"sf_foliage_tree_spawner_"..trunksize.."_top.png^[hsl:"..hue..":0:0",
			"sf_foliage_tree_spawner_"..trunksize.."_top.png^[hsl:"..hue..":0:0",
			"sf_foliage_tree_spawner_"..trunksize..".png^[hsl:"..hue..":0:0",
		},
		groups = { editor_breakable = 1, tree_spawner = 1 },
		sounds = sf_sounds.node_sound_tree_defaults(),
	})
end
for b=1, #sf_foliage.bushes do
	local hue = (b-1)*(360/#sf_foliage.bushes)
	local bush = sf_foliage.bushes[b]
	local id = bush.name
	minetest.register_node("sf_foliage:bush_spawner_"..id, {
		description = S("Bush Spawner: @1", id),
		tiles = {
			"sf_foliage_bush_spawner_top.png^[hsl:"..hue..":0:0",
			"sf_foliage_bush_spawner_top.png^[hsl:"..hue..":0:0",
			"sf_foliage_bush_spawner.png^[hsl:"..hue..":0:0",
		},
		groups = { editor_breakable = 1, bush_spawner = 1 },
		sounds = sf_sounds.node_sound_leaves_defaults(),
	})
end

local function get_schematic_name_from_node(nodename)
	if string.sub(nodename, 1, 24) == "sf_foliage:bush_spawner_" then
		return SCHEM_PATH.."/sf_foliage_"..string.sub(nodename, 25)..".mts"
	elseif string.sub(nodename, 1, 24) == "sf_foliage:tree_spawner_" then
		return SCHEM_PATH.."/sf_foliage_"..string.sub(nodename, 25)..".mts"
	else
		return nil
	end
end

-- Get a pseudorandom orientation for a given pos.
local function get_orientation(pos)
	local hash = minetest.hash_node_position(pos)
	local rnd = PcgRandom(hash)
	local r = rnd:next(0,3)
	return tostring(r * 90)
end

local function extend_trunk_after_place(pos)
	local below = vector.offset(pos, 0, -1, 0)
	local trunk = minetest.get_node(pos)
	local floor = minetest.get_node(below)
	if minetest.get_item_group(floor.name, "leveled_node") == 0 then
		return
	end
	if minetest.get_item_group(trunk.name, "tree_small") >= 1 and minetest.get_item_group(trunk.name, "tree_small_extension") == 0 then
		trunk.name = trunk.name .. "x"
		minetest.set_node(pos, trunk)
	elseif minetest.get_item_group(trunk.name, "tree") >= 1 then
		minetest.set_node(below, trunk)
		local offsets = {
			vector.new(1,1,0),
			vector.new(1,1,1),
			vector.new(0,1,1),
		}
		for o=1, #offsets do
			local offpos = vector.add(below, offsets[o])
			local offnode = minetest.get_node(offpos)
			if minetest.get_item_group(offnode.name, "tree") >= 1 then
				offpos.y = offpos.y - 1
				minetest.set_node(offpos, offnode)
			end
		end
	end
end

sf_foliage.grow_spawner = function(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "tree_spawner") == 0 and minetest.get_item_group(node.name, "bush_spawner") == 0 then
		return false
	end
	local schematic_name = get_schematic_name_from_node(node.name)
	if not schematic_name then
		return false
	end
	local orientation = get_orientation(pos)
	minetest.remove_node(pos)
	minetest.place_schematic(pos, schematic_name, orientation, {}, true, {place_center_x=true, place_center_z=true})
	extend_trunk_after_place(pos)
	return true
end

local function select_random_tree(pos)
	local node = minetest.get_node(pos)
	local r = math.random(1, #sf_foliage.trees)
	local tree = sf_foliage.trees[r]
	return tree
end

sf_foliage.place_random_tree = function(pos)
	local tree = select_random_tree(pos)
	local schematic_name = SCHEM_PATH.."/sf_foliage_"..tree.name..".mts"
	local orientation = get_orientation(pos)
	minetest.place_schematic(pos, schematic_name, orientation, {}, true, {place_center_x=true, place_center_z=true})
	extend_trunk_after_place(pos)
end

sf_foliage.place_random_tree_spawner = function(pos)
	local tree = select_random_tree(pos)
	local spawner = "sf_foliage:tree_spawner_"..tree.name
	minetest.set_node(pos, {name=spawner})
end

