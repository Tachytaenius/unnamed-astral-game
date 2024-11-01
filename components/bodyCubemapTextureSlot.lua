local concord = require("lib.concord")

local consts = require("consts")

local sideLength = consts.bodyTextureCubemapSideLength

return concord.component("bodyCubemapTextureSlot", function(c)
	c.claimed = false
	c.lastClaim = nil

	c.baseColour = love.graphics.newCanvas(sideLength, sideLength, {type = "cube"})
	c.normal = love.graphics.newCanvas(sideLength, sideLength, {type = "cube", format = "rgba16f", linear = true})
	-- Height comes with a min/max texture and a view for its faces
	c.height = love.graphics.newCanvas(sideLength, sideLength, {type = "cube", format = consts.bodyHeightmapFormat, linear = true})
	c.heightMinMax = love.graphics.newCanvas(2, 1, {format = consts.bodyHeightmapFormat, linear = true}) -- Min on the left, max on the right
	c.heightView = love.graphics.newTextureView(c.height, {type = "array", layerstart = 1, layers = 6}) -- Cubemap to array
end)
