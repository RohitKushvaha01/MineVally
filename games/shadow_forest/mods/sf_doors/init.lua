local S = minetest.get_translator("sf_doors")
local NS = function(s) return s end

local DOOR_LIMIT = 6/16

local register_door = function(id, description, tiles)
	minetest.register_node("sf_doors:door_"..id.."_closed", {
		description = S("@1 (closed)", description),
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "4dir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 1.5, -DOOR_LIMIT },
		},
		groups = { editor_breakable = 1, door = 1 },
		on_rightclick = function(pos, node, clicker)
			minetest.set_node(pos, { name = "sf_doors:door_"..id.."_open", param2 = node.param2 })
		end,
		sounds = sf_sounds.node_sound_wood_defaults(),
	})
	minetest.register_node("sf_doors:door_"..id.."_open", {
		description = S("@1 (open)", description),
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "4dir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, -DOOR_LIMIT, 1.5, 0.5 },
		},
		groups = { editor_breakable = 1, door = 2 },
		on_rightclick = function(pos, node, clicker)
			minetest.set_node(pos, { name = "sf_doors:door_"..id.."_closed", param2 = node.param2 })
		end,
		sounds = sf_sounds.node_sound_wood_defaults(),
	})
end

-- TODO: Door texture
register_door("wood", NS("Wooden Door"), { "sf_nodes_wood.png^[brighten" })
