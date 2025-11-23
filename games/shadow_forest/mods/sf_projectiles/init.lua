sf_projectiles = {}

sf_projectiles.add_projectile = function(pos, projectilename, velocity, shooter, punch_tool_properties)
	local obj = minetest.add_entity(pos, projectilename)
	if obj then
		local lua = obj:get_luaentity()
		if shooter then
			lua._shooter = shooter:get_player_name()
		end
		obj:set_velocity(velocity)
		if punch_tool_properties then
			lua._punch_tool_properties = punch_tool_properties
		end
		return obj
	end
end

local PROJECTILE_LIFE_TIME = 30

local LIGHT_GLOW = 12

local light_move_particles = function(ent)
	minetest.add_particlespawner({
		amount = 8,
		time = 0.01,
		exptime = {
			min = 0.3,
			max = 0.6,
		},
		size = 1.1,
		pos = ent.object:get_pos(),
		vel = {
			min = vector.new(-2, -2, -2),
			max = vector.new(2, 2, 2),
		},
		drag = vector.new(8, 8, 8),
		texture = {
			name = "sf_particles_light.png",
			scale_tween = { 1, 0, start = 0.5 },
			alpha_tween = { 1, 0, start = 0.5 },
		},
		glow = LIGHT_GLOW,
	})
end
local light_impact_particles = function(ent)
	minetest.add_particlespawner({
		amount = 16,
		time = 0.05,
		exptime = {
			min = 1,
			max = 2,
		},
		size = 1.75,
		pos = ent.object:get_pos(),
		vel = {
			min = vector.new(-5, -5, -5),
			max = vector.new(5, 5, 5),
		},
		drag = vector.new(7, 7, 7),
		texture = {
			name = "sf_particles_light.png",
			scale_tween = { 1, 0, start = 0.5 },
			alpha_tween = { 1, 0, start = 0.5 },
		},
		glow = LIGHT_GLOW,
	})
end


local shadow_move_particles = function(ent)
	local pos = ent.object:get_pos()
	pos = vector.add(pos, vector.new(0, 0.1, 0))
	minetest.add_particlespawner({
		amount = 8,
		time = 0.01,
		exptime = {
			min = 0.3,
			max = 0.6,
		},
		size = 1.1,
		pos = pos,
		vel = {
			min = vector.new(-2, -2, -2),
			max = vector.new(2, 2, 2),
		},
		drag = vector.new(8, 8, 8),
		texture = {
			name = "sf_particles_shadow.png",
			scale_tween = { 1, 0, start = 0.5 },
			alpha_tween = { 1, 0, start = 0.5 },
		},
		glow = LIGHT_GLOW,
	})
end
local shadow_impact_particles = function(ent)
	minetest.add_particlespawner({
		amount = 12,
		time = 0.05,
		exptime = {
			min = 0.7,
			max = 1.4,
		},
		size = 1,
		pos = ent.object:get_pos(),
		vel = {
			min = vector.new(-2, -2, -2),
			max = vector.new(2, 2, 2),
		},
		drag = vector.new(5, 5, 5),
		texture = {
			name = "sf_particles_shadow_poof_anim.png",
		},
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = -1,
		},
	})
end

local function register_simple_projectile(id, initial_properties, def)
	minetest.register_entity("sf_projectiles:"..id, {
		initial_properties = initial_properties,

		_life_timer = 0,
		_shooter = nil,
		_punch_tool_properties = nil,
		get_staticdata = function(self)
			local data = {
				punch_tool_properties = self._punch_tool_properties,
				shooter = self._shooter,
				life_timer = self._life_timer,
			}
			local sdata = minetest.serialize(data)
			return sdata
		end,
		on_activate = function(self, staticdata)
			local ddata = minetest.deserialize(staticdata)
			if type(ddata) == "table" then
				self._punch_tool_properties = ddata.punch_tool_properties
				self._shooter = ddata.shooter
				self._life_timer = ddata.life_timer
			end
			self.object:set_armor_groups(def.armor)
		end,
		on_step = function(self, dtime, moveresult)
			local opos = self.object:get_pos()
			if def.move_particles_func then
				def.move_particles_func(self)
			end
			if moveresult.collides then
				for c=1, #moveresult.collisions do
					local collision = moveresult.collisions[c]
					if collision.type == "object" then
						local armor = collision.object:get_armor_groups()
						local dir = vector.direction(opos, collision.object:get_pos())
						if self._punch_tool_properties then
							collision.object:punch(self.object, math.huge, self._punch_tool_properties, dir)
						else
							self.object:remove()
							minetest.log("warning", "[sf_projectiles] Projectile collided with object without _punch_tool_properties!")
							return
						end
						if def.impact_particles_func then
							def.impact_particles_func(self)
						end
						if def.impact_sound then
							minetest.sound_play(def.impact_sound, {pos=opos, max_hear_distance=12}, true)
						end
						if self._shooter then
							-- Play notify sound to shooter when hitting a shadow mob
							if armor and armor.shadow_physical ~= nil and armor.shadow_physical ~= 0  then
								local shooter = minetest.get_player_by_name(self._shooter)
								-- No sound for self-hit
								if shooter and not (collision.object:is_player() and collision.object:get_player_name() == self._shooter) then
									minetest.sound_play({name="sf_projectiles_hit_ranged", gain=0.8}, {to_player=self._shooter}, true)
								end
							end
						end
						self.object:remove()
						return
					elseif collision.type == "node" then
						if def.impact_particles_func then
							def.impact_particles_func(self)
						end
						if def.impact_sound then
							minetest.sound_play(def.impact_sound, {pos=opos}, true)
						end
						self.object:remove()
						return
					end
				end
			end
			self._life_timer = self._life_timer + dtime
			if self._life_timer > PROJECTILE_LIFE_TIME then
				self.object:remove()
				return
			end
		end,
	})
end

register_simple_projectile("shadow",
	{
		hp_max = 1,
		textures = {"sf_projectiles_shadow.png"},
		pointable = true,
		is_visible = true,
		visual = "mesh",
		mesh = "sf_projectiles_shadow.obj",
		automatic_rotate = 9,
		physical = true,
		collides_with_objects = true,
		textures = {
			"sf_projectiles_shadow.png",
		},
		collisionbox = { -0.125, 0, -0.125, 0.125, 0.25, 0.125 },
		visual_size = { x = 2.5, y = 2.5, z = 2.5 },
	},
	{
		impact_particles_func=shadow_impact_particles,
		move_particles_func=shadow_move_particles,
		impact_sound={name="sf_projectiles_shadow_impact", gain=0.1},
		-- Special armor group to differenciate the shadow projectile
		-- from shadow mobs (which use shadow_physical)
		armor={shadow_special=100},
	}
)
register_simple_projectile("light",
	{
		hp_max = 1,
		pointable = false,
		visual = "sprite",
		is_visible = true,
		textures = {
			"blank.png",
			"blank.png",
		},
		physical = true,
		collides_with_objects = true,
		collisionbox = { -0.25, 0, -0.25, 0.25, 0.5, 0.25 },
		visual_size = { x = 0.5, y = 0.5, z = 0.5 },
	},
	{
		impact_particles_func=light_impact_particles,
		move_particles_func=light_move_particles,
		impact_sound={name="sf_projectiles_light_impact", gain=0.2},
		armor={light=100},
	}
)
