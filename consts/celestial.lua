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
celestial.galaxyOtherStarCount = 1000000
celestial.galaxyDustSampleBrightnessMultiplier = 0.4e-5 -- stars made around the order of magnitude -5 in max luminance

celestial.maxGaseousBodyColourSteps = 32

return celestial
