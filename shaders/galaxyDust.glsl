#line 1

// Requires include/galaxyDustFunction.glsl concatenated
// Requires include/skyDirection.glsl concatenated

uniform vec3 cameraPosition;
uniform float rayStepCount;

#ifdef PIXEL

struct ConvexRaycastResult {
	bool hit;
	float t1;
	float t2;
};
const ConvexRaycastResult convexRaycastMiss = ConvexRaycastResult (false, 0.0, 0.0);

ConvexRaycastResult sphereRaycast2(vec3 spherePosition, float sphereRadius, vec3 rayStart, vec3 rayDirection) {
	vec3 sphereToStart = rayStart - spherePosition;
	float b = dot(sphereToStart, rayDirection);
	vec3 qc = sphereToStart - b * rayDirection;
	float h = sphereRadius * sphereRadius - dot(qc, qc);
	if (h < 0.0) {
		return convexRaycastMiss;
	}
	float sqrtH = sqrt(h);
	float t1 = -b - sqrtH;
	float t2 = -b + sqrtH;
	return ConvexRaycastResult (true, t1, t2);
}

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	direction.y *= -1.0; // I have no idea
	
	ConvexRaycastResult result = sphereRaycast2(vec3(0.0), galaxyRadius, cameraPosition, direction);
	float t1 = result.t1;
	float t2 = result.t2;
	if (!result.hit || t2 <= 0.0) {
		return vec4(vec3(0.0), 1.0);
	}
	t1 = max(t1, 0.0);

	vec3 totalIncomingLight = vec3(0.0);
	float totalTransmittance = 1.0;
	float stepSize = (t2 - t1) / rayStepCount;
	for (float i = rayStepCount - 1.0; i >= 0.0; i--) {
		float sampleDistance = mix(t1, t2, i / rayStepCount); // AKA t, since direction has a length of 1
		vec3 samplePosition = mix(cameraPosition, cameraPosition + direction, sampleDistance);
		GalaxyDustSample sample = sampleGalaxy(samplePosition);
		
		float extinction = sample.absorption + sample.scatterance;

		float transmittanceThisStep = exp(-extinction * stepSize);
		vec3 incomingLightThisStep = sample.colour * stepSize * sample.emission;

		totalIncomingLight *= transmittanceThisStep;
		totalIncomingLight += incomingLightThisStep;
		totalTransmittance *= transmittanceThisStep;
	}

	return vec4(totalIncomingLight, 1.0 - totalTransmittance);
}

#endif
