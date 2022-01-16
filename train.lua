
local advtrains_present = minetest.get_modpath("advtrains") and true or false
local last_set_by = {}

local find_neighbor_blocks -- defined later
local update_neighbors --defined later
local recalculate_line_to -- defined later
local TRAVERSER_LIMIT = 1000

local update_formspec = function(meta)
	local line = meta:get_string("line")
	local station = meta:get_string("station")
	local index = meta:get_string("index")
	local color = meta:get_string("color") or ""
	local rail_pos = meta:get_string("rail_pos") or ""

	local rail_btns = ""
	if advtrains_present then
		if rail_pos == "" then
			rail_btns = "button_exit[4,3.5;2.5,1;set_rail_pos;Set rail]"
		else
			rail_btns = "button_exit[4,3.5;2.5,1;set_rail_pos;" .. rail_pos .. "]" ..
				"button[6.5,3.5;1.5,1;clear_rail_pos;Clear rail]"
		end
	end

	local prv = meta:get_string("prv_pos")
	local path = meta:get_string("linepath_from_prv")
	local nxt = meta:get_string("nxt_pos")

	meta:set_string("infotext", "Train: Line=" .. line .. ", Station=" .. station ..
		(prv ~= "" and (", prv="..prv) or "") ..
		(path ~= "" and " (found line)" or "") ..
		(nxt ~= "" and (", nxt="..nxt) or ""))

	meta:set_string("formspec", "size[8,4;]" ..
		-- col 1
		"field[0,1;4,1;line;Line;" .. line .. "]" ..
		"button_exit[4,1;4,1;save;Save]" ..

		-- col 2
		"field[0,2.5;4,1;station;Station;" .. station .. "]" ..
		"field[4,2.5;4,1;index;Index;" .. index .. "]" ..

		-- col 3
		"field[0,3.5;4,1;color;Color;" .. color .. "]" ..
		rail_btns
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

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)

		local last_index = 0
		local last_line = ""
		local last_color = ""

		if minetest.is_player(placer) then
			local name = placer:get_player_name()
			if name ~= nil then
				name = string.lower(name)
				if last_set_by[name] ~= nil then
					last_index = last_set_by[name].index + 5
					last_line = last_set_by[name].line
					last_color = last_set_by[name].color
				else
					last_set_by[name] = {}
				end

				last_set_by[name].index = last_index
				last_set_by[name].line = last_line
				last_set_by[name].color = last_color
			end
		end

		meta:set_string("station", "")
		meta:set_string("line", last_line)
		meta:set_int("index", last_index)
		meta:set_string("color", last_color)
		meta:set_string("rail_pos", "")

		update_neighbors(pos, meta, minetest.is_player(placer) and placer:get_player_name() or nil)

		return mapserver.after_place_node(pos, placer, itemstack, pointed_thing)
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, player)
		local fake_meta = minetest.get_meta(pos)

		-- TODO: why doesn't this work properly?

		update_neighbors(pos, fake_meta, player)
	end,

	on_receive_fields = function(pos, formname, fields, sender)

		if not mapserver.can_interact(pos, sender) then
			return
		end

		local meta = minetest.get_meta(pos)
		local name = sender:get_player_name()
		local lname = string.lower(name)

		if fields.save then
			if last_set_by[lname] == nil then
				last_set_by[lname] = {}
			end

			local index = tonumber(fields.index)
			if index ~= nil then
				index = index
			end

			meta:set_string("color", fields.color)
			meta:set_string("line", fields.line)
			meta:set_string("station", fields.station)
			meta:set_int("index", index)

			last_set_by[lname].color = fields.color
			last_set_by[lname].line = fields.line
			last_set_by[lname].station = fields.station
			last_set_by[lname].index = index

			update_neighbors(pos, meta, name)

		elseif fields.clear_rail_pos then
			meta:set_string("rail_pos", "")
			update_neighbors(pos, meta, name)

		elseif fields.set_rail_pos then
			minetest.chat_send_player(name, "Please punch the nearest rail this train line follows.")
			if last_set_by[lname] == nil then
				last_set_by[lname] = {}
			end
			last_set_by[lname].waiting_for_rail = pos
		end
	end
})

