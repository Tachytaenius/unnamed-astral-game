local concord = require("lib.concord")

local systems = require("systems")

local consts = require("consts")
local util = require("util")

local cubemapTextureSlots = concord.system({
	bodies = {"celestialBody"},
	textureSlotEntities = {"bodyCubemapTextureSlot"}
})

function cubemapTextureSlots:init()
	local world = self:getWorld()
	for _=1, consts.bodyCubemapTextureSlotCount do
		world:addEntity(concord.entity():give("bodyCubemapTextureSlot"))
	end
end

function cubemapTextureSlots:update()
	self:getWorld().state.notEnoughCubemapTextureSlotsWarning = false -- Possibly set in this function

	local controlEntity = self:getWorld().state.controlEntity
	if not controlEntity or not controlEntity.celestialCamera then
		return
	end
	local cameraComponent = controlEntity.celestialCamera

	-- Release bodies too distant to hold their slot
	for _, body in ipairs(self.bodies) do
		if
			body.bodyTextureCubemapSlotClaim and
			not util.isBodyResolvable(body, cameraComponent, consts.bodyTextureCubemapSlotClaimFudgeFactor) -- Fudge factor being > 1 makes it be considered resolvable from further away
		then
			body.bodyTextureCubemapSlotClaim.slotEntity.bodyCubemapTextureSlot.claimed = false
			body:remove("bodyTextureCubemapSlotClaim")
		end
	end

	-- Allow bodies which are close enough to claim to get a slot
	for _, body in ipairs(self.bodies) do
		if
			not body.bodyTextureCubemapSlotClaim and
			util.isBodyResolvable(body, cameraComponent, consts.bodyTextureCubemapSlotClaimFudgeFactor)
		then
			-- Attempt to make a claim
			local textureSlotEntity
			for _, entity in ipairs(self.textureSlotEntities) do
				if not entity.bodyCubemapTextureSlot.claimed then
					textureSlotEntity = entity
					break
				end
			end
			if not textureSlotEntity then
				self:getWorld().state.notEnoughCubemapTextureSlotsWarning = true
				break -- No spaces left, no point trying
			else
				body:give("bodyTextureCubemapSlotClaim", textureSlotEntity)

				-- Claim made, now create textures (unless nothing else used the slot in the meantime)
				local slotComponent = textureSlotEntity.bodyCubemapTextureSlot
				if slotComponent.lastClaim ~= body then
					slotComponent.lastClaim = body
					slotComponent.claimed = true

					local seed = body.textureCubemapsSeed.value
					local graphicsObjects = self:getWorld():getSystem(systems.starSystemGeneration).graphicsObjects -- TODO: Move to this system
					local baseColourDrawFunction, heightmapDrawFunction = util.getPlanetTextureCubemapDrawFunctions(body, seed, graphicsObjects)
					util.drawToPlanetTextureCubemaps(slotComponent, baseColourDrawFunction, heightmapDrawFunction)
				end -- Else assume the body's texture is still there
			end
		end
	end

	-- local total = 0
	-- for _, entity in ipairs(self.textureSlotEntities) do
	-- 	if entity.bodyCubemapTextureSlot.claimed then
	-- 		total = total + 1
	-- 	end
	-- end
	-- print("Claimed cubemap tetxure slots: " .. total)
end

return cubemapTextureSlots
