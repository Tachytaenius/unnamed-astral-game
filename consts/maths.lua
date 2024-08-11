local vec3 = require("lib.mathsies").vec3

local maths = {}

maths.tau = math.pi * 2

maths.rightVector = vec3(1, 0, 0)
maths.upVector = vec3(0, 1, 0)
maths.forwardVector = vec3(0, 0, 1)

return maths
