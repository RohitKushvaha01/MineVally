local DARKNESS_DAMAGE_TIMER = 2
local DARKNESS_DAMAGE = 1

-- Damage players trapped in the darkness

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < DARKNESS_DAMAGE_TIMER then
		return
	end
	timer = 0

	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local pos = player:get_pos()
		local above = vector.offset(pos, 0, 1, 0)
		local node = minetest.get_node(pos)
		local node_above = minetest.get_node(above)

		-- Deal damage when entering total darkness
		if (node.name == "sf_nodes:darkness" and node.param1 == 0) or (node_above.name == "sf_nodes:darkness" and node_above.param1 == 0) then
			player:set_hp(player:get_hp() - DARKNESS_DAMAGE)
			sf_dialog.show_dialog(player, "darkness_damage", true)
		end

		-- Warn player
		if (node.name == "sf_nodes:darkness" or node_above.name == "sf_nodes:darkness") then
			sf_dialog.show_dialog(player, "darkness_warning", true)
		end
	end
end)
