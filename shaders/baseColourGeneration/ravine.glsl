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
uniform vec3 ravineRotation; // Axis-angle vector from start to end

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	// TEMP: angular distance to start of ravine
	float dotResult = dot(direction, ravineStart);
	float dotResultClamped = clamp(dotResult, -1.0, 1.0); // Clamping because, at least on the CPU, sometimes precision would cause dot to return a result outside of [-1, 1], breaking acos
	float angularDistance = abs(acos(dotResultClamped));
	float ravineAngularRadiusTEMP = 0.1;
	float ravineOutlineFadeAngularLengthTEMP = 0.05;

	float alpha = 1.0 - min(1.0, max(0.0, angularDistance - ravineAngularRadiusTEMP) / ravineOutlineFadeAngularLengthTEMP);
	vec3 outColour = vec3(0.0);

	return vec4(vec3(outColour), alpha);
}

#endif
