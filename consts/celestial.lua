local tau = math.pi * 2 -- TODO: Evaluate consts in order and allow reading consts from previous files?

local celestial = {}

celestial.gravitationalConstant = 6.6743e-11
celestial.stefanBoltzmannConstant = 5.6703e-8

celestial.orbitNewtonRaphsonEpsilon = 0.001
celestial.maxOrbitNewtonRaphsonIterations = 30

celestial.cameraResetBodyRadiusDistanceRatio = 6
celestial.celestialCameraSpeedPerDistance = 1
celestial.celestialCameraBodyRadiusCollisionPad = 0.1
celestial.celestialCameraAngularSpeed = tau * 0.25
celestial.celestialCameraVerticalFOV = math.rad(70)

celestial.galaxyRadius = 5e20
celestial.gameplayOriginDistance = 3e20
celestial.galaxyDistancePower = 0.6
celestial.galaxySquash = 0.2
celestial.galaxyHaloProportion = 0.1
celestial.galaxyOtherStarCount = 250000

celestial.maxGaseousBodyColourSteps = 32

celestial.constellationAcceptableStarCount = 250 -- Use the n brightest stars in constellations
assert(celestial.constellationAcceptableStarCount <= celestial.galaxyOtherStarCount, "Not enough stars in the galaxy for constellations, increase galaxyOtherStarCount or decrease constellationAcceptableStarCount")
celestial.constellationCountMin = 16
celestial.constellationCountMax = 24
celestial.constellationConnectionMin = 4
celestial.constellationConnectionMax = 10
celestial.constellationMinAngularSeparationWithinSame = 0.06
celestial.constellationMinAngularSeparationOther = 0.075
celestial.constellationLinkToAlreadyClaimedStarChance = 0.35
celestial.constellationLinkSeparationMin = 0.05 -- Length of a link
celestial.constellationLinkSeparationMax = 0.65
celestial.constellationLinkFailuresBeforeGiveUpOrRetry = 30 -- If constellation has at least constellationConnectionMin links then we give up on adding more to it, else we retry and reset the constellations
celestial.constellationRetriesBeforeGalaxyRetry = 5
celestial.constellationMaxAngularSeparationFromStartStar = 0.4

return celestial
