local S = minetest.get_translator("sf_world")

sf_world = {}

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)
local VASE_DEBUG = false

local WORLD_SCHEMATIC_PATH = minetest.get_modpath("sf_world").."/schems/worldmapblocks"
local UNDERGROUND_NODE = "sf_nodes:stone"

local MAPBLOCKSIZE = 16 -- side length of a mapblock

-- The mapgen_limit setting will be forced to this value.
-- The generated world MUST fully fit into this,
-- plus a bit of a buffer for the surrounding darkness.
local FORCED_MAPGEN_LIMIT = 2000

-- cached list of all world schematics
local full_world_schematic_list = nil

local registered_on_teleports = {}

sf_world.world = {
	pos = vector.zero(), -- bottom left front corner of world. This MUST be the lower corner of a mapblock position
	spawn_pos_offset = vector.new(298, 43, 461), -- the player will spawn here (relative to world pos)
	spawn_yaw = math.pi*1.5,
	respawn_pos_offset = vector.new(324.5, 53, 393.5), -- the player will respawn here (relative to world pos)
	respawn_yaw = math.pi*1.4,
	campfire_offsets = nil, -- list of campfire positions (relative to world pos)
	-- For generating the terrain outside the stored map (with Perlin noise)
	out_of_map_terrain = {
		min_y = 48, -- minimum Y of terrain
		max_y = 54, -- maximum Y of terrain
		add_to_top = -0.5, -- extra nodes (fractional) to add on top
		-- arguments 3 and onward for sf_world.generate_2d_terrain
		remaining_args = {
			{spread={x=50,y=50,z=50}, octaves=3, scale=1, offset=0},
			{x=176, y=-304}, -- Offset of the Perlin noise coordinates
			-1.5,
			1.5,
			"sf_nodes:dirt"
		},
	},
}

sf_world.teleport_destinations = {
	-- Dead Forest
	[1] = { pos = { x=160, y=52, z=204 }, yaw = math.pi },
	-- Fog Chasm
	[2] = { pos = { x=231, y=51, z=172 }, yaw = math.pi },
	-- Snow Mountain
	[3] = { pos = { x=362, y=51, z=160 }, yaw = math.pi },
	-- Village
	[4] = { pos = { x=62, y=51, z=422 }, yaw = math.pi/2 },
	-- Tree of Life (bottom)
	[5] = { pos = { x=324.5, y=53, z=393.5 }, yaw = math.pi*1.4 },
	-- Forest
	[6] = { pos = { x=14, y=54, z=218 }, yaw = math.pi*1.5 },
}

sf_world.teleport_to_destination = function(player, destination_id)
	local destination = sf_world.teleport_destinations[destination_id]
	if destination then
		local oldpos = player:get_pos()
		player:set_pos(destination.pos)
		minetest.sound_play({name="sf_world_teleport", gain=0.1}, {to_player=player:get_player_name()}, true)
		player:set_look_horizontal(destination.yaw)
		sf_zones.report_location_change(player)
		minetest.log("action", "[sf_world] Teleported player to destination ID "..destination_id.." at "..minetest.pos_to_string(destination.pos, 0))
		for f=1, #registered_on_teleports do
			registered_on_teleports[f](player, oldpos, destination.pos)
		end

		if destination_id ~= 1 and destination_id ~= 5 then
			minetest.after(2, function()
				if player and player:is_player() then
					sf_dialog.show_dialog(player, "intro3", true)
				end
			end)
		end
		return true
	else
		return false
	end
end

local vmanip_data_buffer = {}
local vmanip_param2data_buffer = {}
local vmanip_lightdata_buffer = {}

