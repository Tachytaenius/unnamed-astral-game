return function(state, dt)
	state.ecs:emit("update", dt)
	state.time = state.time + dt
end
