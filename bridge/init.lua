local MP = minetest.get_modpath("mapserver")
dofile(MP .. "/bridge/defaults.lua")
dofile(MP .. "/bridge/players.lua")
dofile(MP .. "/bridge/advtrains.lua")
dofile(MP .. "/bridge/minecart.lua")
dofile(MP .. "/bridge/locator.lua")


-- mapserver http bridge
local has_advtrains = minetest.get_modpath("advtrains")
local has_minecart = minetest.get_modpath("minecart")
local has_locator = minetest.get_modpath("locator")
local has_monitoring = minetest.get_modpath("monitoring")

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

  if has_minecart then
    -- send minecarts positions if mod is installed
    mapserver.bridge.add_minecart(data)
  end

  if has_advtrains then
    -- send trains if 'advtrains' mod installed
    mapserver.bridge.add_advtrains(data)
  end

  if has_locator then
	-- send locator beacons
	mapserver.bridge.add_locators(data)
  end


  local json = minetest.write_json(data)
  --print(json)--XXX

  local t1 = minetest.get_us_time()
  local process_time = t1 - t0
  if process_time > 10000 then
    minetest.log("warning", "[mapserver-bridge] processing took " .. process_time .. " us")
  end

  local size = string.len(json)
  if size > 256000 then
    minetest.log("warning", "[mapserver-bridge] json-size is " .. size .. " bytes")
  end

  http.fetch({
    url = url .. "/api/minetest",
    extra_headers = { "Content-Type: application/json", "Authorization: " .. key },
    timeout = 5,
    post_data = json
  }, function(res)

    local t2 = minetest.get_us_time()
    local post_time = t2 - t1
    if post_time > 1000000 then -- warn if over a second
      minetest.log("warning", "[mapserver-bridge] post took " .. post_time .. " us")
    end

    if has_monitoring then
	    metric_post_size.inc(size)
	    metric_processing_post_time.inc(process_time)
	    metric_post_time.inc(post_time)
    end

    -- TODO: error-handling
    minetest.after(mapserver.send_interval, send_stats)
  end)

end

function mapserver.bridge_init(_http, _url, _key)
  http = _http
  url = _url
  key = _key

  minetest.after(mapserver.send_interval, send_stats)
end
