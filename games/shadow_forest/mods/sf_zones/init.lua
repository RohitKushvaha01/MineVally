sf_zones = {}

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)
local GRAVITY = 9.81
local ZONE_CHECK_TIME = 0.7
local CRYSTALS_TO_BREAK_BARRIER = 3
local MAX_ZONE_NESTING = 100
local zone_timer = 0.0

local DEFAULT_SKY = "storm_clouds"
local DEFAULT_MUSIC = "shadow_forest"

local registered_zones = {}

--[[
name: zone name
def: {
	areas = { area1, area2, area3, ... }, -- list of areas (must have at least 1) (see below)
	on_enter(zonename, player), -- optional function, called when player enters zone
	on_leave(zonename, player), -- optional function, called when player leaves zone
}

area definition: {
	pos_min, -- left bottom front corner
	pos_max, -- right top back corner
}
]]
function sf_zones.register_zone(name, def)
	local zoneinfo = table.copy(def)
	zoneinfo._players_in_zone = {}
	registered_zones[name] = zoneinfo
end

function sf_zones.get_zone(name)
	return registered_zones[name]
end

function sf_zones.in_which_zones(pos)
	local zones_list = {}
	for zonename, _ in pairs(registered_zones) do
		if sf_zones.is_in_zone(pos, zonename) then
			table.insert(zones_list, zonename)
		end
	end
	return zones_list
end

function sf_zones.is_in_zone(pos, zonename)
	local zone = sf_zones.get_zone(zonename)
	if not zone then
		return false
	end
	local areas = zone.areas
	for a=1, #areas do
		local area = areas[a]
		local pos_min = area.pos_min
		local pos_max = area.pos_max
		local is_in_area = pos.x >= pos_min.x and pos.y >= pos_min.y and pos.z >= pos_min.z and pos.x <= pos_max.x and pos.y <= pos_max.y and pos.z <= pos_max.z
		if is_in_area then
			return true
		end
	end
	return false
end

function sf_zones.get_innermost_zone(pos)
	local zonenames = sf_zones.in_which_zones(pos)
	local innermost = nil
	local deepest_level = -1
	local deepest_zone = nil
	for z=1, #zonenames do
		local zonename = zonenames[z]
		local zone = sf_zones.get_zone(zonename)
		if deepest_level < 0 then
			deepest_zone = zonename
			deepest_level = 0
		end
		local levels = 0
		while zone.parent do
			zonename = zone.parent
			zone = sf_zones.get_zone(zonename)
			levels = levels + 1
			if levels > deepest_level then
				deepest_level = levels
				deepest_zone = zonenames[z]
			end
			if levels > MAX_ZONE_NESTING then
				error("Maximum zone nesting reached!")
			end
		end
	end
	return deepest_zone
end

function sf_zones.get_objects_in_zone(zone)
	local objs = {}
	for a=1, #zone.areas do
		local area = zone.areas[a]
		local area_objs = minetest.get_objects_in_area(area.pos_min, area.pos_max)
		for o=1, #area_objs do
			table.insert(objs, area_objs[o])
		end
	end
	return objs
end

function sf_zones.find_nodes_in_zone(zone, nodenames, grouped)
	local nodes = {}
	for a=1, #zone.areas do
		local area = zone.areas[a]
		local area_nodes = minetest.find_nodes_in_area(area.pos_min, area.pos_max, nodenames, grouped)
		for n=1, #area_nodes do
			table.insert(nodes, area_nodes[n])
		end
	end
	return nodes
end

local get_zone_music = function(zone)
	if zone.music then
		return zone.music
	else
		local music
		while zone.parent do
			zone = sf_zones.get_zone(zone.parent)
			if zone.music then
				return zone.music
			end
		end
	end
	return DEFAULT_MUSIC
end

local get_zone_sky = function(zone)
	if zone.sky then
		return zone.sky
	else
		local sky
		while zone.parent do
			zone = sf_zones.get_zone(zone.parent)
			if zone.sky then
				return zone.sky
			end
		end
	end
	return DEFAULT_SKY
end

