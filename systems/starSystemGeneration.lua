local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")

local starSystemGeneration = concord.system()

local function generateSystem(parent, curveInfo, depth, ownI, state, graphicsObjects)
	local numBodies
	if not parent then
		numBodies = 1
	else
		-- At start, distanceLimitingFactor starts to ramp up from 0, and reaches 1 at start + length
		local start = 3
		local length = 8
		local distanceLimitingFactor = depth > 1 and math.min(math.max(ownI - start, 0) / length, 1) or 1 -- Limit number of children based on proximity to parent
		local maxBodies = math.floor(distanceLimitingFactor * 12 / depth ^ 1.25)
		numBodies = love.math.random(0, maxBodies)
		numBodies = maxBodies -- TEMP
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
			local semiMajorAxis = curveInfo.baseDistance * curveInfo.base ^ i -- Important that i starts from 1
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
			local mass = util.randomRange(1500000, 2500000)
			local density = util.randomRange(0.001, 0.002)
			local volume = mass / density
			local radius = (volume / (2 / 3 * consts.tau)) ^ (1 / 3)
			local radiantFlux = mass ^ 4 * 26 -- AKA luminosity. In watts. The multiplier is in watts per ronnagrams to the fourth. Apparently luminosity/radiant flux of a star is proportional to the mass to the 4th (ish. I'm pretending it's more exact)
			-- Solar mass is 1980000 Rg, put it through the equation and you get a radiant flux of approximately 4*10^26 W, which is approximately that of the sun
			local luminousEfficacy = util.randomRange(90, 100) -- In lumens per Watt
			local luminousFlux = radiantFlux * luminousEfficacy -- In lumens. Visible equivalent to radiant flux. The luminous efficacy, if at the sun's 93 lumens per Watt, would take a radiant flux of the sun to a luminous flux of the sun (which is around 3.62 * 10^28 lumens, apparently)
			-- So: inputting the sun's mass and luminous efficacy gets you the sun's luminous flux. Which is what we want.
			local colour = {1, 1, 1}
			body:give("starData", radiantFlux, luminousEfficacy, colour)
			body:give("celestialMass", mass)
			body:give("celestialRadius", radius)
			-- body:give("atmosphere",
			-- 	radius * util.randomRange(1.2, 1.4),
			-- 	{1, 1, 1},
			-- 	util.randomRange(0.25, 1),
			-- 	luminousFlux * util.randomRange(0.25, 0.5),
			-- 	util.randomRange(0.5, 2)
			-- )
		elseif bodyType == "planet" or bodyType == "moon" then
			-- TEMP: Assume all rocky planets. TODO: Add gas giants
			assert(parent, "Can't have planet/moon without parent")
			local parentVolume = 2 / 3 * consts.tau * parent.celestialRadius.value ^ 3
			local parentDensity = parent.celestialMass.value / parentVolume
			local thisMass = parent.celestialMass.value * 10 ^ util.randomRange(-7.5, -4.5)
			local thisDensity = parentDensity * util.randomRange(0.75, 1.25) * (parent.starData and util.randomRange(3.5, 4.5) or 1)
			local thisVolume = thisMass / thisDensity
			local thisRadius = (thisVolume / (2 / 3 * consts.tau)) ^ (1 / 3)
			body:give("celestialMass", thisMass)
			body:give("celestialRadius", thisRadius)
			if love.math.random() < 0 then -- TEMP atmosphere disabled
				body:give("atmosphere",
					thisRadius * util.randomRange(0.001, 0.05),
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

		local seed = love.math.random(0, 2 ^ 32 - 1)
		local drawFunction = util.getAlbedoCubemapDrawFunction(body, seed, graphicsObjects)
		body:give("albedoCubemap", seed, util.generateCubemap(256, nil, drawFunction))

		state.ecs:addEntity(body)
		if depth < 2 then
			local newCurveInfo = {
				baseDistance = body.celestialRadius.value * util.randomRange(50, 100),
				base = util.randomRange(1.9, 2.5)
			}
			generateSystem(body, newCurveInfo, depth + 1, i, state, graphicsObjects)
		end
	end
end

function starSystemGeneration:init()
	self.graphicsObjects = {}
	self.graphicsObjects.dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))
	self.graphicsObjects.baseColoursShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/albedoGeneration/baseColours.glsl")
	)
	self.graphicsObjects.noiseShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/albedoGeneration/noise.glsl")
	)
end

function starSystemGeneration:newWorld()
	generateSystem(nil, nil, 0, nil, self:getWorld().state, self.graphicsObjects)
end

return starSystemGeneration
