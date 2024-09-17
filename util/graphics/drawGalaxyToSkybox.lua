local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local util = require("util")
local consts = require("consts")

local galaxyDustShader, dummyTexture

local function ensureGraphicsObjects()
	galaxyDustShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/galaxyDust.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))
end

return function(canvas, galaxy, originPositionInGalaxy)
	ensureGraphicsObjects()

	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau / 4,
		1.5,
		0.5
	)

	util.drawToCubemapCanvas(canvas, function(orientation)
		local worldToCameraStationary = mat4.camera(vec3(), orientation)
		local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)

		-- galaxyDustShader:send("cameraPosition", {vec3.components(originPositionInGalaxy)})
		-- galaxyDustShader:send("rayStepCount", consts.galaxyRaySteps)
		-- galaxyDustShader:send("squash", {vec3.components(consts.galaxySquash)})
		-- galaxyDustShader:send("galaxyRadius", consts.galaxyRadius)
		-- galaxyDustShader:send("haloProportion", consts.galaxyHaloProportion)
		galaxyDustShader:send("clipToSky", {mat4.components(clipToSky)})
		love.graphics.setShader(galaxyDustShader)
		love.graphics.draw(dummyTexture, 0, 0, 0, love.graphics.getCanvas()[1][1]:getDimensions())
	end)
end
