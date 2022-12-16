
local has_skinsdb = minetest.get_modpath("skinsdb") and skins

mapserver.bridge.add_players = function(data)

  data.players = {}

  for _, player in ipairs(minetest.get_connected_players()) do

    local is_hidden = minetest.check_player_privs(player:get_player_name(), {mapserver_hide_player = true})
    local is_moderator = minetest.check_player_privs(player:get_player_name(), {ban = true})

    local detail = minetest.get_player_information(player:get_player_name())
    local protocol_version = -1
    local rtt = -1

    if detail then
      rtt = detail.avg_rtt
      protocol_version = detail.protocol_version
    end

    local skin
    if has_skinsdb then
      skin = skins.get_player_skin(player):get_texture()
    end

    local info = {
      name = player:get_player_name(),
      pos = player:get_pos(),
      hp = player:get_hp(),
      breath = player:get_breath(),
      velocity = player:get_velocity(),
      moderator = is_moderator,
      rtt = rtt,
      yaw = player:get_look_horizontal(),
      skin = skin,
      protocol_version = protocol_version
    }

    if not is_hidden then
      table.insert(data.players, info)
    end
  end

end
