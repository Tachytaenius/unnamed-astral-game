#line 1

// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform samplerCube skybox;

uniform float nonHdrBrightnessMultiplier;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec4 sample = Texel(skybox, normalize(directionPreNormalise));
	sample.rgb *= nonHdrBrightnessMultiplier;
	return sample;
}

#endif
