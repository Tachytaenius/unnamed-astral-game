local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")

local starSystemGeneration = concord.system()

local function generateSystem(parent, depth, ownI, state)
	local numBodies
	if parent then
		-- At start, distanceLimitingFactor starts to ramp up from 0, and reaches 1 at start + length
		local start = 2
		local length = 4
		local distanceLimitingFactor = depth > 1 and math.min(math.max(ownI - start, 0) / length, 1) or 1 -- Limit number of children based on proximity to parent
		local maxBodies = math.floor(distanceLimitingFactor * 12 / depth ^ 1.25)
		numBodies = love.math.random(0, maxBodies)
	else
		numBodies = 1
	end

	for i = 1, numBodies do
		local body = concord.entity()
		local bodyType =
			depth == 0 and "star" or
			depth == 1 and "planet" or
			depth == 2 and "moon"
		body:give("celestialBody", bodyType)
		body:give("satellites")

		if not parent then
			assert(depth == 0, "Can't have star system depth without parent")
			state.originBody = body
		else
			parent.satellites.value[#parent.satellites.value + 1] = body

			-- Kepler orbital elements
			local semiMajorAxis = parent.celestialRadius.value * (i ^ 2.3 * (40 + util.randomRange(0, 2.5))) / depth ^ 2 -- Important that i starts from 1
			local eccentricity = util.randomRange(0, 0.05)
			local argumentOfPeriapsis = util.randomRange(0, consts.tau)
			local initialMeanAnomaly = util.randomRange(0, consts.tau)
			local longitudeOfAscendingNode = util.randomRange(0, consts.tau)
			local inclination = (consts.tau * 0.0025 * (love.math.random() * 2 - 1))

			body:give("keplerOrbit", parent,
				semiMajorAxis,
				eccentricity,
				argumentOfPeriapsis,
				initialMeanAnomaly,
				longitudeOfAscendingNode,
				inclination
			)
		end

		if bodyType == "star" then
			local mass = util.randomRange(10, 50)
			local density = util.randomRange(20, 40)
			local volume = mass / density
			local radius = (volume / (2 / 3 * consts.tau)) ^ (1 / 3)
			local luminosity = mass ^ 4 * 100
			assert(luminosity ~= math.huge and luminosity == luminosity)
			local colour = {1, 1, 1}
			body:give("starData", luminosity, colour)
			body:give("celestialMass", mass)
			body:give("celestialRadius", radius)
			body:give("atmosphere",
				radius * util.randomRange(1.2, 1.4),
				{1, 1, 1},
				util.randomRange(0.25, 1),
				luminosity * util.randomRange(0.025, 0.05),
				util.randomRange(0.5, 2)
			)
		elseif bodyType == "planet" or bodyType == "moon" then
			assert(parent, "Can't have planet/moon without parent")
			local parentVolume = 2 / 3 * consts.tau * parent.celestialRadius.value ^ 3
			local parentDensity = parent.celestialMass.value / parentVolume
			local thisMass = parent.celestialMass.value * util.randomRange(0.0005, 0.02)
			local thisDensity = parentDensity * util.randomRange(0.75, 1.25)
			local thisVolume = thisMass / thisDensity
			local thisRadius = (thisVolume / (2 / 3 * consts.tau)) ^ (1 / 3)
			body:give("celestialMass", thisMass)
			body:give("celestialRadius", thisRadius)
			if love.math.random() < 1 then
				body:give("atmosphere",
					thisRadius * util.randomRange(0.01, 0.1),
					{1, 1, 1},
					util.randomRange(3, 5),
					0,
					util.randomRange(0.5, 2)
				)
			end
		end

		-- TODO: Tidal locking (only if has parent)
		local rotationAxisRotation = quat.fromAxisAngle(util.randomInSphereVolume(consts.tau * 0.1)) -- Used to perturb rotation axis off forward vector
		local rotationAxis = vec3.rotate(consts.forwardVector, rotationAxisRotation)
		local initialAngle = love.math.random() * consts.tau
		local surfaceSpeed = util.randomRange(0.5, 1)
		local angularSpeed = surfaceSpeed / body.celestialRadius.value
		body:give("celestialRotation", rotationAxis, initialAngle, angularSpeed)

		state.ecs:addEntity(body)
		if depth < 2 then
			generateSystem(body, depth + 1, i, state)
		end
	end
end

function starSystemGeneration:newWorld()
	generateSystem(nil, 0, nil, self:getWorld().state)
end

return starSystemGeneration
