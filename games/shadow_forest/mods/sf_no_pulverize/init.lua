local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

-- Remove pulverize chat command in-game
if not EDITOR then
	minetest.unregister_chatcommand("pulverize")
end
