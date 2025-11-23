local S = minetest.get_translator("sf_mobs")
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

-- If player is within this square radius fom spawner, spawner starts spawning
local SPAWNER_DETECT_RANGE = 30
-- Time in seconds after which to trigger spawner (minimum/maximum)
local SPAWNER_TIMER_MIN = 4
local SPAWNER_TIMER_MAX = 6
-- Spawner does not spawn if player is within this range
local SPAWNER_PLAYER_PREVENT_RANGE = 5
-- Spawner does not spawn if any mob is within this range
local SPAWNER_MOB_PREVENT_RANGE = 1.5
-- Distance from spawner within which to check the mob cap
local SPAWNER_LIMIT_RANGE = 32
-- When spawner refused to spawn, do another check in this many seconds
local SPAWNER_RESTART_TIMER = 1.0
-- How many mobs a spawner spawns before going to sleep
local SPAWNER_CONTENTS = 1
-- When spawner has spawned everything, go to sleep for this many seconds
local SPAWNER_SLEEP_TIMER = 300
-- Special param2 to denote when the spawner is asleep
local PARAM2_SLEEP = 255

-- Whether mobs can spawn
local mobs_can_spawn = not EDITOR

local spawn_mob = function(pos, entitystring)
	minetest.add_entity(pos, entitystring)
	minetest.log("action", "[sf_mobs] Mob spawner at "..minetest.pos_to_string(pos).." spawns mob of type '"..entitystring.."'")
end

local register_mob_spawner = function(id, def)
	local drawtype, pointable
	if EDITOR then
		drawtype = "allfaces"
		pointable = true
	else
		drawtype = "airlike"
		pointable = false
	end
	minetest.register_node("sf_mobs:spawner_"..id, {
		description = def.description,
		pointable = pointable,
		drawtype = drawtype,
		visual_scale = 0.5,
		paramtype = "light",
		sunlight_propagates = true,
		tiles = {def.texture.."^sf_mobs_spawner_overlay.png"},
		walkable = false,
		groups = { spawner = 1, editor_breakable = 1 },
		on_timer = function(pos)
			if not mobs_can_spawn then
				return
			end
			if def.limit == 0 then
				return
			end
			local node = minetest.get_node(pos)
			local contained_mobs = node.param2
			if node.param2 == 0 or node.param2 == PARAM2_SLEEP then
				contained_mobs = SPAWNER_CONTENTS
				minetest.log("verbose", "[sf_mobs] Spawner at "..minetest.pos_to_string(pos).." wakes up with "..contained_mobs.." mob(s)")
			end

			local objs = minetest.get_objects_inside_radius(pos, math.max(SPAWNER_PLAYER_PREVENT_RANGE, SPAWNER_LIMIT_RANGE))
			local mobs_of_same_kind = 0
			for o=1, #objs do
				local obj = objs[o]
				local opos = obj:get_pos()
				local distance = vector.distance(opos, pos)
				if distance <= SPAWNER_PLAYER_PREVENT_RANGE and obj:is_player() then
					local timer = minetest.get_node_timer(pos)
					timer:start(SPAWNER_RESTART_TIMER)
					return
				end
				local lua = obj:get_luaentity()
				if lua then
					local kind = lua.name
					if distance <= SPAWNER_LIMIT_RANGE and kind == "sf_mobs:"..id then
						mobs_of_same_kind = mobs_of_same_kind + 1
					end
					if distance <= SPAWNER_MOB_PREVENT_RANGE and string.sub(kind, 1, 8) == "sf_mobs:" then
						local timer = minetest.get_node_timer(pos)
						timer:start(SPAWNER_RESTART_TIMER)
						return
					end
				end
				if mobs_of_same_kind > def.limit-1 then
					local timer = minetest.get_node_timer(pos)
					timer:start(SPAWNER_RESTART_TIMER)
					return
				end
			end

			spawn_mob(pos, "sf_mobs:"..id)

			contained_mobs = contained_mobs - 1
			if contained_mobs <= 0 then
				node.param2 = PARAM2_SLEEP
				minetest.swap_node(pos, node)
				local timer = minetest.get_node_timer(pos)
				timer:start(SPAWNER_SLEEP_TIMER)
				minetest.log("verbose", "[sf_mobs] Spawner at "..minetest.pos_to_string(pos).." goes to sleep for "..SPAWNER_SLEEP_TIMER.."s")
			else
				node.param2 = contained_mobs
				minetest.swap_node(pos, node)
				minetest.log("verbose", "[sf_mobs] Spawner at "..minetest.pos_to_string(pos).." has "..contained_mobs.." mob(s) left")
			end
		end,
	})
end

register_mob_spawner("crawler", {
	description = S("Crawler Spawner"),
	texture = "sf_mobs_shadow.png",
	limit = 16,
})
register_mob_spawner("flyershooter", {
	description = S("Flyer Shooter Spawner"),
	texture = "sf_mobs_shadow.png",
	limit = 8,
})
register_mob_spawner("shadow_orb", {
	description = S("Shadow Orb Spawner"),
	texture = "sf_mobs_shadow.png",
	-- this mob must be spawned manually
	limit = 0,
})

local spawner_check_timer = 0
minetest.register_globalstep(function(dtime)
	if not mobs_can_spawn then
		return
	end
	spawner_check_timer = spawner_check_timer + dtime
	if spawner_check_timer < 0.5 then
		return
	end
	spawner_check_timer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local ppos = player:get_pos()
		local offset = vector.new(SPAWNER_DETECT_RANGE, SPAWNER_DETECT_RANGE, SPAWNER_DETECT_RANGE)
		local spawners = minetest.find_nodes_in_area(vector.add(ppos, offset), vector.subtract(ppos, offset), "group:spawner")
		for s=1, #spawners do
			local spawner = spawners[s]
			local timer = minetest.get_node_timer(spawner)
			if not timer:is_started() then
				local snode = minetest.get_node(spawner)
				if snode.param2 == PARAM2_SLEEP then
					timer:start(SPAWNER_SLEEP_TIMER)
				else
					local time = SPAWNER_TIMER_MIN + (math.random(0, 1000) * (SPAWNER_TIMER_MAX - SPAWNER_TIMER_MIN)) / 1000
					timer:start(time)
				end
			end
		end
	end
end)

minetest.register_chatcommand("toggle_mobs", {
	description = S("Toggles the spawning of hostile mobs"),
	privs = { server = true },
	func = function(name)
		mobs_can_spawn = not mobs_can_spawn
		if mobs_can_spawn then
			return true, S("Mob spawning enabled.")
		else
			return false, S("Mob spawning disabled.")
		end
	end,
})
