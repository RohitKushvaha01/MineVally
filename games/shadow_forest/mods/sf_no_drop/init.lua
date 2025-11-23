local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)


-- Disallow spawning any item entities
minetest.add_item = function()
	return nil
end

-- Disallowing drop in-game.
-- Dropping in editor is permitted but will destroy the item
-- because of the mintest.add_item_override.
minetest.item_drop = function(itemstack, dropper, pos)
	if EDITOR then
		return ""
	end
end

