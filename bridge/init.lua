local MP = minetest.get_modpath("mapserver")
dofile(MP .. "/bridge/defaults.lua")
dofile(MP .. "/bridge/players.lua")
dofile(MP .. "/bridge/advtrains.lua")
dofile(MP .. "/bridge/locator.lua")


-- mapserver http bridge
local has_advtrains = minetest.get_modpath("advtrains")
local has_locator = minetest.get_modpath("locator")

local has_airutils = minetest.get_modpath("airutils")
if has_airutils then
	dofile(MP .. "/bridge/airutils_planes.lua")
end

function send_stats()
	-- data to send to mapserver
	local data = {}

	mapserver.bridge.add_players(data)
	mapserver.bridge.add_defaults(data)

	if has_advtrains then
		-- send trains if 'advtrains' mod installed
		mapserver.bridge.add_advtrains(data)
	end

	if has_locator then
		-- send locator beacons
		mapserver.bridge.add_locators(data)
	end

	if has_airutils then
		-- send airutils plane entities
		mapserver.bridge.add_airutils_planes(data)
	end

	mapserver.api.send_stats(data, function()
		-- re-schedule
		minetest.after(mapserver.send_interval, send_stats)
	end)
end

function mapserver.bridge_init()
	minetest.after(mapserver.send_interval, send_stats)
end