function sf_zones.update_player_ambience(player)
	if EDITOR then
		return
	end
	local zonename = sf_zones.get_innermost_zone(player:get_pos())
	local zone = sf_zones.get_zone(zonename)
	if zone then
		local music = get_zone_music(zone)
		local sky = get_zone_sky(zone)
		sf_music.change_music(player, music)
		sf_sky.set_sky(player, sky)
	else
		sf_music.change_music(player, DEFAULT_MUSIC)
		sf_sky.set_sky(player, DEFAULT_SKY)
	end
end

local check_zones = function(player)
	local pos = player:get_pos()
	local pname = player:get_player_name()
	local zones_changed = false
	for zonename, zone in pairs(registered_zones) do
		if sf_zones.is_in_zone(pos, zonename) then
			if not zone._players_in_zone[pname] then
				zone._players_in_zone[pname] = true
				zones_changed = true
				minetest.log("action", "[sf_zones] "..player:get_player_name().." enters zone '"..zonename.."'")
				if zone.on_enter then
					zone.on_enter(zonename, player)
				end
			end
		else
			if zone._players_in_zone[pname] then
				zone._players_in_zone[pname] = nil
				zones_changed = true
				minetest.log("action", "[sf_zones] "..player:get_player_name().." leaves zone '"..zonename.."'")
				if zone.on_leave then
					zone.on_leave(zonename, player)
				end
			end
		end
	end
	if zones_changed then
		sf_zones.update_player_ambience(player)
	end
end

minetest.register_globalstep(function(dtime)
	zone_timer = zone_timer + dtime
	if zone_timer < ZONE_CHECK_TIME then
		return
	end
	zone_timer = 0

	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		check_zones(player)
	end
end)

function sf_zones.report_location_change(player)
	check_zones(player)
end

-- Tree of Life
sf_zones.register_zone("portal_tree", {
	areas = {
		-- tree interior and outside ladder
		{ pos_min = vector.new(315, 45, 385), pos_max = vector.new(333, 95, 407) },
		-- balcony
		{ pos_min = vector.new(325, 74, 387), pos_max = vector.new(337, 82, 407) },
	},
	music = "shadow_forest",
	sky = "storm_clouds",
	on_enter = function(zonename, player)
		if EDITOR then
			return
		end
		sf_dialog.show_dialog(player, "intro2", true)
	end,
})
sf_zones.register_zone("dead_forest", {
	areas = {
		-- main area
		{ pos_min = vector.new(5, 13, 5), pos_max = vector.new(214, 100, 185) },
		-- entrance
		{ pos_min = vector.new(141, 30, 181), pos_max = vector.new(175, 100, 206) },
	},
	music = "shadow_forest",
	sky = "smoky_clouds",
})
sf_zones.register_zone("forest", {
	areas = {
		-- roughly the starting area
		{ pos_min = vector.new(8, 31, 183), pos_max = vector.new(133, 90, 237) },
		-- remainder (a bit of overlap)
		{ pos_min = vector.new(8, 31, 237), pos_max = vector.new(173, 90, 506) },
	},
	music = "shadow_forest",
	sky = "storm_clouds",
})

sf_zones.register_zone("fog_chasm", {
	areas = {{
		pos_min = vector.new(214, 13, 0),
		pos_max = vector.new(351, 57, 174),
	}},
	music = "fog_chasm",
	sky = "fog",
})
sf_zones.register_zone("snow_mountain", {
	areas = {{
		pos_min = vector.new(279, 45, 17),
		pos_max = vector.new(433, 100, 167),
	}},
	music = "shadow_forest",
	sky = "storm_clouds",
})
sf_zones.register_zone("chimneys", {
	parent = "dead_forest",
	areas = {{
		pos_min = vector.new(19, 42, 2),
		pos_max = vector.new(116, 78, 83),
	}},
	on_enter = function(zonename, player)
		sf_dialog.show_dialog(player, "chimneys", true)
	end,
})
local break_weak_spikeplants_in_area = function(pos_min, pos_max)
	sf_util.break_nodes_in_area(pos_min, pos_max, "sf_nodes:spikeplant_weak", {name = "sf_zones_spikeplant_break", gain=1.0})
end

