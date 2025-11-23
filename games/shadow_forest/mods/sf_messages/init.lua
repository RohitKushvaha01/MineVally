local S = minetest.get_translator("sf_messages")
sf_messages = {}

local current_messages = {}
local speech_queues = {}

local BIG_FONT_AT_WINDOW_WIDTH = 1920

-- Word wrap after this many characters at 100% font size at the reference window width
local WORD_WRAP_CHARS = 71
local WORD_WRAP_REFERENCE_WINDOW_WIDTH = 1920

local BUBBLE_OFFSET_X = 24 -- offset from screen border
local SPEAKER_OFFSET_X = 12 -- offset from speech bubble border
local TEXT_OFFSET_X = 144 -- offset from speaker icon

local BUBBLE_OFFSET_X_TOTAL = BUBBLE_OFFSET_X
local SPEAKER_OFFSET_X_TOTAL = BUBBLE_OFFSET_X + SPEAKER_OFFSET_X
local TEXT_OFFSET_X_TOTAL = BUBBLE_OFFSET_X + SPEAKER_OFFSET_X + TEXT_OFFSET_X

-- Legacy support: Name of the HUD type field for 'hud_add'.
local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Luanti/Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Luanti/Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

-- HACK:
-- Word-wrap a translatable string
-- * player: player to wrap the text for
-- * text: text to word-wrap (must have translation markers)
-- * chars: amount of characters after which to word-wrap
--
-- This is a hack because it modifies the translated string
-- which is discouraged by the Lua API. But hey, we're only
-- in singleplayer so it couldn't be that bad, right?
--
-- Returns text if not in singleplayer.
local hacky_word_wrap = function(player, text, chars)
	if not minetest.is_singleplayer() then
		return text
	end
	local pinfo = minetest.get_player_information(player:get_player_name())
	local translated_text = minetest.get_translated_string(pinfo.lang_code, text)
	local wrapped_text = minetest.wrap_text(translated_text, chars, false)
	return wrapped_text
end

sf_messages.is_showing_speech = function(player)
	local pname = player:get_player_name()
	return current_messages[pname] and current_messages[pname].speech_time ~= nil
end

sf_messages.remove_current_speech = function(from_player)
	local pname = from_player:get_player_name()
	local message = current_messages[pname]
	if not sf_messages.is_showing_speech(from_player) then
		return
	end
	from_player:hud_remove(message.speech_bg)
	from_player:hud_remove(message.speech_text)
	if message.speech_icon then
		from_player:hud_remove(message.speech_icon)
	end
	message.speech_bg = nil
	message.speech_text = nil
	message.speech_icon = nil
	message.speech_sound = nil
	message.speech_time = nil
	message.speech_duration = nil
end

sf_messages.show_speech = function(to_player, text, icon, sound, duration)
	local pname = to_player:get_player_name()
	if not current_messages[pname] then
		current_messages[pname] = {}
	end
	if sf_messages.is_showing_speech(to_player) then
		if not speech_queues[pname] then
			speech_queues[pname] = {}
		end
		local new_entry = { text, icon, sound, duration }
		table.insert(speech_queues[pname], new_entry)
		return
	end

	-- Determine text size depending on window size
	local text_size = { x = 1, y = 1 }
	local window_info = minetest.get_player_window_information(to_player:get_player_name())
	local window_width
	if window_info and window_info.size then
		window_width = window_info.size.x
		if window_info.size.x >= BIG_FONT_AT_WINDOW_WIDTH then
			text_size = { x = 2, y = 2 }
		end
	else
		-- Assume a fallback width if window info cannot be gotten
		window_width = 800
	end

	local id_bg = to_player:hud_add({
		[hud_type_field_name] = "image",
		position = { x = 1, y = 0 },
		scale = { x = -41, y = 10 },
		text = "sf_messages_speech_bubble.png",
		alignment = { x = -1, y = 1 },
		offset = { x = -BUBBLE_OFFSET_X_TOTAL, y = 24 },
		z_index = 100,
	})
	local id_icon
	if icon then
		id_icon = to_player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 1, y = 0 },
			scale = { x = 2, y = 2 },
			text = "sf_messages_portrait_bg.png^("..icon..")",
			offset = { x = - (SPEAKER_OFFSET_X_TOTAL), y = 40 },
			alignment = { x = -1, y = 1 },
			z_index = 101,
		})
	end

	-- Apply a word-wrap to the text
	local effective_text_size = text_size.x * window_info.real_gui_scaling
	local chars = WORD_WRAP_CHARS / math.max(0.1, effective_text_size)

	chars = chars * ( (window_width - (TEXT_OFFSET_X_TOTAL))/WORD_WRAP_REFERENCE_WINDOW_WIDTH)
	chars = math.floor(chars)
	chars = math.max(6, chars)

	text = hacky_word_wrap(to_player, text, chars)

	local id_text = to_player:hud_add({
		[hud_type_field_name] = "text",
		position = { x = 1, y = 0 },
		scale = { x = 100, y = 100 },
		text = text,
		number = 0xFFFFFF,
		alignment = { x = -1, y = 1 },
		size = text_size,
		style = 0,
		offset = { x = -(TEXT_OFFSET_X_TOTAL), y = 34 },
		z_index = 102,
	})
	if sound then
		minetest.sound_play(sound, {to_player=to_player:get_player_name()}, true)
	end
	current_messages[pname].speech_bg = id_bg
	current_messages[pname].speech_icon = id_icon
	current_messages[pname].speech_sound = sound
	current_messages[pname].speech_text = id_text
	local now = minetest.get_us_time()
	current_messages[pname].speech_time = now
	current_messages[pname].speech_duration = duration
end


minetest.register_globalstep(function(dtime)
	local now = minetest.get_us_time()
	for playername, message in pairs(current_messages) do
		local player = minetest.get_player_by_name(playername)
		if player then
			if message.speech_duration and (now > (message.speech_time + message.speech_duration)) then
				sf_messages.remove_current_speech(player)
			end
		end
	end

	for playername, queue in pairs(speech_queues) do
		local player = minetest.get_player_by_name(playername)
		if player and (not sf_messages.is_showing_speech(player)) then
			if #queue >= 1 then
				local entry = queue[1]
				sf_messages.show_speech(player, entry[1], entry[2], entry[3], entry[4])
				table.remove(queue, 1)
			end
		end
	end

end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	current_messages[pname] = nil
	speech_queues[pname] = nil
end)

-- Displays random messages in quick succession to test if it displays correctly.
-- * player: Player to show messages to
-- * count: Count of messages
-- * maxlen: Maximum length of a single message (in characters)
function sf_messages.message_test(player, count, maxlen)
	for c=1, count do
		local len = math.random(1, maxlen or 200)
		local message = ""
		local l = 0
		while l < len do
			if l > 0 then
				message = message .. " "
			end
			local wordlen = math.random(1, 12)
			-- Construct random word
			local word = ""
			for w=1, wordlen do
				local capital = math.random(1,4)
				local char
				local first, last
				if capital == 1 then
					-- capital letter
					first, last = 0x41, 0x5A
				else
					-- lowercase letter
					first, last = 0x61, 0x7A
				end
				local char = string.char(math.random(first, last))
				word = word .. char
			end
			message = message .. word
			l = string.len(message)
		end
		sf_messages.show_speech(player, message, "blank.png", {}, 100000)
	end
end
