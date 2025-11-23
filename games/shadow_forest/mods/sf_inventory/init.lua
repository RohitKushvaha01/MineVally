local S = minetest.get_translator("sf_upgrade")
local FS = function(...) return minetest.formspec_escape(S(...)) end

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local resources_in_inventory = {
	"sf_resources:shadow_fragment",
	"sf_resources:healing_essence",
	"__NEWLINE__",
	"sf_resources:light_crystal",
}

local function update_non_editor_inventory_formspec(player)
	local rstr = ""
	local rxi = 0.6
	local rxl = 1.7
	local ryi = 0.6
	local ryl = ryi + 0.5
	for r=1, #resources_in_inventory do
		local rii = resources_in_inventory[r]
		if rii == "__NEWLINE__" then
			ryi = ryi + 1.1
			ryl = ryl + 1.1
			rxi = 0.6
			rxl = 1.7
		else
			local regres = sf_resources.registered_resources[rii]
			rstr = rstr.."image["..rxi..","..ryi..";1,1;"..regres.icon.."]"
			rstr = rstr.."tooltip["..rxi..","..ryi..";1,1;"..minetest.formspec_escape(regres.description).."]"
			rstr = rstr.."label["..rxl..","..ryl..";"..FS("×@1", sf_resources.get_resource_count(player, rii)).."]"
			rxi = rxi + 1.8
			rxl = rxl + 1.8
		end
	end
	player:set_inventory_formspec([=[
		formspec_version[6]size[11,6]
		]=]..rstr..[=[
		list[current_player;main;0.6,4;3,1;]]=])

end

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	inv:set_size("craft", 0)
	if EDITOR then
		inv:set_size("main", 8*4)
		player:set_inventory_formspec([=[
			formspec_version[6]size[11,6]
			list[current_player;main;0.6,0.6;8,4;]]=])
	else
		inv:set_size("main", 3)
		update_non_editor_inventory_formspec(player)
	end
end)

sf_resources.register_on_resource_change(function(player)
	if not EDITOR then
		update_non_editor_inventory_formspec(player)
	end
end)
