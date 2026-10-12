
local http, url, key = ...

local api = {}

local extra_headers_auth_json = { "Content-Type: application/json", "Authorization: " .. key }

-- stats to mapserver
function api.send_stats(stats, callback)
    http.fetch({
        url = url .. "/api/luanti/stats",
        extra_headers = extra_headers_auth_json,
        timeout = 5,
        post_data = minetest.write_json(stats),
        quiet = true
    }, callback or function() end)
end

-- search-result query
function api.search(json, callback)
    http.fetch({
        url = url .. "/api/mapobjects/",
        timeout = 10,
        extra_headers = { "Content-Type: application/json" },
        post_data = json,
        quiet = true
    }, callback)
end

-- node definitions to mapserver
function api.send_nodedefs(nodedefs, callback)
    http.fetch({
        url = url .. "/api/luanti/nodedefs",
        extra_headers = extra_headers_auth_json,
        timeout = 5,
        post_data = minetest.write_json(nodedefs),
        quiet = true
    }, callback)
end

return api