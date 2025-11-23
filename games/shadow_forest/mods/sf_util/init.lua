local GRAVITY = 9.81

sf_util = {}

sf_util.get_singleplayer = function()
	return minetest.get_player_by_name("singleplayer")
end

-- Returns the closest player to pos or nil if no player connected
sf_util.get_closest_player = function(pos)
	local players = minetest.get_connected_players()
	local closest_player = nil
	local closest_dist = math.huge
	for p=1, #players do
		local ppos = players[p]:get_pos()
		local dist = vector.distance(pos, ppos)
		if dist < closest_dist then
			closest_player = players[p]
			closest_dist = dist
		end
	end
	return closest_player
end

-- Sort the 2 positions pos1 and pos2 so that the lower
-- XYZ coordinates are all in pos1 and the higher XYZ
-- coordinates are all in pos2.
sf_util.sort_positions = function(pos1, pos2)
	local retpos1, retpos2 = {}, {}
	local axes = {"x", "y", "z"}
	for a=1, #axes do
		local axis = axes[a]
		if pos1[axis] < pos2[axis] then
			retpos1[axis] = pos1[axis]
			retpos2[axis] = pos2[axis]
		else
			retpos1[axis] = pos2[axis]
			retpos2[axis] = pos1[axis]
		end
	end
	return retpos1, retpos2
end

-- Convert a node position to a mapblock position
function sf_util.nodepos_to_blockpos(nodepos)
	local bpos = {}
	bpos.x = math.floor(nodepos.x/16)
	bpos.y = math.floor(nodepos.y/16)
	bpos.z = math.floor(nodepos.z/16)
	return bpos
end

-- Get max and min node coordinates of a mapblock position
function sf_util.get_blockpos_bounds(blockpos)
	local min = {}
	min.x = blockpos.x * 16
	min.y = blockpos.y * 16
	min.z = blockpos.z * 16
	local max = {}
	max.x = blockpos.x * 16 + 15
	max.y = blockpos.y * 16 + 15
	max.z = blockpos.z * 16 + 15
	return min, max
end

-- Set a "tower" of nodes from min_y up to pos.y, where y can be
-- a fractional number. The fractional part will be used
-- to add a leveled node at the top.
-- nodename is the name of the full node and leveled_nodename
-- is the name of its leveled equivalent.
-- vmanip_data, vmanip_param2data and vmanip_area are optional; if set, the nodes will be set
-- in a LuaVoxelManip data object instead (used by map generation)
function sf_util.set_xz_nodes(pos, min_y, nodename, leveled_nodename, vmanip_area, vmanip_data, vmanip_param2data)
	if not leveled_nodename then
		minetest.log("error", "[sf_util] sf_util.set_xz_nodes called without leveled_nodename!")
	end

	local cid = minetest.get_content_id(nodename)
	local cidl = minetest.get_content_id(leveled_nodename)

	local frac = pos.y % 1
	local param2 = math.round(frac * 64)
	param2 = param2 - param2 % 4
	pos.y = math.floor(pos.y)

	if pos.y > min_y then
		local fpos = table.copy(pos)
		for y = fpos.y, min_y, -1 do
			local ffpos = vector.new(fpos.x, y, fpos.z)
			if vmanip_data then
				local idx = vmanip_area:indexp(ffpos)
				vmanip_data[idx] = cid
				vmanip_param2data[idx] = 0
			else
				minetest.set_node(ffpos, {name=nodename, param2=0})
			end
		end
	else
		local fpos = vector.new(pos.x, min_y, pos.z)
		if vmanip_data then
			local idx = vmanip_area:indexp(fpos)
			vmanip_data[idx] = cid
			vmanip_param2data[idx] = 0
		else
			minetest.set_node(fpos, {name=nodename, param2=0})
		end
	end

	if param2 ~= 0 then
		local fpos = vector.new(pos.x, pos.y+1, pos.z)
		if vmanip_data then
			local idx = vmanip_area:indexp(fpos)
			vmanip_data[idx] = cidl
			vmanip_param2data[idx] = param2
		else
			minetest.set_node(fpos, {name=leveled_nodename, param2=param2})
		end
	end
end


sf_util.break_nodes_in_area = function(pos_min, pos_max, nodename, sound)
	local nodes = minetest.find_nodes_in_area(pos_min, pos_max, nodename)
	local broken = 0
	for n=1,#nodes do
		local nodepos = nodes[n]
		minetest.remove_node(nodepos)
		minetest.add_particlespawner({
			amount = 16,
			time = 0.05,
			exptime = {
				min = 1,
				max = 1.5,
			},
			pos = {
				min = vector.add(nodepos, vector.new(-0.2, -0.2, -0.2)),
				max = vector.add(nodepos, vector.new(0.2, 0.2, 0.2)),
			},
			vel = {
				min = vector.new(-2, -2, -2),
				max = vector.new(2, 2, 2),
			},
			size = 2,
			drag = vector.new(2, 0, 2),
			acc = vector.new(0, -GRAVITY, 0),
			collisiondetection = true,
			node = {name=nodename},
		})
		broken = broken + 1
	end
	if broken > 0 then
		local pos = table.copy(pos_min)
		-- Get area middle to play sound
		pos.x = pos_min.x + (pos_max.x - pos_min.x)/2
		pos.y = pos_min.y + (pos_max.y - pos_min.y)/2
		pos.z = pos_min.z + (pos_max.z - pos_min.z)/2
		if sound then
			minetest.sound_play(sound, {pos=pos}, true)
		end
		minetest.log("action", "[sf_util] "..broken.." node(s) of type '"..nodename.."' broken in area")
	end
end

