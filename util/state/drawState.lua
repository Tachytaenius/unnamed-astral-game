return function(state, outputCanvas, dt)
	state.ecs:emit("draw", outputCanvas, dt)
end
