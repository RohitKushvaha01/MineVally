local S = minetest.get_translator("sf_upgrade")
local NS = function(s) return s end
local FS = function(...) return minetest.formspec_escape(S(...)) end

local FALLBACK_UPGRADE_ICON = "sf_upgrade_noicon.png"

sf_upgrade = {}

local player_states = {}

local registered_upgrades = {}
local registered_categories = {}

local upgrade_particles = function(player)
	minetest.add_particlespawner({
		amount = 32,
		time = 0.05,
		exptime = {
			min = 3,
			max = 5,
		},
		size = 1.5,
		pos = {
			min = vector.new(-0.8, 0, -0.8),
			max = vector.new(0.8, 1.5, 0.8),
		},
		attached = player,
		vel = {
			min = vector.new(0, 1, 0),
			max = vector.new(0, 3, 0),
		},
		drag = vector.new(5, 3, 5),
		texture = {
			name = "sf_upgrade_particle.png",
			alpha_tween = { 1, 0, start = 0.8 },
		},
	})
end

sf_upgrade.register_upgrade = function(name, def)
	registered_upgrades[name] = def
end
sf_upgrade.register_category = function(name)
	table.insert(registered_categories, name)
end

sf_upgrade.register_category("speed")
sf_upgrade.register_category("health")
sf_upgrade.register_category("orb")
sf_upgrade.register_category("lightstaff_damage")
sf_upgrade.register_category("lightstaff_speed")

sf_upgrade.register_upgrade("speed1", {
	name = NS("Fast Walker 1"),
	description = NS("Walking speed +5%"),
	icon = "sf_upgrade_speed1.png",
	category = "speed",
	price = 15,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		playerphysics.add_physics_factor(player, "speed", "sf_upgrade:speed1", 1.05)
	end,
	on_unapply = function(player)
		playerphysics.remove_physics_factor(player, "speed", "sf_upgrade:speed1")
	end,
})
sf_upgrade.register_upgrade("speed2", {
	name = NS("Fast Walker 2"),
	description = NS("Walking speed +5%"),
	icon = "sf_upgrade_speed2.png",
	category = "speed",
	depends = "speed1",
	price = 30,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		playerphysics.add_physics_factor(player, "speed", "sf_upgrade:speed2", 1.05)
	end,
	on_unapply = function(player)
		playerphysics.remove_physics_factor(player, "speed", "sf_upgrade:speed2")
	end,
})
sf_upgrade.register_upgrade("speed3", {
	name = NS("Fast Walker 3"),
	description = NS("Walking speed +5%"),
	icon = "sf_upgrade_speed3.png",
	category = "speed",
	depends = "speed2",
	price = 45,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		playerphysics.add_physics_factor(player, "speed", "sf_upgrade:speed3", 1.05)
	end,
	on_unapply = function(player)
		playerphysics.remove_physics_factor(player, "speed", "sf_upgrade:speed3")
	end,
})
sf_upgrade.register_upgrade("bright_orb", {
	name = NS("Bright Orb"),
	description = NS("Your light orb shines brighter"),
	icon = "sf_upgrade_bright_orb.png",
	category = "orb",
	price = 10,
	price_type = "sf_resources:shadow_fragment",
	on_upgrade = function(player)
		minetest.after(3, function(player)
			if player and player:is_player() then
				sf_dialog.show_dialog(player, "brighter")
			end
		end, player)
	end,
	on_apply = function(player)
		local ppos = player:get_pos()
		local nodes = minetest.find_nodes_in_area(vector.offset(ppos, -5, -5, -5), vector.offset(ppos, 5, 5, 5), {"group:light_orb_light"})
		for n=1, #nodes do
			minetest.set_node(nodes[n], {name="sf_mobs:light_orb_light_2"})
		end
	end,
	on_unapply = function(player)
		local ppos = player:get_pos()
		local nodes = minetest.find_nodes_in_area(vector.offset(ppos, -5, -5, -5), vector.offset(ppos, 5, 5, 5), {"group:light_orb_light"})
		for n=1, #nodes do
			minetest.set_node(nodes[n], {name="sf_mobs:light_orb_light"})
		end
	end,
})
sf_upgrade.register_upgrade("hard_light1", {
	name = NS("Hard Light 1"),
	description = NS("Staff of Light damage +1"),
	icon = "sf_upgrade_hard_light.png^sf_upgrade_level1.png",
	category = "lightstaff_damage",
	price = 20,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})
