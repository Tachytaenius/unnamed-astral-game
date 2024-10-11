#line 1

// Requires const int maxColourSteps definition concatenated
// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

const float tau = 6.28318530718;

#ifdef PIXEL

struct ColourStep {
	vec3 colour;
	float start;
};

uniform int colourStepCount;
uniform ColourStep[maxColourSteps] colourSteps;

uniform float blendSize;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	// float progress = direction.z * 0.5 + 0.5;
	float progress = acos(clamp(direction.z, -1.0, 1.0)) / (tau / 2.0);

	// int stepIndex = int(floor(clamp(progress, 0.0, 1.0) * float(colourStepCount)));
	// vec3 outColour = colourSteps[stepIndex];

	int index;
	bool found = false;
	for (int i = colourStepCount - 1; i >= 0; i--) {
		if (colourSteps[i].start <= progress) {
			found = true;
			index = i;
			break;
		}
	}
	if (!found) {
		discard; // error!
	}

	vec3 outColour = colourSteps[index].colour;
	float startToHere = progress - colourSteps[index].start;
	// float end =
	// 	index < colourStepCount - 1 ?
	// 	colourSteps[index + 1].start :
	// 	1.0;
	if (startToHere < blendSize && index > 0) {
		outColour = mix(colourSteps[index - 1].colour, outColour, startToHere / blendSize);
	}

	return vec4(outColour, 1.0);
}

#endif
