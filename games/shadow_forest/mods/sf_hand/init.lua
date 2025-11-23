local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local hand_range
if EDITOR then
	hand_range = 20
else
	hand_range = 4
end

minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x=1.0, y=1.0, z=3.0},
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level = 0,
		groupcaps = {
			loot_node = {uses=0, times = { [1] = 0, [2] = 0, [3] = 0 }},
		},
		damage_groups = {fleshy = 1},
	},
	range = hand_range,
})
