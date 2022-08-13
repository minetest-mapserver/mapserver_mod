
local planes = {}

-- we monkey patch various functions within airutils to let us know when plane entities are
-- added, updated, or removed from game scope
-- planes deactivated by the game (no players in range, etc) will not be sent to mapserver
if airutils then
    minetest.log("info", "[mapserver-bridge] patching airutils functions to track planes")
    local au_setText = airutils.setText
    local au_actfunc = airutils.actfunc
    local au_save_inv = airutils.save_inventory

    -- actfunc is always called when planes are activated, so it provides
    -- a single convenient point to start tracking them
    if au_actfunc and (type(au_setText) == "function") then
        airutils.actfunc = function(self, staticdata, dtime_s)
            if not self.__id then
                self.__id = tostring(math.random())
            end
            planes[self.__id] = self

            -- call original
            return au_actfunc(self, staticdata, dtime_s)
        end
    end

    -- save_inventory is called when planes are deactivated, so it provides
    -- a single convenient point to untrack them
    if au_save_inv and (type(au_setText) == "function") then
        airutils.save_inventory = function(self)
            if planes[self.__id] then
                planes[self.__id] = nil
            end

            -- call original
            return au_save_inv(self)
        end
    end

    -- this is a convenience, which allows us to grab the "proper name"
    -- of the plane
    if au_setText and (type(au_setText) == "function") then
        airutils.setText = function(self, vehicle_name)
            self.__name = vehicle_name

            -- call original function
            return au_setText(self, vehicle_name)
        end
    end
else
    minetest.log("warning", "[mapserver-bridge] no airutils!")
end

mapserver.bridge.add_airutils_planes = function(data)
    data.airutils_planes = {}
    for _, plane in pairs(planes) do
        if plane then
            -- do some extra work for passengers, which vary between planes
            local passengers
            if plane._passenger then
                passengers = plane._passenger
            elseif plane._passengers then
                for _, p in ipairs(plane._passengers) do
                    if p then
                        if passengers then passengers = passengers .. ", " .. p
                        else passengers = p end
                    end
                end
            end

            -- blimp uses color while others use _color
            local color
            if plane.color then color = plane.color
            else color = plane._color end

            table.insert(data.airutils_planes, {
                entity = plane.name,
                name = plane.__name,
                id = plane.__id,
                owner = plane.owner,
                driver = plane.driver_name,
                passenger = passengers,
                color = color,
                pos = plane.object:get_pos(),
                yaw = plane.object:get_yaw()
            })
        end
    end
end
