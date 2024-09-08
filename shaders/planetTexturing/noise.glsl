#line 1

// Requires include/lib/simplex3d.glsl concatenated
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

	float blank = 0.0;
	float mixingNoise = pow(max(0.0, snoise(direction * 3.0 + 200.0) * 0.5 + 0.5), 1.0);
	float mixedNoise = mix(blank, filteredNoise, mixingNoise);
	float outNoise = 1.0 - mixedNoise * noiseEffect;
	return vec4(vec3(outNoise), 1.0);
}

#endif
