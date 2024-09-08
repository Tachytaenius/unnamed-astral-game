#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

float calculateFogFactor(float dist, float maxDist, float fogFadeLength) { // More fog the further you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return dist < maxDist ? 0.0 : 1.0;
	}
	return clamp((dist - maxDist + fogFadeLength) / fogFadeLength, 0.0, 1.0);
}

float calculateFogFactor2(float dist, float fogFadeLength) { // More fog the closer you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return 1.0; // Immediate fog
	}
	return clamp(1 - dist / fogFadeLength, 0.0, 1.0);
}

uniform float angularRadius;
uniform vec3 location; // Should be normalised
uniform float noisiness;
uniform float alphaMultiplier;
uniform float edgeFadeAngularLength;
uniform bool outputAlpha;

// Clamping before inputting to inverse trig functions in case of values outside of [-1, 1], which would produce an invalid result

float getAngularDistance(vec3 a, vec3 b) { // Both should be normalised
	return acos(clamp(dot(a, b), -1.0, 1.0));
}

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float angularDistance = getAngularDistance(location, direction);
	float removalNoise = noisiness * pow(snoise(direction * 60.0) * 0.5 + 0.5, 1.0);
	float alpha = 1.0 - min(1.0, max(0.0, angularDistance - angularRadius) / edgeFadeAngularLength - removalNoise);

	if (outputAlpha) {
		return vec4(vec3(alpha), 1.0);
	} else {
		return vec4(loveColour.rgb, loveColour.a * alphaMultiplier);
	}
}

#endif