minetest.register_on_punchnode(function(pos, node, sender, pointed_thing)
	local name = sender:get_player_name()
	local lname = string.lower(name)
	local blockpos = nil
	if last_set_by[lname] ~= nil and
		last_set_by[lname].waiting_for_rail ~= nil then

		blockpos = last_set_by[lname].waiting_for_rail
	else
		return
	end
	if not mapserver.can_interact(blockpos, sender) then
		return
	end

	if blockpos and advtrains_present then
		if vector.distance(pos, blockpos) <= 20 then
			local node_ok, conns, rhe = advtrains.get_rail_info_at(pos, advtrains.all_tracktypes)
			if node_ok then
				local meta = minetest.get_meta(blockpos)
				meta:set_string("rail_pos", minetest.pos_to_string(pos))
				update_neighbors(blockpos, meta, name)
			else
				minetest.chat_send_player(name, "This is not rail! Aborted.")
			end
		else
			minetest.chat_send_player(name, "Node is too far away. Aborted.")
		end
		last_set_by[lname].waiting_for_rail = nil
	end
end)

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


update_neighbors = function(pos, meta, name)
	if meta == nil then
		meta = minetest.get_meta(pos)
	end
	local line = meta:get_string("line")
	local index = tonumber(meta:get_string("index"))
	local rail_pos = meta:get_string("rail_pos")

	-- if anything critical changed (pos/line/index) virtually remove us
	local prv = minetest.string_to_pos(meta:get_string("prv_pos"))
	local nxt = minetest.string_to_pos(meta:get_string("nxt_pos"))
	local prv_meta = prv ~= nil and minetest.get_meta(prv) or nil
	local nxt_meta = nxt ~= nil and minetest.get_meta(nxt) or nil

	if prv ~= nil and prv_meta:get_string("line") ~= line and
		nxt ~= nil and nxt_meta:get_string("line") ~= line then
		if prv ~= nil and nxt == nil then
			-- loose end
			prv_meta:set_string("nxt_pos", "")
			prv_meta:set_string("nxt_index", "")
			prv_meta:set_string("nxt_rail_pos", "")
		elseif prv == nil and nxt ~= nil then
			-- loose end
			nxt_meta:set_string("prv_pos", "")
			nxt_meta:set_string("prv_index", "")
			nxt_meta:set_string("prv_rail_pos", "")

			nxt_meta:set_string("linepath_from_prv", "")
		else
			-- we were in the middle
			prv_meta:set_string("nxt_pos", nxt)
			prv_meta:set_string("nxt_index", meta:get_string("nxt_index"))
			prv_meta:set_string("nxt_rail_pos", meta:get_string("nxt_rail_pos"))

			nxt_meta:set_string("prv_pos", prv)
			nxt_meta:set_string("prv_index", meta:get_string("prv_index"))
			nxt_meta:set_string("prv_rail_pos", meta:get_string("prv_rail_pos"))

			recalculate_line_to(prv, nxt, prv_meta, nxt_meta)
		end

		for _,m in ipairs({prv_meta, nxt_meta}) do
			if m ~= nil then
				update_formspec(m)
			end
		end

		-- remove meta from self
		meta:set_string("prv_pos", "")
		meta:set_string("prv_index", "")
		meta:set_string("prv_rail_pos", "")

		meta:set_string("nxt_pos", "")
		meta:set_string("nxt_index", "")
		meta:set_string("nxt_rail_pos", "")

		meta:set_string("linepath_from_prv", "")
	end

	if line == "" then
		update_formspec(meta)
		return
	end

	-- update or add us
	-- repurposing prv, prv_meta etc. vars
	local neighbors = find_neighbor_blocks(pos, meta, name)
	prv = neighbors[1]
	nxt = neighbors[2]
	prv_meta = prv ~= nil and minetest.get_meta(prv.pos) or nil
	nxt_meta = nxt ~= nil and minetest.get_meta(nxt.pos) or nil
	-- if index or rail pos changed, recalculate line path
	if prv ~= nil then
		local old_nxt_pos = prv_meta:get_string("nxt_pos")
		local old_nxt_index = tonumber(prv_meta:get_string("nxt_index"))
		local old_nxt_rail_pos = prv_meta:get_string("nxt_rail_pos")

		-- if old info on prev does not match us, set correct
		if old_nxt_pos ~= (nxt == nil and "" or nxt.pos) then
			if old_nxt_pos == pos then
				-- phew, it's just us
			elseif nxt ~= nil and old_nxt_pos == nxt.pos then
				-- okay we are just freshly added
				-- update the previous block
				prv_meta:set_string("nxt_pos", minetest.pos_to_string(pos))
			else
				-- there are more nodes we don't know about!
			end
		end
		if old_nxt_index ~= index then
			-- index changed! since our position is still unchanged
			-- (otherwise removing/re-adding above would have happened instead)
			-- we just need to update the info, without linepath recalculation
			prv_meta:set_int("nxt_index", index)
		end
		if old_nxt_rail_pos ~= rail_pos then
			-- rail pos changed! definitely need linepath recalculation
			prv_meta:set_string("nxt_rail_pos", rail_pos)
			meta:set_string("linepath_from_prv", "")
		end

		meta:set_string("prv_pos", minetest.pos_to_string(prv.pos))
		meta:set_int("prv_index", prv.index)
		meta:set_string("prv_rail_pos", prv.rail_pos)
	end
	if nxt ~= nil then
		local old_prv_pos = nxt_meta:get_string("prv_pos")
		local old_prv_index = tonumber(nxt_meta:get_string("prv_index"))
		local old_prv_rail_pos = nxt_meta:get_string("prv_rail_pos")

		-- if old info on next does not match us, set correct
		if old_prv_pos ~= (prv == nil and "" or prv.pos) then
			if old_prv_pos == pos then
				-- phew, it's just us
			elseif prv ~= nil and old_prv_pos == prv.pos then
				-- okay we are just freshly added
				-- update the previous block
				nxt_meta:set_string("prv_pos", minetest.pos_to_string(pos))
				nxt_meta:set_string("linepath_from_prv", "")
			else
				-- there are more nodes we don't know about!
			end
		end
		if old_prv_index ~= index then
			-- index changed! since our position is still unchanged
			-- (otherwise removing/re-adding above would have happened instead)
			-- we just need to update the info, without linepath recalculation
			nxt_meta:set_int("prv_index", index)
		end
		if old_prv_rail_pos ~= rail_pos then
			-- rail pos changed! definitely need linepath recalculation
			nxt_meta:set_string("prv_rail_pos", rail_pos)
			nxt_meta:set_string("linepath_from_prv", "")
		end

		meta:set_string("nxt_pos", minetest.pos_to_string(nxt.pos))
		meta:set_int("nxt_index", nxt.index)
		meta:set_string("nxt_rail_pos", nxt.rail_pos)
	end

	if rail_pos ~= "" then
		if prv ~= nil and prv.rail_pos ~= "" then
			local line = recalculate_line_to(prv.pos, pos, prv_meta, meta)
			if name then
				if #line > 0 then
					minetest.chat_send_player(name, "Found line from prv ("..tonumber(#line).."): "..table.concat(line, "->"))
				else
					minetest.chat_send_player(name, "Did not find line from prv.")
				end
			end
		end
		if nxt ~= nil and nxt.rail_pos ~= "" then
			local line = recalculate_line_to(pos, nxt.pos, meta, nxt_meta)
			if name then
				if #line > 0 then
					minetest.chat_send_player(name, "Found line to nxt ("..tonumber(#line).."): "..table.concat(line, "->"))
				else
					minetest.chat_send_player(name, "Did not find line to nxt.")
				end
			end
		end
	end

	for _,m in ipairs({prv_meta, nxt_meta}) do
		if m ~= nil then
			update_formspec(m)
		end
	end
	update_formspec(meta)
end

local nroot = function(root, num)
	return num^(1/root)
end

if vector == nil then
	vector = {}
	vector.new = function(a, b,c)
		if vector.check(a) then
			return vector.copy(a)
		elseif type(a) == "number" and type(b) == "number" and type(c) == "number" then
			return {x=a, y=b, z=c}
		end
	end
	vector.zero = function()
		return vector.new(0,0,0)
	end
	vector.copy = function(v)
		return vector.new(v.x, v.y, v.z)
	end
	vector.to_string = function(v)
		if vector.check(v) then
			return "("..table.concat({v.x, v.y, v.z}, ",")..")"
		else
			return "(invalid vector)"
		end
	end

	vector.add = function(p1, p2)
		return vector.new(p1.x+p2.x, p1.y+p2.y, p1.z+p2.z)
	end
	vector.subtract = function(p1, p2)
		return vector.new(p1.x-p2.x, p1.y-p2.y, p1.z-p2.z)
	end
	vector.multiply = function(v, s)
		return vector.new(v.x*s, v.y*s, v.z*s)
	end
	vector.divide = function(v, s)
		return vector.new(v.x/s, v.y/s, v.z/s)
	end

	vector.distance = function(p1, p2)
		return vector.length(vector.subtract(p2, p1))
	end
	vector.length = function(v)
		return nroot(3, v.x*v.x + v.y*v.y + v.z*v.z)
	end
	vector.normalize = function(v)
		return vector.multiply(v, 1/vector.length(v))
	end
	vector.offset = function(v, x,y,z)
		return vector.new(v.x+x, v.y+y, v.z+z)
	end
	vector.check = function(v)
		return type(v) == "table" and
			type(v.x) == "number" and
			type(v.y) == "number" and
			type(v.z) == "number"
	end
end

-- searching an area for nodes is expensive.
-- minetest limits the amount to 4,096,000 nodes.
-- because there is not a good way to form one cuboid to fit all major long-distance usecases,
local max_nodes = 4096000
local cuboid_width_for_height = function(height)
	return math.floor(math.sqrt(max_nodes / height))
end
local span_rectangle = function(pos, radius, height, v_offset, v_invert)
	local v_dir = v_invert and -1 or 1
	return { vector.add(pos, vector.multiply(vector.new(-radius, v_offset, -radius), v_dir)),
			 vector.add(pos, vector.multiply(vector.new(radius, height+v_offset, radius), v_dir)) }
end
local halve_area = function(length)
	return math.floor((length-1) / 2)
end
local twocube_length = math.floor(nroot(3, max_nodes*2))
local flat_height = 7
local flat_halflength = halve_area(cuboid_width_for_height(flat_height))
local cuboid_height = math.floor(twocube_length/3)
local cuboid_length = cuboid_width_for_height(cuboid_height)
local area_from_offset = function(pos, offset)
	return {vector.subtract(pos, offset), vector.add(pos, offset)}
end
local eight_corners = function(a, b)
	local diff = vector.subtract(b, a)
	return { a,
		vector.add(a, vector.new(diff.x, 0, 0)),
		vector.add(a, vector.new(0, diff.y, 0)),
		vector.add(a, vector.new(0, 0, diff.z)),
		vector.add(a, vector.new(diff.x, diff.y, 0)),
		vector.add(a, vector.new(diff.x, 0, diff.z)),
		vector.add(a, vector.new(0, diff.y, diff.z)),
		b }
end
local get_volume = function(span)
	local diff = vector.subtract(span[2], span[1])
	return (math.abs(diff.x)+1) * (math.abs(diff.y)+1) * (math.abs(diff.z)+1)
end

find_neighbor_blocks = function(pos, meta, name)
	if meta == nil then
		meta = minetest.get_meta(pos)
	end
	local line = meta:get_string("line")
	local index = tonumber(meta:get_string("index"))
	local rail_pos = meta:get_string("rail_pos")

	-- the offsets are chosen so that the resulting area is just under the maximum allowable size
	local areas = {
		flat = area_from_offset(pos, vector.new(flat_halflength, halve_area(flat_height), flat_halflength)),
		upper_half = span_rectangle(pos, halve_area(cuboid_length), cuboid_height-1, halve_area(flat_height)+1),
		lower_half = span_rectangle(pos, halve_area(cuboid_length), cuboid_height-1, halve_area(flat_height)+1, true)
	}
	local blocks = {}
	for i,span in pairs(areas) do
		if get_volume(span) > max_nodes then
			minetest.chat_send_player(name, "Invalid span "..i.." between "..minetest.pos_to_string(span[1]).." and "..minetest.pos_to_string(span[2]).." (volume of "..tostring(get_volume(span))..")")
			return {}
		end
		print("["..i.."] Getting nodes between "..minetest.pos_to_string(span[1]).." and "..minetest.pos_to_string(span[2]).." (should be volume of "..tostring(get_volume(span))..")")
		blocks[i] = minetest.find_nodes_in_area(span[1], span[2], "mapserver:train")
		minetest.bulk_set_node(eight_corners(span[1], span[2]), {name=moditems.goldblock})
		minetest.chat_send_player(name, "Found "..tostring(#blocks[i]).." nodes between "..minetest.pos_to_string(span[1]).." and "..minetest.pos_to_string(span[2]).." ("..i..")")
	end
	local prv = nil
	local nxt = nil
	local meta = nil

	for _,span in pairs(blocks) do
		for _,p in pairs(span) do
			meta = minetest.get_meta(p)
			if meta:get_string("line") == line then
				local idx = tonumber(meta:get_string("index"))
				if idx < index and
					(prv == nil or idx > prv.index) then
						prv = {
							pos = p,
							index = idx,
							rail_pos = meta:get_string("rail_pos")
						}
				end
				if idx > index and
					(nxt == nil or idx < nxt.index) then
						nxt = {
							pos = p,
							index = idx,
							rail_pos = meta:get_string("rail_pos")
						}
				end
			end
		end
	end

	return {prv, nxt}
end

local clone = nil
clone = function(tbl, n)
	local out = {}
	local i,v = next(tbl, nil)
	while i do
		if type(v) == "table" then
			out[i] = clone(v, (n or 0)+1)
		else
			out[i] = v
		end
		i,v = next(tbl, i)
	end
	return out
end

recalculate_line_to = function(pos_a, pos_b, meta_a, meta_b)
	if meta_a == nil then
		meta_a = minetest.get_meta(pos_a)
	end
	if meta_b == nil then
		meta_b = minetest.get_meta(pos_b)
	end
	local line = {}
	local rail_pos_a = minetest.string_to_pos(meta_a:get_string("rail_pos"))
	local rail_pos_b = minetest.string_to_pos(meta_b:get_string("rail_pos"))
	local node_ok_a, conns_a, rhe_a = advtrains.get_rail_info_at(rail_pos_a, advtrains.all_tracktypes)
	local node_ok_b, conns_b, rhe_b = advtrains.get_rail_info_at(rail_pos_b, advtrains.all_tracktypes)
	if not node_ok_a or not node_ok_b then
		table.insert(line, node_ok_a and minetest.pos_to_string(rail_pos_a) or pos_a)
	else
		-- depth first search for rail_pos_b,
		-- vector.distance(step, rail_pos_b) is score

		-- keep track of all visited positions to avoid going in circles
		local visited_nodes = {}
		-- heads of search positions: {pos=<pos>, score=<cached score>, steps=<nth node tried>, line=<line until pos>}
		local progress = {}

		-- put starting rail in, for every direction
		for connid, conn in ipairs(conns_a) do
			table.insert(progress, {
				pos = rail_pos_a,
				conns = conns_a,
				connid = connid,
				steps = 0,
				score = vector.distance(rail_pos_a, rail_pos_b),
				line = {}
			})
		end

		while next(progress, nil) do
			local min_idx = nil
			local min_item = nil
			-- try the node closest to the destination
			for i,v in pairs(progress) do
				if v.steps < TRAVERSER_LIMIT and
					(min_item == nil or v.score < min_item.score) then
					min_idx = i
					min_item = v
				end
			end

			-- check the adjacent rail
			local adj_pos, adj_connid, conn_idx, nextrail_y, next_conns = advtrains.get_adjacent_rail(min_item.pos, min_item.conns, min_item.connid, advtrains.all_tracktypes)
			if not adj_pos then
				-- there is no rail, end-of-track
				progress[min_idx] = nil
			elseif visited_nodes[minetest.pos_to_string(adj_pos)..adj_connid] ~= nil then
				-- already been here in this direction, no use repeating same steps
				progress[min_idx] = nil
			elseif minetest.pos_to_string(adj_pos) == minetest.pos_to_string(rail_pos_b) then
				-- found destination!
				-- set line and break loop
				line = min_item.line
				table.insert(line, minetest.pos_to_string(rail_pos_b))
				break
			else
				-- remember we did this one to prevent circles
				visited_nodes[minetest.pos_to_string(adj_pos)..adj_connid] = true

				if min_item.steps > TRAVERSER_LIMIT then
					print("went over traverser limit! "..minetest.pos_to_string(rail_pos_a).." → "..minetest.pos_to_string(adj_pos))
				else
					local inconn = next_conns[adj_connid]
					-- query the next conns
					local quarter = AT_CMAX/4
					for nconnid, nconn in ipairs(next_conns) do
						local normed = (nconn.c-inconn.c)%AT_CMAX
						-- only accept conns that turn 90deg at most
						if normed >= quarter and normed <= quarter*3 then
							local line = clone(min_item.line)
							if nconn.c ~= inconn.c then
								table.insert(line, minetest.pos_to_string(adj_pos))
							end
							table.insert(progress, {
								pos = adj_pos,
								conns = next_conns,
								connid = nconnid,
								steps = min_item.steps + 1,
								score = vector.distance(adj_pos, rail_pos_b),
								line = line
							})
						end
					end
				end
				-- we are done with this item
				progress[min_idx] = nil
			end
		end
	end
	meta_b:set_string("linepath_from_prv", table.concat(line, ";"))
	return line
end
