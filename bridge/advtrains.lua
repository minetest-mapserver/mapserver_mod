
mapserver.bridge.add_advtrains = function(data)
  -- train/wagon data
  data.trains = {}
  for _, train in pairs(advtrains.trains) do

    local t = {
      text_outside = train.text_outside,
      text_inside = train.text_inside,
      line = train.line,
      pos = train.last_pos,
      velocity = train.velocity,
      off_track = train.off_track,
      id = train.id,
      wagons = {}
    }

    for _, part in pairs(train.trainparts) do
      local wagon = advtrains.wagons[part]
      if wagon ~= nil then
        table.insert(t.wagons, {
          id = wagon.id,
          type = wagon.type,
          pos_in_train = wagon.pos_in_train,
        })
      end
    end

    table.insert(data.trains, t)
  end

  -- signal data
  data.signals = {}
  local ildb = advtrains.interlocking.db.save()
  for _, entry in pairs(ildb.tcbs) do
    --print(dump(entry))
    if entry[1].signal then
      local tcb = entry[1]
      local green = tcb.aspect and tcb.aspect.main and tcb.aspect.main.free
      table.insert(data.signals, {
	      pos = tcb.signal,
	      green = green
      })
    elseif entry[2].signal then
      local tcb = entry[2]
      local green = tcb.aspect and tcb.aspect.main and tcb.aspect.main.free
      table.insert(data.signals, {
	      pos = tcb.signal,
	      green = green
      })
    end
  end

end
