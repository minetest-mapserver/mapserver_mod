

function mapserver.show_waypoint(playername, pos, name, seconds)
	local player = minetest.get_player_by_name(playername)
	if not player then
		return
	end

	local id = player:hud_add({
		hud_elem_type = "waypoint",
		name = name,
		text = "m",
		number = 0xFF0000,
		world_pos = pos
	})

	minetest.after(seconds, function()
		player = minetest.get_player_by_name(playername)
		if not player then
			return
		end

		player:hud_remove(id)
	end)
end
