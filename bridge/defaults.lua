
mapserver.bridge.add_defaults = function(data)
  data.time = minetest.get_timeofday() * 24000
  data.uptime = minetest.get_server_uptime()
  data.max_lag = minetest.get_server_max_lag()

end
