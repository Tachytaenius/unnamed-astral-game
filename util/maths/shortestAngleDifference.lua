local consts = require("consts")

return function(a, b)
	return (a - b + consts.tau / 2) % consts.tau - consts.tau / 2
end
