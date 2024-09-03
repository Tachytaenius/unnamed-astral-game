local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local consts = require("consts")
local util = require("util")

local heightmapToNormalShader, dummyTexture

local function ensureGraphicsObjects()
	heightmapToNormalShader = heightmapToNormalShader or love.graphics.newShader(
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/heightmapToNormal.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))
end

return function(sideLength, baseColourDrawFunction, heightmapDrawFunction)
	ensureGraphicsObjects()

	local baseColourSideCanvas = love.graphics.newCanvas(sideLength, sideLength)
	local baseColourSides = {}
	local heightmapSideCanvas = love.graphics.newCanvas(sideLength, sideLength, {format = "r16f", linear = true})
	local heightmapSides = {}
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

		love.graphics.setCanvas(heightmapSideCanvas)
		love.graphics.clear()
		heightmapDrawFunction(orientation)
		love.graphics.setCanvas()
		heightmapSides[#heightmapSides + 1] = heightmapSideCanvas:newImageData()
	end

	local heightmapCubemap = love.graphics.newCubeImage(heightmapSides, {linear = true})
	heightmapCubemap:setFilter("linear")
	heightmapToNormalShader:send("heightmap", heightmapCubemap)
	local rotateAngle = -- We want an angle that's small enough to catch all changes in the texture. You need a smaller rotation angle the closer you are to the corners of the texture
		util.angleBetweenVectors(
			vec3(1, 1, 1),
			vec3(1, 1, 1 - 2 / sideLength)
		) -- Unsure if this would work (are the texture coords in the shader + 0.5? (probably) etc), but the idea is to get the rotation angle between the corner of the cubemap and one of the closest pixels.
		/ 4 -- Making it even smaller than what is possibly the minimum should be safe, provided our bump map is not using nearest neighbour
		-- I'm pretty sure it's not going to be perfect.
	heightmapToNormalShader:send("rotateAngle", rotateAngle)
	heightmapToNormalShader:send("strength", 0.75)
	heightmapToNormalShader:send("forwardVector", {vec3.components(consts.forwardVector)})
	-- heightmapToNormalShader:send("upVector", {vec3.components(consts.upVector)})
	heightmapToNormalShader:send("rightVector", {vec3.components(consts.rightVector)})
	local normalMapCubemap, normalSides = util.generateCubemap(sideLength, {linear = true}, function(orientation)
		love.graphics.setShader(heightmapToNormalShader)
		local worldToCameraStationary = mat4.camera(vec3(), orientation)
		local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)
		heightmapToNormalShader:send("clipToSky", {mat4.components(clipToSky)})
		-- Something about uhhhhhhhh being near the poles breaking stuff so like yeah
		-- This is NOT perfect but the game is art, and if it looks good enough it's Good Enough!!!!!1111
		local rotatedForwards = vec3.rotate(consts.forwardVector, orientation)
		local nearPole = false
		if math.abs(rotatedForwards.z) > math.abs(rotatedForwards.x) and math.abs(rotatedForwards.z) > math.abs(rotatedForwards.y) then
			-- Forward or backward face-- there's a pole in it. Use an alternative vector to rotate with. sijghfsghsighdflhgjkg.
			nearPole = true
		end
		heightmapToNormalShader:send("nearPole", nearPole)
		love.graphics.draw(dummyTexture, 0, 0, 0, sideLength)
		-- Shader is popped
	end)

	return {
		baseColour = love.graphics.newCubeImage(baseColourSides),
		baseColourSides = baseColourSides,
		normal = normalMapCubemap,
		normalSides = normalSides,
		heightmap = heightmapCubemap,
		heightmapSides = heightmapSides
	}
end
