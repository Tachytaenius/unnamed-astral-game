local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")

local starSystemGeneration = concord.system()

-- https://www.desmos.com/calculator/spkmau6z7n

local function baseLineCurve(x)
	return
		x < 0.5 and 0 or
		x > 0.5 and 1 or
		math.sin(consts.tau * x / 2) * 0.5 + 0.5
end

local function transformedCurve(x, peak, transition, width, base)
	local baseOut = baseLineCurve((x - transition) / width)
	return peak * (baseOut * (1 - base / peak) + base / peak)
end

local function planetProbabilityWeightCurve(
	x, peak,
	transitionLeft, widthLeft, baseLeft,
	transitionRight, widthRight, baseRight
)
	-- TODO: Error for values producing discontinuities in the function. Or blend between them, which should be made such that for piecewise baseLineCurve functions that hit 1 it makes no difference. The piecewise joining point between the two functions is in the if statement below, which is where the discontinuity would happen
	if x < transitionLeft + widthLeft / 2 then
		-- Left side
		return transformedCurve(x, peak, transitionLeft, widthLeft, baseLeft)
	else
		-- Right side (fliped around its transition point)
		return transformedCurve(2 * transitionRight - x, peak, transitionRight, widthRight, baseRight)
	end
end

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
	end

	for i = 1, numBodies do
		local body = concord.entity()
		local bodyType

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

		if depth == 0 then
			bodyType = "star"
		elseif depth == 1 then
			local distance = body.keplerOrbit.semiMajorAxis -- Should be average distance from star over time, really, but the orbits aren't very eccentric
			local function saturate(x) return math.max(0, math.min(1, x)) end
			-- bodyType = util.weightedRandomChoice({
			-- 	{value = "rocky", weight = saturate(1 - distance / 4e10)},
			-- 	{value = "gaseous", weight = }
			-- })
			local gaseousChance = saturate((distance - 6e11) / 1e12) * 0.8
			bodyType = love.math.random() < gaseousChance and "gaseous" or "rocky"
		else
			bodyType = "rocky"
		end
		body:give("celestialBody", bodyType)

		local parentVolume = parent and 2 / 3 * consts.tau * parent.celestialRadius.value ^ 3
		local parentDensity = parent and parent.celestialMass.value / parentVolume
		local mass, radius
		if bodyType == "star" then
			mass = util.randomRange(1.5e30, 2.5e30)
			local density = util.randomRange(1200, 1600)
			local volume = mass / density
			radius = (volume / (2 / 3 * consts.tau)) ^ (1 / 3)
			local radiantFlux = mass ^ 4 * 2.451e-95 -- AKA luminosity. In watts. The multiplier is in watts per kilograms to the fourth. Apparently luminosity/radiant flux of a star is proportional to the mass to the 4th (ish. I'm pretending it's more exact)
			-- Solar mass is 1.988 * 10^30 kg, put it through the equation and you get a radiant flux of approximately 4*10^26 W, which is approximately that of the sun
			local luminousEfficacy = util.randomRange(90, 100) -- In lumens per Watt
			local luminousFlux = radiantFlux * luminousEfficacy -- In lumens. Visible equivalent to radiant flux. The luminous efficacy, if at the sun's 93 lumens per Watt, would take a radiant flux of the sun to a luminous flux of the sun (which is around 3.62 * 10^28 lumens, apparently)
			-- So: inputting the sun's mass and luminous efficacy gets you the sun's luminous flux. Which is what we want.
			local colour = {1, 1, 1}
			body:give("starData", radiantFlux, luminousEfficacy, colour)
			-- body:give("atmosphere",
			-- 	radius * util.randomRange(1.2, 1.4),
			-- 	{1, 1, 1},
			-- 	util.randomRange(0.25, 1),
			-- 	luminousFlux * util.randomRange(0.25, 0.5),
			-- 	util.randomRange(0.5, 2)
			-- )
		elseif bodyType == "rocky" then
			mass = parent.celestialMass.value * 10 ^ util.randomRange(-7.5, -4.5)
			local thisDensity = parentDensity * util.randomRange(0.75, 1.25) * (
				depth == 1 and util.randomRange(3.5, 4.5)
				or 1
			)
			local thisVolume = mass / thisDensity
			radius = (thisVolume / (2 / 3 * consts.tau)) ^ (1 / 3)

			if love.math.random() < 0 then -- TEMP atmosphere disabled
				body:give("atmosphere",
					radius * util.randomRange(0.001, 0.05),
					{1, 1, 1},
					util.randomRange(3, 5),
					0,
					util.randomRange(0.5, 2)
				)
			end

			-- Oceanic worlds should have different sets of features (or perhaps hide their features under the ocean)
			local primaryColour = {love.math.random(), love.math.random(), love.math.random()} -- TEMP
			local secondaryColour = {love.math.random(), love.math.random(), love.math.random()} -- TEMP, base it on primaryColour
			local features = {}
			-- Code here is confusing because feature sets are features that contain features
			for featureSetIndex = 1, love.math.random(0, 2) do
				local featureSet = {isSet = true}
				featureSet.baseColour = {}
				for i = 1, 3 do
					featureSet.baseColour[i] = primaryColour[i] * util.randomRange(0.25, 0.5)
				end
				featureSet.baseColour[4] = util.randomRange(0.5, 1)
				-- None of this leads to a uniform distribution of feature points on the sphere particularly but whatever
				featureSet.baseDirection = util.randomOnSphereSurface(1)
				featureSet.featureMaxAngularDistance = util.randomRange(consts.tau * 0.1, consts.tau * 0.3)
				for featureIndex = 1, love.math.random(10, 40) do
				local feature = {}
					feature.type = love.math.random() < 0.6 and "streak" or "patch"
					local baseToFeature = util.randomOnSphereSurface(love.math.random() * featureSet.featureMaxAngularDistance)
					local featurePos = vec3.rotate(featureSet.baseDirection, quat.fromAxisAngle(baseToFeature))
					if feature.type == "streak" then
						feature.startPoint = featurePos
						local rotationToEnd = util.randomOnSphereSurface(util.randomRange(consts.tau * 0.1, consts.tau * 0.4))
					feature.endPoint = vec3.rotate(feature.startPoint, quat.fromAxisAngle(rotationToEnd))
						feature.angularWidth = util.randomRange(consts.tau * 0.0001, consts.tau * 0.002)
						feature.alphaMultiplier = util.randomRange(0.8, 1)
						feature.edgeFadeAngularLength = feature.angularWidth * util.randomRange(0.2, 1.5)
					elseif feature.type == "patch" then
						feature.location = featurePos
						feature.angularRadius = util.randomRange(consts.tau * 0.002, consts.tau * 0.02)
						feature.noisiness = util.randomRange(0.2, 0.8)
						feature.alphaMultiplier = util.randomRange(0.4, 1)
						feature.edgeFadeAngularLength = feature.angularRadius * util.randomRange(0.2, 2)
					end
					featureSet[featureIndex] = feature
				end
				features[featureSetIndex] = featureSet
			end
			-- Non-set features
			for _=1, love.math.random(0, 100) do
				local feature = {}
				local impact = util.randomRange(0.1, 1)
				feature.type = "crater"
				feature.direction = util.randomOnSphereSurface(1)
				feature.angularRadius = util.lerp(consts.tau * 0.005, consts.tau * 0.01, impact)
				feature.depth = util.lerp(0, 10, impact + love.math.random() * 0.2)
				feature.power = util.randomRange(1, 3)
				feature.centreAngularRadius = feature.angularRadius * util.randomRange(0.02, 0.1)
				feature.centreHeight = feature.depth * util.randomRange(0.01, 0.05)
				feature.centrePower = util.randomRange(1, 2)
				feature.wallWidthRampUp = feature.angularRadius * util.randomRange(0.01, 0.11)
				feature.wallWidthRampDown = feature.angularRadius * util.randomRange(0.45, 0.55)
				feature.wallPeakHeight = util.lerp(0, 8, impact)
				feature.heightMultiplierNoiseFrequency = util.randomRange(40, 80)
				feature.heightMultiplierNoiseAmplitude = util.randomRange(0, 0.5)
				features[#features + 1] = feature
			end
			body:give("celestialBodySurface", {primaryColour, secondaryColour}, features)
		elseif bodyType == "gaseous" then
			mass = parent.celestialMass.value * 10 ^ util.randomRange(-4.5, -3)
			local thisDensity = parentDensity * util.randomRange(0.75, 1.25) 
			local thisVolume = mass / thisDensity
			radius = (thisVolume / (2 / 3 * consts.tau)) ^ (1 / 3)
		end
		if not body.celestialBodySurface then
			body:give("celestialBodySurface", {{1, 1, 1}, {0.5, 0.5, 0.5}}, {}) -- TEMP
		end
		body:give("celestialMass", mass)
		body:give("celestialRadius", radius)

		-- TODO: Tidal locking (only if has parent)
		local rotationAxisRotation = quat.fromAxisAngle(util.randomInSphereVolume(consts.tau * 0.1)) -- Used to perturb rotation axis off forward vector
		local rotationAxis = vec3.rotate(consts.forwardVector, rotationAxisRotation)
		local initialAngle = love.math.random() * consts.tau
		local surfaceSpeed = util.randomRange(0.5, 1) * 50000 -- TODO TEMP
		local angularSpeed = surfaceSpeed / body.celestialRadius.value
		body:give("celestialRotation", rotationAxis, initialAngle, angularSpeed)

		local seed = love.math.random(0, 2 ^ 32 - 1)
		local sideSize = 1024
		local baseColourDrawFunction, normalDrawFunction = util.getPlanetTextureCubemapDrawFunctions(body, seed, graphicsObjects, sideSize)
		local cubemaps = util.generatePlanetTextureCubemaps(sideSize, baseColourDrawFunction, normalDrawFunction)
		body:give("textureCubemaps", seed, cubemaps.baseColour, cubemaps.normal, cubemaps.height)

		body:give("satellites")
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
	self.graphicsObjects.baseShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/planetTexturing/base.glsl")
	)
	self.graphicsObjects.noiseShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/noise.glsl")
	)
	self.graphicsObjects.featureSetShader = love.graphics.newShader(
		--[[love.filesystem.read(]]"shaders/planetTexturing/featureSet.glsl"--[[)]]
	)
	self.graphicsObjects.heightmapBaseShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/random.glsl") ..
		love.filesystem.read("shaders/include/lib/dist.glsl") ..
		love.filesystem.read("shaders/include/lib/worley.glsl") ..
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/heightmapBase.glsl")
	)

	self.graphicsObjects.surfaceFeatureMeshes = {}
	
	local surfaceFeatureBaseColourShaders = {}
	surfaceFeatureBaseColourShaders.streak = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/streak.glsl")
	)
	surfaceFeatureBaseColourShaders.patch = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/patch.glsl")
	)
	self.graphicsObjects.surfaceFeatureBaseColourShaders = surfaceFeatureBaseColourShaders

	local surfaceFeatureHeightmapShaders = {}
	surfaceFeatureHeightmapShaders.crater = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/planetTexturing/craterHeightmap.glsl")
	)
	self.graphicsObjects.surfaceFeatureHeightmapShaders = surfaceFeatureHeightmapShaders
end

function starSystemGeneration:newWorld()
	generateSystem(nil, nil, 0, nil, self:getWorld().state, self.graphicsObjects)
end

return starSystemGeneration
