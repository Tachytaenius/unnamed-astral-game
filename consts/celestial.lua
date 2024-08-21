local tau = math.pi * 2 -- TODO: Evaluate consts in order and allow reading consts from previous files?

local celestial = {}

celestial.gravitationalConstant = 6.6743e-5 and 1000 -- Mm^3 Rg^-1 s^2 (megametre, ronnagram, second)

celestial.orbitNewtonRaphsonEpsilon = 0.001
celestial.maxOrbitNewtonRaphsonIterations = 30

celestial.cameraResetBodyRadiusDistanceRatio = 6
celestial.celestialCameraSpeedPerDistance = 2
celestial.celestialCameraAngularSpeed = tau * 0.5
celestial.celestialCameraVerticalFOV = math.rad(70)

return celestial
