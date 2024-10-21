#line 1

// Requires include/galaxyDustFunction.glsl concatenated

struct Star {
	vec3 position;
	vec3 incomingLightPreExtinction;
};
readonly buffer Stars {
	Star stars[];
};

struct StarDrawable {
	vec3 direction;
	vec3 incomingLight;
};
buffer StarDrawables {
	StarDrawable starDrawables[];
};

uniform uint starCount;
uniform vec3 cameraPosition;
uniform float rayStepCount;

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

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
	uint i = love_GlobalThreadID.x;
	if (i >= starCount) {
		return;
	}

	Star star = stars[i];
	vec3 difference = star.position - cameraPosition;
	float starDistance = length(difference);
	vec3 direction = difference / starDistance;

	ConvexRaycastResult result = sphereRaycast2(vec3(0.0), galaxyRadius, cameraPosition, direction);
	float t1 = result.t1;
	float t2 = result.t2;
	if (!result.hit || t2 <= 0.0) {
		return;
	}
	t1 = max(t1, 0.0);
	t2 = min(t2, starDistance);
	if (t2 <= t1) {
		return;
	}

	float totalTransmittance = 1.0;
	float stepSize = (t2 - t1) / rayStepCount;
	for (float i = rayStepCount - 1.0; i >= 0.0; i--) {
		float sampleDistance = mix(t1, t2, i / rayStepCount);
		vec3 samplePosition = mix(cameraPosition, cameraPosition + direction, sampleDistance);
		GalaxyDustSample dustSample = sampleGalaxy(samplePosition);
		float extinction = dustSample.absorption + dustSample.scatterance;
		float transmittanceThisStep = exp(-extinction * stepSize);
		totalTransmittance *= transmittanceThisStep;
	}

	StarDrawable starDrawable = StarDrawable (
		direction,
		star.incomingLightPreExtinction * totalTransmittance
	);
	starDrawables[i] = starDrawable;
}
