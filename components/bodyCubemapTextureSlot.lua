local concord = require("lib.concord")

local consts = require("consts")

local sideLength = consts.bodyTextureCubemapSideLength

return concord.component("bodyCubemapTextureSlot", function(c)
	c.claimed = false
	c.lastClaim = nil

	c.baseColour = love.graphics.newCanvas(sideLength, sideLength, {type = "cube"})
	c.normal = love.graphics.newCanvas(sideLength, sideLength, {type = "cube", format = "rgba16f", linear = true})
	c.height = love.graphics.newCanvas(sideLength, sideLength, {type = "cube", format = "r32f", linear = true})
end)
