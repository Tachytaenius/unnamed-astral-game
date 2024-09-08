local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local concord = require("lib.concord")

local util = require("util")
local consts = require("consts")
local settings = require("settings")

local celestialCameraControl = concord.system({
	bodies = {"celestialMotionState"}
})

local function calculateAbsolutePosition(cameraComponent)
	cameraComponent.absolutePosition = cameraComponent.relativeTo.celestialMotionState.position + cameraComponent.relativePosition
end

local function setRelativeBody(cameraComponent, body)
	cameraComponent.relativePosition = cameraComponent.absolutePosition - body.celestialMotionState.position
	cameraComponent.relativeTo = body
	-- calculateAbsolutePosition(cameraComponent)
end

function celestialCameraControl:update(dt)
	local controlEntity = self:getWorld().state.controlEntity
	if not controlEntity or not controlEntity.celestialCamera then
		return
	end
	local cameraComponent = controlEntity.celestialCamera

	if not cameraComponent.absolutePosition then
		calculateAbsolutePosition(cameraComponent)
	end

	if love.keyboard.isDown(settings.controls.celestialCamera.setRelativeBody) then
		local lowestScoreBody
		local lowestScore = math.huge
		local cameraForwards = vec3.rotate(consts.forwardVector, cameraComponent.orientation)
		for _, body in ipairs(self.bodies) do
			local score = 1 - math.max(0, vec3.dot(cameraForwards, vec3.normalise(body.celestialMotionState.position - cameraComponent.absolutePosition)))
			if score < 0.1 then
				if score < lowestScore then
					lowestScore = score
					lowestScoreBody = body
				end
			end
		end
		if lowestScoreBody then
			setRelativeBody(cameraComponent, lowestScoreBody)
		end
	end

	local lowestDistance, closestBody
	for _, body in ipairs(self.bodies) do
		local distance = vec3.distance(cameraComponent.absolutePosition, body.celestialMotionState.position)
		if not lowestDistance or distance < lowestDistance then
			lowestDistance = distance
			closestBody = body
		end
	end
	assert(lowestDistance, "Celestial camera doesn't work without any bodies")
	local speed = cameraComponent.speedPerDistance * lowestDistance

	local translation = vec3()
	if love.keyboard.isDown(settings.controls.celestialCamera.moveRight) then
		translation = translation + consts.rightVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.moveLeft) then
		translation = translation - consts.rightVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.moveUp) then
		translation = translation + consts.upVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.moveDown) then
		translation = translation - consts.upVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.moveForwards) then
		translation = translation + consts.forwardVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.moveBackwards) then
		translation = translation - consts.forwardVector
	end
	local relativeVelocity = util.normaliseOrZero(translation) * speed
	local velocity = vec3.rotate(relativeVelocity, cameraComponent.orientation)
	cameraComponent.relativePosition = cameraComponent.relativePosition + velocity * dt
	-- Collision
	local relativePositionLength = vec3.length(cameraComponent.relativePosition)
	local minimumDistance = closestBody.celestialRadius.value * 1.1
	if 0 < relativePositionLength and relativePositionLength < minimumDistance then
		cameraComponent.relativePosition = cameraComponent.relativePosition / relativePositionLength * minimumDistance
	end

	local rotation = vec3()
	if love.keyboard.isDown(settings.controls.celestialCamera.pitchDown) then
		rotation = rotation + consts.rightVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.pitchUp) then
		rotation = rotation - consts.rightVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.yawRight) then
		rotation = rotation + consts.upVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.yawLeft) then
		rotation = rotation - consts.upVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.rollAnticlockwise) then
		rotation = rotation + consts.forwardVector
	end
	if love.keyboard.isDown(settings.controls.celestialCamera.rollClockwise) then
		rotation = rotation - consts.forwardVector
	end
	local rotationQuat = quat.fromAxisAngle(util.limitVectorLength(rotation, 1 * cameraComponent.angularSpeed * dt))
	cameraComponent.orientation = quat.normalise(cameraComponent.orientation * rotationQuat) -- Normalise to prevent numeric drift

	calculateAbsolutePosition(cameraComponent)
end

return celestialCameraControl
