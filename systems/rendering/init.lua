local concord = require("lib.concord")

local consts = require("consts")
local util = require("util")
local assets = require("assets")

local rendering = concord.system({
	bodies = {"celestialBody"},
	bodiesWithAtmospheres = {"celestialBody", "atmosphere"},
	stars = {"celestialBody", "starData"},
	ringSystems = {"ringSystem"}
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
	self.lightCanvas = love.graphics.newCanvas(w, h, {format = "rgba32f", linear = true})
	self.positionCanvas = love.graphics.newCanvas(w, h, {format = "rgba32f", linear = true})
	self.depthBuffer = love.graphics.newCanvas(w, h, {format = "depth32f"})
	self.HUDCanvas = love.graphics.newCanvas(w, h)

	-- Images
	self.dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))

	-- Shaders
	local lightsShaderCode =
		"#line 1\n" ..
		"const int maxLights = " .. consts.maxLightsCelestial .. ";\n" ..
		"const int maxSpheres = " .. consts.maxShadowSpheresCelestial .. ";\n" ..
		"const int maxRings = " .. consts.maxShadowRingsCelestial .. ";\n" ..
		love.filesystem.read("shaders/include/lights.glsl")
	self.bodyShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		lightsShaderCode ..
		love.filesystem.read("shaders/include/lib/simplex4d.glsl") ..
		love.filesystem.read("shaders/include/colourSpaceConversion.glsl") ..
		love.filesystem.read("shaders/include/lib/random.glsl") ..
		love.filesystem.read("shaders/include/lib/dist.glsl") ..
		love.filesystem.read("shaders/include/lib/worley.glsl") ..
		love.filesystem.read("shaders/body.glsl")
	)
	self.ringShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		lightsShaderCode ..
		love.filesystem.read("shaders/ring.glsl")
	)
	self.lineShader = love.graphics.newShader("shaders/line.glsl")
	self.atmosphereShader = love.graphics.newShader(
		love.filesystem.read("shaders/include/lib/simplex3d.glsl") ..
		lightsShaderCode ..
		"#define FLIP_Y\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/atmosphere.glsl")
	)
	self.skyboxShader = love.graphics.newShader(
		"#define FLIP_Y\n" .. love.filesystem.read("shaders/include/skyDirection.glsl") ..
		love.filesystem.read("shaders/skybox.glsl")
	)
	self.blurredPointShader = love.graphics.newShader("shaders/blurredPoint.glsl")

	-- Meshes
	self.orbitLineMesh = util.generateCircleMesh(1024) -- TEMP: Not enough for distant orbits
	self.bodyMesh = assets.misc.meshes.icosphereSmooth
	self.ringMesh = assets.misc.meshes.plane
	self.lineMesh = love.graphics.newMesh(consts.lineVertexFormat, {
		{0, 0, 0, 1, 1, 1},
		{0, 0, 0, 1, 1, 1},
		{1, 1, 1, 1, 1, 1}
	}, "triangles")
	self.diskMesh = util.generateDiskMesh(consts.blurredPointDiskMeshVertices)

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
			self:renderCelestialCamera(outputCanvas, state.controlEntity)
		-- elseif state.controlEntity.player, etc
		end
	end
end

return rendering
