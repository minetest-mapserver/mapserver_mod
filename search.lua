
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
						print( dump(data) )
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