sf_upgrade.register_upgrade("hard_light2", {
	name = NS("Hard Light 2"),
	description = NS("Staff of Light damage +2"),
	icon = "sf_upgrade_hard_light.png^sf_upgrade_level2.png",
	category = "lightstaff_damage",
	depends = "hard_light1",
	price = 30,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})
sf_upgrade.register_upgrade("hard_light_3", {
	name = NS("Hard Light 3"),
	description = NS("Staff of Light damage +3"),
	icon = "sf_upgrade_hard_light.png^sf_upgrade_level3.png",
	depends = "hard_light2",
	category = "lightstaff_damage",
	price = 40,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})

sf_upgrade.register_upgrade("swift_staff1", {
	name = NS("Swift Staff 1"),
	description = NS("Staff of Light fires faster"),
	icon = "sf_upgrade_swift_staff.png^sf_upgrade_level1.png",
	category = "lightstaff_speed",
	price = 40,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})
sf_upgrade.register_upgrade("swift_staff2", {
	name = NS("Swift Staff 2"),
	description = NS("Staff of Light fires even faster"),
	icon = "sf_upgrade_swift_staff.png^sf_upgrade_level2.png",
	category = "lightstaff_speed",
	depends = "swift_staff1",
	price = 60,
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})
sf_upgrade.register_upgrade("swift_staff3", {
	name = NS("Swift Staff 3"),
	description = NS("Staff of Light fires super-fast!"),
	icon = "sf_upgrade_swift_staff.png^sf_upgrade_level3.png",
	category = "lightstaff_speed",
	price = 80,
	depends = "swift_staff2",
	price_type = "sf_resources:shadow_fragment",
	on_apply = function(player)
		-- Upgrade is handled by staff of light item
	end,
	on_unapply = function(player)
		-- Upgrade is handled by staff of light item
	end,
})



local apply_health = function(player)
	sf_health.update_max_hp(player)
end
local unapply_health = function(player)
	sf_health.update_max_hp(player)
end
sf_upgrade.register_upgrade("health1", {
	name = NS("Life Force 1"),
	description = NS("Max. health +2"),
	icon = "sf_upgrade_health.png^sf_upgrade_level1.png",
	category = "health",
	price = 75,
	price_type = "sf_resources:healing_essence",
	on_apply = apply_health,
	on_unapply = unapply_health,
})
sf_upgrade.register_upgrade("health2", {
	name = NS("Life Force 2"),
	description = NS("Max. health +2"),
	icon = "sf_upgrade_health.png^sf_upgrade_level2.png",
	category = "health",
	price = 75,
	price_type = "sf_resources:healing_essence",
	on_apply = apply_health,
	on_unapply = unapply_health,
	depends = "health1",
})
sf_upgrade.register_upgrade("health3", {
	name = NS("Life Force 3"),
	description = NS("Max. health +2"),
	icon = "sf_upgrade_health.png^sf_upgrade_level3.png",
	category = "health",
	price = 75,
	price_type = "sf_resources:healing_essence",
	on_apply = apply_health,
	on_unapply = unapply_health,
	depends = "health2",
})
sf_upgrade.register_upgrade("health4", {
	name = NS("Life Force 4"),
	description = NS("Max. health +2"),
	icon = "sf_upgrade_health.png^sf_upgrade_level4.png",
	category = "health",
	price = 75,
	price_type = "sf_resources:healing_essence",
	on_apply = apply_health,
	on_unapply = unapply_health,
	depends = "health3",
})


