#line 1

// Requires const int maxLights defined
// Requires const int maxSpheres defined

struct ConvexRaycastResult {
	bool hit;
	float t1;
	float t2;
};
const ConvexRaycastResult convexRaycastMiss = ConvexRaycastResult (false, 0.0, 0.0);

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
	float intensity;
};

struct Sphere {
	vec3 position;
	float radius;
};

uniform int lightCount;
uniform Light[maxLights] lights;

uniform int sphereCount;
uniform Sphere[maxSpheres] spheres;

uniform float maxBrightness;

bool shadowCast(Light light, vec3 pointPosition) {
	for (int j = 0; j < sphereCount; j++) {
		Sphere sphere = spheres[j];
		vec3 difference = pointPosition - light.position;
		float dist = length(difference);
		vec3 direction = difference / dist;
		ConvexRaycastResult result = sphereRaycast2(sphere.position, sphere.radius, light.position, direction);
		if (result.hit && 0.0 <= result.t1 && result.t1 <= dist) {
			return true;
		}
	}
	return false;
}

vec3 getLightAtPoint(vec3 pointPosition) {
	vec3 ret = vec3(0.0);
	for (int i = 0; i < lightCount; i++) {
		Light light = lights[i];
		if (shadowCast(light, pointPosition)) {
			continue;
		}
		vec3 difference = pointPosition - light.position;
		float brightness = light.intensity * 1.0 / dot(difference, difference); // Inverse square law
		brightness = min(maxBrightness, brightness);
		ret += brightness * light.colour;
	}
	return ret;
}

vec3 getLightAtPointNormal(vec3 pointPosition, vec3 pointNormal) {
	vec3 ret = vec3(0.0);
	for (int i = 0; i < lightCount; i++) {
		Light light = lights[i];
		if (shadowCast(light, pointPosition)) {
			continue;
		}
		vec3 difference = pointPosition - light.position;
		float brightness = light.intensity * 1.0 / dot(difference, difference); // Inverse square law
		brightness = min(maxBrightness, brightness);
		brightness *= max(0.0, dot(-normalize(difference), pointNormal));
		ret += brightness * light.colour;
	}
	return ret;
}
