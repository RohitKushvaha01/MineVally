local S = minetest.get_translator("sf_commands")

minetest.register_chatcommand("hp", {
	privs = { server = true },
	params = S("<health>"),
	description = S("Set your health points"),
	func = function(name, param)
		if minetest.settings:get_bool("enable_damage") == false then
			return false, S("Not possible, damage is disabled.")
		end
		local player = minetest.get_player_by_name(name)
		if player == nil or not player:is_player() then
			return false, S("Player does not exist.")
		end
		local hp = param
		hp = minetest.parse_relative_number(hp, player:get_hp())
		if not hp then
			return false, S("Invalid health!")
		end
		hp = math.floor(hp)
		local hp_max = player:get_properties().hp_max
		hp = math.max(0, math.min(hp_max, hp))
		player:set_hp(hp)
		return true, S("Health set to @1.", hp)
	end,
})