minetest.register_on_generated(function(minp, maxp, blockseed)
	if EDITOR then
		return
	end
	local vmanip, emin, emax = minetest.get_mapgen_object("voxelmanip")
	if not vmanip then
		minetest.log("error", "[sf_world] Cannot get the voxelmanip mapgen object!")
		return
	end

	local minp_block = sf_util.nodepos_to_blockpos(minp)
	local maxp_block = sf_util.nodepos_to_blockpos(maxp)
	local full_schematic_list = sf_world.get_world_schematic_list(sf_world.world.pos)
	local local_schematic_list = sf_world.select_world_schematics_to_place(minp_block, maxp_block, full_schematic_list)
	local covered_area
	-- Place world schematic
	if #local_schematic_list > 0 then
		minetest.log("action", "[sf_world] Placing world schematics between "..minetest.pos_to_string(minp).." and "..minetest.pos_to_string(maxp).." ...")
		covered_area = sf_world.place_world_schematics(vmanip, local_schematic_list)
		-- Get a new voxelmanip object because above function invalidates the vmanip object
		vmanip, emin, emax = minetest.get_mapgen_object("voxelmanip")
		if not vmanip then
			minetest.log("error", "[sf_world] Cannot get the voxelmanip mapgen object after placing the world schematic!")
			return
		end
	end
	local vmanip_area = VoxelArea(emin, emax)
	local vmanip_data = vmanip:get_data(vmanip_data_buffer)
	local vmanip_param2data = vmanip:get_param2_data(vmanip_param2data_buffer)
	local vmanip_lightdata = vmanip:get_light_data(vmanip_lightdata_buffer)

	local terrain_min_y = sf_world.world.pos.y + sf_world.world.out_of_map_terrain.min_y
	local terrain_max_y = sf_world.world.pos.y + sf_world.world.out_of_map_terrain.max_y

	-- Generate darkness nodes above the max terrain Y;
	-- The area outside the main map should be covered in darkness nodes.
	local function generate_darkness(_minp, _maxp)
		if _maxp.y > terrain_max_y then
			local dmin = table.copy(_minp)
			local dmax = table.copy(_maxp)
			dmin.y = math.max(_minp.y, terrain_max_y + 1)
			sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, dmin, dmax, "sf_nodes:darkness")
			sf_world.set_area_light(vmanip_area, vmanip_lightdata, _minp, _maxp, 0)
		end
	end

	-- Generate 'filler' terrain at the area the world schematics do not cover
	if not covered_area then
		-- No world schematic in this mapchunk; generate terrain for the entire mapchunk
		local mintp = table.copy(minp)
		local maxtp = table.copy(maxp)
		mintp.y = terrain_min_y
		maxtp.y = terrain_max_y
		if mintp.y >= minp.y and mintp.y < maxp.y and maxtp.y <= maxp.y and maxtp.y > minp.y then
			sf_world.generate_2d_terrain(vmanip_area, vmanip_data, vmanip_param2data, vmanip_lightdata, mintp, maxtp, unpack(sf_world.world.out_of_map_terrain.remaining_args))
			-- FIXME: This darkness does not generate all the way up so this might be an issue if the terrain height
			-- ends close to the mapchunk border. However, this is "good enough" for now.
			generate_darkness(minp, maxp)
		end

		-- Generate the underground (all the same node)
		if minp.y < terrain_min_y then
			local umin = minp
			local umax = table.copy(maxp)
			umax.y = math.min(maxp.y, terrain_min_y - 1)
			sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, umin, umax, UNDERGROUND_NODE)
		end
	else
		--[[ This mapchunk was only partially filled with world schematics.
		     So we fill the remaining area in with filler terrain in 4 new sections:

		        LLMMRR
		        LLMMRR
		        LLOORR
		        LLOORR
		        LLmmRR
	                LLmmRR

                     ^
                     |
                     z
                      x -->

		    O = world schematic area (already generated)
		    L = left
		    m = middle, front
		    M = middle, back
		    R = right

		    All 4 sections may have a size of 0, in which case nothing is generated here.
		]]
		local remainders = {
			-- left
			{
				min = {x=minp.x, y=terrain_min_y, z=minp.z},
				max = {x=covered_area.min.x-1, y=terrain_max_y, z=maxp.z},
			},
			-- middle, front
			{
				min = {x=covered_area.min.x, y=terrain_min_y, z=minp.z},
				max = {x=covered_area.max.x, y=terrain_max_y, z=covered_area.min.z-1},
			},
			-- middle, back
			{
				min = {x=covered_area.min.x, y=terrain_min_y, z=covered_area.max.z},
				max = {x=covered_area.max.x, y=terrain_max_y, z=maxp.z},
			},
			-- right
			{
				min = {x=covered_area.max.x, y=terrain_min_y, z=minp.z},
				max = {x=maxp.x, y=terrain_max_y, z=maxp.z},
			},
		}
		for r=1, #remainders do
			local rem = remainders[r]
			if rem.min.x < rem.max.x and rem.min.y < rem.max.y and rem.min.z < rem.max.z then
				minetest.log("info", "[sf_world] Generated remainder terrain between "..minetest.pos_to_string(rem.min).." and "..minetest.pos_to_string(rem.max))
				sf_world.generate_2d_terrain(vmanip_area, vmanip_data, vmanip_param2data, vmanip_lightdata, rem.min, rem.max, unpack(sf_world.world.out_of_map_terrain.remaining_args))
				local dmax = table.copy(rem.max)
				dmax.y = maxp.y
				generate_darkness(rem.min, dmax)

				-- Generate the underground (all the same node)
				if minp.y < terrain_min_y then
					local umin = table.copy(rem.min)
					umin.y = minp.y
					local umax = table.copy(rem.max)
					umax.y = math.min(maxp.y, terrain_min_y - 1)
					sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, umin, umax, UNDERGROUND_NODE)
				end
			end
		end
		-- Generate the underground for the covered area
		if minp.y < sf_world.world.pos.y then
			local umin = table.copy(covered_area.min)
			umin.y = minp.y
			local umax = table.copy(covered_area.max)
			umax.y = math.min(maxp.y, sf_world.world.pos.y - 1)
			sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, umin, umax, UNDERGROUND_NODE)
		end
	end

	vmanip:set_data(vmanip_data)
	vmanip:set_param2_data(vmanip_param2data)
	vmanip:set_light_data(vmanip_lightdata)
	vmanip:calc_lighting()
	vmanip:write_to_map()



	sf_world.place_trees(minp, maxp)

	local campfires = minetest.find_nodes_in_area(minp, maxp, "group:campfire")
	for c=1, #campfires do
		local cpos = campfires[c]
		local cnode = minetest.get_node(cpos)
		local cdef = minetest.registered_nodes[cnode.name]
		if cdef.on_construct then
			cdef.on_construct(cpos)
		end
	end

	-- Clean up light orb lights that accidentally ended up in world schematics
	local lights = minetest.find_nodes_in_area(minp, maxp, "group:light_orb_light")
	for l=1, #lights do
		minetest.remove_node(lights[l])
	end
