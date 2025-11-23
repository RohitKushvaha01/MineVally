local playerstates = {}

local GRAVITY = 9.81
local STEP_EFFECT_UPDATE = 0.1
local STEP_THRESHOLD = 0.1
local PUDDLE_PARTICLES = 12
local SNOW_PARTICLES = 4
local MUD_PARTICLES = 3

local splash = function(player, offset, particlenode, amount)
	minetest.add_particlespawner({
		amount = amount,
		time = 0.05,
		exptime = {
			min = 1,
			max = 1.5,
		},
		pos = offset,
		attached = player,
		vel = {
			min = vector.new(-2, 2, -2),
			max = vector.new(2, 4, 2),
		},
		bounce = 0.5,
		drag = vector.new(5, 0, 5),
		acc = vector.new(0, -GRAVITY, 0),
		collisiondetection = true,
		node = particlenode,
	})
end

local function step_effect(player)
	local pos = player:get_pos()
	pos.y = math.ceil(pos.y)
	local nodei = minetest.get_node(pos)
	local below = vector.add(pos, vector.new(0, -1, 0))
	local nodeb = minetest.get_node(below)
	local offset = vector.zero()
	if minetest.get_item_group(nodei.name, "puddle") == 1 then
		local height = nodei.param2 / 64
		offset.y = height
		splash(player, offset, nodei, PUDDLE_PARTICLES)
	elseif minetest.get_item_group(nodeb.name, "snow") == 1 then
		splash(player, offset, nodeb, SNOW_PARTICLES)
	elseif minetest.get_item_group(nodei.name, "snow") == 1 then
		splash(player, offset, nodei, SNOW_PARTICLES)
	elseif minetest.get_item_group(nodeb.name, "mud") == 1 then
		splash(player, offset, nodeb, MUD_PARTICLES)
	elseif minetest.get_item_group(nodei.name, "mud") == 1 then
		splash(player, offset, nodei, MUD_PARTICLES)
	end
end

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local pname = player:get_player_name()
		if not playerstates[pname] then
			playerstates[pname] = {
				step_effect_timer = 0,
				last_pos = player:get_pos(),
			}
		else
			local state = playerstates[pname]
			state.step_effect_timer = state.step_effect_timer + dtime
			if state.step_effect_timer >= STEP_EFFECT_UPDATE then
				state.step_effect_timer = 0
				if vector.distance(player:get_pos(), state.last_pos) >= STEP_THRESHOLD then
					step_effect(player)
				end
				state.last_pos = player:get_pos()
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	playerstates[player:get_player_name()] = nil
end)
