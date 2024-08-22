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

	local e = meanAnomaly
	local f = e - orbit.eccentricity * math.sin(e) - meanAnomaly
	local i = 0
	while math.abs(f) > consts.orbitNewtonRaphsonEpsilon and i < consts.maxOrbitNewtonRaphsonIterations do
		e = e - f / (1 - orbit.eccentricity * math.cos(e))
		f = e - orbit.eccentricity * math.sin(e) - meanAnomaly
		i = i + 1
	end
	local eccentricAnomaly = e

	local trueAnomaly = orbit.argumentOfPeriapsis + 2 * math.atan2(
		math.sqrt(1 + orbit.eccentricity) * math.sin(eccentricAnomaly / 2),
		math.sqrt(1 - orbit.eccentricity) * math.cos(eccentricAnomaly / 2)
	)
	local distance = orbit.semiMajorAxis * (1 - orbit.eccentricity * math.cos(eccentricAnomaly))

	local position2D = vec2.fromAngle(trueAnomaly) * distance
	local velocity2D = math.sqrt(standardGravitationalParameter * orbit.semiMajorAxis) / distance * vec2(
		-math.sin(eccentricAnomaly + orbit.argumentOfPeriapsis),
		math.sqrt(1 - orbit.eccentricity ^ 2) * math.cos(eccentricAnomaly + orbit.argumentOfPeriapsis)
	)
	local rotation = util.getOrbitalPlaneRotation(body)

	-- TODO: Test velocity
	return
		vec3.rotate(vec3(position2D.x, position2D.y, 0), rotation),
		vec3.rotate(vec3(velocity2D.x, velocity2D.y, 0), rotation)
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