end)

-- Set all nodes within pos1, pos2 to air (needs LuaVoxelManip)
function sf_world.clear_area(vmanip_area, vmanip_data, vmanip_param2data, pos1, pos2)
	sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, pos1, pos2, "air")
end

-- Set all nodes within pos1, pos2 to a node (needs LuaVoxelManip)
function sf_world.set_area(vmanip_area, vmanip_data, vmanip_param2data, pos1, pos2, nodename)
	local cpos1 = table.copy(pos1)
	local cpos2 = table.copy(pos2)
	local spos1, spos2 = sf_util.sort_positions(cpos1, cpos2)
	local cid = minetest.get_content_id(nodename)
	for z=spos1.z, spos2.z do
	for y=spos1.y, spos2.y do
	for x=spos1.x, spos2.x do
		local idx = vmanip_area:index(x,y,z)
		vmanip_data[idx] = cid
		vmanip_param2data[idx] = 0
	end
	end
	end
end

-- Set all nodes within pos1, pos2 to the given light value (needs LuaVoxelManip)
function sf_world.set_area_light(vmanip_area, vmanip_lightdata, pos1, pos2, light)
	local cpos1 = table.copy(pos1)
	local cpos2 = table.copy(pos2)
	local spos1, spos2 = sf_util.sort_positions(cpos1, cpos2)
	for z=spos1.z, spos2.z do
	for y=spos1.y, spos2.y do
	for x=spos1.x, spos2.x do
		local idx = vmanip_area:index(x,y,z)
		vmanip_lightdata[idx] = light
	end
	end
	end
end

