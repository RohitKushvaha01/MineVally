local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

minetest.register_on_newplayer(function(player)
	if EDITOR then
		return
	end
	local inv = player:get_inventory()
	inv:set_stack("main", 2, "sf_weapons:lightstaff")
	inv:set_stack("main", 3, "sf_weapons:stick")
end)
