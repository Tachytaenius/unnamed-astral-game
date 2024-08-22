local consts = require("consts")

return function(sideLength, canvasOptions, drawFunction)
	local sideCanvas = love.graphics.newCanvas(sideLength, sideLength, canvasOptions)
	local sides = {}
	for _, orientation in ipairs(consts.cubemapOrientations) do
		love.graphics.setCanvas(sideCanvas) -- If another canvas is needed, this one can be stored with love.graphics.getCanvas()
		love.graphics.clear() -- Can clear again in drawFunction
		drawFunction(orientation)
		love.graphics.setCanvas()
		sides[#sides + 1] = sideCanvas:newImageData()
	end
	return love.graphics.newCubeImage(sides), sides
end