-- Generates terrain based on a 2D perlin noise between pos1 and pos2.
-- If the node has a leveled node variant, leveled nodes may be placed.
-- NOTE: Before calling this function, the area MUST have been emerged first.
function sf_world.generate_2d_terrain(vmanip_area, vmanip_data, vmanip_param2data, vmanip_lightdata, pos1, pos2, noiseparams, noise_offset, min_noiseval, max_noiseval, nodename)
	local cpos1 = table.copy(pos1)
	local cpos2 = table.copy(pos2)
	local spos1, spos2 = sf_util.sort_positions(cpos1, cpos2)
	local cidd = minetest.get_content_id("sf_nodes:darkness")
	local def = minetest.registered_nodes[nodename]
	local leveled_node
	if def and def._sf_leveled_node_variant then
		leveled_node = def._sf_leveled_node_variant
	end

	local ndiff = max_noiseval - min_noiseval
	local ydiff = pos2.y - pos1.y

	local noise = PerlinNoise(noiseparams)
	for z=spos1.z, spos2.z do
	for x=spos1.x, spos2.x do
		-- Note: the Y axis in the Perlin noise corresponds to the Z axis of the world!
		local nval = noise:get_2d({ x = x + noise_offset.x, y = z + noise_offset.y })
		nval = math.max(min_noiseval, math.min(max_noiseval, nval))
		local nfrac = (nval - min_noiseval) / ndiff
		nfrac = math.max(0.0, math.min(1.0, nfrac))
		local y = pos1.y + nfrac * ydiff

		if vmanip_data then
			-- Add darkness nodes for the entire Y column; the out-of-map terrain needs
			-- to be covered in darkness.
			for dy=spos1.y, spos2.y do
				local idx = vmanip_area:index(x,dy,z)
				vmanip_data[idx] = cidd
				vmanip_param2data[idx] = 0
				vmanip_lightdata[idx] = 0
			end
		end

		y = y + sf_world.world.out_of_map_terrain.add_to_top
		sf_util.set_xz_nodes({x=x,y=y,z=z}, spos1.y, nodename, leveled_node, vmanip_area, vmanip_data, vmanip_param2data)
	end
	end
end

function sf_world.place_world_schematics(vmanip, world_schematic_list)
	local covered_area
	for s=1, #world_schematic_list do
		local entry = world_schematic_list[s]

		local area_min = table.copy(entry.pos)
		local area_max = vector.offset(area_min,MAPBLOCKSIZE,MAPBLOCKSIZE,MAPBLOCKSIZE)
		if not covered_area then
			covered_area = {}
			covered_area.min = area_min
			covered_area.max = area_max
		else
			local axes = { "x", "y", "z" }
			for a=1, #axes do
				local axis = axes[a]
				if area_min[axis] < covered_area.min[axis] then
					covered_area.min[axis] = area_min[axis]
				end
				if area_max[axis] > covered_area.max[axis] then
					covered_area.max[axis] = area_max[axis]
				end
			end
		end

		local path = WORLD_SCHEMATIC_PATH .."/"..entry.schematic
		local result = minetest.place_schematic_on_vmanip(vmanip, entry.pos, path, "0", {}, false, {})
		if result == true then
			minetest.log("info", "[sf_world] Placed world schematic '"..path.."' at "..minetest.pos_to_string(entry.pos))
		elseif result == false then
			minetest.log("error", "[sf_world] World schematic '"..path.."' was only partially placed at "..minetest.pos_to_string(entry.pos))
		elseif result == nil then
			minetest.log("error", "[sf_world] World schematic '"..path.."' could not be placed at "..minetest.pos_to_string(entry.pos))
		end
	end
	return covered_area
end

function sf_world.select_world_schematics_to_place(min_blockpos, max_blockpos, world_schematic_list)
	local new_world_schematic_list = {}
	for s=1, #world_schematic_list do
		local entry = world_schematic_list[s]
		if vector.in_area(entry.blockpos, min_blockpos, max_blockpos) then
			table.insert(new_world_schematic_list, entry)
		end
	end
	return new_world_schematic_list
end

function sf_world.get_world_schematic_filenames()
	-- Parse file names
	local dir_tree = minetest.get_dir_list(WORLD_SCHEMATIC_PATH, false)
	local filenames = {}
	for f=1, #dir_tree do
		local filename = dir_tree[f]
		local x, y, z = string.match(filename, "(%d+)_(%d+)_(%d+).mts$")
		if x and y and z then
			table.insert(filenames, filename)
		end
	end
	table.sort(filenames)
	return filenames
end

