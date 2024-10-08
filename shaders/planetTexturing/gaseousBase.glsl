#line 1

// Requires const int maxColourSteps definition concatenated
// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

const float tau = 6.28318530718;

#ifdef PIXEL

uniform int colourStepCount;
uniform vec3[maxColourSteps] colourSteps;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	// float progress = direction.z * 0.5 + 0.5;
	float progress = acos(clamp(direction.z, -1.0, 1.0)) / (tau / 2.0);
	int stepIndex = int(floor(clamp(progress, 0.0, 1.0) * float(colourStepCount)));
	vec3 outColour = colourSteps[stepIndex];

	return vec4(outColour, 1.0);
}

#endif
