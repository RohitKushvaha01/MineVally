sf_sounds = {}
local S = minetest.get_translator("sf_sounds")
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local active_sound_players = {}
local SOUND_PLAYER_RANGE_ACTIVATE = 24
local SOUND_PLAYER_RANGE_DEACTIVATE = 32

sf_sounds.node_sound_dirt_defaults = function(pitch)
	return {
		footstep = {name = "sf_sounds_dirt_footstep", gain = 0.15, pitch=pitch},
	}
end

sf_sounds.node_sound_mud_defaults = function(pitch)
	return {
		footstep = {name ="sf_sounds_mud_footstep", gain = 0.2, pitch=pitch},
	}
end

sf_sounds.node_sound_wood_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_wood_footstep", gain = 0.25, pitch=pitch},
	}
end

sf_sounds.node_sound_tree_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_wood_footstep", pitch = 0.8, gain=0.25, pitch=pitch},
	}
end

sf_sounds.node_sound_snow_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_snow_footstep", gain = 0.3, pitch=pitch},
	}
end

sf_sounds.node_sound_gravel_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_gravel_footstep", gain = 0.3, pitch=pitch},
	}
end

sf_sounds.node_sound_stone_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_stone_footstep", pitch=pitch, gain=0.8},
	}
end
sf_sounds.node_sound_metal_defaults = function(...)
	-- TODO: custom sound
	return sf_sounds.node_sound_stone_defaults(...)
end
sf_sounds.node_sound_stone_reverb_defaults = function(pitch)
	return {
		footstep = {name="sf_sounds_stone_footstep_reverb", pitch=pitch, gain=0.8},
	}
end

sf_sounds.node_sound_leaves_defaults = function(pitch)
	return {
		footstep = { name = "sf_sounds_leaves_footstep", gain = 0.4, pitch = pitch },
	}
end

sf_sounds.node_sound_water_defaults = function(...)
	-- TODO: custom sound
	return sf_sounds.node_sound_puddle_defaults(...)
end

sf_sounds.node_sound_puddle_defaults = function(pitch)
	return {
		footstep = { name = "sf_sounds_puddle_footstep", gain = 0.4, pitch=pitch },
	}
end

local register_sound_player = function(id, def)
	local drawtype, pointable
	if EDITOR then
		drawtype = "allfaces"
		pointable = true
	else
		drawtype = "airlike"
		pointable = false
	end
	minetest.register_node("sf_sounds:player_"..id, {
		description = def.description,
		pointable = pointable,
		drawtype = drawtype,
		visual_scale = 0.5,
		paramtype = "light",
		sunlight_propagates = true,
		tiles = {"sf_sounds_player.png"},
		walkable = false,
		groups = { sound_player = 1, editor_breakable = 1 },
		on_destruct = function(pos)
			local hash = minetest.hash_node_position(pos)
			local active_sound = active_sound_players[hash]
			if not active_sound then
				return
			end
			minetest.sound_stop(active_sound)
			active_sound_players[hash] = nil
			local node = minetest.get_node(pos)
			minetest.log("action", "[sf_sounds] Stopped environment sound at "..minetest.pos_to_string(pos) .." ("..node.name..")")
		end,
		_sf_sound = def._sf_sound,
	})
end

local check_timer = 0
minetest.register_globalstep(function(dtime)
	check_timer = check_timer + dtime
	if check_timer < 1.0 then
		return
	end
	check_timer = 0

	-- Check for sound players to activate
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local ppos = player:get_pos()
		local offset = vector.new(SOUND_PLAYER_RANGE_ACTIVATE, SOUND_PLAYER_RANGE_ACTIVATE, SOUND_PLAYER_RANGE_ACTIVATE)
		local splayers = minetest.find_nodes_in_area(vector.add(ppos, offset), vector.subtract(ppos, offset), "group:sound_player")
		for s=1, #splayers do
			local splayerpos = splayers[s]
			local hash = minetest.hash_node_position(splayerpos)
			local active_sound = active_sound_players[hash]
			if not active_sound then
				local splayernode = minetest.get_node(splayerpos)
				local def = minetest.registered_nodes[splayernode.name]
				local offset = math.max(0.0, math.min(1.0, math.random(500,4000)*0.001))
				local handle = minetest.sound_play(def._sf_sound, {loop=true, pos=splayerpos, start_time = offset})
				active_sound_players[hash] = handle
				minetest.log("action", "[sf_sounds] Started environment sound at "..minetest.pos_to_string(splayerpos) .." ("..splayernode.name..")")
			end
		end
	end

	-- Check for sound players to deactivate
	for hash, handle in pairs(active_sound_players) do
		local spos = minetest.get_position_from_hash(hash)
		local offset = vector.new(SOUND_PLAYER_RANGE_DEACTIVATE, SOUND_PLAYER_RANGE_DEACTIVATE, SOUND_PLAYER_RANGE_DEACTIVATE)
		local objs = minetest.get_objects_in_area(vector.add(spos, offset), vector.subtract(spos, offset))
		local player_found = false
		for o=1, #objs do
			local obj = objs[o]
			if obj:is_player() then
				player_found = true
				break
			end
		end
		if not player_found then
			minetest.sound_stop(handle)
			active_sound_players[hash] = nil
			local node = minetest.get_node(spos)
			minetest.log("action", "[sf_sounds] Stopped environment sound at "..minetest.pos_to_string(spos) .." ("..node.name..")")
		end
	end
end)

register_sound_player("river", {
	description = S("River Sound Player"),
	_sf_sound = { name = "sf_sounds_river", gain = 0.2, max_hear_distance = 14 },
})

sf_sounds.stop_all_sound_players = function()
	for hash, handle in pairs(active_sound_players) do
		minetest.sound_stop(handle)
		active_sound_players[hash] = nil
	end
	minetest.log("action", "[sf_sounds] Stopped all environment sounds")
end
