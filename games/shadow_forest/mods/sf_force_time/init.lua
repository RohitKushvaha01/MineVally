-- HACK:
-- Constantly reset the time of day to middday to keep the sky consistent

local time_timer = 0
minetest.register_globalstep(function(dtime)
	time_timer = time_timer + dtime
	if time_timer > 5 then
		minetest.set_timeofday(0.5)
		time_timer = 0
	end
end)
