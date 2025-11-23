local S = minetest.get_translator("sf_loot")
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

-- Legacy support: Name of the HUD type field for 'hud_add'.
local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Luanti/Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Luanti/Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

-- CHEAT: If enabled, shows vases near you
local vase_radar = false

local VASE_RADAR_UPDATE_TIMER = 1.0

local vase_drop = nil
if not EDITOR then
	vase_drop = ""
end

-- Vase radar timer
local vtimer = 0

minetest.register_node("sf_loot:vase", {
	description = S("Vase"),
	tiles = {
		"sf_loot_vase_top.png",
		"sf_loot_vase_bottom.png",
		"sf_loot_vase_side.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{ -2/16, 4/16, -2/16, 2/16, 5/16, 2/16 }, -- cap top
			{ -3/16, 3/16, -3/16, 3/16, 4/16, 3/16 }, -- cap bottom
			{ -4/16, -6/16, -4/16, 4/16, 3/16, 4/16 }, -- main body
			{ -3/16, -7/16, -3/16, 3/16, -6/16, 3/16 }, -- base top
			{ -2/16, -0.5, -2/16, 2/16, -7/16, 2/16 }, -- base bottom
		},
	},
	sounds = {
		footstep = sf_sounds.node_sound_stone_defaults().footstep,
		dug = { name = "sf_loot_vase_break", gain = 0.5 },
	},
	groups = { editor_breakable = 1, loot_node = 1 },
	on_destruct = function(pos)
		vtimer = VASE_RADAR_UPDATE_TIMER
		if EDITOR then
			return
		end
		local node = minetest.get_node(pos)
		if node.param2 > 0 then
			for i=1, node.param2 do
				local obj = minetest.add_entity(pos, "sf_resources:healing_essence")
				if obj then
					local vel = vector.zero()
					vel.x = math.random(-100, 100)*0.01
					vel.y = math.random(0, 100)*0.01
					vel.z = math.random(-100, 100)*0.01
					obj:set_velocity(vel)
				end
			end
		end
	end,
	drop = vase_drop,
})

local waypoints = {}
minetest.register_globalstep(function(dtime)
	if not vase_radar then
		return
	end
	vtimer = vtimer + dtime
	if vtimer <= VASE_RADAR_UPDATE_TIMER then
		return
	end
	vtimer = 0
	local players = minetest.get_connected_players()
	local areasize = vector.new(30, 30, 30)
	for p=1, #players do
		local player = players[p]
		local pname = player:get_player_name()
		if not waypoints[pname] then
			waypoints[pname] = {}
		end
		for w=1, #waypoints[pname] do
			player:hud_remove(waypoints[pname][w])
		end
		local ppos = vector.round(players[p]:get_pos())
		local vases = minetest.find_nodes_in_area(vector.subtract(ppos, areasize), vector.add(ppos, areasize), "sf_loot:vase")
		for v=1, #vases do
			local vnode = minetest.get_node(vases[v])
			local id = players[p]:hud_add({
				[hud_type_field_name] = "waypoint",
				name = S("Vase (@1)", vnode.param2),
				precision = 1,
				text = S("m"),
				number = 0xFF8080,
				world_pos = vases[v],
			})
			table.insert(waypoints[pname], id)
		end
	end
end)

minetest.register_chatcommand("vase_radar", {
	description = S("Toggles the vase radar which shows vases near you"),
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		vase_radar = not vase_radar
		if vase_radar then
			vtimer = VASE_RADAR_UPDATE_TIMER
			return true, S("Vase radar enabled.")
		else
			if waypoints[name] then
				for w=1, #waypoints[name] do
					player:hud_remove(waypoints[name][w])
				end
			end
			return false, S("Vase radar disabled.")
		end
	end,
})
