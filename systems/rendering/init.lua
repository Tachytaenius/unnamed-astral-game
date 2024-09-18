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
		love.filesystem.read("shaders/body.glsl")
	)
	self.lineShader = love.graphics.newShader("shaders/line.glsl")
	self.tonemappingShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/tonemapping.glsl")
	)
	self.atmosphereShader = love.graphics.newShader(
		lightsShaderCode ..
		"#define FLIP_Y 1\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/atmosphere.glsl")
	)
	self.storeLuminanceShader = love.graphics.newShader("shaders/storeLuminance.glsl")
	self.maxValueShader = love.graphics.newShader("shaders/maxValue.glsl")
	self.averageValueShader = love.graphics.newShader("shaders/averageValue.glsl")
	self.skyboxShader = love.graphics.newShader(
		"#define FLIP_Y 1\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/skybox.glsl")
	)

	-- Meshes
	self.orbitLineMesh = util.generateCircleMesh(1024) -- TEMP: Not enough for distant orbits
	self.bodyMesh = assets.misc.meshes.icosphereSmooth

	-- Misc
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
	self.skybox = love.graphics.newCanvas(consts.skyboxCubemapSideLength, consts.skyboxCubemapSideLength, {type = "cube", format = "rgba16f", linear = true})
	util.drawGalaxyToSkybox(self.skybox, self:getWorld().state.galaxyOtherStars, self:getWorld().state.originPositionInGalaxy)
end

function rendering:draw(outputCanvas)
	local state = self:getWorld().state
	if state.controlEntity then
		if state.controlEntity.celestialCamera then
			self:renderCelestialCamera(outputCanvas, state.controlEntity)
		-- elseif state.controlEntity.player, etc
		end
	end
end

return rendering
