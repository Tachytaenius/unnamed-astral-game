local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")
local settings = require("settings")
local util = require("util")

local celestial = {}

function celestial:renderCelestialCamera(outputCanvas, entity)
	local camera = entity.celestialCamera

	love.graphics.setMeshCullMode("none")

	-- Get matrices
	local worldToCamera = mat4.camera(camera.absolutePosition, camera.orientation)
	local cameraToClip = mat4.perspectiveLeftHanded(
		outputCanvas:getWidth() / outputCanvas:getHeight(),
		camera.verticalFOV,
		consts.celestialFarPlaneDistance,
		consts.celestialNearPlaneDistance
	)
	local worldToClip = cameraToClip * worldToCamera
	local worldToCameraStationary = mat4.camera(vec3(), camera.orientation)
	local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)

	-- Get and send lights
	local lights = self:getLights()
	self.bodyShader:send("maxBrightness", consts.maxLightBrightness)
	self:sendLights(self.bodyShader, lights)
	self.atmosphereShader:send("maxBrightness", consts.maxLightBrightness)
	self:sendLights(self.atmosphereShader, lights)

	-- Clear canvasses
	love.graphics.setCanvas({
		self.lightCanvas,
		self.positionCanvas,
		depthstencil = self.depthBuffer
	})
	love.graphics.clear({0, 0, 0, 1}, {0, 0, 0, 0}, false, true)

	-- TODO: Draw skybox to light canvas, no depth or position
	love.graphics.setDepthMode("always", false)
	-- Skybox shader, dummy texture, light canvas...

	-- Draw bodies to light canvas, with depth and position information
	love.graphics.setDepthMode("lequal", true)
	love.graphics.setShader(self.bodyShader)
	for _, body in ipairs(self.bodies) do
		local modelToWorld = mat4.transform(
			body.celestialMotionState.position,
			body.celestialOrientationState.value,
			body.celestialRadius.value
		)
		local modelToClip = worldToClip * modelToWorld

		self.bodyShader:send("modelToWorld", {mat4.components(modelToWorld)})
		self.bodyShader:send("modelToClip", {mat4.components(modelToClip)})
		self.bodyShader:send("modelToWorldNormal", {util.getNormalMatrix(modelToWorld)})
		local shadowSpheres = body.starData and {} or self:getShadowSpheres(body, true)
		self:sendShadowSpheres(self.bodyShader, shadowSpheres)

		love.graphics.draw(self.bodyMesh)
	end

	-- Draw orbit lines to light canvas, with depth and position information
	-- The idea is that they are like (illusory) glowing solids. Just superimposing them over atmosphere has an undesirable look
	if settings.graphics.drawOrbitLines then
		love.graphics.setShader(self.lineShader)
		love.graphics.setColor(consts.orbitLineColour)
		love.graphics.setMeshCullMode("none")
		love.graphics.setWireframe(true)
		for _, body in ipairs(self.bodies) do
			local orbit = body.keplerOrbit
			if orbit then
				local semiMinorAxis = orbit.semiMajorAxis * math.sqrt(1 - orbit.eccentricity ^ 2)
				local modelToWorld = mat4.transform(
					util.getOrbitCentre(body),
					util.getOrbitalPlaneRotation(body) * quat.fromAxisAngle(consts.forwardVector * orbit.argumentOfPeriapsis),
					vec3(orbit.semiMajorAxis, semiMinorAxis, 1)
				)
				local modelToClip = worldToClip * modelToWorld
				self.lineShader:send("modelToWorld", {mat4.components(modelToWorld)})
				self.lineShader:send("modelToClip", {mat4.components(modelToClip)})

				love.graphics.draw(self.orbitLineMesh)
			end
		end
		love.graphics.setColor(1, 1, 1)
		love.graphics.setWireframe(false)
		love.graphics.setMeshCullMode("back")
	end

	-- Draw atmospheres to light canvas, using position information but not writing to it
	love.graphics.setDepthMode("always", false)
	love.graphics.setBlendMode("add")
	love.graphics.setShader(self.atmosphereShader)
	self.atmosphereShader:send("positionCanvas", self.positionCanvas)
	self.atmosphereShader:send("clipToSky", {mat4.components(clipToSky)})
	self.atmosphereShader:send("cameraPosition", {vec3.components(camera.absolutePosition)})
	self.atmosphereShader:send("rayStepCount", consts.atmosphereRayStepCount)
	for _, body in ipairs(self.bodiesWithAtmospheres) do
		local atmosphere = body.atmosphere
		self.atmosphereShader:send("bodyPosition", {vec3.components(body.celestialMotionState.position)})
		self.atmosphereShader:send("bodyRadius", body.celestialRadius.value)
		self.atmosphereShader:send("densityPower", atmosphere.densityPower)
		self.atmosphereShader:send("atmosphereEmissiveness", math.min(consts.maxAtmosphereEmissiveness, atmosphere.emissiveness))
		self.atmosphereShader:send("atmosphereRadius", body.celestialRadius.value + atmosphere.height)
		self.atmosphereShader:send("atmosphereDensity", atmosphere.density)
		local shadowSpheres = body.starData and {} or self:getShadowSpheres(body, false)
		self:sendShadowSpheres(self.atmosphereShader, shadowSpheres)
		love.graphics.setColor(atmosphere.colour)
		love.graphics.draw(self.dummyTexture, 0, 0, 0, self.lightCanvas:getDimensions())
	end
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1)

	-- Draw light canvas to output canvas with HDR
	love.graphics.setCanvas(outputCanvas)
	love.graphics.clear()
	love.graphics.setShader(self.tonemappingShader)
	love.graphics.draw(self.lightCanvas, 0, consts.canvasSystemHeight, 0, 1, -1)
	love.graphics.setCanvas()
	love.graphics.setShader()
