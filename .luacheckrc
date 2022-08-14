unused_args = false
allow_defined_top = true

globals = {
	"mapserver",
	"moditems",
	"airutils"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump",

	-- Deps
	"unified_inventory", "default", "advtrains",
	locator = { fields = { "beacons" } },

	-- optional mods
	"xban", "monitoring", "QoS",
	"mcl_core", "mcl_sounds", "bones"
}
