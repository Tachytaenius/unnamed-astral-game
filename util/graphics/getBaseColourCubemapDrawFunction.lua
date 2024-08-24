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
	if body.celestialBody.type == "rocky" then
		return function(orientation)
			randomGenerator:setState(randomStartState)
			local function drawDummy()
				love.graphics.draw(graphicsObjects.dummyTexture, 0, 0, 0, love.graphics.getCanvas():getDimensions())
			end
			local gfx = graphicsObjects
			local worldToCameraStationary = mat4.camera(vec3(), orientation)
			local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)
			local function sendSky()
				love.graphics.getShader():send("clipToSky", {mat4.components(clipToSky)})
			end

			-- All graphics changes get popped

			-- Get base colour
			love.graphics.setShader(gfx.baseShader)
			gfx.baseShader:send("colourMixNoiseFrequency", 1.0)
			gfx.baseShader:sendColor("primaryColour", {0.75, 0.5, 0.3})
			gfx.baseShader:sendColor("secondaryColour", {0.8, 0.2, 0})
			sendSky()
			love.graphics.setBlendMode("alpha")
			drawDummy()

			-- Apply noise
			local noiseShader = gfx.noiseShader -- Was going to have a shader per type
			love.graphics.setShader(noiseShader)
			noiseShader:send("noiseFrequency", 4)
			noiseShader:send("noiseEffect", 0.5)
			noiseShader:send("noiseType", randomGenerator:random(0, highestNoiseType))
			sendSky()
			love.graphics.setBlendMode("multiply", "premultiplied")
			drawDummy()
		end
	else
		return function(orientation) end
	end
end
