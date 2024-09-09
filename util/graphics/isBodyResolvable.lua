local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")

local util = require("util")

-- Aware this is not optimised/simplified at all lol

return function(body, cameraComponent, fudgeFactor)
	-- Higher fudgeFactor means higher pretend angular radius-- i.e. the body is considered resolvable even when it isn't.
	-- Lower means it's not considered resolvable even when it is.
	fudgeFactor = fudgeFactor or 1

	-- Setup matrices
	local cameraToClip = mat4.perspectiveLeftHanded(
		consts.canvasSystemWidth / consts.canvasSystemHeight,
		cameraComponent.verticalFOV,
		1.5,
		0.5
	)
	-- local worldToCameraStationary = mat4.camera(vec3(), quat())
	local clipToSky = mat4.inverse(cameraToClip --[[* worldToCameraStationary]])
	-- Get vectors
	local topRightClipSpace = vec3(1, 1, -1) -- -1 puts it on the near plane which is nice :)
	local closerToCentreClipSpace = vec3(
		(consts.canvasSystemWidth / 2 - 1) / (consts.canvasSystemWidth / 2),
		(consts.canvasSystemHeight / 2 - 1) / (consts.canvasSystemHeight / 2),
		-1
	)
	local topRightSkySpace = clipToSky * topRightClipSpace
	local closerToCentreSkySpace = clipToSky * closerToCentreClipSpace
	-- Get angular separation
	local largestPixelAngularRadius = util.angleBetweenVectors(topRightSkySpace, closerToCentreSkySpace)

	-- Get angular radius of body
	local angularRadius = util.getSphereAngularRadius(body.celestialRadius.value, vec3.distance(cameraComponent.absolutePosition, body.celestialMotionState.position))

	-- Check for NaN (inside body (floats can be funky so we're not going to just "is distance <= radius" at the beginning of the function))
	if angularRadius ~= angularRadius then
		-- Inside body. May as well say it's resolvable
		return true
	end

	-- Compare
	return fudgeFactor * angularRadius >= largestPixelAngularRadius
end
