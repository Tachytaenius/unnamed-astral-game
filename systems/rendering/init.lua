local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")
local assets = require("assets")

local rendering = concord.system({
	bodies = {"celestialBody"},
	bodiesWithAtmospheres = {"celestialBody", "atmosphere"},
	stars = {"celestialBody", "starData"}
})

for _, moduleName in ipairs({
	"celestial"
}) do
	for k, v in pairs(require("systems.rendering." .. moduleName)) do
		rendering[k] = v
	end
end

function rendering:init()
	-- Canvasses
	local w, h = consts.canvasSystemWidth, consts.canvasSystemHeight
	local wNextPowerOf2, hNextPowerOf2 -- Used so that sampling a 2x2 square of texels to downscale is fine
	local n = 0
	repeat
		wNextPowerOf2 = 2 ^ n
		n = n + 1
	until wNextPowerOf2 >= w
	local n = 0
	repeat
		hNextPowerOf2 = 2 ^ n
		n = n + 1
	until hNextPowerOf2 >= h
	local highest = math.max(wNextPowerOf2, hNextPowerOf2)
	wNextPowerOf2, hNextPowerOf2 = highest, highest
	self.lightCanvas = love.graphics.newCanvas(w, h, {format = "rgba32f", linear = true})
	self.atmosphereLightCanvas = love.graphics.newCanvas(w, h, {format = "rgba32f", linear = true}) -- Separated and rejoined during tonemapping because of absolute colours being mixed into the light canvas
	self.maxLuminanceCanvas = love.graphics.newCanvas(wNextPowerOf2, hNextPowerOf2, {format = "r32f", mipmaps = "manual", linear = true})
	self.averageLuminanceCanvas = love.graphics.newCanvas(wNextPowerOf2, hNextPowerOf2, {format = "r32f", mipmaps = "manual", linear = true})
	self.eyeAdaptationCanvasA = love.graphics.newCanvas(2, 1, {format = "r32f", linear = true})
	self.eyeAdaptationCanvasA:setFilter("nearest") -- It's meant to carry two separate variables. Blurring would not be good!
	self.eyeAdaptationCanvasB = love.graphics.newCanvas(2, 1, {format = "r32f", linear = true}) -- There are two, they are swapped between to be able to do maths on source and destination values when drawing to it
	self.eyeAdaptationCanvasB:setFilter("nearest")
	self.positionCanvas = love.graphics.newCanvas(w, h, {format = "rgba32f", linear = true})
	self.depthBuffer = love.graphics.newCanvas(w, h, {format = "depth32f"})
	self.HUDCanvas = love.graphics.newCanvas(w, h)

	-- Texture views
	self.maxLuminanceCanvasViews = {}
	for i = 1, self.maxLuminanceCanvas:getMipmapCount() do
		self.maxLuminanceCanvasViews[i] = love.graphics.newTextureView(self.maxLuminanceCanvas, {
			mipmapstart = i,
			mipmapcount = 1,
			debugname = "Max luminance canvas texture view " .. i
		})
	end
	self.averageLuminanceCanvasViews = {}
	for i = 1, self.averageLuminanceCanvas:getMipmapCount() do
		self.averageLuminanceCanvasViews[i] = love.graphics.newTextureView(self.averageLuminanceCanvas, {
			mipmapstart = i,
			mipmapcount = 1,
			debugname = "Average luminance canvas texture view " .. i
		})
	end

	-- Images
	self.dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))

	-- Shaders
	local lightsShaderCode =
		"#line 1\n" ..
		"const int maxLights = " .. consts.maxLightsCelestial .. ";\n" ..
		"const int maxSpheres = " .. consts.maxShadowSpheresCelestial .. ";\n" ..
		love.filesystem.read("shaders/include/lights.glsl")
	self.bodyShader = love.graphics.newShader(
		lightsShaderCode ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/lib/random.glsl") ..
		love.filesystem.read("shaders/include/lib/dist.glsl") ..
		love.filesystem.read("shaders/include/lib/worley.glsl") ..
		love.filesystem.read("shaders/include/lib/simplex4d.glsl") ..
		love.filesystem.read("shaders/body.glsl")
	)
	self.lineShader = love.graphics.newShader("shaders/line.glsl")
	self.tonemappingShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/tonemapping.glsl")
	)
	self.atmosphereShader = love.graphics.newShader(
		lightsShaderCode ..
		"#define FLIP_Y\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/atmosphere.glsl")
	)
	self.storeLuminanceShader = love.graphics.newShader("shaders/storeLuminance.glsl")
	self.logLuminanceShader = love.graphics.newShader("shaders/logLuminance.glsl")
	self.maxValueShader = love.graphics.newShader("shaders/maxValue.glsl")
	self.averageValueShader = love.graphics.newShader("shaders/averageValue.glsl")
	self.skyboxShader = love.graphics.newShader(
		"#define FLIP_Y\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/skybox.glsl")
	)
	self.eyeAdaptationShader = love.graphics.newShader("shaders/eyeAdaptation.glsl")

	-- Meshes
	self.orbitLineMesh = util.generateCircleMesh(1024) -- TEMP: Not enough for distant orbits
	self.bodyMesh = assets.misc.meshes.icosphereSmooth

	-- Misc
	self.eyeAdaptationUninitialised = true
	self.missingTextureSlot = concord.entity():give("bodyCubemapTextureSlot").bodyCubemapTextureSlot -- HACK: Entity is discarded (not added to world), component is kept
	util.drawToPlanetTextureCubemaps(self.missingTextureSlot,
		function(orientation) -- Base colour
			local w, h = love.graphics.getCanvas()[1][1]:getDimensions() -- Cubemap
			love.graphics.clear(consts.missingTextureColourA)
			love.graphics.setColor(consts.missingTextureColourB)
			local subdivisions = consts.missingTextureSubdivisions
			for x = 0, subdivisions - 1 do
				for y = 0, subdivisions - 1 do
					if (x + y) % 2 == 0 then
						love.graphics.rectangle("fill", x * w / subdivisions, y * h / subdivisions, w / subdivisions, h / subdivisions)
					end
				end
			end
		end,
		function(orientation) -- Heightmap
			-- Cleared to 0 already
		end
	)
	self.skybox = love.graphics.newCanvas(consts.skyboxCubemapSideLength, consts.skyboxCubemapSideLength, {type = "cube", format = "rgba32f", linear = true})
	util.drawGalaxyToSkybox(self.skybox, self:getWorld().state.galaxy)
	for i = 1, 2 do
		local name = "coronaReductionTexture" .. i
		self[name] = love.graphics.newCanvas(consts.coronaReductionTextureSideLength, consts.coronaReductionTextureSideLength, {type = "cube", format = "r8", linear = true})
		util.drawCoronaReductionTexture(self[name], i)
		self[name]:setFilter("linear")
	end
end

function rendering:draw(outputCanvas, dt)
	local state = self:getWorld().state
	if state.controlEntity then
		if state.controlEntity.celestialCamera then
			self:renderCelestialCamera(outputCanvas, dt, state.controlEntity)
		-- elseif state.controlEntity.player, etc
		end
	end
end

return rendering
