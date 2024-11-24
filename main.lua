package.loaded.systems = {}
package.loaded.assemblages = {}
local util = require("util")
util.load()

local concord = require("lib.concord")

local systems = require("systems")
local assemblages = require("assemblages")
concord.utils.loadNamespace("components")
concord.utils.loadNamespace("systems", systems)
concord.utils.loadNamespace("assemblages", assemblages)

local assets = require("assets")
local consts = require("consts")
local settings = require("settings")

local state
local outputCanvas

local paused -- Updated and used in update and used in draw
local forceRedrawCanvas -- Reset after being read in draw. Used in case toggling fullscreen empties canvasses or whatever

local lastDt -- To allow draw to access dt

function love.load(args)
	util.remakeWindow()
	assets.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	outputCanvas = love.graphics.newCanvas(consts.canvasSystemWidth, consts.canvasSystemHeight)
	state = util.newState()
	state.ecs:emit("newWorld")
end

function love.update(dt)
	paused = false -- TODO: Figure it out from UIs etc
	if not paused then
		util.updateState(state, dt)
	end
	lastDt = dt
end

function love.draw()
	if not paused or forceRedrawCanvas then
		util.drawState(state, outputCanvas, lastDt)
	end
	forceRedrawCanvas = false

	local x, y =
		(love.graphics.getWidth() - consts.canvasSystemWidth * settings.graphics.canvasScale) / 2,
		(love.graphics.getHeight() - consts.canvasSystemHeight * settings.graphics.canvasScale) / 2
	love.graphics.draw(outputCanvas, x, y, 0, settings.graphics.canvasScale)

	love.graphics.print(  -- TEMP (as in, find a better way lol)
		"FPS: " .. love.timer.getFPS() .. "\n" ..
		(state.notEnoughCubemapTextureSlotsWarning and "Not enough celestial body cubemap texture slots, some bodies may render wrong" or "") .. "\n"
	)
end

function love.keypressed(key)
	if key == settings.controls.drawElements.toggleOrbitLines then
		settings.graphics.drawOrbitLines = not settings.graphics.drawOrbitLines
	elseif key == settings.controls.drawElements.toggleBodyReticles then
		settings.graphics.drawBodyReticles = not settings.graphics.drawBodyReticles
	elseif key == settings.controls.drawElements.toggleConstellations then
		settings.graphics.drawConstellations = not settings.graphics.drawConstellations
	end
end
