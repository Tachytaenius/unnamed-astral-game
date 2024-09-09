local concord = require("lib.concord")
return concord.component("bodyTextureCubemapSlotClaim", function(c, slotEntity)
	c.slotEntity = slotEntity
end)
