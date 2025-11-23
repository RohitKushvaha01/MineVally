local S = minetest.get_translator("sf_weapons")

local LIGHTSTAFF_SPEED = 15
local LIGHTSTAFF_REUSE_DELAY_L0 = 800000
local LIGHTSTAFF_REUSE_DELAY_L1 = 600000
local LIGHTSTAFF_REUSE_DELAY_L2 = 500000
local LIGHTSTAFF_REUSE_DELAY_L3 = 250000

local LIGHT_PROJECTILE_TOOL_PROPERTIES_L0 = {
	full_punch_interval = 0.0,
	damage_groups = { shadow_physical = 2, shadow_special = 2 },
}
local LIGHT_PROJECTILE_TOOL_PROPERTIES_L1 = {
	full_punch_interval = 0.0,
	damage_groups = { shadow_physical = 3, shadow_special = 3 },
}
local LIGHT_PROJECTILE_TOOL_PROPERTIES_L2 = {
	full_punch_interval = 0.0,
	damage_groups = { shadow_physical = 5, shadow_special = 5 },
}
local LIGHT_PROJECTILE_TOOL_PROPERTIES_L3 = {
	full_punch_interval = 0.0,
	damage_groups = { shadow_physical = 8, shadow_special = 8 },
}

local get_lightstaff_toolprops = function(player)
	if sf_upgrade.has_upgrade(player, "hard_light3") then
		return LIGHT_PROJECTILE_TOOL_PROPERTIES_L3
	elseif sf_upgrade.has_upgrade(player, "hard_light2") then
		return LIGHT_PROJECTILE_TOOL_PROPERTIES_L2
	elseif sf_upgrade.has_upgrade(player, "hard_light1") then
		return LIGHT_PROJECTILE_TOOL_PROPERTIES_L1
	else
		return LIGHT_PROJECTILE_TOOL_PROPERTIES_L0
	end
end

local get_reuse_delay = function(player)
	local level = 0
	for i=1, 3 do
		if sf_upgrade.has_upgrade(player, "swift_staff"..i) then
			level = level + 1
		end
	end
	if level == 1 then
		return LIGHTSTAFF_REUSE_DELAY_L1
	elseif level == 2 then
		return LIGHTSTAFF_REUSE_DELAY_L2
	elseif level == 3 then
		return LIGHTSTAFF_REUSE_DELAY_L3
	else
		return LIGHTSTAFF_REUSE_DELAY_L0
	end
end

local last_ranged_shot = {}

minetest.register_tool("sf_weapons:stick", {
	description = S("Dagger of Light"),
	wield_scale= { x=1.75,y=1.75,z=2.2 },
	wield_image = "sf_weapons_stick.png^[transformR90",
	inventory_image = "sf_weapons_stick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		damage_groups = { fleshy = 2, shadow_physical = 3 },
	},
	groups = { weapon = 1 },
})

minetest.register_tool("sf_weapons:lightstaff", {
	description = S("Staff of Light"),
	wield_scale = { x=1.75,y=1.75,z=2.2 },
	wield_image = "sf_weapons_lightstaff_wield.png",
	inventory_image = "sf_weapons_lightstaff.png",
	groups = { weapon = 1 },
	on_use = function(itemstack, player, pointed_thing)
		if not player or not player:is_player() then
			return itemstack
		end

		local last_shot = last_ranged_shot[player:get_player_name()]
		local now = minetest.get_us_time()
		local reuse_delay = get_reuse_delay(player)
		if last_shot ~= nil and (now - last_shot <= reuse_delay) then
			return itemstack
		end
		last_ranged_shot[player:get_player_name()] = minetest.get_us_time()

		local spawnpos_p = player:get_pos()
		local dir = player:get_look_dir()
		local pprops = player:get_properties()
		local height = pprops.eye_height
		spawnpos_p = vector.add(spawnpos_p, vector.new(0, height, 0))
		local spawnpos = vector.add(spawnpos_p, vector.multiply(dir, 1))

		-- Don't spawn projectile if a node blocks the path
		local ray = minetest.raycast(spawnpos_p, spawnpos, false, false)
		for pointed_thing in ray do
			if pointed_thing.type == "node" then
				return itemstack
			end
		end

		local vel = vector.multiply(dir, LIGHTSTAFF_SPEED)
		local toolprops = get_lightstaff_toolprops(player)
		sf_projectiles.add_projectile(spawnpos, "sf_projectiles:light", vel, player, toolprops)
		minetest.sound_play({name="sf_weapons_light_shoot", gain=0.2}, {pos=spawnpos}, true)
		return itemstack
	end,
})

minetest.register_on_leaveplayer(function(player)
	last_ranged_shot[player:get_player_name()] = nil
end)


-- Change update the lightstaff image while it's inert.
local function update_lightstaffs(player)
	local inv = player:get_inventory()
	local img_inv, img_wield
	local last_shot = last_ranged_shot[player:get_player_name()]
	local now = minetest.get_us_time()
	local reuse_delay = get_reuse_delay(player)
	if last_shot == nil or (now-last_shot) > reuse_delay then
		img_inv = ""
		img_wield = ""
	else
		img_inv = "sf_weapons_lightstaff_inert.png"
		img_wield = "sf_weapons_lightstaff_inert_wield.png"
	end
	for i=1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		if stack:get_name() == "sf_weapons:lightstaff" then
			local imeta = stack:get_meta()
			if imeta:get_string("inventory_image") ~= img_inv then
				imeta:set_string("inventory_image", img_inv)
				imeta:set_string("wield_image", img_wield)
				inv:set_stack("main", i, stack)
			end
		end
	end
end
minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		update_lightstaffs(player)
	end
end)
