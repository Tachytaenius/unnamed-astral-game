local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")

local cubemapSideSize = consts.bodyTextureCubemapSideLength

local highestNoiseType = 2
local highestFractalNoiseType = 3

return function(body, seed, graphicsObjects)
	local randomGenerator = love.math.newRandomGenerator(seed)
	local randomStartState = randomGenerator:getState() -- Must have state reset at start of drawFunction to ensure random values don't vary across cubemap faces
	local cameraToClip = mat4.perspectiveLeftHanded(
		1,
		consts.tau * 0.25,
		body.celestialRadius.value * 1.5, -- 1.5,
		body.celestialRadius.value * 0.5 -- 0.5
	)
	local gfx = graphicsObjects
	local setAlphaCanvas = love.graphics.newCanvas(cubemapSideSize, cubemapSideSize, {format = "r8", linear = true})

	local function drawDummy()
		local w, h
		local canvas = love.graphics.getCanvas()
		if canvas.getDimensions then
			w, h = canvas:getDimensions()
		else
			-- Cubemap
			w, h = canvas[1][1]:getDimensions()
		end
		love.graphics.draw(graphicsObjects.dummyTexture, 0, 0, 0, w, h)
	end
	local function sendSky(clipToSky)
		love.graphics.getShader():send("clipToSky", {mat4.components(clipToSky)})
	end

	local function drawSurfaceFeaturesBaseColour(worldToClip, clipToSky)
		local function drawFeature(feature, drawingToAlpha)
			if feature.type == "streak" then
				local shader = gfx.surfaceFeatureBaseColourShaders.streak
				love.graphics.setShader(shader)
				shader:send("angularWidth", feature.angularWidth)
				shader:send("startPoint", {vec3.components(feature.startPoint)})
				shader:send("endPoint", {vec3.components(feature.endPoint)})
				shader:send("alphaMultiplier", feature.alphaMultiplier)
				shader:send("edgeFadeAngularLength", feature.edgeFadeAngularLength)
				shader:send("outputAlpha", drawingToAlpha)
				shader:send("clipToSky", {mat4.components(clipToSky)})
				drawDummy()
			elseif feature.type == "patch" then
				local shader = gfx.surfaceFeatureBaseColourShaders.patch
				love.graphics.setShader(shader)
				shader:send("location", {vec3.components(feature.location)})
				shader:send("angularRadius", feature.angularRadius)
				shader:send("noisiness", feature.noisiness)
				shader:send("alphaMultiplier", feature.alphaMultiplier)
				shader:send("edgeFadeAngularLength", feature.edgeFadeAngularLength)
				shader:send("outputAlpha", drawingToAlpha)
				shader:send("clipToSky", {mat4.components(clipToSky)})
				drawDummy()
			end
		end

		for _, feature in ipairs(body.celestialBodySurface.features) do
			if feature.isSet then
				if feature.drawToOwnAlphaCanvas then
					love.graphics.push("all")
					love.graphics.setCanvas(setAlphaCanvas)
					love.graphics.clear()
					love.graphics.setBlendMode("lighten", "premultiplied")
					for _, subFeature in ipairs(feature) do
						drawFeature(subFeature, true)
					end
					love.graphics.pop()

					love.graphics.setShader(gfx.featureSetShader)
					-- gfx.featureSetShader:send("clipToSky", {mat4.components(clipToSky)})
					love.graphics.setColor(feature.baseColour)
					love.graphics.draw(setAlphaCanvas)
					love.graphics.setColor(1, 1, 1)
				else
					for _, subFeature in ipairs(feature) do
						drawFeature(subFeature, false)
					end
				end
			else
				drawFeature(feature, false)
			end
		end
	end

	local function drawSurfaceFeaturesHeight(worldToClip, clipToSky)
		local function drawFeature(feature)
			if feature.type == "crater" then
				local shader = gfx.surfaceFeatureHeightmapShaders.crater
				love.graphics.setShader(shader)
				shader:send("clipToSky", {mat4.components(clipToSky)})
				shader:send("featureDirection", {vec3.components(feature.direction)})
				shader:send("angularRadius", feature.angularRadius)
				shader:send("depth", feature.depth)
				shader:send("power", feature.power)
				shader:send("centreAngularRadius", feature.centreAngularRadius)
				shader:send("centreHeight", feature.centreHeight)
				shader:send("centrePower", feature.centrePower)
				shader:send("wallWidthRampUp", feature.wallWidthRampUp)
				shader:send("wallWidthRampDown", feature.wallWidthRampDown)
				shader:send("wallPeakHeight", feature.wallPeakHeight)
				shader:send("heightMultiplierNoiseFrequency", feature.heightMultiplierNoiseFrequency)
				shader:send("heightMultiplierNoiseAmplitude", feature.heightMultiplierNoiseAmplitude)
				drawDummy()
			elseif feature.type == "mountain" then
				local shader = gfx.surfaceFeatureHeightmapShaders.mountain
				love.graphics.setShader(shader)
				shader:send("clipToSky", {mat4.components(clipToSky)})
				shader:send("featureDirection", {vec3.components(feature.direction)})
				shader:send("angularRadius", feature.angularRadius)
				shader:send("height", feature.height)
				shader:send("radiusWarpIterations", feature.radiusWarpIterations)
				shader:send("radiusWarpBase", feature.radiusWarpBase)
				shader:send("radiusWarpPower", feature.radiusWarpPower)
				shader:send("radiusWarpLerp", feature.radiusWarpLerp)
				shader:send("radiusWarpFlowerHarshness", feature.radiusWarpFlowerHarshness)
				shader:send("directionWarpDirection", {vec3.components(feature.directionWarpDirection)})
				shader:send("directionWarpMagnitude", feature.directionWarpMagnitude)
				drawDummy()
			end
		end

		for _, feature in ipairs(body.celestialBodySurface.features) do
			if feature.isSet then
				for _, subFeature in ipairs(feature) do
					drawFeature(subFeature)
				end
			else
				drawFeature(feature)
			end
		end
	end

	if body.celestialBody.type == "rocky" then
		local function baseColour(orientation)
			randomGenerator:setState(randomStartState)
			local worldToCamera = mat4.camera(vec3(), orientation) -- No camera position in the first place
			local worldToClip = cameraToClip * worldToCamera
			local clipToSky = mat4.inverse(worldToClip)

			-- All graphics changes get popped

			-- Get base colour
			love.graphics.setShader(gfx.baseShader)
			gfx.baseShader:send("colourMixNoiseFrequency", 1.0)
			gfx.baseShader:sendColor("primaryColour", body.celestialBodySurface.colours[1])
			gfx.baseShader:sendColor("secondaryColour", body.celestialBodySurface.colours[2])
			sendSky(clipToSky)
			love.graphics.setBlendMode("alpha")
			drawDummy()

			-- Apply noise
			local noiseShader = gfx.noiseShader -- Was going to have a shader per type
			love.graphics.setShader(noiseShader)
			noiseShader:send("noiseFrequency", 4)
			noiseShader:send("noiseEffect", 0.5)
			noiseShader:send("noiseType", randomGenerator:random(0, highestNoiseType))
			noiseShader:send("fractalNoiseType", randomGenerator:random(0, highestFractalNoiseType))
			noiseShader:send("normalFractalNoiseMix", randomGenerator:random() * 0.5 + 0.25)
			sendSky(clipToSky)
			love.graphics.setBlendMode("multiply", "premultiplied")
			drawDummy()

			-- Draw surface features
			love.graphics.setBlendMode("alpha")
			drawSurfaceFeaturesBaseColour(worldToClip, clipToSky)
		end

		local function heightmap(orientation)
			randomGenerator:setState(randomStartState)
			local worldToCamera = mat4.camera(vec3(), orientation)
			local worldToClip = cameraToClip * worldToCamera
			local clipToSky = mat4.inverse(worldToClip)

			local baseShader = gfx.heightmapBaseShader
			love.graphics.setShader(baseShader)
			love.graphics.setBlendMode("add") -- Popped

			local bumps = randomGenerator:random() < 0.8
			local valleys = randomGenerator:random() < 0.3
			if not (bumps or valleys) then
				bumps = true
			end
			baseShader:send("bumps", bumps)
			local radius = body.celestialRadius.value
			baseShader:send("bumpHeight", radius * (randomGenerator:random() * 0.005 + 0.001))
			baseShader:send("bumpFrequency", randomGenerator:random() * 20 + 2) -- Based on direction, doesn't care about body size
			baseShader:send("valleys", valleys)
			baseShader:send("valleyDepth", radius * (randomGenerator:random() * 0.001 + 0.001))
			baseShader:send("valleyDensity", randomGenerator:random() * 40 + 5)
			baseShader:send("valleyWidth", randomGenerator:random() * 0.02 + 0.02) -- Also doesn't need to care about body size
			baseShader:send("seed", seed)

			sendSky(clipToSky)
			drawDummy()

			love.graphics.setBlendMode("add")
			drawSurfaceFeaturesHeight(worldToClip, clipToSky)
		end

		return baseColour, heightmap
	elseif body.celestialBody.type == "gaseous" then
		local function baseColour(orientation)
			randomGenerator:setState(randomStartState)
			local worldToCamera = mat4.camera(vec3(), orientation) -- No camera position in the first place
			local worldToClip = cameraToClip * worldToCamera
			local clipToSky = mat4.inverse(worldToClip)

			love.graphics.setShader(gfx.gaseousBaseShader)
			local colourCount = #body.celestialBodySurface.colours
			gfx.gaseousBaseShader:send("rotationAxis", {vec3.components(body.celestialRotation.rotationAxis)})
			gfx.gaseousBaseShader:send("blendSize", (randomGenerator:random() * 0.05 + 0.2) / colourCount)
			gfx.gaseousBaseShader:send("noiseAmplitude", randomGenerator:random() * 0.125)
			gfx.gaseousBaseShader:send("noiseFrequency", randomGenerator:random() * 2.5 + 1)
			gfx.gaseousBaseShader:send("colourStepCount", colourCount)
			for i, step in ipairs(body.celestialBodySurface.colours) do
				gfx.gaseousBaseShader:send("colourSteps[" .. i - 1 .. "].colour", step.colour)
				gfx.gaseousBaseShader:send("colourSteps[" .. i - 1 .. "].start", step.start)
			end
			-- gfx.gaseousBaseShader:send("colourSteps", unpack(body.celestialBodySurface.colours))
			sendSky(clipToSky)
			drawDummy()
		end

		local function heightmap(orientation)

		end

		return baseColour, heightmap
	else
		local function baseColour(orientation)

		end

		local function heightmap(orientation)

		end

		return baseColour, heightmap
	end
end
