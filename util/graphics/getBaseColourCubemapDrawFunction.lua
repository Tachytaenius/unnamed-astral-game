local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")

local highestNoiseType = 2

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

	local function drawDummy()
		love.graphics.draw(graphicsObjects.dummyTexture, 0, 0, 0, love.graphics.getCanvas():getDimensions())
	end
	local function sendSky(clipToSky)
		love.graphics.getShader():send("clipToSky", {mat4.components(clipToSky)})
	end

	local surfaceFeatureModels = {}
	for _, feature in ipairs(body.celestialBodySurface.features) do
		local model = {}
		model.feature = feature
		model.mesh = gfx.surfaceFeatureMeshes[feature.type] -- If nil, it's drawn using screen direction
		model.shader = gfx.surfaceFeatureShaders[feature.type]
		if feature.type == "ravine" then
			function model:graphicsSetup()
				-- model.shader:send("ravineWidth", feature.width)
				-- model.shader:send(TODO) -- Depth should be encoded by colour or something
				model.shader:send("ravineStart", {vec3.components(feature.startPoint)})
				-- model.shader:send("ravineRotation", feature.rotationToEnd)
			end
		end
		surfaceFeatureModels[#surfaceFeatureModels + 1] = model
	end

	local function drawSurfaceFeatures(worldToClip, clipToSky)
		for _, model in ipairs(surfaceFeatureModels) do
			love.graphics.setShader(model.shader)
			if model.shader:hasUniform("modelToClip") then
				local modelToClip = worldToClip * model.modelToWorld
				model.shader:send("modelToClip", {mat4.components(modelToClip)})
			end
			if model.shader:hasUniform("clipToSky") then
				model.shader:send("clipToSky", {mat4.components(clipToSky)})
			end
			love.graphics.push("all")
			if model.graphicsSetup then
				model:graphicsSetup()
			end
			love.graphics.pop()
			if model.mesh then
				love.graphics.draw(model.mesh)
			else
				drawDummy()
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
