local S = minetest.get_translator("sf_resources")

sf_resources = {}

-- Legacy support: Name of the HUD type field for 'hud_add'.
local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Luanti/Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Luanti/Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

local GRAVITY = 9.81
local LIFE_TIMER = 300
local MAGNET_RANGE = 0.8
local HUD_SHOW_TIME = 5000000
local MAX_RESOURCES = 999

sf_resources.registered_resources = {}
local registered_resource_entities = {}

local registered_on_resource_changes = {}

local player_huds = {}

sf_resources.register_on_resource_change = function(func)
	table.insert(registered_on_resource_changes, func)
end

local function report_resource_change(player, resource, count)
	for i=1, #registered_on_resource_changes do
		registered_on_resource_changes[i](player, resource, count)
	end
end

sf_resources.register_resource = function(id, def)
	sf_resources.registered_resources["sf_resources:"..id] = {
		description = def.description,
		texture = def.texture,
		icon = def.icon or def.texture,
	}
	minetest.register_entity("sf_resources:"..id, {
		initial_properties = {
			pointable = false,
			physical = true,
			collide_with_objects = false,
			visual = "sprite",
			vertical = true,
			textures = { def.texture },
			use_texture_alpha = true,
			visual_size = { x = 0.3, y = 0.3, z = 0.3 },
			collisionbox = { -0.15, -0.15, -0.15, 0.15, 0.15, 0.15 },
			selectionnbox = { -0.15, -0.15, -0.15, 0.15, 0.15, 0.15 },
		},
		_life_timer = 0,
		_count = 1,
		get_staticdata = function(self)
			local tabl = {
				life_timer = self._life_timer,
				count = self._count,
			}
			return minetest.serialize(tabl)
		end,
		on_activate = function(self, staticdata)
			local tabl = minetest.deserialize(staticdata)
			if type(tabl) == "table" then
				self._life_timer = tabl._life_timer or 0
				self._count = tabl._count or 1
			end
			self.object:set_armor_groups({immortal=1})
			self.object:set_acceleration({x=0,y=-GRAVITY,z=0})
		end,
		on_step = function(self, dtime, moveresult)
			if moveresult and moveresult.collides then
				if moveresult.touching_ground then
					local vel = self.object:get_velocity()
					vel.x = 0
					vel.z = 0
					self.object:set_velocity(vel)
				end
			end
			if not def.never_despawns then
				self._life_timer = self._life_timer + dtime
				if self._life_timer > LIFE_TIMER then
					self.object:remove()
					return
				end
			end
		end,
	})
end

local collect_resource = function(player, resource_object)
	local pmeta = player:get_meta()
	local rname = resource_object:get_luaentity().name
	local rcount_player = sf_resources.get_resource_count(player, rname)
	local rcount_res = resource_object:get_luaentity()._count or 1
	local newcount = rcount_player + rcount_res
	sf_resources.set_resource_count(player, rname, newcount)
	local rdesc = sf_resources.registered_resources[rname].description
	minetest.sound_play({name="sf_resources_collect", gain=0.9}, {to_player=player:get_player_name()}, true)
	resource_object:remove()
end

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local objs = minetest.get_objects_inside_radius(player:get_pos(), MAGNET_RANGE)
		for o=1, #objs do
			local obj = objs[o]
			local lua = obj:get_luaentity()
			if lua and sf_resources.registered_resources[lua.name] then
				collect_resource(player, obj)
			end
		end
	end
end)

function sf_resources.spawn_resource(pos, rname, count)
	if not count then
		count = 1
	end
	local obj = minetest.add_entity(pos, rname)
	if obj then
		local lua = obj:get_luaentity()
		if lua then
			lua._count = count
		end
	end
	return obj
end

