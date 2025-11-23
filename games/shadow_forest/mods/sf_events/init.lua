local checktimer = 0
minetest.register_globalstep(function(dtime)
	checktimer = checktimer + dtime
	if checktimer < 3 then
		return
	end
	checktimer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local pos = player:get_pos()
		local offset = vector.new(5,2,5)
		local campfires = minetest.find_nodes_in_area(vector.subtract(pos,offset), vector.add(pos,offset), "sf_nodes:campfire_on")
		for c=1, #campfires do
			local cnode = minetest.get_node(campfires[c])
			if cnode.param2 ~= 2 then
				sf_dialog.show_dialog(player, "campfire", true)
			end
		end
		local enemies = minetest.get_objects_inside_radius(pos, 8)
		for e=1, #enemies do
			local enemy = enemies[e]
			local lua = enemy:get_luaentity()
			if lua and (lua.name == "sf_mobs:crawler" or lua.name == "sf_mobs:flyershooter") then
				sf_dialog.show_dialog(player, "enemy_hint", true)
			end
		end
	end
end)


