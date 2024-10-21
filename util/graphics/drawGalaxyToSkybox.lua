local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local util = require("util")
local consts = require("consts")

local galaxyDustShader, dummyTexture
local diskMesh
local blurredPointInstanceShader
local starExtinctionComputeShader

-- In this process we divide distances by galaxyRadius as it wasn't very happy with the float exponents (also multiply inverse distances (like scatterance coefficient etc (essentially a chance of distance units?)))

local function ensureGraphicsObjects()
	galaxyDustShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/galaxyDustFunction.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/galaxyDust.glsl")
	)
	dummyTexture = dummyTexture or love.graphics.newImage(love.image.newImageData(1, 1))

	blurredPointInstanceShader = love.graphics.newShader("shaders/blurredPoint.glsl", {defines = {INSTANCED = true}})
	diskMesh = util.generateDiskMesh(consts.blurredPointDiskMeshVertices)

	starExtinctionComputeShader = love.graphics.newComputeShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/galaxyDustFunction.glsl") ..
		love.filesystem.read("shaders/compute/starExtinction.glsl")
	)
end

local function sendGalaxyInfoToShader(shader, galaxy)
	local crossResult = vec3.cross(galaxy.forwards, consts.rightVector)
	local galaxyUp = #crossResult > 0 and vec3.normalise(crossResult) or consts.upVector
	local galaxyRight = vec3.cross(galaxy.forwards, galaxyUp)
	shader:send("squashAmount", galaxy.squashAmount) -- squashDirection is galaxy forwards
	shader:send("galaxyRadius", galaxy.radius / galaxy.radius) -- 1
	shader:send("baseScatterance", 1.6e-20 * galaxy.radius)
	shader:send("baseAbsorption", 1.6e-20 * galaxy.radius)
	if shader:hasUniform("baseEmission") then
		shader:send("baseEmission", 1.5e-25 * galaxy.radius)
		shader:send("emissionDensityCurvePower", 3)
	end
	shader:send("haloProportion", galaxy.galaxyHaloProportion)
	shader:send("galaxyForwards", {vec3.components(galaxy.forwards)})
	shader:send("galaxyUp", {vec3.components(galaxyUp)})
	shader:send("galaxyRight", {vec3.components(galaxyRight)})
end

return function(canvas, galaxy)
	ensureGraphicsObjects()

	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau / 4,
		1.5,
		0.5
	)

	-- Draw galaxy dust

	galaxyDustShader:send("cameraPosition", {vec3.components(galaxy.originPositionInGalaxy / galaxy.radius)})
	galaxyDustShader:send("rayStepCount", consts.galaxyRaySteps)
	sendGalaxyInfoToShader(galaxyDustShader, galaxy)
	util.drawToCubemapCanvas(canvas, function(orientation)
		love.graphics.clear(0, 0, 0, 1)

		-- Do volumetrics
		love.graphics.setColorMask(true, true, true, false)
		love.graphics.setBlendMode("alpha", "premultiplied")
		local worldToCameraStationary = mat4.camera(vec3(), orientation)
		local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)
		galaxyDustShader:send("clipToSky", {mat4.components(clipToSky)})
		love.graphics.setShader(galaxyDustShader)
		love.graphics.draw(dummyTexture, 0, 0, 0, love.graphics.getCanvas()[1][1]:getDimensions())
		love.graphics.setBlendMode("alpha")
		love.graphics.setColorMask()
	end, false, false)

	-- Prepare stars

	local starBuffer = love.graphics.newBuffer({
		{name = "position", format = "floatvec3"},
		{name = "incomingLightPreExtinction", format = "floatvec3"}
	}, #galaxy.otherStars, {shaderstorage = true})
	local starDrawableBuffer = love.graphics.newBuffer({
		{name = "direction", format = "floatvec3"},
		{name = "incomingLight", format = "floatvec3"}
	}, #galaxy.otherStars, {shaderstorage = true})

	local solidAngle = consts.tau * (1 - math.cos(consts.pointLightBlurAngularRadius))
	local starBufferData = {}
	for i, star in ipairs(galaxy.otherStars) do
		local relativePosition = star.position - galaxy.originPositionInGalaxy
		local distance = #relativePosition

		local luminousFlux = star.radiantFlux * star.luminousEfficacy
		local illuminance = luminousFlux * distance ^ -2
		local luminance = illuminance / solidAngle

		local x, y, z = vec3.components(star.position / galaxy.radius)
		local r, g, b = love.math.gammaToLinear(star.colour)

		starBufferData[i] = {
			x, y, z,
			r * luminance, g * luminance, b * luminance
		}
	end
	starBuffer:setArrayData(starBufferData)

	sendGalaxyInfoToShader(starExtinctionComputeShader, galaxy)
	starExtinctionComputeShader:send("Stars", starBuffer)
	starExtinctionComputeShader:send("StarDrawables", starDrawableBuffer)
	starExtinctionComputeShader:send("starCount", #galaxy.otherStars)
	starExtinctionComputeShader:send("cameraPosition", {vec3.components(galaxy.originPositionInGalaxy / galaxy.radius)})
	starExtinctionComputeShader:send("rayStepCount", consts.galaxyRaySteps)
	local groupCount = math.ceil(#galaxy.otherStars / starExtinctionComputeShader:getLocalThreadgroupSize())
	love.graphics.dispatchThreadgroups(starExtinctionComputeShader, groupCount) -- Get star extinctions

	-- Draw stars

	local diskDistanceToSphere = util.unitSphereSphericalCapHeightFromAngularRadius(consts.pointLightBlurAngularRadius)
	local scaleToGetAngularRadius = math.tan(consts.pointLightBlurAngularRadius)
	blurredPointInstanceShader:send("diskDistanceToSphere", diskDistanceToSphere)
	blurredPointInstanceShader:send("scale", scaleToGetAngularRadius)
	blurredPointInstanceShader:send("vertexFadePower", consts.blurredPointVertexFadePower)
	blurredPointInstanceShader:send("StarDrawables", starDrawableBuffer) -- Has star extinctions
	util.drawToCubemapCanvas(canvas, function(orientation)
		-- All love graphics state changes are popped

		local worldToClip = cameraToClip * mat4.camera(vec3(), orientation)
		local cameraUp = vec3.rotate(consts.upVector, orientation)
		local cameraRight = vec3.rotate(consts.rightVector, orientation)
		blurredPointInstanceShader:send("cameraUp", {vec3.components(cameraUp)})
		blurredPointInstanceShader:send("cameraRight", {vec3.components(cameraRight)})
		blurredPointInstanceShader:send("worldToClip", {mat4.components(worldToClip)})

		love.graphics.setBlendMode("add")

		love.graphics.setShader(blurredPointInstanceShader)
		love.graphics.drawInstanced(diskMesh, #galaxy.otherStars)
	end, true, true)
end
