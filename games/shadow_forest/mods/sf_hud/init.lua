sf_hud = {}

-- Legacy support: Name of the HUD type field for 'hud_add'.
local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Luanti/Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Luanti/Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

-- experimental dirty/shadowy screen when damaged
local USE_DAMAGE_SCREEN = false
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

-- Damage indicator
local damage_indicators = {}

local DAMAGE_INDICATOR_COLOR = "#ff0000"
local DAMAGE_INDICATOR_ANGLE_STEP = 15
local DAMAGE_INDICATOR_SHOW_TIME = 2.0

local BIG_HP_STATBAR_WINDOW_WIDTH = 1200
local SMALL_HP_STATBAR_WINDOW_WIDTH = 750

local angles = {}
for a=0, 360, DAMAGE_INDICATOR_ANGLE_STEP do
	local angle = a % 360
	local transform
	if angle <= 45 then
		transform = ""
	elseif angle <= 90 then
		transform = "^[transformFYR90"
	elseif angle <= 135 then
		transform = "^[transformR270"
	elseif angle <= 180 then
		transform = "^[transformFY"
	elseif angle <= 225 then
		transform = "^[transformR180"
	elseif angle <= 270 then
		transform = "^[transformFXR90"
	elseif angle <= 315 then
		transform = "^[transformR90"
	else
		transform = "^[transformFX"
	end

	local base = "sf_hud_damage_indicator.png"
	local angle90 = a % 90
	local halfstep = DAMAGE_INDICATOR_ANGLE_STEP/2
	if angle90 <= halfstep then
		base = "sf_hud_damage_indicator.png"
	elseif angle90 <= 3*halfstep then
		base = "sf_hud_damage_indicator_15.png"
	elseif angle90 <= 5*halfstep then
		base = "sf_hud_damage_indicator_30.png"
	elseif angle90 <= 7*halfstep then
		base = "sf_hud_damage_indicator_45.png"
	elseif angle90 <= 9*halfstep then
		base = "sf_hud_damage_indicator_30.png"
	elseif angle90 <= 11*halfstep then
		base = "sf_hud_damage_indicator_15.png"
	else
		base = "sf_hud_damage_indicator.png"
	end
	
	table.insert(angles, {
		angle = a,
		texture = base..transform,
	})
end

sf_hud.show_damage_indicator = function(player, angle)
	local pname = player:get_player_name()
	if not damage_indicators[pname] then
		damage_indicators[pname] = {}
	end
	local angle_deg = (angle/(math.pi*2))*360
	angle_deg = angle_deg % 360
	angle_deg = 360 - angle_deg
	local min_diff = math.huge
	local min_diff_index = 1
	for a=1, #angles do
		local angle_check = angles[a]
		local diff = math.abs(angle_deg - angle_check.angle)
		if diff < min_diff then
			min_diff_index = a
			min_diff = diff
		end
	end
	local base_texture = angles[min_diff_index].texture
		
	local hud_id = player:hud_add({
		[hud_type_field_name] = "compass",
		size = { x = 256, y = 256 },
		text = "("..base_texture..")^[multiply:"..DAMAGE_INDICATOR_COLOR..":100",
		alignment = { x = 0, y = 0 },
		position = { x = 0.5, y = 0.5 },
		offset = { x = 0, y = 0 },
		direction = 1,
		z_index = 1,
	})
	damage_indicators[pname][hud_id] = true
	minetest.after(DAMAGE_INDICATOR_SHOW_TIME, function(param)
		if not param.player:is_player() then
			return
		end
		sf_hud.remove_damage_indicator(param.player, param.hud_id)
	end, {player=player, hud_id=hud_id})
end

sf_hud.remove_damage_indicator = function(player, hud_id)
	local pname = player:get_player_name()
	if damage_indicators[pname] and damage_indicators[pname][hud_id] then
		player:hud_remove(hud_id)
		damage_indicators[pname][hud_id] = nil
	end
end

sf_hud.remove_all_damage_indicators = function(player)
	local pname = player:get_player_name()
	if damage_indicators[pname] then
		for hud_id, _ in pairs(damage_indicators[pname]) do
			player:hud_remove(hud_id)
		end
		damage_indicators[pname] = {}
	end
end

minetest.register_on_dieplayer(function(player)
	sf_hud.remove_all_damage_indicators(player)
end)
minetest.register_on_respawnplayer(function(player)
	sf_hud.remove_all_damage_indicators(player)
end)

-- Damage screen effect
local damage_screens = {}
local damage_screen_positions = {
	[1] = { x = 0.1, y = 0.1 },
	[2] = { x = 0.05, y = 0.4 },
	[3] = { x = 0.2, y = 0.4 },
	[4] = { x = 0.7, y = 0.1 },
	[5] = { x = 0.3, y = 0.3 },
	[6] = { x = 0.7, y = 0.3 },
	[7] = { x = 0, y = 0.5 },
	[8] = { x = 0.5, y = 0 },
	[9] = { x = 0.5, y = 0.1 },
	[10] = { x = 0.3, y = 0.5 },
	[11] = { x = 0, y = 0.74 },
	[12] = { x = 0.3, y = 0.8 },
	[13] = { x = 0.4, y = 0.4 },
	[14] = { x = 0.5, y = 0.3 },
	[15] = { x = 0.7, y = 0 },
	[16] = { x = 0.8, y = 0.1 },
}

