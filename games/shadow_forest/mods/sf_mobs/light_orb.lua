local S = minetest.get_translator("sf_mobs")

local LIGHT_ORB_NODE_TIMER = 0.1
local LIGHT_ORB_Y_OFFSET = 3.4
local LIGHT_ORB_Y_OFFSET_FALLBACK = 2.6
local LIGHT_ORB_Y_OFFSET_FALLBACK_2 = 1.6
local LIGHT_ORB_HOR_OFFSET = 3.0
local LIGHT_ORB_SPEED = 7
local LIGHT_ORB_LIGHT_LEVEL_1 = 10
local LIGHT_ORB_LIGHT_LEVEL_2 = minetest.LIGHT_MAX
local FORCE_CACHE_UPDATE_TIMER = 3.0
local HIGH_DISTANCE_TELEPORT = 100

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

-- Count number of active light orbs in the game. There can only be one!
local light_orb_count = 0

local light_orb_light = true

if EDITOR then
	-- Whether to enable the lighting of the light orb in Editor Mode
	light_orb_light = minetest.settings:get_bool("sf_editor_light_orb_light", false)
end

local function teleport_light_orb(light_orb, pos, eventname)
	minetest.log("action", "[sf_mobs] Light orb at "..minetest.pos_to_string(light_orb:get_pos(), 1).." teleports close to "..minetest.pos_to_string(pos, 1).. " ("..eventname..")")
	light_orb:set_pos(vector.offset(pos, 0, LIGHT_ORB_Y_OFFSET, 0))
end

for i=1, 2 do
	local id, desc, light
	if i == 1 then
		id = "sf_mobs:light_orb_light"
		desc = S("Light Orb Light")
		light = LIGHT_ORB_LIGHT_LEVEL_1
	else
		id = "sf_mobs:light_orb_light_2"
		desc = S("Bright Light Orb Light")
		light = LIGHT_ORB_LIGHT_LEVEL_2
	end
	minetest.register_node(id, {
		description = desc,
		pointable = false,
		walkable = false,
		drawtype = "airlike",
		paramtype = "light",
		sunlight_propagates = true,
		wield_image = "[fill:16x16:0,0:#ffffff",
		inventory_image = "[fill:16x16:0,0:#ffffff",
		buildable_to = true,
		floodable = true,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(LIGHT_ORB_NODE_TIMER)
		end,
		on_timer = function(pos)
			if not light_orb_light then
				minetest.remove_node(pos)
				return
			end
			local objs = minetest.get_objects_inside_radius(pos, 3)
			for o=1, #objs do
				if objs[o]:get_luaentity() and objs[o]:get_luaentity().name == "sf_mobs:light_orb" then
					local timer = minetest.get_node_timer(pos)
					timer:start(LIGHT_ORB_NODE_TIMER)
					return
				end
			end
			minetest.remove_node(pos)
		end,
		light_source = light,
		groups = { light_orb_light = i },
	})
end

sf_mobs.respawn_light_orb = function(player)
	local ppos = player:get_pos()
	if light_orb_count > 0 then
		return
	end
	minetest.load_area(vector.add(ppos, vector.new(-5,-5,-5)), vector.add(ppos, vector.new(5,5,5)))
	local spawnpos = vector.add(ppos, vector.new(0, LIGHT_ORB_Y_OFFSET, 0))
	minetest.log("action", "[sf_mobs] (Re-)spawning light orb at "..minetest.pos_to_string(spawnpos, 1))
	minetest.add_entity(spawnpos, "sf_mobs:light_orb")
end

local function node_is_lightable(node)
	return node.name == "air" or minetest.get_item_group(node.name, "light_orb_light") > 0
end

