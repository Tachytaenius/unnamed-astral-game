#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform float noiseFrequency;
uniform float noiseEffect;
uniform int noiseType;
uniform int fractalNoiseType;
uniform float normalFractalNoiseMix;

// idk lol i just found this i didnt write it but it works
float snoiseFractal(vec3 m) {
	return   0.5333333* snoise(m)
				+0.2666667* snoise(2.0*m)
				+0.1333333* snoise(4.0*m)
				+0.0666667* snoise(8.0*m);
}

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float noiseIn = snoise(direction * noiseFrequency) * 0.5 + 0.5;
	float fractalNoiseIn = snoise(direction * noiseFrequency / 4.0) * 0.5 + 0.5;

	float filteredNoise;
	// Make sure the highest noise type is actually the highest case number for both of these switch blocks
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
	switch (fractalNoiseType) {
		// case 0 is default
		case 1:
			filteredNoise = mix(filteredNoise, fractalNoiseIn, normalFractalNoiseMix);
		case 2:
			filteredNoise = mix(filteredNoise, abs(fractalNoiseIn - 0.5) * 2.0, normalFractalNoiseMix);
		case 3:
			filteredNoise = mix(filteredNoise, 1.0 - abs(fractalNoiseIn - 0.5) * 2.0, normalFractalNoiseMix);
		default:
			filteredNoise += 0.0;
	}

	float blank = 0.0;
	float mixingNoise = pow(max(0.0, snoise(direction * 3.0 + 200.0) * 0.5 + 0.5), 1.0);
	float mixedNoise = mix(blank, filteredNoise, mixingNoise);
	float outNoise = 1.0 - mixedNoise * noiseEffect;
	return vec4(vec3(outNoise), 1.0);
}

#endif
