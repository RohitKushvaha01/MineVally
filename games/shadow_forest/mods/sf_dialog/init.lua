sf_dialog = {}
local S = minetest.get_translator("sf_dialog")

local DEFAULT_DURATION = 4000000
local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local speakers = {
	light_orb = { image = "sf_messages_speaker_light_orb.png", sound = {name="sf_messages_speaker_light_orb", gain=0.3} },
	wizard = { image = "sf_messages_speaker_wizard.png", sound = {name="sf_messages_speaker_wizard", gain=0.3} },
	shadow_orb = { image = "sf_messages_speaker_shadow_orb.png", sound = {name="sf_messages_speaker_light_orb", gain=0.6, pitch=0.5} },
	meta = { image = "blank.png", sound = {name="sf_messages_speaker_light_orb", gain=0.5} },
}
local orb = speakers.light_orb
local wiz = speakers.wizard
local sha = speakers.shadow_orb
local met = speakers.meta

local dialog_texts = {
	["intro"] = { texts = {
		{ orb, S("The forest is dying and all you do is run!"), },
		{ wiz, S("We’re heading towards safety."), },
		{ orb, S("This land is cursed by eternal darkness."), },
		{ orb, S("And the Shadows keep terrorizing us."), },
		{ wiz, S("Don’t worry, Light Orb! I have a plan."), },
	}},
	["intro2"] = { texts = {
		{ wiz, S("Ahh! The Tree of Life!"), },
		{ orb, S("It looks very overgrown."), },
		{ wiz, S("There are green portals inside … they’re important."), },
		{ wiz, S("They connect various parts of the forest."), },
	}},
	["intro3"] = { texts = {
		{ orb, S("Sir, what are we doing here?"), },
		{ wiz, S("We look for light crystals."), },
		{ orb, S("Why?"), },
		{ wiz, S("You’ll see."), },
	}},
	["enemy_hint"] = { texts = {
		{ orb, S("The shadows attack!"), },
		{ wiz, S("Time to use the staff of light!"), },
	}},
	["boss"] = { texts = {
		{ sha, S("You dare you disturb the mighty Shadow Orb!") },
		{ sha, S("Prepare to die!") },
	}},
	["outro"] = { texts = {
		{ wiz, S("BOOM! Take that!"), },
		{ orb, S("This must have been the source of the Shadows."), },
		{ wiz, S("Yes."), },
		{ orb, S("So will the forest return to normal?"), },
		{ wiz, S("Yes. But it will take time to heal …"), },
		{ met, S("THANK YOU FOR PLAYING SHADOW FOREST!") },
	}},
	["chimneys"] = { texts = {
		{ orb, S("What is this monstrosity?") },
		{ wiz, S("I don’t know. I’ve never seen something like this.") },
		{ orb, S("Well, this is unexpected …") },
		{ wiz, S("That black stuff coming out from the top …") },
		{ wiz, S("… it doesn’t look healthy.") },
		{ wiz, S("Whatever it is, I’ll put an end to this!") },
	}},
	["campfire"] = { texts = {
		{ wiz, S("I can use the campfire to improve my skills.") },
	}},
	["shadow_fragment"] = { texts = {
		{ orb, S("You found a shadow fragment!"), },
		{ orb, S("Use them to improve your skills.") },
	}},
	["healing_essence"] = { texts = {
		{ orb, S("You found a healing essence!"), },
		{ orb, S("Use them to increase your health.") },
	}},
	["respawn"] = { texts = {
		{ wiz, S("My head hurts …") },
		{ orb, S("Sir! You’re alive!") },
		{ wiz, S("Seems like the Tree of Life is on our side.") },
	}},
	["first_shadow_fragment_loss"] = { texts = {
		{ orb, S("You’ve lost all shadow fragments.") },
	}},
	["brighter"] = { texts = {
		{ orb, S("I'm feeling very bright!") },
	}},
	["first_light_crystal"] = { texts = {
		{ orb, S("A light crystal!"), },
		{ orb, S("But what do we do with it?"), },
		{ wiz, S("You’ll see …"), },
	}},
	["bush_spell_early"] = { texts = {
		{ orb, S("The shadow bushes are blocking the way."), },
		{ wiz, S("I need more light crystals!"), },
	}},
	["bush_spell"] = { texts = {
		{ wiz, S("OMENA TENMU GNURF PELMI!"), },
		{ orb, S("Oh, THAT’S why you needed the light crystals!"), },
	}},
	["darkness_warning"] = { texts = {
		{ orb, S("This place is so dark, not even I can light it up.") },
		{ orb, S("I sense a great danger …") },
	}},
	["darkness_damage"] = { texts = {
		{ orb, S("The shadows are violent! Turn back!") }
	}},
}

-- Displays every possible dialog text of the game
function sf_dialog.dialog_test(player)
	for did, dialog in pairs(dialog_texts) do
	local texts = dialog.texts
		for t=1, #texts do
			local textdata = texts[t]
			local speakerinfo = textdata[1]
			local message = textdata[2]
			sf_messages.show_speech(player, message, speakerinfo.image, speakerinfo.sound, 400000)
		end
	end
end

function sf_dialog.show_dialog(player, id, only_once)
	if EDITOR then
		return
	end
	if only_once then
		-- Don't repeat the same message
		local pmeta = player:get_meta()
		local gotten = pmeta:get_int("sf_dialog:gotten__"..id)
		if gotten == 1 then
			return
		end
		pmeta:set_int("sf_dialog:gotten__"..id, 1)
	end
	local texts = dialog_texts[id].texts
	for t=1, #texts do
		local textdata = texts[t]
		local speakerinfo = textdata[1]
		local message = textdata[2]
		sf_messages.show_speech(player, message, speakerinfo.image, speakerinfo.sound, DEFAULT_DURATION)
	end
end

function sf_dialog.reset_dialogs(player)
	local pmeta = player:get_meta()
	for id, _ in pairs(dialog_texts) do
		pmeta:set_int("sf_dialog:gotten__"..id, 0)
	end
end

minetest.register_chatcommand("reset_dialogs", {
	privs = { server = true },
	params = "",
	description = S("Set the state of all dialog texts to “unseen” so they can appear again."),
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player == nil or not player:is_player() then
			return false, S("Player does not exist.")
		end
		sf_dialog.reset_dialogs(player)
		return true, S("Done.")
	end,
})

