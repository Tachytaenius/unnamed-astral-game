local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")
local settings = require("settings")
local util = require("util")

local celestial = {}

function celestial:renderCelestialCamera(outputCanvas, entity)
	local camera = entity.celestialCamera
	local drawTime = self:getWorld().state.lastTime
	love.graphics.setMeshCullMode("none")

	-- Get position offset
	local positionOffset = -camera.absolutePosition -- Where needed, we make things relative to the camera so that precision issues go away (GPUs only use single-precision floats)

	-- Get matrices
	local worldToCamera = mat4.camera(camera.absolutePosition + positionOffset, camera.orientation)
	local aspectRatio = outputCanvas:getWidth() / outputCanvas:getHeight()
	local verticalFOV = camera.verticalFOV
	local cameraToClip = mat4.perspectiveLeftHanded(
		aspectRatio,
		verticalFOV,
		consts.celestialFarPlaneDistance,
		consts.celestialNearPlaneDistance
	)
	local worldToClip = cameraToClip * worldToCamera
	local worldToCameraStationary = mat4.camera(vec3(), camera.orientation)
	local clipToSky = mat4.inverse(cameraToClip * worldToCameraStationary)

	-- Get and send lights
	local lights = self:getLights()
	self:sendLights(self.bodyShader, lights, positionOffset)
	self:sendLights(self.atmosphereShader, lights, positionOffset)
	self:sendLights(self.ringShader, lights, positionOffset)

	-- Clear canvasses
	love.graphics.setCanvas({
		self.lightCanvas,
		self.positionCanvas,
		depthstencil = self.depthBuffer
	})
	love.graphics.clear({0, 0, 0, 1}, {0, 0, 0, 0}, false, true)

	-- Draw skybox to light canvas, no depth or position
	love.graphics.setDepthMode("always", false)
	love.graphics.setCanvas(self.lightCanvas)
	love.graphics.setShader(self.skyboxShader)
	self.skyboxShader:send("clipToSky", {mat4.components(clipToSky)})
	self.skyboxShader:send("skybox", self.skybox)
	self.skyboxShader:send("nonHdrBrightnessMultiplier", consts.pointLuminanceToRGBNonHDR)
	love.graphics.draw(self.dummyTexture, 0, 0, 0, self.lightCanvas:getDimensions())

	if settings.graphics.drawConstellations then
		-- Draw constellations
		love.graphics.push("all")
		love.graphics.setCanvas(self.HUDAndConstellationCanvas)
		love.graphics.clear()
		love.graphics.setWireframe(true)
		love.graphics.setShader(self.lineShader)
		self.lineShader:send("useStartAndOffset", true)
		local cameraToClipForDirections = mat4.perspectiveLeftHanded(
			aspectRatio,
			verticalFOV,
			1.5,
			0.5
		)
		local worldToClipForDirections = cameraToClipForDirections * worldToCamera
		self.lineShader:send("worldToClip", {mat4.components(worldToClipForDirections)})
		local galaxy = self:getWorld().state.galaxy
		for _, constellation in ipairs(galaxy.constellations) do
			for _, link in ipairs(constellation.links) do
				local aDir = vec3.normalise(link.a.position - galaxy.originPositionInGalaxy)
				local bDir = vec3.normalise(link.b.position - galaxy.originPositionInGalaxy)
				self.lineShader:send("lineStart", {vec3.components(aDir)})
				self.lineShader:send("lineOffset", {vec3.components(bDir - aDir)})
				love.graphics.draw(self.lineMesh)
			end
		end
		love.graphics.pop()
		love.graphics.setShader()
		love.graphics.setCanvas(self.lightCanvas)
		love.graphics.push("all")
		love.graphics.setBlendMode("add")
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.draw(self.HUDAndConstellationCanvas)
		love.graphics.pop()
	end

	-- Sort out what to draw and how
	local bodiesToDrawDirectly, atmosphereBodiesToDraw, bodiesToDrawAsPoints = {}, {}, {}
	for _, body in ipairs(self.bodies) do
		if util.isBodyResolvable(body, camera, consts.bodySolidOrPointFudgeFactor) then
			bodiesToDrawDirectly[#bodiesToDrawDirectly + 1] = body
			if body.atmosphere then
				atmosphereBodiesToDraw[#atmosphereBodiesToDraw + 1] = body
			end
		else
			bodiesToDrawAsPoints[#bodiesToDrawAsPoints + 1] = body
		end
	end

	-- Draw faraway bodies as points on the background
	-- We're using disks. The angular radius of a disk at distance 1 is atan(radius) (would divide radius by distance).
	-- We want a radius that gets the right angular radius, so we use tan.
	local scaleToGetAngularRadius = math.tan(consts.pointLightBlurAngularRadius)
	local cameraUp = vec3.rotate(consts.upVector, camera.orientation)
	local cameraRight = vec3.rotate(consts.rightVector, camera.orientation)
	local cameraToClipPoint = mat4.perspectiveLeftHanded(
		aspectRatio,
		verticalFOV,
		1.5,
		0.5
	)
	local worldToClipPoint = cameraToClipPoint * worldToCameraStationary
	local diskDistanceToSphere = util.unitSphereSphericalCapHeightFromAngularRadius(consts.pointLightBlurAngularRadius)
	self.blurredPointShader:send("cameraUp", {vec3.components(cameraUp)})
	self.blurredPointShader:send("cameraRight", {vec3.components(cameraRight)})
	self.blurredPointShader:send("scale", scaleToGetAngularRadius)
	self.blurredPointShader:send("diskDistanceToSphere", diskDistanceToSphere)
	self.blurredPointShader:send("worldToClip", {mat4.components(worldToClipPoint)})
	self.blurredPointShader:send("vertexFadePower", consts.blurredPointVertexFadePower)
	love.graphics.setShader(self.blurredPointShader)
	love.graphics.setBlendMode("add")
	for _, body in ipairs(bodiesToDrawAsPoints) do
		local direction = vec3.normalize(body.celestialMotionState.position - camera.absolutePosition) -- No need to consider position offset
		local colour, brightness
		if body.starData then
			colour = body.starData.colour
			brightness = consts.distantStarBodyBrightness
		else
			-- TODO!
			colour = {0, 0, 0}
			brightness = 0
		end

		self.blurredPointShader:send("pointDirection", {vec3.components(direction)})
		local r, g, b = love.math.gammaToLinear(colour)
		self.blurredPointShader:send("pointIncomingLight", {r * brightness, g * brightness, b * brightness})
		love.graphics.draw(self.diskMesh)
	end
	love.graphics.setBlendMode("alpha")

	-- Draw bodies to light canvas, with depth and position information, then draw rings
	love.graphics.setCanvas({
		self.lightCanvas,
		self.positionCanvas,
		depthstencil = self.depthBuffer
	})
	love.graphics.setDepthMode("lequal", true)
	love.graphics.setShader(self.bodyShader)
	for _, body in ipairs(bodiesToDrawDirectly) do
		local modelToWorld = mat4.transform(
			body.celestialMotionState.position + positionOffset,
			body.celestialOrientationState.value,
			body.celestialRadius.value
		)
		local modelToClip = worldToClip * modelToWorld

		-- self.bodyShader:send("modelToWorld", {mat4.components(modelToWorld)})
		-- self.bodyShader:send("modelToClip", {mat4.components(modelToClip)})
		self.bodyShader:send("modelToWorldNormal", {util.getNormalMatrix(modelToWorld)})
		-- print(mat4.inverse(mat4.inverse(modelToWorld)), modelToWorld) -- utterly absurd precision issues using metres as a unit :3 (you can invert such matrices by inverting the variables used to create them and then making a matrix from those, though)
		self.bodyShader:send("worldToModelNormal", {util.getInverseNormalMatrix(modelToWorld)})

		-- Fix artifacting with raycasted spherical atmosphere interacting with icosphere body
		self.bodyShader:send("clipToSky", {mat4.components(clipToSky)})
		self.bodyShader:send("cameraPosition", {vec3.components(camera.absolutePosition + positionOffset)})
		self.bodyShader:send("cameraForwardVector", {vec3.components(vec3.rotate(consts.forwardVector, camera.orientation))})
		self.bodyShader:send("nearDistance", consts.celestialNearPlaneDistance)
		self.bodyShader:send("farDistance", consts.celestialFarPlaneDistance)
		self.bodyShader:send("bodyPosition", {vec3.components(body.celestialMotionState.position + positionOffset)})
		self.bodyShader:send("bodyRadius", body.celestialRadius.value)

		self.bodyShader:send("enableSelfShadowing", true)
		local inverseBodyOrientationMatrix = mat4.rotate(quat.inverse(body.celestialOrientationState.value)) -- I think this serves the same purpose as... modelToWorldNormal? worldToModelNormal?
		self.bodyShader:send("inverseBodyOrientationMatrix", {util.toMat3(inverseBodyOrientationMatrix)})

		self.bodyShader:send("isStar", not not body.starData)
		self.bodyShader:send("time", drawTime)
		if not body.starData then
			local slot =
				body.bodyTextureCubemapSlotClaim
				and body.bodyTextureCubemapSlotClaim.slotEntity.bodyCubemapTextureSlot
				or self.missingTextureSlot
			self.bodyShader:send("baseColourTexture", slot.baseColour)
			self.bodyShader:send("normalTexture", slot.normal)
			self.bodyShader:send("heightmapTexture", slot.height)
			self.bodyShader:send("heightmapMinMax", slot.heightMinMax)
		else
			self.bodyShader:sendColor("starColour", body.starData.colour)
			-- self.bodyShader:send("starLuminousFlux", body.starData.radiantFlux * body.starData.luminousEfficacy)

			-- self.bodyShader:send("simplexTimeRate", 0.5)
			-- self.bodyShader:send("simplexFrequency", 12)
			-- -- self.bodyShader:send("simplexColourHueShift", 0.1)
			-- -- self.bodyShader:send("simplexColourSaturationAdd", 0.5)
			-- -- self.bodyShader:send("simplexColourValueMultiplier", 0.25)
			-- self.bodyShader:sendColor("simplexColour", body.starData.sunspotColour)
			-- self.bodyShader:send("simplexPower", 4)
			-- self.bodyShader:send("simplexEffect", 1)

			-- self.bodyShader:send("worleyFrequency", 4)
			-- self.bodyShader:send("worleyEffect", 0.6)
		end

		local shadowObjects = body.starData and {} or self:getShadowObjects(body, true, nil)
		self:sendShadowObjects(self.bodyShader, shadowObjects, positionOffset)

		love.graphics.draw(self.dummyTexture, 0, 0, 0, self.lightCanvas:getDimensions())

		-- Debug rotation axis
		-- love.graphics.push("all")
		-- love.graphics.setWireframe(true)
		-- love.graphics.setShader(self.lineShader)
		-- self.lineShader:send("useStartAndOffset", true)
		-- self.lineShader:send("lineStart", {vec3.components(body.celestialMotionState.position + positionOffset)})
		-- local lineVector = body.celestialRotation.rotationAxis * body.celestialRadius.value * 1.5
		-- self.lineShader:send("worldToClip", {mat4.components(worldToClip)})
		-- -- Rotation axis
		-- self.lineShader:send("lineOffset", {vec3.components(lineVector)})
		-- love.graphics.setColor(0, 0, 1)
		-- love.graphics.draw(self.lineMesh)
		-- -- Negative rotation axis
		-- self.lineShader:send("lineOffset", {vec3.components(-lineVector)})
		-- love.graphics.setColor(1, 1, 0)
		-- love.graphics.draw(self.lineMesh)
		-- -- Forward vector
		-- self.lineShader:send("lineOffset", {vec3.components(consts.forwardVector * body.celestialRadius.value * 1.25)})
		-- love.graphics.setColor(1, 0, 0)
		-- love.graphics.draw(self.lineMesh)
		-- -- Negative forward vector
		-- self.lineShader:send("lineOffset", {vec3.components(-consts.forwardVector * body.celestialRadius.value * 1.25)})
		-- love.graphics.setColor(0, 1, 1)
		-- love.graphics.draw(self.lineMesh)
		-- love.graphics.pop()
	end
	love.graphics.setShader(self.ringShader)
	for _, ringEntity in ipairs(self.ringSystems) do
		local ring = ringEntity.ringSystem
		local parent = ring.parent

		-- Align to equatorial plane of planet (i read equatorial bulge migrates rings towards equator over time)
		local rotationAxis = parent.celestialRotation.rotationAxis
		local axis, angle = util.axisAngleBetweenDirections(consts.forwardVector, rotationAxis)
		local orientation
		if not axis then
			orientation = quat()
		else
			orientation = quat.fromAxisAngle(axis * angle)
		end

		local modelToWorld = mat4.transform(
			parent.celestialMotionState.position + positionOffset,
			orientation,
			ring.startDistance + ring.size -- Ring furthest distance
		)
		local modelToClip = worldToClip * modelToWorld

		self.ringShader:send("modelToWorld", {mat4.components(modelToWorld)})
		self.ringShader:send("modelToClip", {mat4.components(modelToClip)})
		-- self.ringShader:send("modelToWorldNormal", {util.getNormalMatrix(modelToWorld)})
		self.ringShader:send("ringCentre", {vec3.components(parent.celestialMotionState.position + positionOffset)})
		self.ringShader:send("startDistance", ring.startDistance)
		self.ringShader:send("endDistance", ring.startDistance + ring.size)

		self.ringShader:send("colours", unpack(ring.colours))
		self.ringShader:send("noiseAFrequency", ring.noiseAFrequency)
		self.ringShader:send("noiseBFrequency", ring.noiseBFrequency)
		self.ringShader:send("noiseCFrequency", ring.noiseCFrequency)
		self.ringShader:send("discardThreshold", ring.discardThreshold)

		-- self.ringShader:send("cameraPosition", {vec3.components(camera.absolutePosition + positionOffset)})

		local shadowObjects = self:getShadowObjects(parent, false, ringEntity)
		self:sendShadowObjects(self.ringShader, shadowObjects, positionOffset)

		love.graphics.draw(self.ringMesh)
	end

	-- The idea is that they are like (illusory) solids in space. Just superimposing them over atmosphere has an undesirable look
	if settings.graphics.drawOrbitLines then
		love.graphics.setShader(self.lineShader)
		love.graphics.setColor(consts.orbitLineColour)
		self.lineShader:send("negativeAlpha", false)
		self.lineShader:send("useStartAndOffset", false)
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setMeshCullMode("none")
		love.graphics.setWireframe(true)
		for _, body in ipairs(self.bodies) do
			local orbit = body.keplerOrbit
			if orbit then
				local semiMinorAxis = orbit.semiMajorAxis * math.sqrt(1 - orbit.eccentricity ^ 2)
				local modelToWorld = mat4.transform(
					util.getOrbitCentre(body) + positionOffset,
					util.getOrbitalPlaneRotation(body) * quat.fromAxisAngle(consts.forwardVector * orbit.argumentOfPeriapsis),
					vec3(orbit.semiMajorAxis, semiMinorAxis, 1)
				)
				self.lineShader:send("modelToWorld", {mat4.components(modelToWorld)})
				self.lineShader:send("worldToClip", {mat4.components(worldToClip)})

				love.graphics.draw(self.orbitLineMesh)
			end
		end
		love.graphics.setColor(1, 1, 1)
		love.graphics.setWireframe(false)
		love.graphics.setMeshCullMode("back")
	end

	-- Draw atmospheres to light canvas, using position information but not writing to it
	love.graphics.setCanvas(self.lightCanvas)
	love.graphics.setDepthMode("always", false)
	love.graphics.setBlendMode("alpha", "alphamultiply")
	love.graphics.setColorMask(true, true, true, false)
	love.graphics.setShader(self.atmosphereShader)
	self.atmosphereShader:send("positionCanvas", self.positionCanvas)
	self.atmosphereShader:send("clipToSky", {mat4.components(clipToSky)})
	self.atmosphereShader:send("cameraPosition", {vec3.components(camera.absolutePosition + positionOffset)})
	self.atmosphereShader:send("stepsPerRay", consts.atmosphereRayStepCount)
	for _, body in ipairs(atmosphereBodiesToDraw) do
		local atmosphere = body.atmosphere
		self.atmosphereShader:send("atmospherePosition", {vec3.components(body.celestialMotionState.position + positionOffset)})
		self.atmosphereShader:send("bodyRadius", body.celestialRadius.value)
		self.atmosphereShader:send("atmosphereRadius", body.celestialRadius.value + atmosphere.height)
		self.atmosphereShader:send("baseScatterance", atmosphere.scatterance)
		self.atmosphereShader:send("baseAbsorption", atmosphere.absorption)
		self.atmosphereShader:send("baseEmission", atmosphere.emission)
		self.atmosphereShader:sendColor("atmosphereColour", atmosphere.colour)
		self.atmosphereShader:send("atmosphereDensityPower", atmosphere.densityPower)
		if not body.starData then
			self.atmosphereShader:send("starCorona", false)
		else
			self.atmosphereShader:send("starCorona", true)
			self.atmosphereShader:send("coronaReductionTexture1", self.coronaReductionTexture1)
			self.atmosphereShader:send("coronaReductionTexture2", self.coronaReductionTexture2)
			self.atmosphereShader:send("coronaReductionMatrix1", {
				util.toMat3(mat4.rotate(
					quat.fromAxisAngle(
						0.1 * drawTime *
						vec3.normalise(vec3(
							1, 2, 3
						))
					)
				))
			})
			self.atmosphereShader:send("coronaReductionMatrix2", {
				util.toMat3(mat4.rotate(
					quat.fromAxisAngle(
						0.2 * drawTime *
						vec3.normalise(vec3(
							-1, 3, -5
						))
					)
				))
			})
		end
		local shadowObjects = body.starData and {} or self:getShadowObjects(body, false)
		self:sendShadowObjects(self.atmosphereShader, shadowObjects, positionOffset)
		love.graphics.setColor(atmosphere.colour)
		love.graphics.draw(self.dummyTexture, 0, 0, 0, self.lightCanvas:getDimensions())
	end
	love.graphics.setBlendMode("alpha")
	love.graphics.setColorMask()
	love.graphics.setColor(1, 1, 1)

	-- Draw HUD
	love.graphics.setCanvas(self.HUDAndConstellationCanvas)
	love.graphics.setShader()
	love.graphics.clear()
	local function drawReticle(worldSpacePosition, circleRadius)
		local cameraSpacePosition = worldToCamera * worldSpacePosition
		if cameraSpacePosition.z > 0 then
			local positionProjected = cameraToClip * cameraSpacePosition
			local positionProjected2D = vec2(positionProjected.x, -positionProjected.y)
			local screenSpacePos = (positionProjected2D * 0.5 + 0.5) * vec2(self.HUDAndConstellationCanvas:getDimensions())
			love.graphics.circle("line", screenSpacePos.x, screenSpacePos.y, circleRadius)
		end
	end
	if settings.graphics.drawBodyReticles then
		love.graphics.setColor(consts.bodyReticleColour)
		for _, body in ipairs(self.bodies) do
			local position = body.celestialMotionState.position + positionOffset
			drawReticle(position, 10)
		end
		love.graphics.setColor(1, 1, 1)
	end

	for _, body in ipairs(self.bodies) do
		if body.equinoxesSolstices then
			local parentOffset = body.keplerOrbit.parent.celestialMotionState.position
			local component = body.equinoxesSolstices
			local solsticeAPosition = util.getLocalStateVectorsFromMeanAnomaly(component.solsticeAMeanAnomaly, body)
			local solsticeBPosition = util.getLocalStateVectorsFromMeanAnomaly(component.solsticeBMeanAnomaly, body)
			local equinoxAPosition = util.getLocalStateVectorsFromMeanAnomaly(component.equinoxAMeanAnomaly, body)
			local equinoxBPosition = util.getLocalStateVectorsFromMeanAnomaly(component.equinoxBMeanAnomaly, body)
			love.graphics.setColor(1, 0, 0)
			drawReticle(solsticeAPosition + parentOffset + positionOffset, 6)
			drawReticle(solsticeBPosition + parentOffset + positionOffset, 6)
			love.graphics.setColor(0, 1, 0)
			drawReticle(equinoxAPosition + parentOffset + positionOffset, 6)
			drawReticle(equinoxBPosition + parentOffset + positionOffset, 6)
		end
	end
	love.graphics.setColor(1, 1, 1)

	-- love.graphics.circle("line", self.HUDAndConstellationCanvas:getWidth() / 2, self.HUDAndConstellationCanvas:getHeight() / 2, 4)

	-- Draw light canvas to output canvas, then draw HUD canvas too
	love.graphics.setCanvas(outputCanvas)
	love.graphics.clear()
	love.graphics.setShader()
	love.graphics.draw(self.lightCanvas)
	love.graphics.setShader()
	love.graphics.draw(self.HUDAndConstellationCanvas)
	love.graphics.setCanvas()
end

function celestial:getLights()
	local lights = {}
	for _, star in ipairs(self.stars) do
		lights[#lights + 1] = {
			position = vec3.clone(star.celestialMotionState.position),
			colour = util.shallowClone(star.starData.colour),
			-- luminousFlux = star.starData.radiantFlux * star.starData.luminousEfficacy
		}
	end
	return lights
end

function celestial:getShadowObjects(body, ignoreCurrentBody, ignoreRingEntity)
	-- Crops out bodies and their rings where you have to go up the tree and then down again

	-- ignoreCurrentBody (boolean) is used when shading planet surfaces. Since they're spheres, lighting calculations using the normal will do the job of having a shadow anyway
	-- ignoreRingEntity is used when shading rings. It is the entity of the ring currently being shaded

	local spheres = {}
	local rings = {}

	local function addBody(bodyToAdd)
		if bodyToAdd.ringSystemsList then
			for _, ringEntity in ipairs(bodyToAdd.ringSystemsList.value) do
				if not ignoreRingEntity or ignoreRingEntity ~= ringEntity then
					local ringSystem = ringEntity.ringSystem -- Component
					local shadowRing = {}
					shadowRing.planeNormal = bodyToAdd.celestialRotation.rotationAxis
					shadowRing.planeCentre = bodyToAdd.celestialMotionState.position
					shadowRing.startDistance = ringSystem.startDistance
					shadowRing.endDistance = ringSystem.startDistance + ringSystem.size
					shadowRing.noiseCFrequency = ringSystem.noiseCFrequency
					shadowRing.discardThreshold = ringSystem.discardThreshold
					rings[#rings + 1] = shadowRing
				end
			end
		end

		if bodyToAdd.starData or ignoreCurrentBody and bodyToAdd == body then
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

	return {spheres = spheres, rings = rings}
end

function celestial:sendLights(shader, lights, offset)
	assert(#lights <= consts.maxLightsCelestial, "Too many lights (" .. #lights .. "), should be no more than " .. consts.maxLightsCelestial)
	shader:send("lightCount", #lights)
	for i, light in ipairs(lights) do
		local glslI = i - 1
		local prefix = "lights[" .. glslI .. "]."
		shader:send(prefix .. "position", {vec3.components(light.position + offset)})
		shader:sendColor(prefix .. "colour", light.colour)
		-- shader:send(prefix .. "luminousFlux", light.luminousFlux)
	end
end

function celestial:sendShadowObjects(shader, objects, offset)
	local spheres, rings = objects.spheres or {}, objects.rings or {}

	assert(#spheres <= consts.maxShadowSpheresCelestial, "Too many shadow spheres (" .. #spheres .. "), should be no more than " .. consts.maxShadowSpheresCelestial)
	assert(#rings <= consts.maxShadowRingsCelestial, "Too many shadow rings (" .. #rings .. "), should be no more than " .. consts.maxShadowRingsCelestial)

	shader:send("sphereCount", #spheres)
	for i, sphere in ipairs(spheres) do
		local glslI = i - 1
		local prefix = "spheres[" .. glslI .. "]."
		shader:send(prefix .. "position", {vec3.components(sphere.position + offset)})
		shader:send(prefix .. "radius", sphere.radius)
	end

	shader:send("ringCount", #rings)
	for i, ring in ipairs(rings) do
		local glslI = i - 1
		local prefix = "rings[" .. glslI .. "]."
		shader:send(prefix .. "planeNormal", {vec3.components(ring.planeNormal)})
		shader:send(prefix .. "ringCentre", {vec3.components(ring.planeCentre + offset)})
		shader:send(prefix .. "startDistance", ring.startDistance)
		shader:send(prefix .. "endDistance", ring.endDistance)
		shader:send(prefix .. "noiseCFrequency", ring.noiseCFrequency)
		shader:send(prefix .. "discardThreshold", ring.discardThreshold)
	end
end

return celestial
