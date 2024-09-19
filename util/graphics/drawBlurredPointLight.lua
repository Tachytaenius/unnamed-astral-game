local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local util = require("util")
local consts = require("consts")

local diskMesh, blurredPointShader

local function ensureGraphicsObjects()
	blurredPointShader = love.graphics.newShader("shaders/blurredPoint.glsl")
	diskMesh = util.generateDiskMesh(consts.blurredPointDiskMeshVertices)
end

-- worldToClip should not translate (camera should be at the origin)
return function(direction, cameraToClip, cameraOrientation, angularRadius, colour) -- Colour contains brightness. It goes to the lightCanvas which has float pixels.
	ensureGraphicsObjects()

	-- We're using disks. The angular radius of a disk at distance 1 is atan(radius) (would divide radius by distance).
	-- We want a radius that gets the right angular radius, so we use tan.
	local scaleToGetAngularRadius = math.tan(angularRadius)
	local cameraUp = vec3.rotate(consts.upVector, cameraOrientation)
	local worldToClip = cameraToClip * mat4.camera(vec3(), cameraOrientation)
	local diskDistanceToSphere = util.unitSphereSphericalCapHeightFromAngularRadius(angularRadius)

	blurredPointShader:send("vertexFadePower", consts.blurredPointVertexFadePower)
	blurredPointShader:send("pointDirection", {vec3.components(direction)})
	blurredPointShader:sendColor("pointColour", colour)
	blurredPointShader:send("cameraUp", {vec3.components(cameraUp)})
	blurredPointShader:send("scale", scaleToGetAngularRadius)
	blurredPointShader:send("diskDistanceToSphere", diskDistanceToSphere)
	blurredPointShader:send("worldToClip", {mat4.components(worldToClip)})
	love.graphics.setShader(blurredPointShader)

	love.graphics.setBlendMode("add")
	love.graphics.draw(diskMesh)
end
