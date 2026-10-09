
function mapserver.post_nodedefs(http, mapserver_url, mapserver_key)

    local count = 0
    local defs = {}
    local mapped_fields = {
        "drawtype",
        "visual_scale",
        "tiles",
        "overlay_tiles",
        "special_tiles",
        "color",
        "use_texture_alpha",
        "palette",
        "post_effect_color",
        "post_effect_color_shaded",
        "paramtype",
        "paramtype2",
        "sunlight_propagates",
        "walkable",
        "pointable",
        "climbable",
        "liquidtype",
        "liquid_alternative_flowing",
        "liquid_alternative_source",
        "leveled",
        "leveled_max",
        "liquid_range",
        "node_box",
        "connects_to",
        "connect_sides",
        "mesh",
        "selection_box",
        "collision_box",
        "waving"
    }

    for name, nodedef in pairs(minetest.registered_nodes) do
        count = count + 1
        local def = {}
        for _, fieldname in ipairs(mapped_fields) do
            def[fieldname] = nodedef[fieldname]
        end

        defs[name] = def
    end

    local json = minetest.write_json(defs)

    local function do_post()
        print("[Mapserver] Posting nodedef data: " .. #json .. " bytes / " .. count .. " defs")

        http.fetch({
            url = mapserver_url .. "/api/luanti/nodedefs",
            extra_headers = { "Content-Type: application/json", "Authorization: " .. mapserver_key },
            timeout = 5,
            post_data = json
        }, function(res)
            if not res.succeeded then
                print("[Mapserver] failed to post nodedef data, retrying later again")
                minetest.after(60, do_post)
            end
        end)
    end

    do_post()
end