minetest.register_chatcommand("resource", {
	privs = { server = true },
	params = S("((<resource name> | all) [<count>]) | list"),
	description = S("Show or set your resources"),
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player == nil or not player:is_player() then
			return false, S("Player does not exist.")
		end
		if param == "" then
			return false
		end
		if param == "list" then
			local list = {}
			for k,_ in pairs(sf_resources.registered_resources) do
				table.insert(list, k)
			end
			local out = table.concat(list, "\n")
			return true, out
		end
		local rname, rcount = string.match(param, "([a-z0-9_:]+) ([-~%d.]+)")
		if rname and rcount then
			if rname == "all" then
				for k,_ in pairs(sf_resources.registered_resources) do
					local rcount_player = sf_resources.get_resource_count(player, k)
					local rrcount = minetest.parse_relative_number(rcount, rcount_player)
					rrcount = math.floor(rrcount)
					sf_resources.set_resource_count(player, k, rrcount)
				end
				return true, S("All resources set!")
			else
				if not sf_resources.registered_resources[rname] then
					return false, S("Unknown resource.")
				end
				local rcount_player = sf_resources.get_resource_count(player, rname)
				rcount = minetest.parse_relative_number(rcount, rcount_player)
				rcount = math.floor(rcount)
				sf_resources.set_resource_count(player, rname, rcount)
				local newrcount = sf_resources.get_resource_count(player, rname)
				return true, S("@1: @2", sf_resources.registered_resources[rname].description, newrcount)
			end
		else
			rname = param
			if sf_resources.registered_resources[rname] then
				local rcount_player = sf_resources.get_resource_count(player, rname)
				return true, S("@1: @2", sf_resources.registered_resources[rname].description, rcount_player)
			else
				return false, S("Not a valid resource name.")
			end
		end
	end,
})

sf_resources.get_resource_count = function(player, resourcename)
	local pmeta = player:get_meta()
	local rcount = pmeta:get_int(resourcename)
	return rcount
end

sf_resources.set_resource_count = function(player, resourcename, count)
	local pmeta = player:get_meta()
	if count > MAX_RESOURCES then
		count = MAX_RESOURCES
	end
	if count < 0 then
		count = 0
	end
	pmeta:set_int(resourcename, count)
	report_resource_change(player, resourcename, count)
end


local init_hud = function(player)
	local pname = player:get_player_name()
	local id_icon = player:hud_add({
		[hud_type_field_name] = "image",
		position = { x = 0, y = 1 },
		scale = { x = 4, y = 4 },
		text = "blank.png",
		offset = { x = 20, y = -100 },
		alignment = { x = 1, y = -1 },
		z_index = 101,
	})
	local id_num = player:hud_add({
		[hud_type_field_name] = "text",
		position = { x = 0, y = 1 },
		scale = { x = 100, y = 100 },
		text = "",
		number = 0xFFFFFF,
		alignment = { x = 1, y = -1 },
		size = { x = 2, y = 2 },
		style = 0,
		offset = { x = 100, y = -118 },
		z_index = 102,
	})
	player_huds[pname] = {
		icon = id_icon,
		num = id_num,
		shown = false,
	}
end

sf_resources.register_on_resource_change(function(player, resource, count)
	local pname = player:get_player_name()
	if not player_huds[pname] then
		return
	end
	local icon = sf_resources.registered_resources[resource].icon
	player:hud_change(player_huds[pname].icon, "text", icon)
	player:hud_change(player_huds[pname].num, "text", tostring(count))
	player_huds[pname].shown = true
	player_huds[pname].shown_at = minetest.get_us_time()
end)

sf_resources.register_on_resource_change(function(player, rname, count)
	if rname == "sf_resources:shadow_fragement" then
		sf_dialog.show_dialog(player, "shadow_fragment", true)
	elseif rname == "sf_resources:healing_essence" then
		sf_dialog.show_dialog(player, "healing_essence", true)
	elseif rname == "sf_resources:light_crystal" then
		sf_dialog.show_dialog(player, "first_light_crystal", true)
	end
end)

minetest.register_globalstep(function(dtime)
	local now = minetest.get_us_time()
	for playername, hudinfo in pairs(player_huds) do
		local player = minetest.get_player_by_name(playername)
		if player then
			if player_huds[playername].shown and now - player_huds[playername].shown_at > HUD_SHOW_TIME then
				player:hud_change(player_huds[playername].icon, "text", "blank.png")
				player:hud_change(player_huds[playername].num, "text", "")
				player_huds[playername].shown = false
				player_huds[playername].shown_at = nil
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	init_hud(player)
end)

minetest.register_on_leaveplayer(function(player)
	player_huds[player:get_player_name()] = nil
end)

sf_resources.register_resource("shadow_fragment", { description = S("Shadow Fragment"), texture = "sf_resources_shadow_fragment.png", icon = "sf_resources_shadow_fragment_icon.png" })
sf_resources.register_resource("light_crystal", { description = S("Light Crystal"), texture = "sf_resources_light_crystal.png", never_despawns = true })
sf_resources.register_resource("healing_essence", { description = S("Healing Essence"), texture = "sf_resources_healing_essence.png", icon = "sf_resources_healing_essence_icon.png", never_despawns = true })
