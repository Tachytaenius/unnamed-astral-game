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
	self.lightCanvas = love.graphics.newCanvas(consts.canvasSystemWidth, consts.canvasSystemHeight, {format = "rgba16f"})
	self.positionCanvas = love.graphics.newCanvas(consts.canvasSystemWidth, consts.canvasSystemHeight, {format = "rgba32f"})
	self.depthBuffer = love.graphics.newCanvas(consts.canvasSystemWidth, consts.canvasSystemHeight, {format = "depth32f"})

	self.dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))

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
		love.filesystem.read("shaders/atmosphere.glsl")
	)

	self.orbitLineMesh = util.generateCircleMesh(1024)
	self.bodyMesh = assets.misc.meshes.icosphereSmooth
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
