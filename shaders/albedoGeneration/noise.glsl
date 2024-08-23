#line 1

// Requires include/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform float noiseFrequency;
uniform float noiseEffect;
uniform int noiseType;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float noiseIn = snoise(direction * noiseFrequency) * 0.5 + 0.5;

	float filteredNoise;
	switch (noiseType) {
		// case 0 is default
		case 1:
			filteredNoise = abs(noiseIn - 0.5) * 2.0;
			break;
		case 2:
			filteredNoise = 1.0 - abs(noiseIn - 0.5) * 2.0;
			break;
		default:
			filteredNoise = noiseIn;
	}

	float outNoise = 1.0 - filteredNoise * noiseEffect;
	return vec4(vec3(outNoise), 1.0);
}

#endif
