local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local util = require("util")
local consts = require("consts")

local galaxyDustShader, dummyTexture
local diskMesh
local blurredPointInstanceShader

local function ensureGraphicsObjects()
	galaxyDustShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/galaxyDust.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))

	blurredPointInstanceShader = love.graphics.newShader("shaders/blurredPointInstanced.glsl")
	diskMesh = util.generateDiskMesh(consts.blurredPointDiskMeshVertices)
end

return function(canvas, otherStars, originPositionInGalaxy)
	ensureGraphicsObjects()

	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau / 4,
		1.5,
		0.5
	)

	util.drawToCubemapCanvas(canvas, function(orientation)
		love.graphics.clear(0, 0, 0, 1)

		local worldToCameraStationary = mat4.camera(vec3(), orientation)
		local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)

		-- galaxyDustShader:send("cameraPosition", {vec3.components(originPositionInGalaxy)})
		-- galaxyDustShader:send("rayStepCount", consts.galaxyRaySteps)
		-- galaxyDustShader:send("squash", {vec3.components(consts.galaxySquash)})
		-- galaxyDustShader:send("galaxyRadius", consts.galaxyRadius)
		-- galaxyDustShader:send("haloProportion", consts.galaxyHaloProportion)
		galaxyDustShader:send("clipToSky", {mat4.components(clipToSky)})
		love.graphics.setShader(galaxyDustShader)
		-- love.graphics.draw(dummyTexture, 0, 0, 0, love.graphics.getCanvas()[1][1]:getDimensions())
	end, false, false)

	local solidAngle = consts.tau * (1 - math.cos(consts.pointLightBlurAngularRadius))
	local diskDistanceToSphere = util.unitSphereSphericalCapHeightFromAngularRadius(consts.pointLightBlurAngularRadius)
	local scaleToGetAngularRadius = math.tan(consts.pointLightBlurAngularRadius)
	blurredPointInstanceShader:send("diskDistanceToSphere", diskDistanceToSphere)
	blurredPointInstanceShader:send("scale", scaleToGetAngularRadius)
	local instanceMeshVertices = {}
	for i, star in ipairs(otherStars) do
		local relativePosition = star.position - originPositionInGalaxy
		local distance = #relativePosition
		local direction = relativePosition / distance

		local luminousFlux = star.radiantFlux * star.luminousEfficacy
		local illuminance = luminousFlux * distance ^ -2
		local luminance = illuminance / solidAngle
		-- local colour = {vec3.components(
		-- 	luminance * vec3(unpack(star.colour))
		-- )}
		-- local colour = {
		-- 	luminance * star.colour[1],
		-- 	luminance * star.colour[2],
		-- 	luminance * star.colour[3]
		-- }

		instanceMeshVertices[i] = {
			direction.x, direction.y, direction.z,
			luminance * star.colour[1], luminance * star.colour[2], luminance * star.colour[3]
		}
	end
	local instanceMesh = love.graphics.newMesh(consts.blurredPointInstanceVertexFormat, instanceMeshVertices, "points", "static")
	diskMesh:attachAttribute("InstanceDirection", instanceMesh, "perinstance")
	diskMesh:attachAttribute("InstanceColour", instanceMesh, "perinstance")

	util.drawToCubemapCanvas(canvas, function(orientation)
		-- All love graphics state changes are popped

		local worldToClip = cameraToClip * mat4.camera(vec3(), orientation)
		local cameraUp = vec3.rotate(consts.upVector, orientation)
		blurredPointInstanceShader:send("worldToClip", {mat4.components(worldToClip)})
		blurredPointInstanceShader:send("cameraUp", {vec3.components(cameraUp)})

		love.graphics.setBlendMode("add")

		love.graphics.setShader(blurredPointInstanceShader)
		love.graphics.drawInstanced(diskMesh, #otherStars)
	end, true, true)
end