-- Find a position close to the player for the light orb to light up,
-- based on look direction and available space
local function find_lightable_position(player)
	local look_yaw = player:get_look_horizontal()
	local yaw_dir = minetest.yaw_to_dir(look_yaw)
	local try_positions = {
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET, y_offset = LIGHT_ORB_Y_OFFSET },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK_2 },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-1, y_offset = LIGHT_ORB_Y_OFFSET },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-1, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-1, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK_2 },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-2, y_offset = LIGHT_ORB_Y_OFFSET },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-2, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK },
		{ yaw_distance = LIGHT_ORB_HOR_OFFSET-2, y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK_2 },
		{ y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK },
		{ y_offset = LIGHT_ORB_Y_OFFSET_FALLBACK_2 },
	}

	local htargetpos, vtargetpos
	local found = false
	local ppos = player:get_pos()
	for t=1, #try_positions do
		local try = try_positions[t]
		htargetpos = table.copy(ppos)
		htargetpos.y = 0
		if try.yaw_distance then
			local look_add = vector.multiply(yaw_dir, try.yaw_distance)
			htargetpos = vector.add(htargetpos, look_add)
		end
		vtargetpos = table.copy(htargetpos)
		vtargetpos.y = ppos.y
		if try.y_offset then
			vtargetpos.y = vtargetpos.y + try.y_offset
		end
		local vnode = minetest.get_node(vtargetpos)
		if node_is_lightable(vnode) then
			found = true
			break
		elseif not try.yaw_distance then
			local offsets = {
				{ x=0,y=0,z=1 },
				{ x=0,y=0,z=-1 },
				{ x=1,y=0,z=0 },
				{ x=-1,y=0,z=0 },
			}
			for o=1, #offsets do
				local offset = offsets[o]
				htargetpos = vector.add(ppos, offset)
				vtargetpos = table.copy(htargetpos)
				htargetpos.y = 0
				local vnode = minetest.get_node(vtargetpos)
				if node_is_lightable(vnode) then
					found = true
					break
				end
			end
		end
		if found then
			break
		end
	end
	-- Ultimate fallback
	if not found then
		htargetpos = player:get_pos()
		htargetpos.y = 0
		vtargetpos = player:get_pos()
		vtargetpos.y = vtargetpos.y + 0.8
	end
	return htargetpos, vtargetpos
end

minetest.register_entity("sf_mobs:light_orb", {
	initial_properties = {
		pointable = false,
		hp_max = 20,
		visual = "mesh",
		mesh = "sf_mobs_light_orb.obj",
		physical = false,
		collide_with_objects = false,
		textures = {
			"sf_mobs_light_orb.png",
		},
		use_texture_alpha = true,
		automatic_rotate = -1,
		selectionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2, rotate = true },
		visual_size = { x = 4, y = 4, z = 4 },
		glow = LIGHT_ORB_LIGHT_LEVEL_1,
		static_save = false,
	},
	_light_timer = 0,
	_idle_timer = 0,
	_cleanup_timer = 0,
	_force_cache_update_timer = 0,
	_cached_player_position = nil,
	_cached_player_yaw = nil,
	_cached_target_position = nil,
	on_deactivate = function(self)
		light_orb_count = light_orb_count - 1
		if light_orb_count < 0 then
			minetest.log("error", "[sf_mobs] light_orb_count has become lower than 0!")
		end
	end,
	on_activate = function(self)
		light_orb_count = light_orb_count + 1
		if light_orb_count > 1 then
			minetest.log("action", "[sf_mobs] Prevented spawning of another light orb")
			self.object:remove()
			return
		end
		self.object:set_armor_groups({immortal = 1})
	end,
	on_step = function(self, dtime, moveresult)
		local opos = self.object:get_pos()

		self._idle_timer = self._idle_timer + dtime
		if self._idle_timer > math.pi*200000 then
			self._idle_timer = 0
		end

		local player = sf_util.get_closest_player(opos)

		self._cleanup_timer = self._cleanup_timer + dtime
		if self._cleanup_timer >= 10 then
			self._cleanup_timer = 0
			if player then
				if vector.distance(self.object:get_pos(), player:get_pos()) > HIGH_DISTANCE_TELEPORT then
					teleport_light_orb(self.object, player:get_pos(), "high distance event")
					return
				end
			end
		end

		if player then
			local htargetpos, vtargetpos

			-- Cache the orb's target position and use it when the player's position and yaw
			-- haven't (practically) changed to reduce the number of required
			-- get_node calls.
			if self._cached_target_position then
				-- At every X seconds, the cache is forced to be ignored
				-- and a new target check be done (in case
				self._force_cache_update_timer = self._force_cache_update_timer + dtime
				local can_use_cache = self._force_cache_update_timer < FORCE_CACHE_UPDATE_TIMER
				local ppos = player:get_pos()
				local yaw = player:get_look_horizontal()
				if can_use_cache and vector.distance(self._cached_player_position, ppos) < 0.001 and math.abs(yaw - self._cached_player_yaw) < 0.001 then
					vtargetpos = table.copy(self._cached_target_position)
					htargetpos = table.copy(self._cached_target_position)
					htargetpos.y = 0
				else
					self._cached_player_position = player:get_pos()
					self._cached_player_yaw = player:get_look_horizontal()
				end
				if self._force_cache_update_timer >= FORCE_CACHE_UPDATE_TIMER then
					self._force_cache_update_timer = 0
				end
			else
				self._cached_player_position = player:get_pos()
				self._cached_player_yaw = player:get_look_horizontal()
			end

			if not vtargetpos then
				htargetpos, vtargetpos = find_lightable_position(player)
				self._cached_target_position = table.copy(vtargetpos)
			end

			local hopos = table.copy(opos)
			hopos.y = 0
			local hdist = vector.distance(hopos, htargetpos)
			local vdist = vector.distance(opos, vtargetpos)
			if hdist > 0.2 or vdist > 2 then
				local dir = vector.direction(opos, vtargetpos)
				dir = vector.normalize(dir)
				dir = vector.multiply(dir, LIGHT_ORB_SPEED)
				self.object:set_velocity(dir)
			else
				self.object:set_velocity({x=0, y=math.sin(self._idle_timer*3)*0.5, z=0})
			end
		else
			self.object:set_velocity(vector.zero())
		end


		self._light_timer = self._light_timer + dtime
		if self._light_timer < 0.1 then
			return
		end
		self._light_timer = 0

		-- Set light nodes unless this has been disabled
		if light_orb_light then
			local lightnode
			if player and sf_upgrade.has_upgrade(player, "bright_orb") then
				self.object:set_properties({glow=LIGHT_ORB_LIGHT_LEVEL_2})
				lightnode = {name="sf_mobs:light_orb_light_2"}
			else
				self.object:set_properties({glow=LIGHT_ORB_LIGHT_LEVEL_1})
				lightnode = {name="sf_mobs:light_orb_light"}
			end
			local mynode = minetest.get_node(opos)
			if mynode.name == "air" or (minetest.get_item_group(mynode.name, "light_orb_light") > 0 and mynode.name ~= lightnode.name) then
				minetest.set_node(opos, lightnode)
			end
		end
	end,
})

