local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local consts = require("consts")

local clearNormalShader, dummyTexture

local function ensureGraphicsObjects()
	clearNormalShader = clearNormalShader or love.graphics.newShader(
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/clearNormal.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))
end

return function(sideLength, baseColourDrawFunction, normalDrawFunction)
	ensureGraphicsObjects()

	local baseColourSideCanvas = love.graphics.newCanvas(sideLength, sideLength)
	local baseColourSides = {}
	local normalSideCanvas = love.graphics.newCanvas(sideLength, sideLength, {linear = true})
	local normalSides = {}
	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau / 4,
		1.5,
		0.5
	)
	for _, orientation in ipairs(consts.cubemapOrientations) do
		love.graphics.setCanvas(baseColourSideCanvas) -- If another canvas is needed, this setup can be stored with love.graphics.getCanvas()
		love.graphics.clear() -- Can clear again to another colour in drawFunction
		baseColourDrawFunction(orientation)
		love.graphics.setCanvas()
		baseColourSides[#baseColourSides + 1] = baseColourSideCanvas:newImageData()

		love.graphics.setCanvas(normalSideCanvas)
		-- love.graphics.clear(love.math.linearToGamma(0.5, 0.5, 1))
		love.graphics.setShader(clearNormalShader)
		local worldToCameraStationary = mat4.camera(vec3(), orientation)
		local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)
		clearNormalShader:send("clipToSky", {mat4.components(clipToSky)})
		love.graphics.draw(dummyTexture, 0, 0, 0, normalSideCanvas:getDimensions())
		love.graphics.setShader()
		normalDrawFunction(orientation)
		love.graphics.setCanvas()
		normalSides[#normalSides + 1] = normalSideCanvas:newImageData()
	end
	return {
		baseColour = love.graphics.newCubeImage(baseColourSides),
		baseColourSides = baseColourSides,
		normal = love.graphics.newCubeImage(normalSides),
		normalSides = normalSides
	}
end
