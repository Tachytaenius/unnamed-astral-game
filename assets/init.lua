local cargo = require("lib.cargo")

local util = require("util")

local assets = cargo.init({
	dir = "assets",
	loaders = {
		obj = util.loadObj
	}
})

function assets.load()
	assets(true)
end

return assets
