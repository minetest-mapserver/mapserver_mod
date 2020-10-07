local default_path = minetest.get_modpath("default") and default
local mineclone_path = minetest.get_modpath("mcl_core") and mcl_core

moditems = {}

if mineclone_path then
	moditems.sound_glass = mcl_sounds.node_sound_glass_defaults
	moditems.goldblock = "mcl_core:goldblock"
	moditems.steelblock = "mcl_core:ironblock"
	moditems.steel_ingot = "mcl_core:iron_ingot"
	moditems.paper = "mcl_core:paper"
	moditems.glass = "mcl_core:glass"
	moditems.dye = "mcl_dye:"
elseif default_path then
	moditems.sound_glass = default.node_sound_glass_defaults
	moditems.goldblock = "default:goldblock"
	moditems.steelblock = "default:steelblock"
	moditems.steel_ingot = "default:steel_ingot"
	moditems.paper = "default:paper"
	moditems.glass = "default:glass"
	moditems.dye = "dye:"
end

mapserver = {
	enable_crafting = minetest.settings:get("mapserver.enable_crafting") == "true",
	send_interval = tonumber(minetest.settings:get("mapserver.send_interval")) or 2,

	bridge = {}
}

local MP = minetest.get_modpath("mapserver")
dofile(MP.."/common.lua")
dofile(MP.."/poi.lua")
dofile(MP.."/train.lua")
dofile(MP.."/label.lua")
dofile(MP.."/border.lua")
dofile(MP.."/legacy.lua")
dofile(MP.."/privs.lua")
dofile(MP.."/show_waypoint.lua")

if minetest.get_modpath("bones") then
	dofile(MP.."/bones.lua")
end


-- optional mapserver-bridge stuff below
local http = minetest.request_http_api()

if http then
	-- check if the mapserver.json is in the world-folder
	local path = minetest.get_worldpath().."/mapserver.json";
	local mapserver_cfg

	local file = io.open( path, "r" );
	if file then
		local json = file:read("*all");
		mapserver_cfg = minetest.parse_json(json);
		file:close();
		print("[Mapserver] read settings from 'mapserver.json'")
	end

	local mapserver_url = minetest.settings:get("mapserver.url")
	local mapserver_key = minetest.settings:get("mapserver.key")

	if mapserver_cfg and mapserver_cfg.webapi then
		if not mapserver_key then
			-- apply key from json
			mapserver_key = mapserver_cfg.webapi.secretkey
		end
		if not mapserver_url then
			-- assemble url from json
			mapserver_url = "http://127.0.0.1:" .. mapserver_cfg.port
		end
	end

	if not mapserver_url then error("mapserver.url is not defined") end
	if not mapserver_key then error("mapserver.key is not defined") end

	print("[Mapserver] starting mapserver-bridge with endpoint: " .. mapserver_url)
	dofile(MP .. "/bridge/init.lua")

	-- enable ingame map-search
	dofile(MP.."/bridge/search.lua")
	mapserver.search_init(http, mapserver_url)

	-- initialize bridge
	mapserver.bridge_init(http, mapserver_url, mapserver_key)

else
	print("[Mapserver] bridge not active, additional infos will not be visible on the map")

end


print("[OK] Mapserver")

if minetest.settings:get_bool("enable_mapserver_integration_test") then
        dofile(MP.."/integration_test.lua")
end
