local MP = minetest.get_modpath("mapserver")
dofile(MP .. "/bridge/defaults.lua")
dofile(MP .. "/bridge/players.lua")
dofile(MP .. "/bridge/advtrains.lua")
dofile(MP .. "/bridge/locator.lua")


-- mapserver http bridge
local has_advtrains = minetest.get_modpath("advtrains")
local has_locator = minetest.get_modpath("locator")
local has_monitoring = minetest.get_modpath("monitoring")

local has_airutils = minetest.get_modpath("airutils")
if has_airutils then
	dofile(MP .. "/bridge/airutils_planes.lua")
end

local metric_post_size
local metric_processing_post_time
local metric_post_time

if has_monitoring then
	metric_post_size = monitoring.counter(
		"mapserver_mod_post_size",
		"size in bytes of post data"
	)
	metric_processing_post_time = monitoring.counter(
		"mapserver_mod_processing_post_time",
		"time usage in microseconds for processing post data"
	)
	metric_post_time = monitoring.counter(
		"mapserver_mod_post_time",
		"time usage in microseconds for post data"
	)
end

local http, url, key

function send_stats()
	local t0 = minetest.get_us_time()

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
