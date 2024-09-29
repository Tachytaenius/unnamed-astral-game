local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local util = require("util")
local consts = require("consts")

local coronaReductionTextureShader, dummyTexture

local function ensureGraphicsObjects()
	coronaReductionTextureShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/coronaReductionTexture.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))
end

return function(canvas, index)
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
		coronaReductionTextureShader:send("clipToSky", {mat4.components(clipToSky)})
		coronaReductionTextureShader:send("noiseFrequency", index == 1 and 10 or 2)
		coronaReductionTextureShader:send("noisePower", index == 1 and 0.25 or 1)
		coronaReductionTextureShader:send("spiky", index == 1)
		love.graphics.setShader(coronaReductionTextureShader)
		love.graphics.draw(dummyTexture, 0, 0, 0, love.graphics.getCanvas()[1][1]:getDimensions())
	end)
end
