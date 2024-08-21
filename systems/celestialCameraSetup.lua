local concord = require("lib.concord")

local assemblages = require("assemblages")

local celestialCameraSetup = concord.system()

function celestialCameraSetup:newWorld()
	local world = self:getWorld()
	local relativeBody = world.state.originBody.satellites.value[1] -- TEMP
	local camera = concord.entity():assemble(assemblages.celestialCamera, relativeBody)
	world:addEntity(camera)
	world.state.controlEntity = camera
end

return celestialCameraSetup