sf_zones.register_zone("shadow_bush_barrier", {
	parent = "dead_forest",
	areas = {{
		pos_min = vector.new(144, 48, 178),
		pos_max = vector.new(171, 61, 192),
	}},
	on_enter = function(zonename, player)
		local crystals = sf_resources.get_resource_count(player, "sf_resources:light_crystal")
		if crystals >= CRYSTALS_TO_BREAK_BARRIER then
			local zone = sf_zones.get_zone(zonename)
			minetest.after(2, function()
				for a=1, #zone.areas do
					local area = zone.areas[a]
					break_weak_spikeplants_in_area(area.pos_min, area.pos_max)
				end
			end)
			sf_dialog.show_dialog(player, "bush_spell", true)
		else
			sf_dialog.show_dialog(player, "bush_spell_early", true)
		end
	end,
})

sf_zones.register_zone("boss_arena", {
	parent = "dead_forest",
	areas = {{
		pos_min = vector.new(52, 12, 20),
		pos_max = vector.new(76, 41, 64),
	}},
})

sf_zones.register_zone("boss_arena_enter", {
	parent = "dead_forest",
	areas = {{
		pos_min = vector.new(52, 12, 40),
		pos_max = vector.new(76, 30, 64),
	}},
	on_enter = function(zonename, player)
		local zone = sf_zones.get_zone("boss_arena")
		local objs = sf_zones.get_objects_in_zone(zone)
		local boss_exists = false
		local pmeta = player:get_meta()
		if pmeta:get_int("sf_mobs:boss_defeated") == 1 then
			minetest.log("action", "[sf_zones] "..player:get_player_name().." entered boss arena but boss already defeated")
			return
		end
		for o=1, #objs do
			local lua = objs[o]:get_luaentity()
			if lua and lua.name == "sf_mobs:shadow_orb" then
				boss_exists = true
				break
			end
		end
		if not boss_exists then
			local spawners = sf_zones.find_nodes_in_zone(zone, "sf_mobs:spawner_shadow_orb")
			for s=1, #spawners do
				minetest.add_entity(spawners[s], "sf_mobs:shadow_orb")
				minetest.log("action", "[sf_zones] Shadow orb boss spawed at "..minetest.pos_to_string(spawners[s]))
			end
		end
		sf_dialog.show_dialog(player, "boss", true)
	end,
})


sf_zones.register_zone("snow_mountain_shrine", {
	parent = "snow_mountain",
	areas = {{
		pos_min = vector.new(333, 60, 69),
		pos_max = vector.new(377, 94, 82),
	}},
	music = "crystal",
})
sf_zones.register_zone("cave", {
	parent = "fog_chasm",
	areas = {{
		pos_min = vector.new(281, 15, 16),
		pos_max = vector.new(350, 22, 54),
	}},
	sky = "fog_underground",
})
sf_zones.register_zone("fog_chasm_shrine", {
	parent = "cave",
	areas = {{
		pos_min = vector.new(316, 15, 20),
		pos_max = vector.new(348, 31, 48),
	}},
	music = "crystal",
})
sf_zones.register_zone("forest_shrine", {
	parent = "forest",
	areas = {{
		pos_min = vector.new(53, 64, 453),
		pos_max = vector.new(67, 76, 479),
	}},
	music = "crystal",
})

-- Remove flyershooters and boss in boss arena if player
-- respawns from boss arena.
-- Done to reset the arena state properly so the player
-- can start from a clean slate on a retry.
minetest.register_on_respawnplayer(function(player)
	if not sf_zones.is_in_zone(player:get_pos(), "boss_arena") then
		return
	end
	local zone = sf_zones.get_zone("boss_arena")
	local objs = sf_zones.get_objects_in_zone(zone)
	for o=1, #objs do
		local lua = objs[o]:get_luaentity()
		if lua then
			if lua.name == "sf_mobs:shadow_orb" then
				minetest.log("action", "[sf_zones] Boss arena: Removing shadow orb at "..minetest.pos_to_string(objs[o]:get_pos()).." on player respawn")
				objs[o]:remove()
			elseif lua.name == "sf_mobs:flyershooter" then
				minetest.log("action", "[sf_zones] Boss arena: Removing flyershooter at "..minetest.pos_to_string(objs[o]:get_pos()).." on player respawn")
				objs[o]:remove()
			end
		end
	end
end)

