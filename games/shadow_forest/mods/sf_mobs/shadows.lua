local S = minetest.get_translator("sf_mobs")

--[[ Armor groups used by the mobs:
	shadow_physical: Normal shadow mob
	shadow_special: Shadow projectile
]]

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local GRAVITY = tonumber(minetest.settings:get("movement_gravity")) or 9.81

local CRAWLER_AGGRESSION_DISTANCE = 16
local CRAWLER_DAMAGE = 1
local CRAWLER_DAMAGE_TIMER = 1
local CRAWLER_SPEED = 2
local CRAWLER_TOOL_PROPERTIES = {
	full_punch_interval = 0.0,
	damage_groups = { fleshy = 1 },
}
local CRAWLER_ATTACK_RANGE = 2
local CRAWLER_REACHED_RANGE = 0.15

local CRAWLERSPAWNER_SPAWN_TIMER = 8
local CRAWLERSPAWNER_MAX_COUNT = 13
local CRAWLERSPAWNER_SPAWN_COUNT = 3
local CRAWLERSPAWNER_CHECK_RANGE = 24

local FLYERSHOOTER_ATTACK_TIMER = 1.5
local FLYERSHOOTER_ATTACK_RANGE = 32
local FLYERSHOOTER_PROJECTILE_SPEED = 10

local SHADOW_ORB_ATTACK_TIMER = 0.5
local SHADOW_ORB_ATTACK_RANGE = 32
local SHADOW_ORB_PROJECTILE_SPEED = 15
local SHADOW_ORB_SPAWN_TIMER = 5
local SHADOW_ORB_SPAWN_CHECK_RANGE = 30
local SHADOW_ORB_SPAWN_COUNT = 4
local SHADOW_ORB_SPAWN_MAX_COUNT = 10
local SHADOW_ORB_FRAGMENTS = 80
local SHADOW_ORB_DEATH_CHECK_RANGE = 40

local SHADOW_PROJECTILE_TOOL_PROPERTIES = {
	full_punch_interval = 0.0,
	damage_groups = { fleshy = 1, light = 1 },
}

local SHADOW_FRAGMENTS_DROP_MIN = 1
local SHADOW_FRAGMENTS_DROP_MAX = 3

local DAMAGE_TEXTURE_MODIFIER = "^[hsl:0:0:80"
local DAMAGE_SOUND = { name = "sf_mobs_shadow_damage", gain = 0.8 }
local DEATH_SOUND = { name = "sf_mobs_shadow_death", gain = 1.0 }

