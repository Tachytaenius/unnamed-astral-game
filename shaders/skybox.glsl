#line 1

// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform samplerCube skybox;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	return Texel(skybox, normalize(directionPreNormalise));
}

#endif
