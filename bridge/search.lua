local FORMNAME = "mapserver_mod_search_results"

-- playername -> {}
local search_results = {}

-- playername = <item>
local selected_item_data = {}

minetest.register_on_leaveplayer(function(player)
	search_results[player:get_player_name()] = nil
	selected_item_data[player:get_player_name()] = nil
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMNAME then
		return
	end

	local selected_item = 0
	local playername = player:get_player_name()

	if fields.items then
		local parts = fields.items:split(":")
		if parts[1] == "CHG" then
			selected_item = tonumber(parts[2]) - 1
		end
	end

	if selected_item > 0 then
		local data = search_results[playername]
		local item = data[selected_item]

		selected_item_data[playername] = item
	end

	local item = selected_item_data[playername]
	if not item then
		return
	end

	if fields.teleport then
		-- teleport player to selected item
		if not minetest.check_player_privs(playername, "teleport") then
			minetest.chat_send_player(playername, "Missing priv: 'teleport'")
			return
		end

		-- flat destination coordinates per default
		local pos1 = vector.subtract(item.pos, {x=2, y=0, z=2})
		local pos2 = vector.add(item.pos, {x=2, y=0, z=2})

		if item.type == "bones" then
			-- search for air _above_ the bones
			pos1 = vector.subtract(item.pos, {x=0, y=0, z=0})
			pos2 = vector.add(item.pos, {x=0, y=10, z=0})
		end

		-- forceload target coordinates before searching for air
		minetest.get_voxel_manip():read_from_map(pos1, pos2)
		local nodes = minetest.find_nodes_in_area(pos1, pos2, "air")

		if #nodes > 0 then
			player:set_pos(nodes[1])
			minetest.sound_play("whoosh", {pos = nodes[1], gain = 0.5, max_hear_distance = 10})
		end
	elseif fields.show then
		mapserver.show_waypoint(playername, item.pos, item.description, 60)
	end

end)


local function show_formspec(playername, data)
	local list = ""
	local player = minetest.get_player_by_name(playername)

	if not player then
		return
	end

	local player_pos = player:get_pos()

	-- populate pos and distance field
	for i, item in ipairs(data) do
		item.pos = {x=item.x, y=item.y, z=item.z}
		item.distance = math.floor(vector.distance(item.pos, player_pos))
	end

	-- sort by distance
	table.sort(data, function(a,b)
		return a.distance < b.distance
	end)

	-- store as last result
	search_results[playername] = data

	-- render list items
	for _, item in ipairs(data) do
		local owner = item.attributes.owner
		local distance = math.floor(item.distance) .. " m"
		local coords = item.pos.x .. "/" .. item.pos.y .. "/" .. item.pos.z
		local description = ""
		local color = "#FFFFFF"
		local add_to_list = true

		-- don't trust any values in attributes, they might not be present
		if item.type == "bones" then
			-- bone
			description = minetest.formspec_escape(
				(item.attributes.info or "?") ..
				" items: " .. (item.attributes.item_count or "?")
			)

		elseif item.type == "shop" then
			-- shop

			if item.attributes.stock == "0" then
				-- don't add empty vendors to the list
				add_to_list = false
			else
				-- stocked shop
				description = minetest.formspec_escape("Shop, " ..
					"trading " .. (item.attributes.out_count or "?") ..
					"x " .. (item.attributes.out_item or "?") ..
					" for " .. (item.attributes.in_count or "?") ..
					"x " .. (item.attributes.in_item or "?") ..
					" Stock: " .. (item.attributes.stock or "?")
				)
			end

		elseif item.type == "poi" then
			-- point of interest
			description = minetest.formspec_escape(
				(item.attributes.name or "?") ..
				" (owner: " .. (item.attributes.owner or "?") .. ")"
			)
		end

		-- save description
		item.description = description

		if add_to_list then
			list = list .. "," ..
				color .. "," ..
				distance .. "," ..
				(owner or "?") .. "," ..
				coords .. "," ..
				description
		end

	end

	list = list .. ";]"

	local teleport_button = ""

	-- show teleport button
	if minetest.check_player_privs(playername, "teleport") then
		teleport_button = "button_exit[4,11;4,1;teleport;Teleport]"
	end

		local formspec = [[
				size[16,12;]
				label[0,0;Search results (]] .. #data .. [[)]
				button_exit[0,11;4,1;show;Show]
				]] .. teleport_button .. [[
				button_exit[12,11;4,1;exit;Exit]
				tablecolumns[color;text;text;text;text]
				table[0,1;15.7,10;items;#999,Distance,Owner,Coords,Description]] .. list

		minetest.show_formspec(playername, FORMNAME, formspec)
end

-- valid search types
local valid_types = {
	shop = true,
	bones = true,
	poi = true
}

-- global values, passed by init
local http, url

-- chatcommand
minetest.register_chatcommand("search", {
	description = "Search for shops or bones near you. Syntax: /search [bones|shop] [<query>|*]\n"
		.. "e.g. /search bones *",
	func = function(playername, param)

		local _, _, type, query = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
		if type == nil or query == nil or not valid_types[type] then
			minetest.chat_send_player(playername, "syntax: /search [bones|shop|poi] [<query>|*]")
			return
		end

		local json = "{"

		json = json .. '"pos1": {"x":-2048, "y":-2048, "z":-2048},'
		json = json .. '"pos2": {"x":2048, "y":2048, "z":2048},'
		json = json .. '"type":"' .. type .. '"'

		-- switch between types of queries
		-- search for "out_item" if it is a shop or for "owner" if bones are wanted
		local key_name = "unknown"
		if type == "poi" then
			key_name = "name"
		elseif type == "bones" then
			key_name = "owner"
		elseif type == "shop" then
			key_name = "out_item"
		end

		if query and query ~= "*" then
			json = json .. ','
			json = json .. '"attributelike":{'
			json = json .. '"key":"' .. key_name .. '",'
			json = json .. '"value":"%' .. query .. '%"'
			json = json .. "}"
		end

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
					minetest.chat_send_player(playername, "Got " .. #data .. " results")
					show_formspec(playername, data)
				else
					minetest.chat_send_player(playername, "Query failed, no results!")
				end
			else
				minetest.chat_send_player(playername, "Query failed, http-status: " .. (res.status or "<none>"))
			end
	  end)



		return true, "Searching for: " .. type .. " '" .. query .. "' ..."
	end
})

function mapserver.search_init(_http, _url)
	http = _http
	url = _url
end
