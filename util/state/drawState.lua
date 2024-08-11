return function(state, outputCanvas)
	state.ecs:emit("draw", outputCanvas)
end
