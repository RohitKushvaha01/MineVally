sf_music = {}

local current_music = {}

local DEFAULT_TRACK = "shadow_forest"
local FADE_SPEED = 0.15
local ALMOST_OFF_GAIN = 0.001

local tracks = {
	shadow_forest = { name = "sf_music_shadow_forest", gain = 0.5 },
	fog_chasm = { name = "sf_music_fog_chasm", gain = 0.3 },
	crystal = { name = "sf_music_crystal", gain = 0.3 },
}

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	current_music[pname] = {
		track_ids = {}
	}
	for trackname, trackdata in pairs(tracks) do
		local gain
		if trackname == DEFAULT_TRACK then
			gain = trackdata.gain
		else
			gain = ALMOST_OFF_GAIN
		end
		local snd = table.copy(trackdata)
		snd.gain = gain
		local id = minetest.sound_play(snd, {to_player=pname, loop=true})
		current_music[pname].track_ids[trackname] = id
		minetest.log("verbose", "[sf_music] For player '"..pname.."', the track '"..trackname.."' got the sound handle "..tostring(id))
	end
	current_music[pname].current_track = DEFAULT_TRACK
end)

sf_music.change_music = function(player, new_track)
	local pname = player:get_player_name()
	if new_track == current_music[pname].current_track then
		return
	end
	local old_track = current_music[pname].current_track
	local old_track_id = current_music[pname].track_ids[old_track]
	if not old_track_id then
		minetest.log("error", "[sf_music] Unknown old track in sf_music.change_music: "..tostring(old_track))
		return
	end
	minetest.sound_fade(old_track_id, FADE_SPEED, ALMOST_OFF_GAIN)
	local new_track_id = current_music[pname].track_ids[new_track]
	if not new_track_id then
		minetest.log("error", "[sf_music] Unknown track provided for sf_music.change_music: "..tostring(new_track))
		return
	end
	minetest.sound_fade(new_track_id, FADE_SPEED, tracks[new_track].gain)
	current_music[pname].current_track = new_track
end

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	current_music[pname] = nil
end)
