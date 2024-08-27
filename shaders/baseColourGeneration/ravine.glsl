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

uniform float ravineWidth;
uniform vec3 ravineStart; // Should be normalised
uniform vec3 ravineEnd; // Also meant to be normalised
uniform vec3 ravineColour;
uniform float ravineAlphaMultiplier;
uniform float ravineOutlineFadeAngularLength;

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

	float ravineTotalAngle = getAngularDistance(ravineStart, ravineEnd);
	// If the "equator" is the great circle from ravine start to ravine end
	vec3 pole = normalize(cross(ravineStart, ravineEnd));
	float longitudeByStart = getAngularDistance(direction, ravineStart); // If prime meridian passes through the ravine start
	float longitudeByEnd = getAngularDistance(direction, ravineEnd); // Or end

	// HACK to get rid of broken double image
	vec3 midpoint = slerp(ravineStart, ravineEnd, 0.5);
	if (getAngularDistance(direction, midpoint) > tau / 4.0) {
		discard;
	}

	float angularDistance;
	if (longitudeByStart > ravineTotalAngle) {
		angularDistance = getAngularDistance(direction, ravineEnd);
	} else if (longitudeByEnd > ravineTotalAngle) {
		angularDistance = getAngularDistance(direction, ravineStart);
	} else {
		angularDistance = abs(asin(clamp(dot(direction, pole), -1.0, 1.0)));
	}

	float effectiveRavineWidth = ravineWidth * min(longitudeByStart, longitudeByEnd) / (ravineTotalAngle / 2.0);
	float alpha = 1.0 - min(1.0, max(0.0, angularDistance - effectiveRavineWidth) / ravineOutlineFadeAngularLength);
	vec3 outColour = vec3(ravineColour);

	return vec4(vec3(outColour), alpha * ravineAlphaMultiplier);
}

#endif
