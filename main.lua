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
end

function love.draw()
	if not paused or forceRedrawCanvas then
		util.drawState(state, outputCanvas)
	end
	forceRedrawCanvas = false

	local x, y =
		(love.graphics.getWidth() - consts.canvasSystemWidth * settings.graphics.canvasScale) / 2,
		(love.graphics.getHeight() - consts.canvasSystemHeight * settings.graphics.canvasScale) / 2
	love.graphics.draw(outputCanvas, x, y, 0, settings.graphics.canvasScale)

	love.graphics.print(love.timer.getFPS()) -- TEMP
end
