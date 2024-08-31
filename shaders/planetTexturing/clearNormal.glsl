#line 1

// Requires include/skyDirection.glsl concatenated

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	vec3 outColour = direction * 0.5 + 0.5;
	return vec4(outColour, 1.0);
}
