
-- possible icons: https://fontawesome.com/icons?d=gallery&s=brands,regular,solid&m=free
-- default: "home"

local update_formspec = function(meta)
	local name = meta:get_string("name")
	local icon = meta:get_string("icon") or "home"
	local addr = meta:get_string("addr") or ""
	local url = meta:get_string("url") or ""
	local image = meta:get_string("image") or ""

	meta:set_string("infotext", "POI, name:" .. name .. ", icon:" .. icon)

	meta:set_string("formspec", "size[8,6;]" ..
		-- col 1
		"field[0.2,1;4,1;name;Name;" .. name .. "]" ..
		"field[4.2,1;4,1;icon;Icon;" .. icon .. "]" ..

		-- col 2
		"field[0.2,2;8,1;addr;Address;" .. addr .. "]" ..

		-- col 3
		"field[0.2,3;8,1;url;URL;" .. url .. "]" ..

		-- col 4
		"field[0.2,4;8,1;image;Image;" .. image .. "]" ..

		-- col 5
		"button_exit[0,5;8,1;save;Save]" ..
		"")

end

local on_receive_fields = function(pos, formname, fields, sender)

	if not mapserver.can_interact(pos, sender) then
		return
	end

	local meta = minetest.get_meta(pos)

	if fields.save then
		meta:set_string("name", fields.name)
		meta:set_string("addr", fields.addr)
		meta:set_string("url", fields.url)
		meta:set_string("image", fields.image)
		meta:set_string("icon", fields.icon or "home")
	end

	update_formspec(meta)
end

local register_poi = function(color, dye)
	minetest.register_node("mapserver:poi_" .. color, {
		description = "Mapserver POI (" .. color .. ")",
		tiles = {
			"[combine:16x16:0,0=mapserver_gold_block.png:3,2=mapserver_poi_" .. color .. ".png"
		},
		groups = {cracky=3,oddly_breakable_by_hand=3,handy=1},
		is_ground_content = false,
		sounds = moditems.sound_glass(),
		can_dig = mapserver.can_interact,
		after_place_node = mapserver.after_place_node,
		_mcl_blast_resistance = 1,
		_mcl_hardness = 0.3,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)

			meta:set_string("name", "<unconfigured>")
			meta:set_string("icon", "home")
			meta:set_string("addr", "")
			meta:set_string("url", "")
			meta:set_string("image", "")

			update_formspec(meta)
		end,

		on_receive_fields = on_receive_fields
	})


	if mapserver.enable_crafting and (minetest.get_modpath("dye") or minetest.get_modpath("mcl_core")) then
		minetest.register_craft({
		    output = 'mapserver:poi_' .. color,
		    recipe = {
					{"", moditems.dye .. dye, ""},
					{moditems.paper, moditems.goldblock, moditems.paper},
					{"", moditems.glass, ""}
				}
		})
	end
end

register_poi("blue", "blue")
register_poi("green", "green")
register_poi("orange", "orange")
register_poi("red", "red")
register_poi("purple", "violet")

-- default poi was always blue
minetest.register_alias("mapserver:poi", "mapserver:poi_blue")
