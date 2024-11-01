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

	-- Used to calculate min and max heightmap values
	self.heightmapMinMaxScratch = love.graphics.newCanvas(consts.bodyTextureCubemapSideLength, consts.bodyTextureCubemapSideLength, {format = consts.bodyHeightmapFormat, mipmaps = "manual", linear = true})
	self.heightmapMinMaxScratchViews = {}
	for i = 1, self.heightmapMinMaxScratch:getMipmapCount() do
		self.heightmapMinMaxScratchViews[i] = love.graphics.newTextureView(self.heightmapMinMaxScratch, {
			mipmapstart = i,
			mipmapcount = 1,
			debugname = "Heightmap min/max scratch texture view " .. i
		})
	end
	self.minValueShader = love.graphics.newShader("shaders/minMaxValue.glsl", {defines = {FUNCTION_NAME = "min"}})
	self.maxValueShader = love.graphics.newShader("shaders/minMaxValue.glsl", {defines = {FUNCTION_NAME = "max"}})
	self.dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))
end

function cubemapTextureSlots:storeMinMaxHeightmapValue(slotComponent)
	local function getMinMax(shader, darkenOrLighten, x)
		-- Draw faces to scratch
		love.graphics.setCanvas(self.heightmapMinMaxScratch)
		for i = 1, 6 do
			love.graphics.setBlendMode(i == 1 and "replace" or darkenOrLighten, "premultiplied")
			love.graphics.drawLayer(slotComponent.heightView, i)
		end
		-- Shrink the darken/lighten-combined faces using the min/max shader down the mipmap chain to 1x1
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader(shader)
		for i = 2, self.heightmapMinMaxScratch:getMipmapCount() do
			love.graphics.setCanvas(self.heightmapMinMaxScratchViews[i])
			shader:send("valueCanvas", self.heightmapMinMaxScratchViews[i - 1])
			shader:send("halfTexelSize", {
				0.5 / self.heightmapMinMaxScratch:getWidth(i - 1),
				0.5 / self.heightmapMinMaxScratch:getHeight(i - 1)
			})
			love.graphics.draw(self.dummyTexture, 0, 0, 0, self.heightmapMinMaxScratch:getDimensions(i))
		end
		-- Draw the 1x1 mipmap to the final storage texture
		love.graphics.setCanvas(slotComponent.heightMinMax)
		love.graphics.setShader()
		love.graphics.draw(self.heightmapMinMaxScratchViews[#self.heightmapMinMaxScratchViews], x, 0)
		love.graphics.setCanvas()
	end

	getMinMax(self.minValueShader, "darken", 0)
	getMinMax(self.maxValueShader, "lighten", 1)

	-- Slow debug stuff
	-- local data = slotComponent.heightMinMax:newImageData()
	-- local min, max = data:getPixel(0, 0), data:getPixel(1, 0)
	-- print("Data:", min, max)
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
					util.drawToPlanetTextureCubemaps(slotComponent, body, baseColourDrawFunction, heightmapDrawFunction)
					self:storeMinMaxHeightmapValue(slotComponent)
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