--[[
world schematic list format:
{
	-- world schematic 1
	{
		pos = <node position of bottom left front corner>,
		blockpos = <mapblock position of bottom left front corner>,
		schematic = <schematic file name without path>,
	},
	-- schematic 2
	{
		pos = ...
		blockpos = ...
		schematic = ...
	},
	...
}
]]

function sf_world.get_world_schematic_list(blockpos_offset)
	if full_world_schematic_list then
		-- Return cached list if available
		return full_world_schematic_list
	end
	local schematic_filenames = sf_world.get_world_schematic_filenames()
	local list = {}
	for s=1, #schematic_filenames do
		local filename = schematic_filenames[s]
		local x, y, z = string.match(filename, "(%d+)_(%d+)_(%d+).mts$")
		x = tonumber(x)
		y = tonumber(y)
		z = tonumber(z)
		if not x or not y or not z then
			minetest.log("error", "[sf_world] World schematic has invalid filename: "..filename.." (should be of form '<x>_<y>_<z>.mts')")
			return
		end
		local blockpos = vector.new(x,y,z)
		blockpos = vector.add(blockpos_offset, blockpos)
		local real_coords = sf_util.get_blockpos_bounds(blockpos)
		table.insert(list, { pos = real_coords, blockpos = blockpos, schematic = filename })
	end
	if #list == 0 then
		minetest.log("error", "[sf_world] Could not find any world schematics in "..WORLD_SCHEMATIC_PATH.."!")
	end

	full_world_schematic_list = list
	return list
end

function sf_world.analyze_world()
	local schems = sf_world.get_world_schematic_list(sf_world.world.pos)
	local campfires = {}
	local vases = {
		total_vase_count = 0,
		zone_vase_counts = {},
		total_res_count = 0,
		zone_res_counts = {},
	}
	for s=1, #schems do
		local schemdata = schems[s]
		local schem_offset = schemdata.pos
		local path = WORLD_SCHEMATIC_PATH .."/".. schemdata.schematic
		local schem = minetest.read_schematic(path, {write_yslice_prob="none"})
		if not schem then
			minetest.log("error", "[sf_world] Could not read schematic for world analysis!")
			return false
		end
		local idx = 1
		for z=1, schem.size.z do
		for y=1, schem.size.y do
		for x=1, schem.size.x do
			local nodename = schem.data[idx].name
			local p2 = schem.data[idx].param2
			local cpos = vector.add(vector.new(x,y,z), schem_offset)
			if nodename == "sf_nodes:campfire" or nodename == "sf_nodes:campfire_on" then
				if campfires[p2] then
					minetest.log("error", "[sf_world] param2 reused by campfire at "..minetest.pos_to_string(cpos).."!")
				end
				campfires[p2] = cpos
			elseif nodename == "sf_loot:vase" then
				vases.total_vase_count = vases.total_vase_count + 1
				vases.total_res_count = vases.total_res_count + p2
				local zones = sf_zones.in_which_zones(cpos)
				for z=1, #zones do
					local zone = zones[z]
					if vases.zone_vase_counts[zone] == nil then
						vases.zone_vase_counts[zone] = 0
					end
					if vases.zone_res_counts[zone] == nil then
						vases.zone_res_counts[zone] = 0
					end
					vases.zone_vase_counts[zone] = vases.zone_vase_counts[zone] + 1
					vases.zone_res_counts[zone] = vases.zone_res_counts[zone] + p2
				end
			end
			idx = idx + 1
		end
		end
		end
	end
	return { campfires = campfires, vases = vases }
end

sf_world.place_trees = function(minp, maxp)
	minetest.log("action", "[sf_world] Placing trees between "..minetest.pos_to_string(minp).." and "..minetest.pos_to_string(maxp).." ...")
	local spawners = minetest.find_nodes_in_area(minp, maxp, {"group:tree_spawner", "group:bush_spawner"})
	local placed = 0
	for s=1, #spawners do
		local ok = sf_foliage.grow_spawner(spawners[s])
		if ok then
			placed = placed + 1
		end
	end
	if placed > 0 then
		minetest.log("action", "[sf_world] Placed "..placed.." foliage (trees and bushes).")
	end
end

