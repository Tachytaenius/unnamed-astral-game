local concord = require("lib.concord")
return concord.component("ringSystem", function(c, parent, type, startDistance, size, colours, noiseAFrequency, noiseBFrequency, noiseCFrequency, discardThreshold)
	c.parent = parent
	c.type = type
	c.startDistance = startDistance
	c.size = size
	c.colours = colours
	c.noiseAFrequency = noiseAFrequency
	c.noiseBFrequency = noiseBFrequency
	c.noiseCFrequency = noiseCFrequency
	c.discardThreshold = discardThreshold
end)
