#line 1

// Requires include/lib/colour-space-conversion.glsl (and its dependencies) to be concatenated in front

const float lightRangeEpsilon = 1e-10; // Avoid redefinition

vec3 jodieReinhard(vec3 c){
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 tc = c / (c + 1.0);
	return mix(c / (l + 1.0), tc, tc);
}

vec3 reinhard(vec3 inColour) {
	return inColour / (inColour + 1.0);
}

// My own tonemapping function
uniform float maxLuminance;
vec3 tachy(vec3 inColour, float maxLuminance) {
	vec3 hsl = rgb2hsl(inColour); // Different kind of luminance to the above...?
	hsl.z /= maxLuminance;
	return hsl2rgb(hsl);
}

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 inColour = Texel(image, textureCoords).rgb;

	// vec3 outColour = inColour;
	// vec3 outColour = tachy(inColour, maxLuminance);
	// vec3 outColour = reinhard(inColour);
	vec3 outColour = jodieReinhard(inColour);

	return vec4(outColour, 1.0);
}
