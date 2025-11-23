local BASE_HEALTH = 8
local REGEN_TIME = 5

local regentimer = 0

sf_health = {}

sf_health.update_max_hp = function(player)
	local upgrades = 0
	for i=1, 4 do
		if sf_upgrade.has_upgrade(player, "health"..i) then
			upgrades = upgrades + 1
		end
	end
	local hp_max = BASE_HEALTH + upgrades * 2
	player:set_properties({
		hp_max = hp_max,
	})
	sf_hud.update_health_hud(player)
end

minetest.register_on_joinplayer(function(player)
	sf_health.update_max_hp(player)
end)

-- Regenerate health
minetest.register_globalstep(function(dtime)
	regentimer = regentimer + dtime
	if regentimer < REGEN_TIME then
		return
	end
	regentimer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local props = player:get_properties()
		local hp = player:get_hp()
		if hp > 0 then
			if hp + 1 <= props.hp_max then
				player:set_hp(hp + 1)
			end
		end
	end
end)

-- Reset regeneration timer on damage to avoid lucky insta-heal
-- when taking damage due to lucky timing.
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if hp_change < 0 then
		regentimer = 0
	end
end)

