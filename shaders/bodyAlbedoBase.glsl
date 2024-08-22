#line 1

// Requires include/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated
// Requires include/colourSpaceConversion.glsl

#ifdef PIXEL

uniform float noiseFrequency;
uniform float noiseEffect;

uniform float colourMixNoiseFrequency;

uniform vec3 primaryColour;
uniform vec3 secondaryColour;

// vec3 mixHsl(vec3 aRgb, vec3 bRgb, float mixFactor) {
// 	vec3 aHsl = rgb2hsl(aRgb);
// 	vec3 bHsl = rgb2hsl(bRgb);
// 	// float outH = mod(aHsl.x + mixFactor * (mod(bHsl.x - aHsl.x + 0.5, 1.0) - 0.5), 1.0);
// 	float outH = mix(aHsl.x, bHsl.x, mixFactor);
// 	vec3 outHsl = vec3(outH, mix(aHsl.yz, bHsl.yz, mixFactor));
// 	return hsl2rgb(outHsl);
// }

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float noise = snoise(direction * noiseFrequency) * 0.5 + 0.5;
	float colourMixNoise = snoise(direction * colourMixNoiseFrequency) * 0.5 + 0.5;
	vec3 baseColour = mix(primaryColour, secondaryColour, colourMixNoise);
	vec3 outColour = baseColour * (1.0 - noise * noiseEffect);
	return vec4(outColour, 1.0);
}

#endif