end

function celestial:getLights()
	local lights = {}
	for _, star in ipairs(self.stars) do
		lights[#lights + 1] = {
			position = vec3.clone(star.celestialMotionState.position),
			colour = util.shallowClone(star.starData.colour),
			intensity = star.starData.luminosity
		}
	end
	return lights
end

function celestial:getShadowSpheres(body, ignoreCurrentBody)
	-- Crops out bodies where you have to go up the tree and then down again

	-- ignoreCurrentBody is used when shading planet surfaces. Since they're spheres, lighting calculations using the normal will do the job of having a shadow anyway

	local spheres = {}

	local function addBody(bodyToAdd)
		if ignoreCurrentBody and bodyToAdd == body then
			return
		end
		spheres[#spheres + 1] = {
			position = vec3.clone(bodyToAdd.celestialMotionState.position),
			radius = bodyToAdd.celestialRadius.value
		}
	end

	local function recurseDown(body)
		addBody(body)
		if not body.satellites then
			return
		end
		for _, satellite in ipairs(body.satellites.value) do
			recurseDown(satellite)
		end
	end

	local function recurseUp(body)
		if not body.keplerOrbit then
			return
		end
		local parent = body.keplerOrbit.parent
		addBody(parent)
		recurseUp(parent)
	end

	recurseDown(body)
	recurseUp(body)

	return spheres
end

function celestial:sendLights(shader, lights)
	assert(#lights <= consts.maxLightsCelestial, "Too many lights (" .. #lights .. "), should be no more than " .. consts.maxLightsCelestial)
	shader:send("lightCount", #lights)
	for i, light in ipairs(lights) do
		local glslI = i - 1
		local prefix = "lights[" .. glslI .. "]."
		shader:send(prefix .. "position", {vec3.components(light.position)})
		shader:sendColor(prefix .. "colour", light.colour)
		shader:send(prefix .. "intensity", light.intensity)
	end
end

function celestial:sendShadowSpheres(shader, spheres)
	assert(#spheres <= consts.maxShadowSpheresCelestial, "Too many shadow spheres (" .. #spheres .. "), should be no more than " .. consts.maxShadowSpheresCelestial)
	shader:send("sphereCount", #spheres)
	for i, sphere in ipairs(spheres) do
		local glslI = i - 1
		local prefix = "spheres[" .. glslI .. "]."
		shader:send(prefix .. "position", {vec3.components(sphere.position)})
		shader:send(prefix .. "radius", sphere.radius)
	end
end

return celestial