local get_upgrade_tree = function()
	local categories = {}
	for k,v in pairs(registered_upgrades) do
		local col = v.category
		if not categories[col] then
			categories[col] = {}
		end
		table.insert(categories[col], k)
	end
	local sorted_categories = {}
	for categoryname, category in pairs(categories) do
		local trailing_upgrade
		local found
		local sorted_category = {}
		repeat
			found = false
			for cc=1, #category do
				local upgradeid = category[cc]
				local upgrade = registered_upgrades[upgradeid]
				if upgrade.depends == nil and #sorted_category == 0 then
					table.insert(sorted_category, upgradeid)
					trailing_upgrade = upgradeid
					found = true
					break
				end
				if upgrade.depends ~= nil and upgrade.depends == trailing_upgrade then
					table.insert(sorted_category, upgradeid)
					trailing_upgrade = upgradeid
					found = true
					break
				end
			end
		until (found == false)
		sorted_categories[categoryname] = sorted_category
	end
	return sorted_categories
end

local upgrade_tree = get_upgrade_tree()

-- Buy upgrade, provided the player is ellegible for it.
-- Returns <success>, <fail_reason>
sf_upgrade.buy_upgrade = function(player, upgradeid)
	local price_type = registered_upgrades[upgradeid].price_type
	local pts = sf_resources.get_resource_count(player, price_type)
	local price = registered_upgrades[upgradeid].price
	if not sf_upgrade.upgrade_unlocked(player, upgradeid) then
		return false, "locked"
	end
	if pts < price then
		-- Buying fails if player doesn't have the upgrade points
		return false, "too_expensive"
	end
	if not sf_upgrade.has_upgrade(player, upgradeid) then
		-- Give upgrade and pay the price
		sf_upgrade.give_upgrade(player, upgradeid)
		local upgrade = registered_upgrades[upgradeid]
		if upgrade.on_upgrade then
			upgrade.on_upgrade(player)
		end
		pts = pts - price
		sf_resources.set_resource_count(player, price_type, pts)
		return true
	end
	-- Already has upgrade
	return false, "has_already"
end

-- Returns true if player has upgrade
sf_upgrade.has_upgrade = function(player, upgradeid)
	local pmeta = player:get_meta()
	return pmeta:get_int("sf_upgrade:upgrade__"..upgradeid) == 1
end

-- Returns true if upgrade is unlocked and can be bought
sf_upgrade.upgrade_unlocked = function(player, upgradeid)
	local pmeta = player:get_meta()
	local upgrade = registered_upgrades[upgradeid]

	-- Check the upgrade's dependency
	if upgrade.depends == nil then
		-- No dependency
		return true
	end
	if sf_upgrade.has_upgrade(player, upgrade.depends) then
		-- The player has the dependency
		return true
	else
		-- The player does not have the dependency
		return false
	end
end

-- Give an upgrade to player
sf_upgrade.give_upgrade = function(player, upgradeid)
	local pmeta = player:get_meta()
	pmeta:set_int("sf_upgrade:upgrade__"..upgradeid, 1)
	local upgrade = registered_upgrades[upgradeid]
	upgrade.on_apply(player)
	minetest.log("action", "[sf_upgrade] Upgrade '"..upgradeid.."' given to "..player:get_player_name())
end

-- Remove an upgrade from player, if it active
sf_upgrade.remove_upgrade = function(player, upgradeid)
	local pmeta = player:get_meta()
	if pmeta:get_int("sf_upgrade:upgrade__"..upgradeid) == 1 then
		pmeta:set_int("sf_upgrade:upgrade__"..upgradeid, 0)
		local upgrade = registered_upgrades[upgradeid]
		upgrade.on_unapply(player)
		minetest.log("action", "[sf_upgrade] Upgrade '"..upgradeid.."' removed from "..player:get_player_name())
	end
