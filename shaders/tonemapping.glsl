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
// uniform float maxLuminance; // Wrong type of luminance
vec3 tachy(vec3 inColour, float maxLuminance) {
	vec3 hsl = rgb2hsl(inColour); // Different kind of luminance to the above...?
	hsl.z /= maxLuminance;
	return hsl2rgb(hsl);
}

// My second tonemapping function
vec3 tachy2(vec3 inColour, float maxLuminance, float averageLuminance, float maxLuminanceOut, float averageLuminanceOut) {
	float inColourLuminance = dot(inColour, vec3(0.2126, 0.7152, 0.0722));
	float outColourLuminance =
		averageLuminanceOut
		* pow(inColourLuminance / averageLuminance,
			log(maxLuminanceOut / averageLuminanceOut) /
			log(maxLuminance / averageLuminance)
		);
	return inColour / inColourLuminance * outColourLuminance;
}

// Third tonemapper of mine, based on the one above
vec3 tachy3(vec3 inColour, float maxLuminance) {
	return inColour / maxLuminance;
}

vec3 finalMaybe(vec3 inColour, float maxLuminance, float averageLuminance) {
	float inColourLuminance = dot(inColour, vec3(0.2126, 0.7152, 0.0722));
	float k = 1.0;
	float lWhite = maxLuminance * maxLuminance;
	float l = k / averageLuminance * inColourLuminance;
	float ld = l * (1.0 + l / lWhite) / (1.0 + l);

	vec3 xyY = rgb2xyY(inColour);
	xyY.z = ld;
	return xyY2rgb(xyY);
	// return inColour / inColourLuminance * ld;
}

uniform sampler2D eyeAdaptationCanvas;

uniform sampler2D atmosphereLightCanvas;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	// float maxLuminance = max(0.0, Texel(maxLuminanceCanvas, vec2(0.5)).r);
	float maxLuminance = Texel(eyeAdaptationCanvas, vec2(0.0, 0.5)).r;
	maxLuminance = maxLuminance == 0.0 ? 1.0 : maxLuminance;

	// float averageLuminance = max(0.0, Texel(averageLuminanceCanvas, vec2(0.5)).r);
	float averageLuminance = Texel(eyeAdaptationCanvas, vec2(1.0, 0.5)).r;
	averageLuminance = averageLuminance == 0.0 ? 0.5 : averageLuminance;

	vec4 inSampleSolid = Texel(image, textureCoords);
	vec4 inSampleAtmosphere = Texel(atmosphereLightCanvas, textureCoords);
	vec3 inColour =
		(inSampleSolid.a >= 0.0 ? inSampleSolid.rgb : maxLuminance * inSampleSolid.rgb)
		+ inSampleAtmosphere.rgb;

	// vec3 outColour = tachy2(inColour, maxLuminance, averageLuminance, 1.0, 0.5);
	vec3 outColour = tachy3(inColour, maxLuminance);

	return vec4(outColour, 1.0);
}
