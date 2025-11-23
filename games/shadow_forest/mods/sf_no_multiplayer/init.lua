local S = minetest.get_translator("sf_no_multiplayer")

if not minetest.is_singleplayer() then
	error(S("This is not a multiplayer game! Please disable server hosting and try again."))
end
