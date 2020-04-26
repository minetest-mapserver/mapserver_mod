
local last_index = 0
local last_line = ""

local update_formspec = function(meta)
	local line = meta:get_string("line")
	local station = meta:get_string("station")
	local index = meta:get_string("index")
	local color = meta:get_string("color") or ""

	meta:set_string("infotext", "Train: Line=" .. line .. ", Station=" .. station)

	meta:set_string("formspec", "size[8,4;]" ..
		-- col 1
		"field[0,1;4,1;line;Line;" .. line .. "]" ..
		"button_exit[4,1;4,1;save;Save]" ..

		-- col 2
		"field[0,2.5;4,1;station;Station;" .. station .. "]" ..
		"field[4,2.5;4,1;index;Index;" .. index .. "]" ..

		-- col 3
		"field[0,3.5;4,1;color;Color;" .. color .. "]" ..
		""
	)

end


minetest.register_node("mapserver:train", {
	description = "Mapserver Train",
	tiles = {
		"mapserver_train.png"
	},
	groups = {cracky=3,oddly_breakable_by_hand=3},
	sounds = moditems.sound_glass(),
	can_dig = mapserver.can_interact,
	after_place_node = mapserver.after_place_node,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)

		last_index = last_index + 5

		meta:set_string("station", "")
		meta:set_string("line", last_line)
		meta:set_int("index", last_index)
		meta:set_string("color", "")

		update_formspec(meta)
	end,

	on_receive_fields = function(pos, formname, fields, sender)

		if not mapserver.can_interact(pos, sender) then
			return
		end

		local meta = minetest.get_meta(pos)

		if fields.save then
			last_line = fields.line
			meta:set_string("color", fields.color)
			meta:set_string("line", fields.line)
			meta:set_string("station", fields.station)
			local index = tonumber(fields.index)
			if index ~= nil then
				last_index = index
				meta:set_int("index", index)
			end
		end

		update_formspec(meta)
	end
})

if mapserver.enable_crafting then
	minetest.register_craft({
	    output = 'mapserver:train',
	    recipe = {
				{"", moditems.steel_ingot, ""},
				{moditems.paper, moditems.goldblock, moditems.paper},
				{"", moditems.glass, ""}
			}
	})
end
