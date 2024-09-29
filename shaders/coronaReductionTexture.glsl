#line 1

// Requires shaders/include/lib/simplex3d.glsl concatenated
// Requires shaders/include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform float noiseFrequency;
uniform float noisePower;
uniform bool spiky;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float noise = snoise(direction * noiseFrequency) * 0.5 + 0.5;
	noise = clamp(noise, 0.0, 1.0);
	noise = pow(noise, noisePower);
	if (spiky) {
		noise = 1.0 - pow(max(0.0, noise), 10.0);
	}
	return vec4(vec3(noise), 1.0);
}

#endif