sf_world.distribute_tree_spawners_on_dirt = function(minp, maxp, chance)
	local dirts = minetest.find_nodes_in_area_under_air(minp, maxp, {"sf_nodes:dirt"})
	for i=1, #dirts do
		if math.random(1, chance) == 1 then
			local pos = dirts[i]
			pos.y = pos.y + 1
			sf_foliage.place_random_tree_spawner(pos)
		end
	end

	local dirt_levels = minetest.find_nodes_in_area_under_air(minp, maxp, {"sf_nodes:dirt_level"})
	for i=1, #dirt_levels do
		if math.random(1, chance) == 1 then
			local pos = dirt_levels[i]
			local above = table.copy(pos)
			above.y = above.y + 1
			sf_foliage.place_random_tree_spawner(above)
		end
	end
end

-- Teleport player to the world's spawn pos
sf_world.go_to_spawn_pos = function(player)
	local spawn_pos = vector.add(sf_world.world.pos, sf_world.world.spawn_pos_offset)
	local oldpos = player:get_pos()
	player:set_pos(spawn_pos)
	player:set_look_horizontal(sf_world.world.spawn_yaw)
	minetest.log("action", "[sf_world] Teleported player to spawn pos at "..minetest.pos_to_string(spawn_pos, 0))
	for f=1, #registered_on_teleports do
		registered_on_teleports[f](player, oldpos, spawn_pos)
	end
end

-- Teleport player to the world's respawn pos
sf_world.go_to_respawn_pos = function(player)
	local oldpos = player:get_pos()
	local respawn_pos = vector.add(sf_world.world.pos, sf_world.world.respawn_pos_offset)
	player:set_pos(respawn_pos)
	player:set_look_horizontal(sf_world.world.respawn_yaw)
	minetest.log("action", "[sf_world] Teleported player to respawn pos at "..minetest.pos_to_string(respawn_pos, 0))
	for f=1, #registered_on_teleports do
		registered_on_teleports[f](player, oldpos, respawn_pos)
	end
end

-- func will be called after the player has teleported with one
-- of the sf_world.* functions.
-- Syntax:
--   func(player, oldpos, newpos)
--   * player: player object
--   * oldpos: position before the teleport
--   * newpos: position after the teleport
sf_world.register_on_teleport = function(func)
	table.insert(registered_on_teleports, func)
end

minetest.register_on_mods_loaded(function()
	if EDITOR then
		return
	end
	local analysis = sf_world.analyze_world()
	sf_world.world.campfire_offsets = analysis.campfires
	if VASE_DEBUG then
		local vases = analysis.vases
		minetest.debug("Vase info:")
		minetest.debug("Total vases: "..vases.total_vase_count)
		minetest.debug("Total resources in vases: "..vases.total_res_count)
		for zonename, count in pairs(vases.zone_vase_counts) do
			minetest.debug("Vases in zone '"..zonename.."': "..count)
		end
		for zonename, count in pairs(vases.zone_res_counts) do
			minetest.debug("Resources in vases in zone '"..zonename.."': "..count)
		end
	end
end)

minetest.register_chatcommand("goto", {
	privs = { teleport = true },
	params = S("<destination> | spawn | respawn"),
	description = S("Teleport to a destination"),
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player == nil or not player:is_player() then
			return false, S("Player does not exist.")
		end
		if param == "" then
			return false
		elseif param == "spawn" then
			sf_world.go_to_spawn_pos(player)
			return true
		elseif param == "respawn" then
			sf_world.go_to_respawn_pos(player)
			return true
		end
		local destination = tonumber(param)
		if not destination or not sf_world.teleport_destinations[destination] then
			local destlist = {}
			for k,v in pairs(sf_world.teleport_destinations) do
				table.insert(destlist, k)
			end
			table.sort(destlist)
			table.insert(destlist, "spawn")
			table.insert(destlist, "respawn")
			-- separate list with commas
			local destlist_txt = table.concat(destlist, S(", "))
			return false, S("Invalid destination! Valid destinations are: @1.", destlist_txt)
		else
			sf_world.teleport_to_destination(player, destination)
			return true
		end
	end,
})

-- Force mapgen_limit so the world has enough space to generate.
-- If mapgen_limit is too low, the world generator cannot fully
-- place the world.
minetest.set_mapgen_setting("mapgen_limit", FORCED_MAPGEN_LIMIT, true)
