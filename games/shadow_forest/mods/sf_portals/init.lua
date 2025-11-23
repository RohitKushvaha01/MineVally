local S = minetest.get_translator("sf_portals")
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

minetest.register_node("sf_portals:portal", {
	description = S("Portal"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -1/16, 0.5, 0.5, 1/16 },
	},
	tiles = {
		"blank.png",
		"blank.png",
		"blank.png",
		"blank.png",
		{ name = "sf_portals_portal_anim.png", animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3 } },
	},
	post_effect_color = {
		r=0,g=255,b=0,a=100,
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "4dir",
	light_source = 7,
	sunlight_propagates = true,
	walkable = false,
	groups = { editor_breakable = 1 },
})

local teletimer = 0
minetest.register_globalstep(function(dtime)
	if EDITOR then
		return
	end
	teletimer = teletimer + dtime
	if teletimer < 1 then
		return
	end
	teletimer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local node = minetest.get_node(player:get_pos())
		if node.name == "sf_portals:portal" then
			local dest_id = math.floor(node.param2 / 4)
			sf_world.teleport_to_destination(player, dest_id)
		end
	end
end)
