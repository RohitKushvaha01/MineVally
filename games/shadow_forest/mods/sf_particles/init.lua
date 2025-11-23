local S = minetest.get_translator("sf_particles")
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local register_particle_emitter = function(id, def)
	local drawtype, pointable
	if EDITOR then
		drawtype = "allfaces"
		pointable = true
	else
		drawtype = "airlike"
		pointable = false
	end
	minetest.register_node("sf_particles:emitter_"..id, {
		description = def.description,
		pointable = pointable,
		drawtype = drawtype,
		visual_scale = 0.5,
		paramtype = "light",
		sunlight_propagates = true,
		tiles = {"sf_particles_emitter_base.png^"..def.texture.."^sf_particles_emitter_overlay.png"},
		walkable = false,
		groups = { particle_emitter = 1, editor_breakable = 1 },
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(0)
		end,
		on_timer = function(pos)
			if not EDITOR then
				local spawnerdef = table.copy(def.spawner)
				if def.pos_offset_min then
					spawnerdef.pos = {
						min = vector.add(pos, def.pos_offset_min),
						max = vector.add(pos, def.pos_offset_max),
					}
				else
					spawnerdef.pos = pos
				end
				minetest.add_particlespawner(spawnerdef)
			end
			local timer = minetest.get_node_timer(pos)
			timer:start(def.spawntimer)
		end,
	})
end

register_particle_emitter("smoke", {
	description = S("Smoke Emitter"),
	texture = "sf_particles_smoke.png",
	spawntimer = 5,
	pos_offset_min = vector.new(-1.2,0,-1.2),
	pos_offset_max = vector.new(1.2,0,1.2),
	spawner = {
		amount = 3,
		time = 5,
		exptime = {
			min = 30,
			max = 50,
		},
		size = {
			min = 9,
			max = 18,
		},
		vel = {
			min = vector.new(-0.01, 0.2, -0.01),
			max = vector.new(0.01, 0.5, 0.01),
		},
		texpool = {
			{ name = "sf_particles_smoke.png", alpha_tween = { 1, 0, start = 0.75 } },
			{ name = "sf_particles_smoke_med.png", alpha_tween = { 1, 0, start = 0.75 } },
			{ name = "sf_particles_smoke_dense.png", alpha_tween = { 1, 0, start = 0.75 } },
		},
	},
})

minetest.register_lbm({
	label = "Restart particle emitter node timers",
	name = "sf_particles:restart_emitter_node_timers",
	nodenames = {"group:particle_emitter"},
	run_at_every_load = true,
	action = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(0)
	end,
})