minetest.register_on_joinplayer(function(player)
	sf_mobs.respawn_light_orb(player)
end)

local light_orb_check_time = 0
minetest.register_globalstep(function(dtime)
	light_orb_check_time = light_orb_check_time + dtime
	if light_orb_check_time < 10 then
		return
	end
	light_orb_check_time = 0
	if light_orb_count <= 0 then
		local player = sf_util.get_singleplayer()
		if player then
			sf_mobs.respawn_light_orb(player)
		end
	end
end)

minetest.register_lbm({
	label = "Clean up light orb light nodes",
	name = "sf_mobs:remove_light_orb_lights",
	nodenames = {"group:light_orb_light"},
	run_at_every_load = true,
	action = function(pos)
		minetest.remove_node(pos)
	end,
})

minetest.register_chatcommand("toggle_light_orb", {
	privs = { server = true },
	params = "",
	description = S("Toggle the light of the light orb"),
	func = function(name, param)
		light_orb_light = not light_orb_light
		if light_orb_light then
			return true, S("The light orb illuminates the environment.")
		else
			return true, S("The light orb no longer illuminates the environment.")
		end
	end,
})

minetest.register_on_joinplayer(function(player)
	if not light_orb_light then
		minetest.chat_send_player(player:get_player_name(), S("The light of the light orb is disabled."))
	end
end)

sf_world.register_on_teleport(function(player, oldpos, newpos)
	local objs = minetest.get_objects_inside_radius(oldpos, 20)
	local light_orb
	for o=1, #objs do
		if objs[o]:get_luaentity() and objs[o]:get_luaentity().name == "sf_mobs:light_orb" then
			light_orb = objs[o]
			break
		end
	end
	if light_orb then
		teleport_light_orb(light_orb, newpos, "register_on_teleport event")
	else
		sf_mobs.respawn_light_orb(player)
	end
end)
