local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local consts = require("consts")
local util = require("util")

local sideLength = consts.bodyTextureCubemapSideLength

local heightmapToNormalShader, dummyTexture

local function ensureGraphicsObjects()
	heightmapToNormalShader = heightmapToNormalShader or love.graphics.newShader(
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/heightmapToNormal.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))
end

return function(slot, body, baseColourDrawFunction, heightmapDrawFunction)
	ensureGraphicsObjects()

	local baseColourCubemapCanvas = slot.baseColour
	local heightmapCubemapCanvas = slot.height
	local normalMapCubemapCanvas = slot.normal

	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau / 4,
		1.5,
		0.5
	)

	for i, orientation in ipairs(consts.cubemapOrientations) do
		love.graphics.setCanvas(baseColourCubemapCanvas, i) -- If another canvas is needed, this setup can be stored with love.graphics.getCanvas()
		love.graphics.clear() -- Can clear again to another colour in drawFunction
		love.graphics.push("all")
		baseColourDrawFunction(orientation)
		love.graphics.pop()

		love.graphics.setCanvas(heightmapCubemapCanvas, i)
		love.graphics.clear()
		love.graphics.push("all")
		heightmapDrawFunction(orientation)
		love.graphics.pop()
	end

	love.graphics.setCanvas()

	heightmapCubemapCanvas:setFilter("linear")
	heightmapToNormalShader:send("heightmap", heightmapCubemapCanvas)
	local rotateAngle = -- We want an angle that's small enough to catch all changes in the texture. You need a smaller rotation angle the closer you are to the corners of the texture
		util.angleBetweenVectors(
			vec3(1, 1, 1),
			vec3(1, 1, 1 - 2 / sideLength)
		) -- Unsure if this would work (are the texture coords in the shader + 0.5? (probably) etc), but the idea is to get the rotation angle between the corner of the cubemap and one of the closest pixels.
		/ 4 -- Making it even smaller than what is possibly the minimum should be safe, provided our bump map is not using nearest neighbour
		-- I'm pretty sure it's not going to be perfect.
	heightmapToNormalShader:send("rotateAngle", rotateAngle)
	heightmapToNormalShader:send("bodyRadius", body and body.celestialRadius.value or 1)
	heightmapToNormalShader:send("forwardVector", {vec3.components(consts.forwardVector)})
	-- heightmapToNormalShader:send("upVector", {vec3.components(consts.upVector)})
	heightmapToNormalShader:send("rightVector", {vec3.components(consts.rightVector)})
	util.drawToCubemapCanvas(normalMapCubemapCanvas, function(orientation)
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
		baseColour = baseColourCubemapCanvas,
		normal = normalMapCubemapCanvas,
		heightmap = heightmapCubemapCanvas
	}
end
