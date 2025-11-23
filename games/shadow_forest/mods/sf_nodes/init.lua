local S = minetest.get_translator("sf_nodes")
local NS = function(s) return s end

local WOOD_WALL_LIMIT = 6/16
local CHAINLINK_LIMIT = 6/16
local RAILING_LIMIT = 6/16
local RAILING_HEIGHT = 4/16
local TABLE_PLATE_LIMIT = 7/16
local TABLE_LEG_LIMIT = 7/16
local TORCH_LIGHT = 8
local PROTRUDING_LEAVES_MULTIPLY_COLOR = "#d0d0d0"
local PLANTLIKE_OFFSET_LEVELS = 15

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

sf_nodes = {}

local make_leveled_node = function(nodename, description)
	local def = minetest.registered_nodes[nodename]
	local new_groups
	if def.groups then
		new_groups = table.copy(def.groups)
	else
		new_groups = {}
	end
	new_groups.leveled_node = 1
	minetest.register_node(nodename.."_level", {
		description = description,
		tiles = def.tiles,
		groups = new_groups,
		drawtype = "nodebox",
		node_box = {
			type = "leveled",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
		},
		use_texture_alpha = def.use_texture_alpha,
		walkable = def.walkable,
		paramtype = "light",
		paramtype2 = "leveled",
		place_param2 = 32,
		sounds = def.sounds,

		-- Store name of original node
		_sf_unleveled_node_variant = nodename,
	})

	minetest.override_item(nodename, {
		-- Store name of leveled node in the original node
		_sf_leveled_node_variant = nodename.."_level"
	})
end
local make_sound_variant_node = function(nodename, description, reverb_sound)
	local def = table.copy(minetest.registered_nodes[nodename])
	def.sounds = reverb_sound
	def.description = description
	def._sf_unreverb = nodename
	if EDITOR and def.tiles and def.tiles[1] then
		if type(def.tiles[1]) == "string" then
			def.tiles[1] = "("..def.tiles[1] .. ")^sf_nodes_reverb_overlay.png"
		elseif type(def.tiles[1]) == "table" and def.tiles[1].name then
			def.tiles[1].name = "("..def.tiles[1].name .. ")^sf_nodes_reverb_overlay.png"
		end
	end
	minetest.register_node(nodename .. "_reverb", def)
	minetest.override_item(nodename, {
		_sf_reverb = nodename .. "_reverb",
	})
end

