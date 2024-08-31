local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")

local highestNoiseType = 2

return function(body, seed, graphicsObjects, cubemapSideSize)
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
		love.graphics.draw(graphicsObjects.dummyTexture, 0, 0, 0, love.graphics.getCanvas():getDimensions())
	end
	local function sendSky(clipToSky)
		love.graphics.getShader():send("clipToSky", {mat4.components(clipToSky)})
	end

	local function drawSurfaceFeatures(worldToClip, clipToSky)
		local function drawFeature(feature, drawingToAlpha)
			if feature.type == "streak" then
				local shader = gfx.surfaceFeatureShaders.streak
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
				local shader = gfx.surfaceFeatureShaders.patch
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
				drawFeature(feature, false)
			end
		end
	end

	if body.celestialBody.type == "rocky" then
		return function(orientation)
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
			sendSky(clipToSky)
			love.graphics.setBlendMode("multiply", "premultiplied")
			drawDummy()

			-- Draw surface features
			love.graphics.setBlendMode("alpha")
			drawSurfaceFeatures(worldToClip, clipToSky)
		end
	else
		return function(orientation) end
	end
end
