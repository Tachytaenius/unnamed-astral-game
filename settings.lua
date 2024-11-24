-- TODO

return {
	graphics = {
		canvasScale = 1,
		fullscreen = false,
		drawOrbitLines = true,
		drawBodyReticles = true,
		drawConstellations = true
	},
	controls = {
		celestialCamera = {
			moveRight = "d",
			moveLeft = "a",
			moveUp = "e",
			moveDown = "q",
			moveForwards = "w",
			moveBackwards = "s",

			pitchDown = "k",
			pitchUp = "i",
			yawRight = "l",
			yawLeft = "j",
			rollAnticlockwise = "u",
			rollClockwise = "o",

			setRelativeBody = "space"
		},
		drawElements = {
			toggleOrbitLines = "f1",
			toggleBodyReticles = "f2",
			toggleConstellations = "f3"
		}
	}
}
