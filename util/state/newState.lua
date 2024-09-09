local vec3 = require("lib.mathsies").vec3
local concord = require("lib.concord")

local systems = require("systems")

return function()
	local state = {}
	state.time = 0
	state.originBodyPosition = vec3()

	state.ecs = concord.world()
	state.ecs.state = state -- Allow systems to access whole state with self:getWorld().state
	state.ecs -- Make sure we don't get swamped in a system ordering nightmare because of systems that pick up on multiple events
		-- newWorld systems
		:addSystem(systems.starSystemGeneration)
		:addSystem(systems.celestialCameraSetup) -- Sets state.controlEntity on newWorld

		-- update systems
		-- "Pre-update" stage
		:addSystem(systems.celestialMotion)
		:addSystem(systems.celestialCameraControl) -- Needs to be separate from setup due to ordering
		-- "Post-update" (pre-draw?) stage
		:addSystem(systems.cubemapTextureSlots)

		-- draw systems
		:addSystem(systems.rendering)

	return state
end
