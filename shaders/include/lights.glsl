#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires const int maxLights defined
// Requires const int maxSpheres defined
// Requires const int maxRings defined

const float tau = 6.28318530718;

struct ConvexRaycastResult {
	bool hit;
	float t1;
	float t2;
};
const ConvexRaycastResult convexRaycastMiss = ConvexRaycastResult (false, 0.0, 0.0);

struct PlaneRaycastResult {
	bool hit;
	float t;
};
const PlaneRaycastResult planeRaycastMiss = PlaneRaycastResult (false, 0.0);

PlaneRaycastResult planeRaycast(vec3 planeNormal, vec3 planeCentre, vec3 rayStart, vec3 rayDirection) {
	float denom = dot(planeNormal, rayDirection);
	if (denom != 0.0) {
		float t = dot(planeCentre - rayStart, planeNormal / denom);
		return PlaneRaycastResult (true, t);
	}
	return planeRaycastMiss;
}

ConvexRaycastResult sphereRaycast(vec3 spherePosition, float sphereRadius, vec3 rayStart, vec3 rayEnd) {
	if (rayStart == rayEnd) {
		return convexRaycastMiss;
	}

	vec3 startToEnd = rayEnd - rayStart;
	vec3 sphereToStart = rayStart - spherePosition;

	float a = dot(startToEnd, startToEnd);
	float b = 2.0 * dot(sphereToStart, startToEnd);
	float c = dot(sphereToStart, sphereToStart) - pow(sphereRadius, 2.0);
	float h = pow(b, 2.0) - 4.0 * a * c;
	if (h < 0.0) {
		return convexRaycastMiss;
	}
	float t1 = (-b - sqrt(h)) / (2.0 * a);
	float t2 = (-b + sqrt(h)) / (2.0 * a);
	return ConvexRaycastResult (true, t1, t2);
}

// Like the sphereRaycast, but rayDirection is a direction (it's relative to the start, and it must be normalised). The return t's are in terms of actual distances. Inputting a non-normalised vector into direction breaks this function.
// This one doesn't break due to precision issues.
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

struct Light {
	vec3 position;
	vec3 colour;
};

struct Sphere {
	vec3 position;
	float radius;
};

struct Ring {
	vec3 planeNormal;
	vec3 ringCentre;
	float startDistance; // On the plane, from the centre
	float endDistance;
	float noiseCFrequency; // The noise that causes gaps
	float discardThreshold; // How much gaps form
};

uniform int lightCount;
uniform Light[maxLights] lights;

uniform int sphereCount;
uniform Sphere[maxSpheres] spheres;

uniform int ringCount;
uniform Ring[maxRings] rings;

bool shadowCast(Light light, vec3 pointPosition) {
	vec3 difference = light.position - pointPosition;
	float dist = length(difference);
	vec3 direction = difference / dist;
	for (int j = 0; j < sphereCount; j++) {
		Sphere sphere = spheres[j];
		ConvexRaycastResult result = sphereRaycast2(sphere.position, sphere.radius, pointPosition, direction);
		if (result.hit && result.t2 >= 0.0 && result.t1 <= dist) { // If the sun is sufficiently far away that float precision can't tell that a planet on the other side of the sun isn't creating a shadow, it might cast a shadow. But such faraway bodies shouldn't be part of the shadow spheres list
			return true;
		}
	}
	for (int j = 0; j < ringCount; j++) {
		Ring ring = rings[j];
		PlaneRaycastResult result = planeRaycast(ring.planeNormal, ring.ringCentre, pointPosition, direction);
		if (!result.hit || result.t < 0.0 || result.t > dist) {
			continue;
		}
		// The plane is in the way, is the ring that lies on it also in the way?
		vec3 planePosition = pointPosition + direction * result.t;
		float ringOutDistance = distance(planePosition, ring.ringCentre);
		if (ringOutDistance < ring.startDistance || ringOutDistance > ring.endDistance) {
			continue;
		}
		// Check for gaps with discard noise (make sure this code is consistent with the ring rendering in ring.glsl)
		float progress = (ringOutDistance - ring.startDistance) / (ring.endDistance - ring.startDistance);
		float noiseC = snoise(vec3(0.0, 0.0, progress * ring.noiseCFrequency)) * 0.5 + 0.5; // Might be a bit above 1 or below 0
		if (min(1.0, noiseC) < ring.discardThreshold) { // min with 1 to ensure that it always discards if threshold is 1
			continue; // Instead of discard!
		}
		return true;
	}
	return false;
}

vec3 getAverageFormShadowAndColourAtPointNormal(vec3 pointPosition, vec3 pointNormal) {
	vec3 preDivide = vec3(0.0);
		float total = 0.0;
		for (int i = 0; i < lightCount; i++) {
			Light light = lights[i];
			if (shadowCast(light, pointPosition)) {
				continue;
			}
			vec3 lightDirection = normalize(light.position - pointPosition);
			float value = max(0.0, dot(lightDirection, pointNormal));
			preDivide += value * light.colour;
			total++;
		}
		return total > 0.0 ? preDivide / total : vec3(0.0);
}

vec3 getAverageLightColourAtPoint(vec3 pointPosition) {
	vec3 preDivide = vec3(0.0);
	float total = 0.0;
	for (int i = 0; i < lightCount; i++) {
		Light light = lights[i];
		if (shadowCast(light, pointPosition)) {
			continue;
		}
		preDivide += light.colour;
		total++;
	}
	return total > 0.0 ? preDivide / total : vec3(0.0);
}
