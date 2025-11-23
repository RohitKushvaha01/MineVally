sf_sky = {}
local registered_skies = {}

local EDITOR = minetest.settings:get_bool("sf_editor", false) or minetest.settings:get_bool("creative_mode", false)

local function register_sky(name, def)
	registered_skies[name] = def
end

function sf_sky.set_sky(player, skyname)
	local skydef = registered_skies[skyname]
	player:set_sky(skydef.sky)
	player:set_clouds(skydef.clouds)
	player:set_sun(skydef.sun)
	player:set_moon(skydef.moon)
	player:set_stars(skydef.stars)
	player:override_day_night_ratio(skydef.day_night_ratio)
end

register_sky("storm_clouds", {
        sky = {
                sky_color = {
                        night_horizon = "#404040",
                        night_sky = "#303030",
                        dawn_horizon = "#404040",
                        dawn_sky = "#303030",
                        day_horizon = "#404040",
                        day_sky = "#303030",
                        indoors = "#000000",
                },
                fog = {
                        fog_distance = 100,
                        fog_start = -1,
                },
                clouds = true,
        },
        clouds = {
                density = 0.55,
		color = "#20202080",
		thickness = 60,
		speed = { x = 10, y = 0 },
        },
        sun = {
                visible = false,
                sunrise_visible = false,
        },
        moon = {
                visible = false,
        },
        stars = {
                visible = false,
        },
        day_night_ratio = 0.5,
})

register_sky("smoky_clouds", {
        sky = {
                sky_color = {
                        night_horizon = "#303030",
                        night_sky = "#202020",
                        dawn_horizon = "#303030",
                        dawn_sky = "#202020",
                        day_horizon = "#303030",
                        day_sky = "#202020",
                        indoors = "#000000",
                },
                fog = {
                        fog_distance = 50,
                        fog_start = 0.5,
                },
                clouds = true,
        },
        clouds = {
                density = 0.6,
		color = "#202020b0",
		thickness = 60,
		speed = { x = 10, y = 0 },
        },
        sun = {
                visible = false,
                sunrise_visible = false,
        },
        moon = {
                visible = false,
        },
        stars = {
                visible = false,
        },
        day_night_ratio = 0.4,
})

register_sky("fog", {
        sky = {
                sky_color = {
                        night_horizon = "#909090",
                        night_sky = "#808080",
                        dawn_horizon = "#909090",
                        dawn_sky = "#808080",
                        day_horizon = "#909090",
                        day_sky = "#808080",
                        indoors = "#000000",
                },
                fog = {
                        fog_distance = 10,
                        fog_start = 0.1,
                },
                clouds = false,
        },
        sun = {
                visible = false,
                sunrise_visible = false,
        },
        moon = {
                visible = false,
        },
        stars = {
                visible = false,
        },
        day_night_ratio = 0.5,
})
register_sky("fog_underground", {
        sky = {
                sky_color = {
                        night_horizon = "#909090",
                        night_sky = "#808080",
                        dawn_horizon = "#909090",
                        dawn_sky = "#808080",
                        day_horizon = "#909090",
                        day_sky = "#808080",
                        indoors = "#000000",
                },
                fog = {
                        fog_distance = 70,
                        fog_start = 0.5,
                },
                clouds = false,
        },
        sun = {
                visible = false,
                sunrise_visible = false,
        },
        moon = {
                visible = false,
        },
        stars = {
                visible = false,
        },
        day_night_ratio = 0.5,
})

register_sky("night", {
	sky = {
		sky_color = {
			night_horizon = "#000020",
			night_sky = "#000020",
			dawn_horizon = "#000020",
			dawn_sky = "#000020",
			day_horizon = "#000020",
			day_sky = "#000020",
			indoors = "#000000",
		},
		fog = {
			fog_distance = -1,
			fog_start = -1,
		},
		clouds = true,
	},
	clouds = {
		density = 0.8,
		thickness = 3,
	},
	sun = {
		visible = true,
		sunrise_visible = false,
	},
	moon = {
		visible = true,
	},
	stars = {
		visible = true,
	},
	day_night_ratio = 0.3,
})

register_sky("darkness", {
	sky = {
		sky_color = {
			night_horizon = "#000000",
			night_sky = "#000000",
			dawn_horizon = "#000000",
			dawn_sky = "#000000",
			day_horizon = "#000000",
			day_sky = "#000000",
			indoors = "#000000",
		},
		fog = {
			fog_distance = 10,
			fog_start = 0.2,
		},
		clouds = false,
	},
	sun = {
		visible = false,
		sunrise_visible = false,
	},
	moon = {
		visible = false,
	},
	stars = {
		visible = false,
	},
	day_night_ratio = 0.1,
})


minetest.register_on_joinplayer(function(player)
	if not EDITOR then
		sf_sky.set_sky(player, "storm_clouds")
	end
end)
