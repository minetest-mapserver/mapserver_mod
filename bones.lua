-- bones owner saving workaround
-- https://github.com/minetest/minetest_game/blob/master/mods/bones/init.lua#L120

local bones_def = minetest.registered_items["bones:bones"]
assert(bones_def)

local bones_on_timer = bones_def.on_timer
assert(bones_on_timer)
assert(type(bones_on_timer) == "function")

minetest.override_item("bones:bones", {
	on_timer = function(pos, elapsed)
		-- save owner in separate field
		local meta = minetest.get_meta(pos)
		meta:set_string("_owner", meta:get_string("owner"))

		-- call original function
		return bones_on_timer(pos, elapsed)
	end
})