sf_nodes.update_plantlike_offset_node = function(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	if not def then
		return
	end
	local below = table.copy(pos)
	below.y = below.y - 1
	local node_below = minetest.get_node(below)

	local new_offset
	if minetest.get_item_group(node_below.name, "leveled_node") == 1 then
		local p2i = 64 - node_below.param2
		new_offset = math.floor(p2i / 4)
		new_offset = math.max(0, math.min(PLANTLIKE_OFFSET_LEVELS, new_offset))
	else
		new_offset = 0
	end

	local offset_group_val = minetest.get_item_group(node.name, "plantlike_offset")
	if offset_group_val > 0 then
		if new_offset > 0 then
			node.name = string.sub(node.name, 1, string.len(node.name) - 2) .. string.format("%02d", new_offset)
			minetest.set_node(pos, node)
		else
			node.name = def._sf_plantlike_base_node
			minetest.set_node(pos, node)
		end
	elseif offset_group_val < 0 then
		if new_offset > 0 then
			node.name = def._sf_plantlike_offset_nodename_prefix .. string.format("%02d", new_offset)
			minetest.set_node(pos, node)
		else
			if node_below.name == "air" then
				minetest.remove_node(pos)
				minetest.set_node(below, node)
			end
		end
	end
end


local make_plantlike_offset_nodes = function(nodename)
	local def = minetest.registered_nodes[nodename]
	for i=1, PLANTLIKE_OFFSET_LEVELS do
		local hue = -(i-1)*12
		local snum = string.format("%02d", i)
		local new_box = table.copy(def.selection_box)
		new_box.fixed[2] = -0.5 - (i/16)
		new_box.fixed[5] = new_box.fixed[5] - (i/16)
		minetest.register_node(nodename.."_offset_"..snum, {
			walkable = false,
			description = S("@1 (offset @2)", def.description, i),
			tiles = def.tiles,
			wield_image = def.tiles[1],
			inventory_image = "("..def.tiles[1]..")^(sf_nodes_offset_overlay.png^[hsl:"..hue..":0:0)",
			drawtype = "mesh",
			mesh = "sf_nodes_plantlike_offset_"..i..".obj",
			use_texture_alpha = "clip",
			paramtype = "light",
			groups = { editor_breakable = 1, plantlike_offset = i },
			selection_box = new_box,
			waving = 1,
			drop = nodename,
			_sf_plantlike_base_node = nodename,
			visual_scale = def.visual_scale,
		})
		local orig_def = minetest.registered_nodes[nodename]
		local groups = table.copy(orig_def.groups or {})
		groups.plantlike_offset = -1
		minetest.override_item(nodename, {
			_sf_plantlike_offset_nodename_prefix = nodename.."_offset_",
			groups = groups,
			on_construct = function(pos)
				sf_nodes.update_plantlike_offset_node(pos)
			end,
		})
	end
end

minetest.register_node("sf_nodes:dirt", {
	description = S("Dirt"),
	tiles = {{ name = "sf_nodes_dirt.png", align_style="world", scale=2 }},
	sounds = sf_sounds.node_sound_dirt_defaults(),
	groups = { editor_breakable = 1 },
})
make_leveled_node("sf_nodes:dirt", S("Leveled Dirt"))

minetest.register_node("sf_nodes:coarse_dirt", {
	description = S("Coarse Dirt"),
	tiles = {{ name = "sf_nodes_coarse_dirt.png", align_style="world", scale=2 }},
	sounds = sf_sounds.node_sound_dirt_defaults(),
	groups = { editor_breakable = 1 },
})
make_leveled_node("sf_nodes:coarse_dirt", S("Leveled Coarse Dirt"))


minetest.register_node("sf_nodes:grass_block", {
	description = S("Grass Block"),
	tiles = {
		{ name = "sf_nodes_grass_cover.png", align_style="world", scale=2 },
	},
	sounds = sf_sounds.node_sound_dirt_defaults(),
	groups = { editor_breakable = 1 },
})
make_leveled_node("sf_nodes:grass_block", S("Leveled Grass Block"))

minetest.register_node("sf_nodes:mud", {
	description = S("Mud"),
	tiles = { "sf_nodes_mud.png" },
	groups = { editor_breakable = 1, mud = 1 },
	sounds = sf_sounds.node_sound_mud_defaults(),
})
make_leveled_node("sf_nodes:mud", S("Leveled Mud"))


minetest.register_node("sf_nodes:snow", {
	description = S("Snow"),
	tiles = { "sf_nodes_snow.png" },
	groups = { editor_breakable = 1, snow = 1 },
	sounds = sf_sounds.node_sound_snow_defaults(),
})
make_leveled_node("sf_nodes:snow", S("Leveled Snow"))

minetest.register_node("sf_nodes:gravel", {
	description = S("Gravel"),
	tiles = { "sf_nodes_gravel.png" },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_gravel_defaults(),
})
make_leveled_node("sf_nodes:gravel", S("Leveled Gravel"))

minetest.register_node("sf_nodes:stone", {
	description = S("Stone"),
	tiles = { { name = "sf_nodes_stone.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_leveled_node("sf_nodes:stone", S("Leveled Stone"))
make_sound_variant_node("sf_nodes:stone", S("Reverb Stone"), sf_sounds.node_sound_stone_reverb_defaults())
make_sound_variant_node("sf_nodes:stone_level", S("Reverb Leveled Stone"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:stone_tile", {
	description = S("Stone Tile"),
	tiles = { { name = "sf_nodes_stone_tile.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_sound_variant_node("sf_nodes:stone_tile", S("Reverb Stone Tile"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:stone_tile_big", {
	description = S("Big Stone Tile"),
	tiles = {
		{ name = "sf_nodes_stone_tile_big.png", align_style = "world", scale = 2 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_sound_variant_node("sf_nodes:stone_tile_big", S("Reverb Big Stone Tile"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:stone_tile_huge", {
	description = S("Huge Stone Tile"),
	tiles = {
		{ name = "sf_nodes_stone_tile_huge.png", align_style = "world", scale = 2 },
		{ name = "sf_nodes_stone_tile_huge.png", align_style = "world", scale = 2 },
		{ name = "sf_nodes_stone_smooth.png", align_style = "world", scale = 2 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_sound_variant_node("sf_nodes:stone_tile_huge", S("Reverb Huge Stone Tile"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:stone_brick", {
	description = S("Stone Brick"),
	tiles = { { name = "sf_nodes_stone_brick.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_sound_variant_node("sf_nodes:stone_brick", S("Reverb Stone Brick"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:stone_smooth", {
	description = S("Smooth Stone"),
	tiles = { { name = "sf_nodes_stone_smooth.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_leveled_node("sf_nodes:stone_smooth", S("Leveled Smooth Stone"))
make_sound_variant_node("sf_nodes:stone_smooth", S("Reverb Smooth Stone"), sf_sounds.node_sound_stone_reverb_defaults())
make_sound_variant_node("sf_nodes:stone_smooth_level", S("Reverb Leveled Smooth Stone"), sf_sounds.node_sound_stone_reverb_defaults())

minetest.register_node("sf_nodes:white_stone", {
	description = S("White Stone"),
	tiles = { { name = "sf_nodes_white_stone.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_leveled_node("sf_nodes:white_stone", S("Leveled White Stone"))

minetest.register_node("sf_nodes:white_stone_tile", {
	description = S("White Stone Tile"),
	tiles = { { name = "sf_nodes_white_stone_tile.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
minetest.register_node("sf_nodes:white_stone_tile_big", {
	description = S("Big White Stone Tile"),
	tiles = {
		{ name = "sf_nodes_white_stone_tile_big.png", align_style = "world", scale = 2 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
minetest.register_node("sf_nodes:white_stone_brick", {
	description = S("White Stone Brick"),
	tiles = { { name = "sf_nodes_white_stone_brick.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
minetest.register_node("sf_nodes:white_stone_smooth", {
	description = S("Smooth White Stone"),
	tiles = { { name = "sf_nodes_white_stone_smooth.png", align_style = "world", scale = 2 } },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_leveled_node("sf_nodes:white_stone_smooth", S("Leveled Smooth White Stone"))



local pebbles = {
	1, 2, 3, 4, 5, 6, 7
}
for p=1, #pebbles do
	local size = pebbles[p]
	minetest.register_node("sf_nodes:pebble_"..size, {
		description = S("Pebble (size @1)", size),
		tiles = { { name = "sf_nodes_stone.png", align_style = "world", scale = 2 } },
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -size/16, -0.5, -size/16, size/16, (size/16)-0.5, size/16 }
		},
		groups = { editor_breakable = 1 },
		sounds = sf_sounds.node_sound_stone_defaults(),
	})
end

minetest.register_node("sf_nodes:pedestal", {
	description = S("Pedestal"),
	tiles = { "sf_nodes_pedestal_top.png", "sf_nodes_pedestal_side.png" },
	groups = { editor_breakable = 1 },
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, 6/16, -0.5, 0.5, 0.5, 0.5 }, -- plate
			{ -5/16, -7/16, -5/16, 5/16, 6/16, 5/16 }, -- body
			{ -0.5, -0.5, -0.5, 0.5, -7/16, 0.5 }, -- base
		},
	},
	sounds = sf_sounds.node_sound_stone_defaults(),
})

minetest.register_node("sf_nodes:concrete", {
	description = S("Concrete"),
	tiles = { "sf_nodes_concrete.png" },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})
make_leveled_node("sf_nodes:concrete", S("Leveled Concrete"))

local wconcrete_tiles
if EDITOR then
	wconcrete_tiles = { "sf_nodes_concrete.png^sf_nodes_weak_concrete_overlay.png" }
else
	wconcrete_tiles = { "sf_nodes_concrete.png" }
end
minetest.register_node("sf_nodes:weak_concrete", {
	description = S("Weak Concrete"),
	tiles = wconcrete_tiles,
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_stone_defaults(),
})

minetest.register_node("sf_nodes:tree", {
	description = S("Tree"),
	paramtype2 = "facedir",
	tiles = {
		"sf_nodes_tree_top.png",
		"sf_nodes_tree_top.png",
		"sf_nodes_tree.png",
	},
	groups = { editor_breakable = 1, tree = 1 },
	sounds = sf_sounds.node_sound_tree_defaults(0.9),
	on_place = function(itemstack, placer, pointed_thing)
		return minetest.rotate_and_place(itemstack, placer, pointed_thing, EDITOR, { force_facedir = true })
	end,
})

local small_tree_names = {
	[2] = NS("Tiny Tree"),
	[4] = NS("Mini Tree"),
	[6] = NS("Small Tree"),
}
for i=2, 6, 2 do
	minetest.register_node("sf_nodes:tree_small_"..i, {
		description = S(small_tree_names[i]),
		paramtype2 = "facedir",
		tiles = {
			"sf_nodes_tree_top_small_"..i..".png",
			"sf_nodes_tree_top_small_"..i..".png",
			"sf_nodes_tree_small_"..i..".png",
		},
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -i/16, -0.5, -i/16, i/16, 0.5, i/16 },
		},
		groups = { editor_breakable = 1, tree = 1, tree_small = i },
		sounds = sf_sounds.node_sound_tree_defaults(0.9),
		on_place = function(itemstack, placer, pointed_thing)
			return minetest.rotate_and_place(itemstack, placer, pointed_thing, EDITOR, { force_facedir = true })
		end,
	})
	minetest.register_node("sf_nodes:tree_small_"..i.."x", {
		description = S("@1 Extension", S(small_tree_names[i])),
		tiles = {
			"sf_nodes_tree_top_small_"..i..".png",
			"sf_nodes_tree_top_small_"..i..".png",
			"sf_nodes_tree_small_"..i..".png",
		},
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -i/16, -1.5+(1/128), -i/16, i/16, 0.5, i/16 },
		},
		groups = { editor_breakable = 1, tree = 1, tree_small = i, tree_small_extension = 1 },
		sounds = sf_sounds.node_sound_tree_defaults(0.9),
	})

end

minetest.register_node("sf_nodes:leaves", {
	description = S("Decidious Leaves"),
	drawtype = "allfaces_optional",
	paramtype = "light",
	tiles = { "sf_nodes_leaves.png" },
	groups = { editor_breakable = 1, leaves = 1 },
	sounds = sf_sounds.node_sound_leaves_defaults(),
})
minetest.register_node("sf_nodes:leaves_protrusion", {
	description = S("Protruding Decidious Leaves"),
	drawtype = "plantlike",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	tiles = { "sf_nodes_leaves_plantlike.png" },
	groups = { editor_breakable = 1, leaves_protrusion = 1 },
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 1/16, 0.5 },
	},
	visual_scale = 1.3,
	sounds = sf_sounds.node_sound_leaves_defaults(),
	walkable = false,
})



minetest.register_node("sf_nodes:conifer_needles", {
	description = S("Conifer Needles"),
	drawtype = "allfaces_optional",
	paramtype = "light",
	tiles = { "sf_nodes_conifer_needles.png" },
	groups = { editor_breakable = 1, leaves = 1 },
	sounds = sf_sounds.node_sound_leaves_defaults(),
})
minetest.register_node("sf_nodes:conifer_needles_protrusion", {
	description = S("Protruding Conifer Needles"),
	paramtype = "light",
	paramtype2 = "wallmounted",
	groups = { editor_breakable = 1, leaves_protrusion = 1 },
	tiles = { "sf_nodes_conifer_needles_plantlike.png^[multiply:"..PROTRUDING_LEAVES_MULTIPLY_COLOR  },
	drawtype = "plantlike",
	walkable = false,
	visual_scale = 1.2,
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
	},
})


minetest.register_node("sf_nodes:wood", {
	description = S("Wooden Planks"),
	tiles = { "sf_nodes_wood.png" },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(),
})
minetest.register_node("sf_nodes:plank", {
	description = S("Wooden Plank"),
	tiles = { "sf_nodes_wood_plank.png" },
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, 6/16, -0.5, 0.5, 0.5, 0.5 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(1.2),
})
minetest.register_node("sf_nodes:metal_plate", {
	description = S("Metal Plate"),
	tiles = { {name="sf_nodes_rusty_metal_soft.png", align_style="world", scale=2} },
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, 6/16, -0.5, 0.5, 0.5, 0.5 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})
minetest.register_node("sf_nodes:industrial_light", {
	description = S("Industrial Light"),
	tiles = { "sf_nodes_industrial_light.png" },
	paramtype = "light",
	light_source = 10,
	sunlight_propagates = true,
	drawtype = "nodebox",
	paramtype2 = "wallmounted",
	node_box = {
		type = "fixed",
		fixed = { -4/16, -0.5, -4/16, 4/16, 5/16, 4/16 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})
minetest.register_node("sf_nodes:metal", {
	description = S("Metal"),
	tiles = { {name="sf_nodes_rusty_metal_soft.png", align_style="world", scale=2} },
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})

minetest.register_node("sf_nodes:plank_small", {
	description = S("Small Wooden Plank"),
	tiles = { "sf_nodes_wood_plank_small.png" },
	paramtype = "light",
	sunlight_propagates = true,
	drawtype = "nodebox",
	paramtype2 = "4dir",
	node_box = {
		type = "fixed",
		fixed = { -0.5, 6/16, -2/16, 0.5, 0.5, 2/16 },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(1.4),
})

minetest.register_node("sf_nodes:chainlink", {
	description = S("Chainlink Fence"),
	tiles = {
		"sf_nodes_chainlink_side.png",
		"sf_nodes_chainlink_side.png",
		"sf_nodes_chainlink_side.png",
		"sf_nodes_chainlink_side.png",
		"sf_nodes_chainlink.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -CHAINLINK_LIMIT },
	},
	groups = { editor_breakable = 1 },
})

minetest.register_node("sf_nodes:railing", {
	description = S("Railing"),
	tiles = {
		"sf_nodes_rusty_metal.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {
			{ -5/16, -0.5, -0.5, -3/16, RAILING_HEIGHT-1/16, -RAILING_LIMIT }, -- left pole
			{ 3/16, -0.5, -0.5, 5/16, RAILING_HEIGHT-1/16, -RAILING_LIMIT }, -- right pole
			{ -0.5, RAILING_HEIGHT-1/16, -0.5, 0.5, RAILING_HEIGHT, -RAILING_LIMIT }, -- rail
		},
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})
minetest.register_node("sf_nodes:railing_corner", {
	description = S("Inner Railing Corner"),
	tiles = {
		"sf_nodes_rusty_metal.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {
			{ -5/16, -0.5, -0.5, -3/16, RAILING_HEIGHT-1/16, -RAILING_LIMIT }, -- left pole
			{ 3/16, -0.5, -0.5, 5/16, RAILING_HEIGHT-1/16, -RAILING_LIMIT }, -- right pole
			{ -0.5, -0.5, -5/16, -RAILING_LIMIT, RAILING_HEIGHT-1/16, -3/16 }, -- front pole
			{ -0.5, -0.5, 3/16, -RAILING_LIMIT, RAILING_HEIGHT-1/16, 5/16 }, -- back pole
			{ -0.5, RAILING_HEIGHT-1/16, -0.5, 0.5, RAILING_HEIGHT, -RAILING_LIMIT }, -- rail left-right
			{ -0.5, RAILING_HEIGHT-1/16, -RAILING_LIMIT, -RAILING_LIMIT, RAILING_HEIGHT, 0.5 } -- rail front-back
		},
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})
minetest.register_node("sf_nodes:railing_corner_outer", {
	description = S("Outer Railing Corner"),
	tiles = {
		"sf_nodes_rusty_metal.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, RAILING_HEIGHT-1/16, -0.5, -RAILING_LIMIT, RAILING_HEIGHT, -RAILING_LIMIT }, -- rail piece
		},
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_metal_defaults(),
})

minetest.register_node("sf_nodes:wood_wall", {
	description = S("Wooden Wall"),
	tiles = { { name = "sf_nodes_wood.png", align_style = "world" } },
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -WOOD_WALL_LIMIT },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(),
})
minetest.register_node("sf_nodes:wood_wall_corner_inner", {
	description = S("Inner Wooden Corner Wall"),
	tiles = { { name = "sf_nodes_wood.png", align_style = "world" } },
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	node_box = {
		type = "fixed",
		fixed = { { -0.5, -0.5, -0.5, -WOOD_WALL_LIMIT, 0.5, 0.5 },
			{ -WOOD_WALL_LIMIT, -0.5, -0.5, 0.5, 0.5, -WOOD_WALL_LIMIT }
		},
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(),
})
minetest.register_node("sf_nodes:wood_wall_corner_outer", {
	description = S("Outer Wooden Corner Wall"),
	tiles = { { name = "sf_nodes_wood.png", align_style = "world" } },
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	node_box = {
		type = "fixed",
		fixed = { { WOOD_WALL_LIMIT, -0.5, -0.5, 0.5, 0.5, -WOOD_WALL_LIMIT } },
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(),
})

minetest.register_node("sf_nodes:wood_table2_piece", {
	description = S("Table Piece"),
	tiles = { { name = "sf_nodes_wood.png", align_style = "world" } },
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, TABLE_PLATE_LIMIT, -0.5, 0.5, 0.5, 0.5 }, -- plate
			{ -0.5, -0.5, -0.5, -TABLE_LEG_LIMIT, TABLE_PLATE_LIMIT, -TABLE_LEG_LIMIT }, -- leg 1
			{ -0.5, -0.5, TABLE_LEG_LIMIT, -TABLE_LEG_LIMIT, TABLE_PLATE_LIMIT, 0.5 }, -- leg 2
		},
	},
	groups = { editor_breakable = 1 },
	sounds = sf_sounds.node_sound_wood_defaults(),
})


local darkness_pointable, darkness_drawtype, darkness_tiles
if EDITOR then
	darkness_pointable = true
	darkness_drawtype = "allfaces"
	darkness_tiles = { "sf_nodes_darkness.png" }
else
	darkness_pointable = false
	darkness_drawtype = "airlike"
	darkness_tiles = nil
end

minetest.register_node("sf_nodes:darkness", {
	description = S("Darkness"),
	pointable = darkness_pointable,
	walkable = false,
	drawtype = darkness_drawtype,
	tiles = darkness_tiles,
	paramtype = "light",
	wield_image = "sf_nodes_darkness.png",
	inventory_image = "sf_nodes_darkness.png",
	groups = { editor_breakable = 1 },
})

local liquid_pointable
if EDITOR then
	liquid_pointable = true
else
	liquid_pointable = false
end

local make_liquid_node = function(nodename, tile, description, description_flowing, description_puddle, post_effect_color)
	minetest.register_node(nodename, {
		description = description,
		pointable = liquid_pointable,
		walkable = false,
		tiles = { tile },
		post_effect_color = post_effect_color,
		post_effect_color_shaded = true,
		drawtype = "liquid",
		paramtype = "light",
		use_texture_alpha = "blend",
		sounds = sf_sounds.node_sound_water_defaults(),
		liquid_move_physics = true,
		move_resistance = 1,
		groups = { editor_breakable = 1 },
		liquid_alternative_source = nodename,
		liquid_alternative_flowing = nodename.."_flowing",
		liquid_range = 2,
	})
	minetest.register_node(nodename.."_flowing", {
		description = description_flowing,
		pointable = liquid_pointable,
		walkable = false,
		tiles = { tile },
		special_tiles = {
			{ name = tile, backface_culling = false },
			{ name = tile, backface_culling = false },
		},
		post_effect_color = post_effect_color,
		post_effect_color_shaded = true,
		drawtype = "flowingliquid",
		paramtype = "light",
		use_texture_alpha = "blend",
		sounds = sf_sounds.node_sound_water_defaults(),
		liquid_move_physics = true,
		move_resistance = 1,
		groups = { editor_breakable = 1 },
		liquid_alternative_source = nodename,
		liquid_alternative_flowing = nodename.."_flowing",
		liquid_range = 2,
	})



	local def = minetest.registered_nodes[nodename]
	minetest.register_node(nodename.."_puddle", {
		description = description_puddle,
		pointable = liquid_pointable,
		walkable = false,
		tiles = { tile, "blank.png" },
		post_effect_color = post_effect_color,
		post_effect_color_shaded = true,
		groups = { editor_breakable = 1, leveled_node = 1, puddle = 1 },
		drawtype = "nodebox",
		node_box = {
			type = "leveled",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
		},
		use_texture_alpha = "blend",
		walkable = false,
		paramtype = "light",
		paramtype2 = "leveled",
		place_param2 = 32,
		sounds = sf_sounds.node_sound_puddle_defaults(),
		liquid_move_physics = false,
		move_resistance = 0,
	})
end

make_liquid_node("sf_nodes:water", "sf_nodes_water.png", S("Water"), S("Flowing Water"), S("Water Puddle"), {r=45,g=106,b=183,a=64})
make_liquid_node("sf_nodes:dirty_water", "sf_nodes_dirty_water.png", S("Dirty Water"), S("Flowing Dirty Water"), S("Dirty Water Puddle"), {r=199,g=156,b=107,a=107})

-- HACK: This is a special mud with puddle footstep sounds.
-- It may only be placed below puddle nodes because the puddle nodes
-- themselves fail to play the puddle sound when placed above a solid node.
minetest.register_node("sf_nodes:puddle_mud", {
	description = S("Puddle Mud"),
	tiles = { "sf_nodes_puddle_mud.png" },
	groups = { editor_breakable = 1, mud = 2 },
	sounds = sf_sounds.node_sound_puddle_defaults(),
})

minetest.register_node("sf_nodes:torch_floor", {
	description = S("Torch (floor)"),
	tiles = {
		"sf_nodes_torch_floor_top.png",
		"sf_nodes_torch_floor_bottom.png",
		"sf_nodes_torch_floor_side.png",
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -1/16, -0.5, -1/16, 1/16, 0, 1/16 }, -- stick
		},
	},
	light_source = TORCH_LIGHT,
	groups = { editor_breakable = 1, torch = 1 },
	walkable = false,
})
minetest.register_node("sf_nodes:torch_wall", {
	description = S("Torch (wall)"),
	tiles = {
		"sf_nodes_torch_wall_top.png",
		"sf_nodes_torch_wall_bottom.png",
		"sf_nodes_torch_wall_side.png",
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -1/16, 0, 5/16, 1/16, 1/16, 0.5 }, -- holder 1
			{ -1/16, -3/16, 5/16, 1/16, -2/16, 0.5 }, -- holder 2
			{ -1/16, -4/16, 3/16, 1/16, 4/16, 5/16 }, -- stick
		},
	},
	light_source = TORCH_LIGHT,
	groups = { editor_breakable = 1, torch = 1 },
	walkable = false,
})

minetest.register_node("sf_nodes:ladder", {
	description = S("Wooden Ladder"),
	tiles = { "sf_nodes_ladder_top.png",
		"sf_nodes_ladder_bottom.png",
		"sf_nodes_ladder_side.png",
		"sf_nodes_ladder_side.png",
		"sf_nodes_ladder.png",
		"sf_nodes_ladder.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = "clip",
	paramtype2 = "4dir",
	walkable = false,
	climbable = true,
	groups = { editor_breakable = 1 },
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, 6/16, -6/16, 0.5, 0.5 }, -- left stick
			{ 6/16, -0.5, 6/16, 0.5, 0.5, 0.5 }, -- right stick
			{ -6/16, 5/16, 6/16, 6/16, 7/16, 0.5 }, -- rung 1
			{ -6/16, 1/16, 6/16, 6/16, 3/16, 0.5 }, -- rung 2
			{ -6/16, -3/16, 6/16, 6/16, -1/16, 0.5 }, -- rung 3
			{ -6/16, -7/16, 6/16, 6/16, -5/16, 0.5 }, -- rung 4
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, 6/16, 0.5, 0.5, 0.5 },
	},
	sounds = sf_sounds.node_sound_wood_defaults(1.4),
})
minetest.register_node("sf_nodes:metal_ladder", {
	description = S("Metal Ladder"),
	tiles = { "sf_nodes_metal_ladder_top.png",
		"sf_nodes_metal_ladder_bottom.png",
		"sf_nodes_metal_ladder_side.png",
		"sf_nodes_metal_ladder_side.png",
		"sf_nodes_metal_ladder.png",
		"sf_nodes_metal_ladder.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = "clip",
	paramtype2 = "4dir",
	walkable = false,
	climbable = true,
	groups = { editor_breakable = 1 },
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, 6/16, -6/16, 0.5, 0.5 }, -- left stick
			{ 6/16, -0.5, 6/16, 0.5, 0.5, 0.5 }, -- right stick
			{ -6/16, 5/16, 6/16, 6/16, 7/16, 0.5 }, -- rung 1
			{ -6/16, 1/16, 6/16, 6/16, 3/16, 0.5 }, -- rung 2
			{ -6/16, -3/16, 6/16, 6/16, -1/16, 0.5 }, -- rung 3
			{ -6/16, -7/16, 6/16, 6/16, -5/16, 0.5 }, -- rung 4
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, 6/16, 0.5, 0.5, 0.5 },
	},
	sounds = sf_sounds.node_sound_metal_defaults(1.4),
})

minetest.register_node("sf_nodes:metal_ladder_x", {
	description = S("Metal Ladder Extension"),
	tiles = { "sf_nodes_metal_ladder_top.png",
		"sf_nodes_metal_ladder_bottom.png",
		"sf_nodes_metal_ladder_side.png",
		"sf_nodes_metal_ladder_side.png",
		"sf_nodes_metal_ladder.png",
		"sf_nodes_metal_ladder.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = "clip",
	paramtype2 = "4dir",
	walkable = false,
	climbable = true,
	groups = { editor_breakable = 1 },
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -1.5, 6/16, -6/16, 0.5, 0.5 }, -- left stick
			{ 6/16, -1.5, 6/16, 0.5, 0.5, 0.5 }, -- right stick
			{ -6/16, 5/16, 6/16, 6/16, 7/16, 0.5 }, -- rung 1
			{ -6/16, 1/16, 6/16, 6/16, 3/16, 0.5 }, -- rung 2
			{ -6/16, -3/16, 6/16, 6/16, -1/16, 0.5 }, -- rung 3
			{ -6/16, -7/16, 6/16, 6/16, -5/16, 0.5 }, -- rung 4

			{ -6/16, -9/16, 6/16, 6/16, -11/16, 0.5 }, -- rung 5
			{ -6/16, -13/16, 6/16, 6/16, -15/16, 0.5 }, -- rung 5
			{ -6/16, -17/16, 6/16, 6/16, -19/16, 0.5 }, -- rung 5
			{ -6/16, -21/16, 6/16, 6/16, -23/16, 0.5 }, -- rung 5
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -1.5, 6/16, 0.5, 0.5, 0.5 },
	},
	sounds = sf_sounds.node_sound_metal_defaults(1.4),
})

minetest.register_node("sf_nodes:fern", {
	walkable = false,
	description = S("Fern"),
	tiles = { "sf_nodes_fern.png" },
	drawtype = "mesh",
	mesh = "sf_nodes_plantlike.obj",
	use_texture_alpha = "clip",
	paramtype = "light",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -0.5, -6/16, 6/16, 0.5, 6/16 },
	},
	waving = 1,
})
make_plantlike_offset_nodes("sf_nodes:fern")

minetest.register_node("sf_nodes:grass", {
	walkable = false,
	description = S("Small Grass"),
	tiles = { "sf_nodes_grass.png" },
	drawtype = "mesh",
	mesh = "sf_nodes_plantlike.obj",
	use_texture_alpha = "clip",
	paramtype = "light",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -0.5, -6/16, 6/16, 0, 6/16 },
	},
	waving = 1,
})
make_plantlike_offset_nodes("sf_nodes:grass")

minetest.register_node("sf_nodes:grass_2", {
	walkable = false,
	description = S("Medium Grass"),
	tiles = { "sf_nodes_grass_2.png" },
	drawtype = "mesh",
	mesh = "sf_nodes_plantlike.obj",
	use_texture_alpha = "clip",
	paramtype = "light",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -0.5, -6/16, 6/16, 0, 6/16 },
	},
	waving = 1,
	visual_scale = 1.1,
})
make_plantlike_offset_nodes("sf_nodes:grass_2")

minetest.register_node("sf_nodes:grass_3", {
	walkable = false,
	description = S("Tall Grass"),
	tiles = { "sf_nodes_grass_3.png" },
	drawtype = "mesh",
	mesh = "sf_nodes_plantlike.obj",
	use_texture_alpha = "clip",
	paramtype = "light",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "fixed",
		fixed = { -7/16, -0.5, -7/16, 7/16, 0.5, 7/16 },
	},
	waving = 1,
	visual_scale = 1.2,
})
make_plantlike_offset_nodes("sf_nodes:grass_3")


minetest.register_node("sf_nodes:ivy", {
	walkable = false,
	description = S("Ivy"),
	tiles = { "sf_nodes_ivy.png" },
	drawtype = "signlike",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "wallmounted",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
	},
})
minetest.register_node("sf_nodes:ivy_sprouting", {
	walkable = false,
	description = S("Sprouting Ivy"),
	tiles = { "sf_nodes_ivy_sprouting.png" },
	drawtype = "signlike",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "wallmounted",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
	},
})
minetest.register_node("sf_nodes:ivy_root", {
	walkable = false,
	description = S("Ivy Root"),
	tiles = { "sf_nodes_ivy_root.png" },
	drawtype = "signlike",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	groups = { editor_breakable = 1 },
	selection_box = {
		type = "wallmounted",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
	},
})



local spikeplant_weak_tiles
if EDITOR then
	spikeplant_weak_tiles = { "sf_nodes_spikeplant_weak.png" }
else
	spikeplant_weak_tiles = { "sf_nodes_spikeplant.png" }
end

-- Same as normal shadow bush, except it is supposed to be destroyed
-- by a special event at the shadow bush barrier in the Dead Forest.
minetest.register_node("sf_nodes:spikeplant_weak", {
	description = S("Weak Shadow Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1, leaves = 1, disable_jump = 1 },
	drawtype = "allfaces_optional",
	tiles = spikeplant_weak_tiles,
	move_resistance = 1,
	damage_per_second = 1,
	walkable = true,
	collision_box = {
		type = "fixed",
		fixed = {-6/16, -0.5, -6/16, 6/16, 6/16, 6/16},
	},
	sounds = sf_sounds.node_sound_leaves_defaults(0.8),
})

minetest.register_node("sf_nodes:spikeplant", {
	description = S("Shadow Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1, leaves = 1, disable_jump = 1 },
	tiles = { "sf_nodes_spikeplant.png" },
	drawtype = "allfaces_optional",
	move_resistance = 1,
	damage_per_second = 1,
	walkable = true,
	collision_box = {
		type = "fixed",
		fixed = {-6/16, -0.5, -6/16, 6/16, 6/16, 6/16},
	},
	sounds = sf_sounds.node_sound_leaves_defaults(0.8),
})
minetest.register_node("sf_nodes:spikeplant_inner", {
	description = S("Branchy Shadow Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1, leaves = 1, disable_jump = 1 },
	tiles = { "sf_nodes_spikeplant_inner.png" },
	drawtype = "allfaces_optional",
	move_resistance = 2,
	damage_per_second = 2,
	walkable = true,
	collision_box = {
		type = "fixed",
		fixed = {-6/16, -0.5, -6/16, 6/16, 6/16, 6/16},
	},
	sounds = sf_sounds.node_sound_leaves_defaults(0.8),
})
minetest.register_node("sf_nodes:spikeplant_protrusion", {
	description = S("Protuding Shadow Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1, leaves_protrusion = 1, disable_jump = 1 },
	tiles = { "sf_nodes_spikeplant_plantlike.png" },
	drawtype = "plantlike",
	paramtype2 = "wallmounted",
	move_resistance = 1,
	walkable = false,
	damage_per_second = 1,
	sounds = sf_sounds.node_sound_leaves_defaults(0.8),
})
minetest.register_node("sf_nodes:spikeplant_angled", {
	description = S("Angled Shadow Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1 },
	tiles = { "sf_nodes_spikeplant_plantlike.png" },
	drawtype = "plantlike",
	paramtype2 = "meshoptions",
	move_resistance = 1,
	walkable = false,
	damage_per_second = 1,
	place_param2 = 4,
	sounds = sf_sounds.node_sound_leaves_defaults(0.8),
})

minetest.register_node("sf_nodes:bush", {
	description = S("Bush"),
	paramtype = "light",
	groups = { editor_breakable = 1, leaves = 1 },
	tiles = { "sf_nodes_bush.png" },
	drawtype = "allfaces_optional",
	collision_box = {
		type = "fixed",
		fixed = {-6/16, -6/16, -6/16, 6/16, 6/16, 6/16},
	},
	sounds = sf_sounds.node_sound_leaves_defaults(1.1),
})
minetest.register_node("sf_nodes:bush_protrusion", {
	description = S("Protruding Bush"),
	paramtype = "light",
	paramtype2 = "wallmounted",
	groups = { editor_breakable = 1, leaves_protrusion = 1 },
	tiles = { "sf_nodes_bush_plantlike.png" },
	drawtype = "plantlike",
	walkable = false,
	visual_scale = 1.2,
	selection_box = {
		type = "fixed",
		fixed = {-6/16, -0.5, -6/16, 6/16, 0, 6/16 },
	},
	sounds = sf_sounds.node_sound_leaves_defaults(1.1),
})


minetest.register_node("sf_nodes:light_crystal", {
	description = S("Light Crystal"),
	paramtype = "light",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX,
	drawtype = "nodebox",
	groups = { editor_breakable = 1, dig_immediate = 3 },
	node_box = {
		type = "fixed",
		fixed = {
			{ -2/16, -0.5, -2/16, 2/16, 2/16, 2/16 }, -- center piece
			{ -4/16, -0.5, -1/16, 4/16, -2/16, 1/16 }, -- low piece 1
			{ -1/16, -0.5, -4/16, 1/16, -2/16, 4/16 }, -- low piece 2
			{ -3/16, -0.5, -3/16, 3/16, -7/16, 3/16 }, -- flatty
		},
	},
	tiles = {{ name = "sf_nodes_light_crystal.png" }},
	use_texture_alpha = "blend",
	sounds = {
		dug = { name = "sf_nodes_crystal_collect", gain = 0.25 },
		place = { name = "sf_nodes_crystal_collect", gain = 0.35, pitch = 0.9 },
	},
	drop = "",
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if EDITOR then
			return
		end
		local count = sf_resources.get_resource_count(digger, "sf_resources:light_crystal")
		count = count + 1
		sf_resources.set_resource_count(digger, "sf_resources:light_crystal", count)
	end,
})

minetest.register_node("sf_nodes:campfire_off", {
	description = S("Campfire"),
	drawtype = "mesh",
	mesh = "sf_nodes_campfire.obj",
	paramtype = "light",
	groups = { editor_breakable = 1, campfire = 1 },
	tiles = {
		"blank.png",
		"blank.png",
		{ name = "sf_nodes_campfire_top.png", backface_culling = true },
		{ name = "sf_nodes_campfire_side.png", backface_culling = true },
	},
	use_texture_alpha = "clip",
	walkable = false,
	selection_box = { type = "fixed", fixed = { -6/16, -0.5, -6/16, 6/16, -6/16, 6/16 }},
	sounds = sf_sounds.node_sound_dirt_defaults(),
})

minetest.register_node("sf_nodes:campfire_on", {
	description = S("Campfire with Fire"),
	drawtype = "mesh",
	mesh = "sf_nodes_campfire.obj",
	paramtype = "light",
	groups = { editor_breakable = 1, campfire = 2 },
	tiles = {
		{ name="sf_nodes_campfire_fire_anim.png", animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.49 } },
		{ name="sf_nodes_campfire_fire_anim.png", animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.5 } },
		{ name = "sf_nodes_campfire_top.png", backface_culling = true },
		{ name = "sf_nodes_campfire_side.png", backface_culling = true },
	},
	use_texture_alpha = "clip",
	walkable = false,
	light_source = minetest.LIGHT_MAX,
	selection_box = { type = "fixed", fixed = { -6/16, -0.5, -6/16, 6/16, -6/16, 6/16 }},
	sounds = sf_sounds.node_sound_dirt_defaults(),
	damage_per_second = 1,
	on_rightclick = function(pos, node, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		sf_upgrade.show_upgrade_formspec(clicker)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Campfire (rightclick to upgrade)"))
	end,
})

-- Warning: This node is very bouncy. Always put another solid node
-- above it (like an invisible barrier)
-- to make sure the player can't bounce into space!
minetest.register_node("sf_nodes:shadow_barrier", {
	description = S("Shadow Barrier"),
	drawtype = "glasslike",
	paramtype = "light",
	-- Bounces the player heavily off when walking into it
	groups = { editor_breakable = 1, bouncy = 225 },
	tiles = {
		{ name = "sf_nodes_shadow_barrier.png", backface_culling = true, animation = { type = "vertical_frames", aspect_w = 64, aspect_h = 64, length = 4, }},
	},
	use_texture_alpha = "blend",
	walkable = true,
})
local ib_pointable, ib_drawtype, ib_tiles
if EDITOR then
	ib_pointable = true
	ib_drawtype = "allfaces"
	ib_tiles = { "sf_nodes_invisible_barrier.png" }
else
	ib_pointable = false
	ib_drawtype = "airlike"
	ib_tiles = nil
end
minetest.register_node("sf_nodes:invisible_barrier", {
	description = S("Invisible Barrier"),
	drawtype = ib_drawtype,
	tiles = ib_tiles,
	wield_image = "sf_nodes_invisible_barrier.png",
	inventory_image = "sf_nodes_invisible_barrier.png",
	paramtype = "light",
	sunlight_propagates = true,
	groups = { editor_breakable = 1 },
	walkable = true,
	pointable = ib_pointable,
})

local ki_pointable, ki_drawtype, ki_tiles, ki_dmg
if EDITOR then
	ki_pointable = true
	ki_drawtype = "allfaces"
	ki_tiles = { "sf_nodes_killer.png" }
	ki_dmg = 0
else
	ki_pointable = false
	ki_drawtype = "airlike"
	ki_tiles = nil
	ki_dmg = 20
end
minetest.register_node("sf_nodes:killer", {
	description = S("Killer"),
	drawtype = ki_drawtype,
	tiles = ki_tiles,
	wield_image = "sf_nodes_killer.png",
	inventory_image = "sf_nodes_killer.png",
	paramtype = "light",
	visual_scale = 0.5,
	sunlight_propagates = true,
	groups = { editor_breakable = 1 },
	walkable = false,
	pointable = ki_pointable,
	damage_per_second = ki_dmg,
})

