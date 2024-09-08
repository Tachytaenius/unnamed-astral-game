local consts = require("consts")

return function(canvas, drawFunction)
	love.graphics.push("all")
	local canvasTextureType = canvas:getTextureType()
	assert(canvasTextureType == "cube", "drawToCubemapCanvas expected cube canvas, got " .. canvasTextureType)

	for i, orientation in ipairs(consts.cubemapOrientations) do
		love.graphics.setCanvas(canvas, i) -- If another canvas is needed, this one can be stored with love.graphics.getCanvas()
		love.graphics.clear() -- Can clear again to another colour in drawFunction
		drawFunction(orientation)
	end
	love.graphics.pop()
end
