local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3

local consts = require("consts")

local util = require("util")

return function(body, cameraComponent, fudgeFactor)
	-- Higher fudgeFactor means higher pretend angular radius-- i.e. the body is considered resolvable even when it isn't.
	-- Lower means it's not considered resolvable even when it is.
	fudgeFactor = fudgeFactor or 1

	-- Get minimum angular radius
	local minimumResolvableAngularRadius = util.getLargestPixelAngularRadius(consts.canvasSystemWidth, consts.canvasSystemHeight, cameraComponent.verticalFOV)
	-- local minimumResolvableAngularRadius = consts.pointLightBlurAngularRadius -- This makes things worse

	-- Get angular radius of body and atmosphere (edit: not doing atmosphere, it makes it worse as well)
	-- local fullRadius = body.celestialRadius.value + (body.atmosphere and body.atmosphere.height or 0)
	local angularRadius = util.getSphereAngularRadius(body.celestialRadius.value, vec3.distance(cameraComponent.absolutePosition, body.celestialMotionState.position))

	-- Check for NaN (inside body (floats can be funky so we're not going to just "is distance <= radius" at the beginning of the function))
	if angularRadius ~= angularRadius then
		-- Inside body. May as well say it's resolvable
		return true
	end

	-- Compare
	return fudgeFactor * angularRadius >= minimumResolvableAngularRadius
end