end

-- Remove all active upgrades from player
sf_upgrade.remove_all_upgrades = function(player)
	local pmeta = player:get_meta()
	for upgradeid, upgrade in pairs(registered_upgrades) do
		if pmeta:get_int("sf_upgrade:upgrade__"..upgradeid) == 1 then
			pmeta:set_int("sf_upgrade:upgrade__"..upgradeid, 0)
			upgrade.on_unapply(player)
		end
	end
	minetest.log("action", "[sf_upgrade] All upgrades removed from "..player:get_player_name())
end

-- Give all possible upgrades to player
sf_upgrade.give_all_upgrades = function(player)
	local pmeta = player:get_meta()
	for upgradeid, upgrade in pairs(registered_upgrades) do
		if pmeta:get_int("sf_upgrade:upgrade__"..upgradeid) == 0 then
			pmeta:set_int("sf_upgrade:upgrade__"..upgradeid, 1)
			upgrade.on_apply(player)
		end
	end
	minetest.log("action", "[sf_upgrade] All upgrades given to "..player:get_player_name())
end

local upgrade_tree_to_formstring = function(tree, player)
	local buttons = "" -- formspec string fo buttons
	local connectors = "" -- lines that show the upgrade dependencies
	local x, y = 0, 0
	local selection = player_states[player:get_player_name()].selected_upgrade
	for c=1, #registered_categories do
		local categoryname = registered_categories[c]
		local category = tree[categoryname]
		for u=1, #category do
			local upgradeid = category[u]
			local upgrade = registered_upgrades[upgradeid]
			local uicon = upgrade.icon or FALLBACK_UPGRADE_ICON
			local icon = uicon
			if not sf_upgrade.upgrade_unlocked(player, upgradeid) then
				icon = "("..icon.."^[hsl:0:-100:0)"
			end
			if sf_upgrade.has_upgrade(player, upgradeid) then
				icon = "sf_upgrade_has_upgrade.png^"..icon
			end
			if selection == upgradeid then
				icon = icon.."^sf_upgrade_selected_upgrade.png"
			end
			-- Add upgrade button (and tooltip)
			buttons = buttons .. "image_button["..x..","..y..";1,1;"..
				icon..";upgrade__"..upgradeid..";]"
			buttons = buttons .. "tooltip[upgrade__"..upgradeid..";"..FS(upgrade.name).."]"

			-- Draw dependency line
			if u < #category then
				connectors = connectors .. "box["..(x+0.45)..","..(y+0.9)..";0.1,0.45;#00000080]"
			end
			y = y + 1.25
		end
		x = x + 1.25
		y = 0
	end
	local form = connectors .. buttons
	return form
end

