#line 1

// Requires include/simplex3d.glsl concatenated
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

uniform float angularWidth;
uniform vec3 startPoint; // Should be normalised
uniform vec3 endPoint; // Also meant to be normalised
uniform float alphaMultiplier;
uniform float edgeFadeAngularLength;
uniform bool outputAlpha;

// Clamping before inputting to inverse trig functions in case of values outside of [-1, 1], which would produce an invalid result
// NOTE: There's a decent amount of wasted computation here, I'd reckon.

float getAngularDistance(vec3 a, vec3 b) { // Both should be normalised
	return acos(clamp(dot(a, b), -1.0, 1.0));
}

vec3 slerp(vec3 a, vec3 b, float t) {
	float omega = getAngularDistance(a, b);
	float sinOmega = sin(omega);
	return sin((1.0 - t) * omega) / sinOmega * a + sin(t * omega) / sinOmega * b;
}

const float tau = 6.28318530718;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	float totalAngle = getAngularDistance(startPoint, endPoint);
	// If the "equator" is the great circle from start to end
	vec3 pole = normalize(cross(startPoint, endPoint));
	float longitudeByStart = getAngularDistance(direction, startPoint); // If prime meridian passes through the start
	float longitudeByEnd = getAngularDistance(direction, endPoint); // Or end

	// HACK to get rid of broken double image
	vec3 midpoint = slerp(startPoint, endPoint, 0.5);
	if (getAngularDistance(direction, midpoint) > tau / 4.0) {
		discard;
	}

	float angularDistance;
	if (longitudeByStart > totalAngle) {
		angularDistance = getAngularDistance(direction, endPoint);
	} else if (longitudeByEnd > totalAngle) {
		angularDistance = getAngularDistance(direction, startPoint);
	} else {
		angularDistance = abs(asin(clamp(dot(direction, pole), -1.0, 1.0)));
	}

	float removalNoise = 0.4 * pow(snoise(direction * 60.0) * 0.5 + 0.5, 1.0);

	float effectiveAngularWidth = angularWidth * min(longitudeByStart, longitudeByEnd) / (totalAngle / 2.0);
	float alpha = 1.0 - min(1.0, max(0.0, angularDistance - effectiveAngularWidth) / edgeFadeAngularLength - removalNoise);

	if (outputAlpha) {
		return vec4(vec3(alpha), 1.0);
	} else {
		return vec4(loveColour.rgb, loveColour.a * alphaMultiplier);
	}
}

#endif
