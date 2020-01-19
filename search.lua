local FORMNAME = "mapserver_mod_search_results"

--[[
{
	x = -107,
	mtime = 1579447326,
	mapblock = {
		y = 0,
		x = -7,
		z = -4
	},
	attributes = {
		in_item = "mapserver:train",
		out_count = "1",
		type = "fancyvend",
		stock = "0",
		owner = "BuckarooBanzai",
		in_count = "1",
		out_item = "fancy_vend:player_vendor"
	},
	y = 4,
	z = -52,
	type = "shop"
}

--]]


local function show_formspec(playername, data)

	local list = ""

	for _, item in ipairs(data) do
		local name = item.type
		local coords = item.x .. "/" .. item.y .. "/" .. item.z
		local description = "Desc"

		list = list .. ",#FFD700," .. name .. "," .. coords .. "," .. description

	end

	list = list .. ";]"

		local formspec = [[
				size[8,12;]
				label[0,0;Search results] ..
				button_exit[0,12;4,1;show;Show]
				tablecolumns[color;text;text;text]
				table[0,0;8,10;messages;#999,Type,Coords,Description
		]] .. list

		minetest.show_formspec(playername, FORMNAME, formspec)
end

function mapserver.search_init(http, url)
	minetest.register_chatcommand("search", {
		func = function(name, query)

			local json = "{"

			json = json .. '"pos1": {"x":-2048, "y":-2048, "z":-2048},'
			json = json .. '"pos2": {"x":2048, "y":2048, "z":2048},'
			json = json .. '"type":"shop",'

			json = json .. '"attributelike":{'
			json = json .. '"key":"out_item",'
			json = json .. '"value":"%' .. query .. '%"'
			json = json .. "}"

			json = json .. "}"

			http.fetch({
		    url = url .. "/api/mapobjects/",
		    timeout = 10,
				extra_headers = { "Content-Type: application/json" },
		    post_data = json
		  }, function(res)
				if res.code == 200 then
					local data = minetest.parse_json(res.data)
					if data and #data > 0 then
						print( dump(data) ) --XXX
						show_formspec(name, data)
					else
						minetest.chat_send_player(name, "Query failed, no results!")
					end
				else
					minetest.chat_send_player(name, "Query failed, http-status: " .. (res.status or "<none>"))
				end
		  end)



			return true, "Searching for: '" .. query .. "' ..."
		end
	})
end
