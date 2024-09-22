#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated
// Requires include/colourSpaceConversion.glsl

uniform vec3 cameraPosition;
uniform float rayStepCount;
// uniform float squashDirection; // galaxyForwards
uniform float squashAmount;
uniform float galaxyRadius;
uniform float haloProportion;
uniform float sampleBrightnessMultiplier;
uniform vec3 galaxyForwards;
uniform vec3 galaxyUp;
uniform vec3 galaxyRight;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

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
	
	vec3 outColour = vec3(0.0);
	ConvexRaycastResult result = sphereRaycast2(vec3(0.0), galaxyRadius, cameraPosition, direction);
	float t1 = result.t1;
	float t2 = result.t2;
	if (!result.hit || t2 <= 0.0) {
		return vec4(outColour, 1.0);
	}
	t1 = max(t1, 0.0);

	float stepSize = (t2 - t1) / rayStepCount;
	for (float i = 0.0; i < rayStepCount; i++) {
		float sampleDistance = mix(t1, t2, i / rayStepCount); // AKA t, since direction has a length of 1
		vec3 samplePosition = mix(cameraPosition, cameraPosition + direction, sampleDistance);

		float haloDensity = max(0.0, 1.0 - length(samplePosition) / galaxyRadius);
		vec3 haloSample = haloDensity * hsl2rgb(vec3(
			snoise(samplePosition / galaxyRadius * 6.0) * 0.5 + 0.5,
			(snoise((samplePosition + 1.0) / galaxyRadius * 4.0) * 0.5 + 0.5) * 0.25 + 0.5,
			snoise((samplePosition - 1.0) / galaxyRadius * 2.0) * 0.5 + 0.5
		));

		float samplePositionElevation = dot(galaxyForwards, samplePosition);
		vec2 samplePosition2D = vec2(
			dot(galaxyRight, samplePosition),
			dot(galaxyUp, samplePosition)
		);
		vec2 samplePosition2DSwirled = rotate(samplePosition2D, length(samplePosition2D) * 4.0 / galaxyRadius);
		vec3 samplePositionSwirled =
			galaxyRight * samplePosition2D.x +
			galaxyUp * samplePosition2D.y +
			galaxyForwards * samplePositionElevation;

		float galaxyCoreFactor = max(0.0, 1.0 - length(samplePosition) / (galaxyRadius * 0.25) + 0.25);
		float diskDensity =
			mix( // Mix between spiral arms and core with no arms
				pow(
					sin(atan(samplePosition2DSwirled.y, samplePosition2DSwirled.x) * 6.0) * 0.5 + 0.5,
					3.3 * length(samplePosition2D) / galaxyRadius
				),
				1.0,
				galaxyCoreFactor
			)
			* max(0.0, 1.0 - length(
				galaxyRight * samplePosition2D.x +
				galaxyUp * samplePosition2D.y +
				galaxyForwards * samplePositionElevation / squashAmount
			) / galaxyRadius);
		vec3 diskSample = diskDensity * hsl2rgb(vec3(
			mod(snoise(samplePositionSwirled / galaxyRadius * 2.0) * 0.5 + 0.5 + 0.5, 1.0),
			(snoise((samplePositionSwirled + 2.0) / galaxyRadius * 7.0) * 0.5 + 0.5) * 0.1 + 0.9,
			(snoise((samplePositionSwirled - 2.0) / galaxyRadius * 4.0) * 0.5 + 0.5) * 0.25 + 0.5
		));

		vec3 sample = mix(diskSample, haloSample, haloProportion) * sampleBrightnessMultiplier;
		outColour += sample * stepSize;
	}

	return vec4(outColour, 1.0);
}

#endif
