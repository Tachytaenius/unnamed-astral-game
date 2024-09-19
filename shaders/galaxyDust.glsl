#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated
// Requires include/colourSpaceConversion.glsl

#ifdef PIXEL

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	direction.y *= -1.0; // I have no idea
	
	// TODO
	vec3 dir2 = normalize(direction / vec3(1.0, 1.0, 5.0));
	float noise = clamp(snoise(dir2) * 0.5 + 0.5, 0.0, 1.0);
	vec3 outColour = vec3(noise);

	// outColour += vec3(1.0, 0.5, 0.5) * max(0.0, 1.0 - distance(direction, vec3(1.0, 0.0, 0.0)) / 0.25);
	// outColour += vec3(0.0, 0.5, 0.5) * max(0.0, 1.0 - distance(direction, vec3(-1.0, 0.0, 0.0)) / 0.25);
	// outColour += vec3(0.5, 1.0, 0.5) * max(0.0, 1.0 - distance(direction, vec3(0.0, 1.0, 0.0)) / 0.25);
	// outColour += vec3(0.5, 0.0, 0.5) * max(0.0, 1.0 - distance(direction, vec3(0.0, -1.0, 0.0)) / 0.25);
	// outColour += vec3(0.5, 0.5, 1.0) * max(0.0, 1.0 - distance(direction, vec3(0.0, 0.0, 1.0)) / 0.25);
	// outColour += vec3(0.5, 0.5, 0.0) * max(0.0, 1.0 - distance(direction, vec3(0.0, 0.0, -1.0)) / 0.25);

	return vec4(outColour, 1.0);
}

#endif
