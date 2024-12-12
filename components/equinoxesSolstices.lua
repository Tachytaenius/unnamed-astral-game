local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3
local quat = mathsies.quat

local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")

return concord.component("equinoxesSolstices", function(c, body)
	local orbit = body.keplerOrbit
	local orbitPlaneOrientation = util.getOrbitalPlaneRotation(body) * quat.fromAxisAngle(consts.forwardVector * orbit.argumentOfPeriapsis)
	local rotationAxisRotated = vec3.rotate(body.celestialRotation.rotationAxis, quat.inverse(orbitPlaneOrientation))
	local crossResult = vec3.cross(consts.forwardVector, rotationAxisRotated)
	if #crossResult == 0 then
		return
	end
	local crossResult2D = vec2(crossResult.x, crossResult.y)
	local equinoxATrueAnomaly = vec2.toAngle(crossResult2D)

	c.equinoxAMeanAnomaly = util.meanAnomalyFromTrueAnomaly(equinoxATrueAnomaly, orbit)
	c.solsticeAMeanAnomaly = util.meanAnomalyFromTrueAnomaly(equinoxATrueAnomaly + consts.tau / 4, orbit)
	c.equinoxBMeanAnomaly = util.meanAnomalyFromTrueAnomaly(equinoxATrueAnomaly + consts.tau / 2, orbit)
	c.solsticeBMeanAnomaly = util.meanAnomalyFromTrueAnomaly(equinoxATrueAnomaly - consts.tau / 4, orbit)
end)

-- local mathsies = require("lib.mathsies")
-- local vec2 = mathsies.vec2
-- local vec3 = mathsies.vec3
-- local quat = mathsies.quat

-- local concord = require("lib.concord")

-- local util = require("util")
-- local consts = require("consts")

-- -- Initially we saved position and time from two plane-ellipse intersections. Now we only save mean anomaly, derived from one ellipse-plane intersection. But the code is still there, so it may look odd. Additionally, I left in any interesting functions made while trying to work stuff out. Trimmed, this code could be a lot shorter.
-- return concord.component("equinoxesSolstices", function(c, body)
-- 	-- Relative to parent body
-- 	local orbit = body.keplerOrbit
-- 	local ellipseCentre = util.getLocalOrbitCentre(body)
-- 	local semiMinorAxis = orbit.semiMajorAxis * math.sqrt(1 - orbit.eccentricity ^ 2)
-- 	local ellipseOrientation = util.getOrbitalPlaneRotation(body) * quat.fromAxisAngle(consts.forwardVector * orbit.argumentOfPeriapsis)
-- 	-- local orbitPlaneNormal = vec3.rotate(consts.forwardVector, ellipseOrientation)

-- 	-- local crossResult = vec3.cross(body.celestialRotation.rotationAxis, orbitPlaneNormal)
-- 	-- if #crossResult == 0 then
-- 	-- 	-- Axis of rotation is perpendicular to orbital plane, no equinoxes or solstices
-- 	-- 	return
-- 	-- end
-- 	-- local crossResultNormalised = vec3.normalise(crossResult)

-- 	-- local solsticeA2D, solsticeB2D -- Relative to ellipse centre, unrotated (periapsis should be at angle 0)
-- 	-- c.solsticeA, c.solsticeB, solsticeA2D, solsticeB2D = util.ellipsePlaneIntersection(
-- 	-- 	ellipseCentre, ellipseOrientation, orbit.semiMajorAxis, semiMinorAxis,
-- 	-- 	crossResultNormalised, 0
-- 	-- )
-- 	-- c.solsticeA, c.solsticeB = nil, nil

-- 	local equinoxA2D, equinoxB2D -- Same reference frame as above
-- 	c.equinoxA, c.equinoxB, equinoxA2D, equinoxB2D = util.ellipsePlaneIntersection(
-- 		ellipseCentre, ellipseOrientation, orbit.semiMajorAxis, semiMinorAxis,
-- 		body.celestialRotation.rotationAxis, 0
-- 	)
-- 	c.equinoxA, c.equinoxB = nil, nil -- Never mind the actual positions, we are just looking for mean anomaly

-- 	local periapsisDistance = orbit.semiMajorAxis * (1 - orbit.eccentricity)
-- 	local apoapsisDistance = orbit.semiMajorAxis * (1 + orbit.eccentricity)
-- 	local localOrbitCentreUnrotated = vec2((periapsisDistance - apoapsisDistance) / 2, 0)

-- 	local function timeFromEventPos2D(eventPos2D)
-- 		return util.getTimeFromTrueAnomaly(vec2.toAngle(eventPos2D + localOrbitCentreUnrotated), orbit)
-- 	end

-- 	local function positionFromTrueAnomaly(trueAnomaly)
-- 		local dir = vec2.fromAngle(trueAnomaly)
-- 		local inT, outT = util.ellipseRaycastUnrotated(vec2(), dir, localOrbitCentreUnrotated, orbit.semiMajorAxis, semiMinorAxis)
-- 		local position2D = dir * inT -- I thought it'd be outT
-- 		local rotation = util.getOrbitalPlaneRotation(body) * quat.fromAxisAngle(consts.forwardVector * orbit.argumentOfPeriapsis)
-- 		return vec3.rotate(vec3(position2D.x, position2D.y, 0), rotation)
-- 	end

-- 	local function trueAnomalyFromTime(time)
-- 		local standardGravitationalParameter = consts.gravitationalConstant * orbit.parent.celestialMass.value
-- 		local meanAnomaly = orbit.initialMeanAnomaly + time * math.sqrt(standardGravitationalParameter / orbit.semiMajorAxis ^ 3)
-- 		return util.trueAnomalyFromMeanAnomaly(meanAnomaly, orbit)
-- 	end

-- 	local function meanAnomalyFromEventPos2D(eventPos2D)
-- 		return util.meanAnomalyFromTrueAnomaly(vec2.toAngle(eventPos2D + localOrbitCentreUnrotated), orbit)
-- 	end

-- 	local function offsetTrueAnomalyOfMeanAnomaly(meanAnomaly, offset)
-- 		return util.meanAnomalyFromTrueAnomaly((util.trueAnomalyFromMeanAnomaly(meanAnomaly, orbit) + offset) % consts.tau, orbit)
-- 	end

-- 	c.equinoxAMeanAnomaly = meanAnomalyFromEventPos2D(equinoxA2D)
-- 	c.equinoxBMeanAnomaly = offsetTrueAnomalyOfMeanAnomaly(c.equinoxAMeanAnomaly, consts.tau / 2)
-- 	c.solsticeAMeanAnomaly = offsetTrueAnomalyOfMeanAnomaly(c.equinoxAMeanAnomaly, -consts.tau / 4)
-- 	c.solsticeBMeanAnomaly = offsetTrueAnomalyOfMeanAnomaly(c.equinoxAMeanAnomaly, consts.tau / 4)
-- end)
