local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local mat4 = mathsies.mat4

local util = require("util")

-- Aware this is not optimised/simplified at all lol

return function(width, height, verticalFOV)
	-- Setup matrices
	local cameraToClip = mat4.perspectiveLeftHanded(
		width / height,
		verticalFOV,
		1.5,
		0.5
	)
	-- local worldToCameraStationary = mat4.camera(vec3(), quat())
	local clipToSky = mat4.inverse(cameraToClip --[[* worldToCameraStationary]])
	-- Get vectors
	local topRightClipSpace = vec3(1, 1, -1) -- -1 puts it on the near plane which is nice :)
	local closerToCentreClipSpace = vec3(
		(width / 2 - 1) / (width / 2),
		(height / 2 - 1) / (height / 2),
		-1
	)
	local topRightSkySpace = clipToSky * topRightClipSpace
	local closerToCentreSkySpace = clipToSky * closerToCentreClipSpace
	-- Get angular separation
	local largestPixelAngularRadius = util.angleBetweenVectors(topRightSkySpace, closerToCentreSkySpace)
	return largestPixelAngularRadius
end
