return function(state, dt)
	state.ecs:emit("update", dt)
	state.lastTime = state.time
	state.time = state.time + dt
end
