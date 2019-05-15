
mapserver.bridge.add_players = function(data)

  data.players = {}

  for _, player in ipairs(minetest.get_connected_players()) do

    local is_hidden = minetest.check_player_privs(player:get_player_name(), {mapserver_hide_player = true})
    local is_moderator = minetest.check_player_privs(player:get_player_name(), {ban = true})

    local info = {
      name = player:get_player_name(),
      pos = player:get_pos(),
      hp = player:get_hp(),
      breath = player:get_breath(),
      velocity = player:get_player_velocity(),
      moderator = is_moderator
    }

    if not is_hidden then
      table.insert(data.players, info)
    end
  end

end
