local consts = require("consts")

return function(canvas, drawFunction, dontClear, yFlipOrientations)
	love.graphics.push("all")
	local canvasTextureType = canvas:getTextureType()
	assert(canvasTextureType == "cube", "drawToCubemapCanvas expected cube canvas, got " .. canvasTextureType)

	for i, orientation in ipairs(yFlipOrientations and consts.cubemapOrientationsYFlip or consts.cubemapOrientations) do
		love.graphics.setCanvas(canvas, i) -- If another canvas is needed, this one can be stored with love.graphics.getCanvas()
		if not dontClear then
			love.graphics.clear() -- Can clear again to another colour in drawFunction
		end
		drawFunction(orientation)
	end
	love.graphics.pop()
end
