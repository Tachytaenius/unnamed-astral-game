local tau = math.pi * 2 -- TODO: Evaluate consts in order and allow reading consts from previous files?

local celestial = {}

celestial.gravitationalConstant = 6.6743e-11
celestial.stefanBoltzmannConstant = 5.6703e-8

celestial.orbitNewtonRaphsonEpsilon = 0.001
celestial.maxOrbitNewtonRaphsonIterations = 30

celestial.cameraResetBodyRadiusDistanceRatio = 6
celestial.celestialCameraSpeedPerDistance = 1
celestial.celestialCameraAngularSpeed = tau * 0.25
celestial.celestialCameraVerticalFOV = math.rad(70)

return celestial