local death_particles = function(mob)
	minetest.add_particlespawner({
		amount = 16,
		time = 0.05,
		exptime = {
			min = 1,
			max = 2,
		},
		size = 1.5,
		pos = mob.object:get_pos(),
		vel = {
			min = vector.new(-3, -3, -3),
			max = vector.new(3, 3, 3),
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

local spawn_particles = function(pos)
	local pos_offset = vector.new(0.2, 0.2, 0.2)
	minetest.add_particlespawner({
		amount = 16,
		time = 0.05,
		exptime = {
			min = 1,
			max = 2,
		},
		size = 1.5,
		pos = {
			min = vector.subtract(pos, pos_offset),
			max = vector.add(pos, pos_offset),
		},
		vel = {
			min = vector.new(0, 1, 0),
			max = vector.new(0, 3, 0),
		},
		drag = vector.new(5, 3, 5),
		texture = {
			name = "sf_particles_shadow_poof_anim.png^[brighten",
		},
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = -1,
		},
	})
end

local on_punch_default = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
	if damage < 1 then
		return
	end
	if self.object:get_hp() - damage <= 0 then
		return
	end
	minetest.sound_play(DAMAGE_SOUND, {pos=self.object:get_pos(), max_hear_distance=16}, true)
end
local on_death_default = function(self)
	death_particles(self)
	local pos = self.object:get_pos()
	minetest.sound_play(DEATH_SOUND, {pos=pos, max_hear_distance=32}, true)

	local fragments = math.random(SHADOW_FRAGMENTS_DROP_MIN, SHADOW_FRAGMENTS_DROP_MAX)
	if fragments > 0 then
		for f=1, fragments do
			local obj = minetest.add_entity(pos, "sf_resources:shadow_fragment")
			if obj then
				obj:set_velocity({
					x = math.random(-100, 100) * 0.02,
					y = math.random(0, 100) * 0.02,
					z = math.random(-100, 100) * 0.02,
				})
			end
		end
	end
end

local get_circular_positions = function(center, radius, count)
	local PRECISION = 1000
	local alpha_start = (math.random(0, PRECISION) * (math.pi*2)) / PRECISION
	local positions = {}
	for c=1, count do
		local alpha = (c-1)*((math.pi*2)/count)
		alpha = (alpha + alpha_start) % (math.pi*2)
		local offset = vector.new(math.cos(alpha)*radius, 0, math.sin(alpha)*radius)
		local pos = vector.add(center, offset)
		table.insert(positions, pos)
	end
	return positions
end

local function remove_if_in_killer_node(mob)
	local pos = mob.object:get_pos()
	local node = minetest.get_node(pos)
	if node.name == "sf_nodes:killer" then
		death_particles(mob)
		mob.object:remove()
		return true
	end
	return false
end

local function activate_gravity(mob)
	mob.object:set_acceleration({x=0, y=-GRAVITY, z=0})
end
local function deactivate_gravity(mob)
	mob.object:set_acceleration({x=0, y=0, z=0})
end

minetest.register_entity("sf_mobs:crawler", {
	initial_properties = {
		hp_max = 1,
		visual = "mesh",
		mesh = "sf_mobs_crawler.obj",
		visual_size = { x = 10, y = 10, z = 10 },
		physical = true,
		collide_with_objects = true,
		textures = {
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
		},
		backface_culling = true,
		stepheight = 0.45,
		selectionbox = { -0.266, 0, -0.266, 0.266, 0.725, 0.266, rotate = true},
		collisionbox = { -0.266, 0, -0.266, 0.266, 0.725, 0.266 },
		damage_texture_modifier = DAMAGE_TEXTURE_MODIFIER,
	},
	_damage_timer = CRAWLER_DAMAGE_TIMER,
	_last_punch = math.huge,
	on_activate = function(self)
		self.object:set_armor_groups({shadow_physical=100})
		self.object:set_animation({x=0, y=10}, 15.0, 0.0, true)
		activate_gravity(self)
	end,
	on_death = on_death_default,
	on_punch = on_punch_default,
	on_step = function(self, dtime, moveresult)
		if remove_if_in_killer_node(self) then
			return
		end
		local opos = self.object:get_pos()
		-- Punch all players nearby
		local punched = false
		if self._damage_timer < CRAWLER_DAMAGE_TIMER then
			self._damage_timer = self._damage_timer + dtime
		else
			local players = minetest.get_connected_players()
			local players_in_range = {}
			for p=1, #players do
				local ppos = players[p]:get_pos()
				if vector.distance(opos, ppos) <= CRAWLER_ATTACK_RANGE then
					table.insert(players_in_range, players[p])
				end
			end
			for p=1, #players_in_range do
				local player = players_in_range[p]
				local dir = vector.direction(opos, player:get_pos())
				player:punch(self.object, self._last_punch, CRAWLER_TOOL_PROPERTIES, dir)
				punched = true
			end
		end
		if punched then
			self._last_punch = 0
			self._damage_timer = 0
		else
			self._last_punch = self._last_punch + dtime
		end

		-- Follow closest player
		local player = sf_util.get_closest_player(opos)
		if not player then
			activate_gravity(self)
			self.object:set_velocity(vector.zero())
			return
		end
		if vector.distance(player:get_pos(), opos) > CRAWLER_AGGRESSION_DISTANCE then
			activate_gravity(self)
			self.object:set_velocity(vector.zero())
			return
		end
		local oldvel = self.object:get_velocity()

		local opos_h = self.object:get_pos()
		opos_h.y = 0
		local ppos_h = player:get_pos()
		ppos_h.y = 0
		local dist = vector.distance(opos_h, ppos_h)
		if dist < CRAWLER_REACHED_RANGE then
			activate_gravity(self)
			-- Stop moving if horizontally close to player
			-- to prevent jittering
			self.object:set_velocity(vector.zero())
			return
		end

		local vel = vector.direction(opos, player:get_pos())
		vel = vector.normalize(vel)
		vel = vector.multiply(vel, CRAWLER_SPEED)
		vel.y = oldvel.y
		if moveresult.collides then
			for c=1, #moveresult.collisions do
				local collision = moveresult.collisions[c]
				if collision.type == "node" and (collision.axis == "x" or collision.axis == "z") then
					deactivate_gravity(self)
					vel.y = CRAWLER_SPEED
					break
				end
			end
		end
		self.object:set_velocity(vel)
		local dir = vector.normalize(vel)
		local yaw = minetest.dir_to_yaw(dir)
		self.object:set_yaw(yaw)
		activate_gravity(self)
	end,
})

minetest.register_entity("sf_mobs:crawlerspawner", {
	initial_properties = {
		hp_max = 32,
		visual = "cube",
		visual_size = { x = 2, y = 2, z = 2 },
		physical = true,
		collide_with_objects = true,
		textures = {
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
		},
		backface_culling = true,
		stepheight = 0.45,
		selectionbox = { -1, -1, -1, 1, 1, 1, rotate = true},
		collisionbox = { -1, -1, -1, 1, 1, 1 },
		damage_texture_modifier = DAMAGE_TEXTURE_MODIFIER,
	},
	_spawn_timer = 0,
	on_activate = function(self)
		self.object:set_armor_groups({shadow_physical=100})
		activate_gravity(self)
	end,
	on_death = on_death_default,
	on_punch = on_punch_default,
	on_step = function(self, dtime, moveresult)
		if remove_if_in_killer_node(self) then
			return
		end
		self._spawn_timer = self._spawn_timer + dtime
		if self._spawn_timer < CRAWLERSPAWNER_SPAWN_TIMER then
			return
		end
		self._spawn_timer = 0
		local opos = self.object:get_pos()
		local objs = minetest.get_objects_inside_radius(opos, CRAWLERSPAWNER_CHECK_RANGE)
		local crawlers_count = 0
		for o=1, #objs do
			local lua = objs[o]:get_luaentity()
			if lua and lua.name == "sf_mobs:crawler" then
				crawlers_count = crawlers_count + 1
			end
		end
		if crawlers_count > CRAWLERSPAWNER_MAX_COUNT then
			return
		end
		local spawn_crawlers = CRAWLERSPAWNER_SPAWN_COUNT
		local alpha_start = (math.random(0,1000) * (math.pi*2)) / 1000
		local spawn_positions = get_circular_positions(opos, 2, spawn_crawlers)
		for c=1, spawn_crawlers do
			local spawnpos = spawn_positions[c]
			spawn_particles(spawnpos)

			local obj = minetest.add_entity(spawnpos, "sf_mobs:crawler")
			if obj then
				local x = 0
				local y = math.random(300,350)*0.01
				local z = 0
				obj:set_velocity(vector.add(opos, {x=x, y=y, z=z}))
			end
		end
	end,
})



minetest.register_entity("sf_mobs:flyershooter", {
	initial_properties = {
		hp_max = 7,
		visual = "mesh",
		mesh = "sf_mobs_flyer.obj",
		automatic_rotate = 3,
		physical = true,
		collide_with_objects = true,
		textures = {
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
		},
		backface_culling = true,
		collisionbox = { -0.4, -0.4, -0.4, 0.4, 0.4, 0.4 },
		selectionbox = { -0.4, -0.4, -0.4, 0.4, 0.4, 0.4, rotate = true },
		visual_size = { x = 8, y = 8, z = 8 },
		damage_texture_modifier = DAMAGE_TEXTURE_MODIFIER,
	},
	_shoot_timer = FLYERSHOOTER_ATTACK_TIMER,
	_fly_timer = 0,
	_fly_timer_next_action = 5,
	on_activate = function(self)
		self.object:set_armor_groups({shadow_physical=100})
		self.object:set_velocity(vector.new())
	end,
	on_death = on_death_default,
	on_punch = on_punch_default,
	on_step = function(self, dtime, moveresult)
		if remove_if_in_killer_node(self) then
			return
		end
		local opos = self.object:get_pos()

		-- Fly to random direction
		self._fly_timer = self._fly_timer + dtime
		if self._fly_timer > self._fly_timer_next_action then
			if vector.length(self.object:get_velocity()) > 1 then
				self.object:set_velocity(vector.zero())
				self._fly_timer_next_action = 1 + math.random(0,3)
			else
				local h_or_v = math.random(1,4)
				local x,y,z = 0,0,0
				if h_or_v == 1 then
					y=math.random(-100,100)*0.015
				else
					x=math.random(-100,100)*0.015
					z=math.random(-100,100)*0.015
				end
				self.object:set_velocity({x=x,y=y,z=z})
				self._fly_timer_next_action = 2 + math.random(0,6)
			end
			self._fly_timer = 0
		end

		-- Shoot at closest player
		local shot = false
		if self._shoot_timer < FLYERSHOOTER_ATTACK_TIMER then
			self._shoot_timer = self._shoot_timer + dtime
		else
			local player = sf_util.get_closest_player(opos)
			if not player then
				return
			end
			local targetpos = player:get_pos()
			local pprops = player:get_properties()
			local player_height = pprops.collisionbox[5] - pprops.collisionbox[2]
			targetpos.y = targetpos.y + player_height/2
			if vector.distance(opos, player:get_pos()) <= FLYERSHOOTER_ATTACK_RANGE then
				local dir = vector.direction(opos, targetpos)
				local projpos = vector.add(opos, vector.multiply(dir, 1.5))

				local vel = vector.multiply(dir, FLYERSHOOTER_PROJECTILE_SPEED)
				sf_projectiles.add_projectile(projpos, "sf_projectiles:shadow", vel, nil, SHADOW_PROJECTILE_TOOL_PROPERTIES)
				minetest.sound_play({name="sf_mobs_shadow_shoot", gain=0.15}, {pos=self.object:get_pos(), max_hear_distance=12}, true)
				shot = true
			end
		end
		if shot then
			self._shoot_timer = 0
		end
	end,
})



minetest.register_entity("sf_mobs:shadow_orb", {
	initial_properties = {
		hp_max = 500,
		visual = "mesh",
		mesh = "sf_mobs_shadow_orb.obj",
		visual_size = { x = 30, y = 30, z = 30 },
		physical = true,
		collide_with_objects = true,
		textures = {
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
			"sf_mobs_shadow.png",
		},
		backface_culling = true,
		selectionbox = { -1.5, -1.5, -1.5, 1.5, 1.5, 1.5 },
		collisionbox = { -1.5, -1.5, -1.5, 1.5, 1.5, 1.5 },
		damage_texture_modifier = DAMAGE_TEXTURE_MODIFIER,
		automatic_rotate = 6,
	},
	_damage_timer = CRAWLER_DAMAGE_TIMER,
	_fly_timer = 0,
	_fly_timer_next_action = 0,
	_shoot_timer = 0,
	_spawn_timer = 0,
	on_activate = function(self)
		self.object:set_armor_groups({shadow_physical=100})
	end,
	on_death = function(self)
		local pos = self.object:get_pos()
		minetest.add_particlespawner({
			amount = 13,
			time = 0.02,
			exptime = {
				min = 8,
				max = 10,
			},
			pos = {
				min = vector.add(pos, vector.new(-1.5,-1.5,-1.5)),
				max = vector.add(pos, vector.new(1.5,1.5,1.5)),
			},
			size = {
				min = 7,
				max = 14,
			},
			vel = {
				min = vector.new(-1, -0.5, 1),
				max = vector.new(1, 0.5, 1),
			},
			drag = vector.new(1, 0, 1),
			texpool = {
				{ name = "sf_particles_smoke.png", alpha_tween = { 1, 0, start = 0.75 } },
				{ name = "sf_particles_smoke_med.png", alpha_tween = { 1, 0, start = 0.75 } },
				{ name = "sf_particles_smoke_dense.png", alpha_tween = { 1, 0, start = 0.75 } },
			},
		})
		minetest.add_particlespawner({
			amount = 16,
			time = 0.05,
			exptime = {
				min = 6,
				max = 7,
			},
			size = 6.5,
			pos = {
				min = vector.add(pos, vector.new(-1.5,-1.5,-1.5)),
				max = vector.add(pos, vector.new(1.5,1.5,1.5)),
			},
			vel = {
				min = vector.new(-5, -5, -5),
				max = vector.new(5, 5, 5),
			},
			drag = vector.new(1, 1, 1),
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

		local objs = minetest.get_objects_inside_radius(pos, SHADOW_ORB_DEATH_CHECK_RANGE)
		for o=1, #objs do
			local lua = objs[o]:get_luaentity()
			if lua and (lua.name == "sf_mobs:flyershooter" or lua.name == "sf_mobs:crawler") then
				death_particles(lua)
				objs[o]:remove()
			end
		end

		minetest.sound_play(DEATH_SOUND, {pos=pos, max_hear_distance=32, pitch=0.4}, true)

		for f=1, SHADOW_ORB_FRAGMENTS do
			local obj = minetest.add_entity(pos, "sf_resources:shadow_fragment")
			if obj then
				obj:set_velocity({
					x = math.random(-100, 100) * 0.05,
					y = math.random(0, 100) * 0.05,
					z = math.random(-100, 100) * 0.05,
				})
			end
		end

		local boss_arena = sf_zones.get_zone("boss_arena")
		for a=1, #boss_arena.areas do
			local area = boss_arena.areas[a]
			sf_util.break_nodes_in_area(area.pos_min, area.pos_max, "sf_nodes:weak_concrete", nil)
		end

		local player = sf_util.get_closest_player(pos)
		if player and player:is_player() then
			local pmeta = player:get_meta()
			pmeta:set_int("sf_mobs:boss_defeated", 1)
		end
		minetest.after(3, function(player)
			if player and player:is_player() then
				sf_dialog.show_dialog(player, "outro", true)
			end
		end, player)
	end,
	on_punch = on_punch_default,
	on_step = function(self, dtime, moveresult)
		local opos = self.object:get_pos()

		-- Fly to random direction
		self._fly_timer = self._fly_timer + dtime
		if self._fly_timer > self._fly_timer_next_action then
			if vector.length(self.object:get_velocity()) > 1 then
				self.object:set_velocity(vector.zero())
				self._fly_timer_next_action = 1 + math.random(0,3)
			else
				local h_or_v = math.random(1,4)
				local x,y,z = 0,0,0
				if h_or_v == 1 then
					y=math.random(-100,100)*0.015
				else
					x=math.random(-100,100)*0.015
					z=math.random(-100,100)*0.015
				end
				self.object:set_velocity({x=x,y=y,z=z})
				self._fly_timer_next_action = 2 + math.random(0,6)
			end
			self._fly_timer = 0
		end

		-- Shoot at closest player
		local shot = false
		if self._shoot_timer < SHADOW_ORB_ATTACK_TIMER then
			self._shoot_timer = self._shoot_timer + dtime
		else
			local player = sf_util.get_closest_player(opos)
			if not player then
				return
			end
			local targetpos = player:get_pos()
			local pprops = player:get_properties()
			local player_height = pprops.collisionbox[5] - pprops.collisionbox[2]
			targetpos.y = targetpos.y + player_height/2
			if vector.distance(opos, player:get_pos()) <= SHADOW_ORB_ATTACK_RANGE then
				local dir = vector.direction(opos, targetpos)
				local projpos = vector.add(opos, vector.multiply(dir, 1.5))

				local vel = vector.multiply(dir, SHADOW_ORB_PROJECTILE_SPEED)
				sf_projectiles.add_projectile(projpos, "sf_projectiles:shadow", vel, nil, SHADOW_PROJECTILE_TOOL_PROPERTIES)
				minetest.sound_play({name="sf_mobs_shadow_shoot", gain=0.15}, {pos=self.object:get_pos(), max_hear_distance=32}, true)
				shot = true
			end
		end
		if shot then
			self._shoot_timer = 0
		end

		-- Spawn flyershooters
		self._spawn_timer = self._spawn_timer + dtime
		if self._spawn_timer < SHADOW_ORB_SPAWN_TIMER then
			return
		end
		self._spawn_timer = 0
		local opos = self.object:get_pos()
		local objs = minetest.get_objects_inside_radius(opos, SHADOW_ORB_SPAWN_CHECK_RANGE)
		local mobs_count = 0
		for o=1, #objs do
			local lua = objs[o]:get_luaentity()
			if lua and lua.name == "sf_mobs:flyershooter" then
				mobs_count = mobs_count + 1
			end
		end
		if mobs_count > SHADOW_ORB_SPAWN_MAX_COUNT then
			return
		end
		local spawn_mobs = SHADOW_ORB_SPAWN_COUNT
		local alpha_start = (math.random(0,1000) * (math.pi*2)) / 1000
		local spawn_positions = get_circular_positions(opos, 3, spawn_mobs)
		for c=1, spawn_mobs do
			local spawnpos = spawn_positions[c]
			spawn_particles(spawnpos)

			local obj = minetest.add_entity(spawnpos, "sf_mobs:flyershooter")
		end

	end,
})