sf_upgrade.show_upgrade_formspec = function(player)
	local pname = player:get_player_name()

	-- Get selected upgrade
	local sel = player_states[pname].selected_upgrade
	local sel_icon, sel_namedesc, sel_price, sel_buy = "", "", "", ""
	if sel then
		local upgrade = registered_upgrades[sel]
		local icon = upgrade.icon or FALLBACK_UPGRADE_ICON
		if not sf_upgrade.upgrade_unlocked(player, sel) then
			icon = icon.."^[hsl:0:-100:0"
		end
		sel_icon = "image[0.25,0.25;1.5,1.5;"..icon.."]"
		sel_namedesc = "textarea[2,0.25;2.75,1.5;;;"..FS(upgrade.name).."\n\n"..FS(upgrade.description).."]"

		if sf_upgrade.has_upgrade(player, sel) then
			sel_price = "label[0.25,0.4;"..minetest.colorize("#50FF50", FS("You have this upgrade.")).."]"
		elseif not sf_upgrade.upgrade_unlocked(player, sel) then
			sel_price = "label[0.25,0.4;"..FS("Upgrade locked.").."]"
		else
			local resource = sf_resources.registered_resources[upgrade.price_type]
			local player_has = sf_resources.get_resource_count(player, upgrade.price_type)
			sel_price = "label[0.25,0.40;"..FS("Cost:").."]" ..
				"image[0.25,0.75;0.5,0.5;"..resource.icon.."]" ..
				"tooltip[0.25,0.75;0.5,0.5;"..minetest.formspec_escape(resource.description).."]" ..
				"label[0.95,1;"..FS("×@1", upgrade.price).."]" ..
				"label[0.25,1.65;"..FS("In inventory: @1", player_has).."]"
			sel_buy = "button[3,1;1,0.75;buy;"..FS("Get").."]"
		end
	end

	local upgrade_tree_formstring = upgrade_tree_to_formstring(upgrade_tree, player)

	local form = [=[
formspec_version[6]
size[10,9.3]
box[0.25,0.25;9.5,0.7;#ff8000]
label[0.5,0.6;]=]..FS("Upgrades")..[=[]
container[0.25,0.95]
        box[0,0;9.5,5.25;#ff800020]
        container[0.25,0.25]
		]=]..upgrade_tree_formstring..[=[
        container_end[]
container_end[]
]=]

	if sel then
		form = form .. [=[
container[0.25,6.7]
	box[0,-0.2;9.5,0.6;#ff8000]
	label[0.25,0.1;]=]..FS("Selected upgrade")..[=[]
	container[0,0.4]
		box[0,0;9.5,2;#ff800020]
		box[5,0;0.25,2;#ff800020]
		container[0,0]
			]=]..sel_icon..sel_namedesc..[=[
		container_end[]
		container[5.25,0]
			]=]..sel_price..sel_buy..[=[
		container_end[]
	container_end[]
container_end[]
]=]
	end
	minetest.show_formspec(pname, "sf_upgrade:upgrade", form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "sf_upgrade:upgrade" then
		return
	end
	local pname = player:get_player_name()

	-- Buy selected upgrade
	if fields.buy then
		local sel = player_states[pname].selected_upgrade
		if not sel then
			return
		end
		local buy_ok, buy_fail_reason = sf_upgrade.buy_upgrade(player, sel)
		if not buy_ok then
			minetest.sound_play({name="sf_upgrade_upgrade_fail", gain=0.8}, {to_player=pname}, true)
		else
			upgrade_particles(player)
			minetest.sound_play({name="sf_upgrade_upgrade", gain=0.5}, {to_player=pname}, true)
			sf_upgrade.show_upgrade_formspec(player)
			minetest.log("action", "[sf_upgrade] "..pname.." bought upgrade "..sel)
		end
		return
	end

	-- Select upgrade
	for upgradeid, upgrade in pairs(registered_upgrades) do
		if fields["upgrade__"..upgradeid] then
			player_states[pname].selected_upgrade = upgradeid
			sf_upgrade.show_upgrade_formspec(player)
			break
		end
	end
end)

minetest.register_chatcommand("remove_upgrades", {
	description = S("Remove all your upgrades"),
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		sf_upgrade.remove_all_upgrades(player)
		return true, S("All upgrades removed.")
	end,
})

minetest.register_chatcommand("get_upgrades", {
	description = S("Get all upgrades"),
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		sf_upgrade.give_all_upgrades(player)
		return true, S("All upgrades received.")
	end,
})

-- Apply the effects of all the player's upgrades initially
local init_apply_upgrades = function(player)
	local pmeta = player:get_meta()
	for upgradeid, upgrade in pairs(registered_upgrades) do
		local has = pmeta:get_int("sf_upgrade:upgrade__"..upgradeid) == 1
		if has then
			upgrade.on_apply(player)
		end
	end
end

minetest.register_on_joinplayer(function(player)
	player_states[player:get_player_name()] = {}

	-- Apply upgrade effects on join
	init_apply_upgrades(player)
end)
minetest.register_on_leaveplayer(function(player)
	player_states[player:get_player_name()] = nil
end)
