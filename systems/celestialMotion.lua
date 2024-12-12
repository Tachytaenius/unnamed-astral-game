local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3
local quat = mathsies.quat
local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")

local celestialMotion = concord.system({
	hasOrbitState = {"celestialMotionState"},
	hasOrientationState = {"celestialOrientationState"},
	rotates = {"celestialRotation"}
})

local function getLocalStateVectors(body, time)
	local orbit = body.keplerOrbit
	local standardGravitationalParameter = consts.gravitationalConstant * orbit.parent.celestialMass.value
	local meanAnomaly = orbit.initialMeanAnomaly + time * math.sqrt(standardGravitationalParameter / orbit.semiMajorAxis ^ 3)
	return util.getLocalStateVectorsFromMeanAnomaly(meanAnomaly, body)
end

local function recurse(body, state)
	if not body.keplerOrbit then
		body:give("celestialMotionState", state.originBodyPosition, vec3())
	else
		local parentPosition = body.keplerOrbit.parent.celestialMotionState.position
		local parentVelocity = body.keplerOrbit.parent.celestialMotionState.velocity
		local localPosition, localVelocity = getLocalStateVectors(body, state.time)
		body:give("celestialMotionState", parentPosition + localPosition, parentVelocity + localVelocity)
	end

	if not body.satellites then
		return
	end

	for _, satellite in ipairs(body.satellites.value) do
		recurse(satellite, state)
	end
end

function celestialMotion:update()
	-- Clear

	for _, entity in ipairs(self.hasOrbitState) do
		entity:remove("celestialMotionState")
	end

	for _, entity in ipairs(self.hasOrientationState) do
		entity:remove("celestialOrientationState")
	end

	-- Add

	local state = self:getWorld().state

	local originBody = state.originBody
	if originBody then
		recurse(originBody, state)
	end

	for _, entity in ipairs(self.rotates) do
		local rotation = entity.celestialRotation
		-- Tidal locking would be controlled here
		local orientation = quat.fromAxisAngle(rotation.rotationAxis * (rotation.initialAngle + rotation.angularSpeed * state.time))
		entity:give("celestialOrientationState", orientation)
	end
end

return celestialMotion
