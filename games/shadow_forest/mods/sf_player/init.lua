local DAMAGE_IMMUNITY_TIME = 500000

local player_last_damage = {}
local player_lost_fragments = {}

-- Damage immunity for a short time after a punch
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if hp_change > 0 then
		return hp_change
	end
	local now = minetest.get_us_time()
	local pname = player:get_player_name()
	local last_damage = player_last_damage[pname]
	if (reason and reason.type ~= "punch") or (last_damage == nil or (now - last_damage) > DAMAGE_IMMUNITY_TIME) then
		player_last_damage[pname] = minetest.get_us_time()
		return hp_change
	else
		return 0
	end
end, true)

minetest.register_on_newplayer(function(player)
	sf_world.go_to_spawn_pos(player)
end)

minetest.register_on_respawnplayer(function(player)
	minetest.sound_play({name="sf_player_respawn", gain=0.3}, {to_player=player:get_player_name()}, true)
	sf_world.go_to_respawn_pos(player)
	minetest.after(1.0, function()
		if player and player:is_player() then
			sf_dialog.show_dialog(player, "respawn", true)
		end
	end)
	if player_lost_fragments[player:get_player_name()] then
		minetest.after(1.5, function()
			if player and player:is_player() then
				sf_dialog.show_dialog(player, "first_shadow_fragment_loss", true)
			end
		end)
	end
	player_lost_fragments[player:get_player_name()] = nil
	return true
end)

minetest.register_on_dieplayer(function(player)
	local count = sf_resources.get_resource_count(player, "sf_resources:shadow_fragment")
	if count > 0 then
		player_lost_fragments[player:get_player_name()] = true
	end
	sf_resources.set_resource_count(player, "sf_resources:shadow_fragment", 0)
end)

minetest.register_on_joinplayer(function(player)
	player:set_properties({
		visual = "mesh",
		visual_size = { x=10, y=10, z=10 },
		mesh = "sf_player_model.obj",
		textures = {
			"sf_player_player.png",
			"sf_player_hat.png",
		},
		backface_culling = true,
	})
	player:set_lighting({
		shadows= {
			intensity = 0.5,
		},
	})
	player:set_fov(92)
	minetest.after(3, function(player)
		if player and player:is_player() then
			sf_dialog.show_dialog(player, "intro", true)
		end
	end, player)
end)
minetest.register_on_leaveplayer(function(player)
	player_last_damage[player:get_player_name()] = nil
	player_lost_fragments[player:get_player_name()] = nil
end)
