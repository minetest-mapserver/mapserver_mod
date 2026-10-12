local ie = ...

function mapserver.post_media()

    -- all media files
    local media_files = {}
    local media_count = 0

    local mods = minetest.get_modnames()
    for _, modname in ipairs(mods) do
        local path = minetest.get_modpath(modname)

        for _, filename in ipairs(minetest.get_dir_list(path .. "/textures", false)) do
            media_count = media_count + 1
            table.insert(media_files, {
                full_path = path .. "/textures/" .. filename,
                filename = filename,
                type = "texture"
            })
        end

        for _, filename in ipairs(minetest.get_dir_list(path .. "/models", false)) do
            media_count = media_count + 1
            table.insert(media_files, {
                full_path = path .. "/models/" .. filename,
                filename = filename,
                type = "model"
            })
        end
    end

    -- current POST data, in-flight
    local current_data
    local prepare_bunch

    local function post_bunch()
        mapserver.log("info", "posting " .. #current_data .. " media items")

        mapserver.api.send_media(current_data, function(res)
            if res.code == 200 then
                -- send next bunch
                minetest.after(1, prepare_bunch)
            else
                -- retry again later
                minetest.after(5, post_bunch)
            end
        end)

    end

    prepare_bunch = function()
        current_data = {}
        local current_size = 0

        -- collect to-send media files
        while true do
            local media = table.remove(media_files)
            if not media then
                -- no more items
                break
            end

            local f = ie.io.open(media.full_path, "rb")
            local data = f:read("*all")
            current_size = current_size + #data
            local base64_data = minetest.encode_base64(data)
            f:close()

            table.insert(current_data, {
                type = media.type,
                data = base64_data,
                filename = media.filename
            })

            if current_size > 128 * 1000 then
                -- enough data
                break
            end
        end

        if #current_data > 0 then
            post_bunch()
        end
    end

    -- start sending
    minetest.after(5, prepare_bunch)
end