local update_damage_screen = function(player, hp)
	if not USE_DAMAGE_SCREEN then
		return
	end
	if not minetest.settings:get_bool("enable_damage", true) then
		return
	end
	local pname = player:get_player_name()
	if not damage_screens[pname] then
		damage_screens[pname] = {}
	end
	local max_hp = player:get_properties().hp_max
	local damage = max_hp - hp
	for d=1, damage do
		if not damage_screens[pname][d] then
			local hud_id = player:hud_add({
				[hud_type_field_name] = "image",
				position = damage_screen_positions[d],
				scale = { x = -30, y = -30 },
				text = "sf_player_damage_screen.png",
				alignment = { x = 1, y = 1 },
				z_index = 1000,
			})
			damage_screens[pname][d] = hud_id
		end
	end
	for d=damage+1, max_hp do
		if damage_screens[pname][d] then
			player:hud_remove(damage_screens[pname][d])
			damage_screens[pname][d] = nil
		end
	end
end

local hp_indicators = {}
local update_hp_display = function(player, hp)
	if not minetest.settings:get_bool("enable_damage", true) then
		return
	end
	local pname = player:get_player_name()
	local window_info = minetest.get_player_window_information(pname)
	local heart_size = { x = 64, y = 64 }
	local heart_offset = { x = 24, y = -74 }
	if window_info and window_info.size then
		if window_info.size.x < SMALL_HP_STATBAR_WINDOW_WIDTH * window_info.real_hud_scaling then
			heart_size = { x = 16, y = 16 }
			heart_offset = { x = 12, y = -30 }
		elseif window_info.size.x < BIG_HP_STATBAR_WINDOW_WIDTH * window_info.real_hud_scaling then
			heart_size = { x = 32, y = 32 }
			heart_offset = { x = 12, y = -50 }
		end
	end

	local hp_max = player:get_properties().hp_max
	if not hp_indicators[pname] then
		local hud_id = player:hud_add({
			[hud_type_field_name] = "statbar",
			position = { x=0,y=1},
			text = "heart.png",
			text2 = "heart_gone.png",
			item = hp_max,
			alignment = { x = 1, y = -1 },
			offset = heart_offset,
			size = heart_size,
			z_index = 0,
			number = hp,
		})
		hp_indicators[pname] = hud_id
	else
		player:hud_change(hp_indicators[pname], "number", hp)
		player:hud_change(hp_indicators[pname], "item", hp_max)
		player:hud_change(hp_indicators[pname], "offset", heart_offset)
		player:hud_change(hp_indicators[pname], "size", heart_size)
	end
end

sf_hud.update_health_hud = function(player)
	local hp = player:get_hp()
	update_damage_screen(player, hp)
	update_hp_display(player, hp)
end

-- Update damage screen
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	local hp = player:get_hp() + hp_change
	update_damage_screen(player, hp)
	update_hp_display(player, hp)
end)

minetest.register_on_punchplayer(function(player, hitter, tflp, tc, dir, damage)
	if damage < 1 then
		return
	end
	if not minetest.settings:get_bool("enable_damage", true) then
		return
	end
	if not hitter then
		return
	end
	local dir_to_hitter = vector.direction(player:get_pos(), hitter:get_pos())
	local yaw = minetest.dir_to_yaw(dir_to_hitter)
	sf_hud.show_damage_indicator(player, yaw)
end)

local hp_update_timer = 0
minetest.register_globalstep(function(dtime)
	hp_update_timer = hp_update_timer + dtime
	if hp_update_timer < 3 then
		return
	end
	hp_update_timer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		update_hp_display(player, player:get_hp())
	end
end)

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({
		minimap = false,
		healthbar = false,
		breath_bar = false,
	})
	update_damage_screen(player, player:get_hp())
	update_hp_display(player, player:get_hp())
	if EDITOR then
		player:hud_set_hotbar_itemcount(8)
		player:hud_set_hotbar_image("sf_hud_hotbar_8.png")
	else
		player:hud_set_hotbar_itemcount(3)
		player:hud_set_hotbar_image("sf_hud_hotbar_3.png")
	end
	player:hud_set_hotbar_selected_image("sf_hud_hotbar_selected.png")

	minetest.after(0.2, function(player)
		if player and player:is_player() then
			sf_hud.update_health_hud(player)
		end
	end, player)
end)

minetest.register_on_leaveplayer(function(player)
	damage_indicators[player:get_player_name()] = nil
	damage_screens[player:get_player_name()] = nil
	hp_indicators[player:get_player_name()] = nil
end)

