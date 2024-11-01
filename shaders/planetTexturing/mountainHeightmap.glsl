#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

uniform vec3 featureDirection;
uniform float angularRadius;
uniform float height;

uniform float radiusWarpIterations;
uniform float radiusWarpBase;
uniform float radiusWarpPower;
uniform float radiusWarpLerp;
uniform float radiusWarpFlowerHarshness;
uniform vec3 directionWarpDirection;
uniform float directionWarpMagnitude;

const float tau = 6.28318530718;

float getAngularDistance(vec3 a, vec3 b) { // Both should be normalised
	return acos(clamp(dot(a, b), -1.0, 1.0)); // Clamp becuase sometimes dot is out of [-1, 1] and then acos returns NaN
}

// float flower(float theta, float n) {
// 	return abs(sin(n * theta / 2.0));
// }

float flower(float theta, float n, float harshness) {
	return (sin(n * theta) * 0.5 + 0.5) * harshness + (1.0 - harshness);
}

// So sorry for my hacky slow maths haha

vec3 axisAngleBetweenVectors(vec3 a, vec3 b) {
	float angle = acos(clamp(dot(a, b), -1.0, 1.0));
	vec3 axis = normalize(cross(a, b));
	return angle * axis; // Will be all NaN if cross result was bad
}

vec4 quatFromAxisAngle(vec3 v) {
	vec3 axis = normalize(v);
	float angle = length(v);
	float s = sin(angle / 2.0);
	float c = cos(angle / 2.0);
	return normalize(vec4(axis * s, c));
}

vec3 rotate(vec3 v, vec4 q) {
	vec3 uv = cross(q.xyz, v);
	vec3 uuv = cross(q.xyz, uv);
	return v + ((uv * q.w) + uuv) * 2.0;
}

float mountainNoiseBase(vec3 pos) {
	return snoise(pos) * 0.5 + 0.5;
}

const float gradientStep = 0.0001;
float mountainNoise(vec3 pos, int iterations, float erosionStrength) {
	// Higher erosion on steeper surfaces
	float total = 0.0;
	float weightTotal = 0.0;
	for (int i = 0; i < iterations; i++) {
		float frequency = pow(2.0, i);
		float amplitude = 1.0 / (i + 1.0);
		weightTotal += amplitude;
		float here = mountainNoiseBase(pos * frequency);
		float x = mountainNoiseBase(pos * frequency + vec3(gradientStep, 0.0, 0.0));
		float y = mountainNoiseBase(pos * frequency + vec3(0.0, gradientStep, 0.0));
		float z = mountainNoiseBase(pos * frequency + vec3(0.0, 0.0, gradientStep));
		float steepness = length(here - vec3(x, y, z));
		float influenceMultiplier = 1.0 / (1.0 + erosionStrength * steepness);
		total += influenceMultiplier * amplitude * here;
	}
	return total / weightTotal;
}

vec3 multiplyVectorInDirection(vec3 v, vec3 d, float m) { // d should be normalised
	vec3 parallel = d * dot(v, d);
	vec3 perpendicular = v - parallel;
	vec3 parallelScaled = parallel * m;
	return parallelScaled + perpendicular;
}

const vec3 pole = vec3(0.0, 0.0, 1.0);

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	vec3 directionWarped = normalize(multiplyVectorInDirection(direction, directionWarpDirection, directionWarpMagnitude));
	
	float angularDistance = max(0.0, getAngularDistance(directionWarped, featureDirection));

	vec3 fromPeakToPole = axisAngleBetweenVectors(featureDirection, pole);
	bool tooCloseToPole = isinf(fromPeakToPole.x);
	vec3 directionRotated = tooCloseToPole ? directionWarped : rotate( // Might be handled "wrong" for the opposite pole but it doesn't matter, since mountains are static anyway
		directionWarped,
		quatFromAxisAngle(
			fromPeakToPole
		)
	);
	float theta = atan(directionRotated.y, directionRotated.x);

	float warpedRadius = 0.0;
	for (float n = 1.0; n <= radiusWarpIterations; n++) {
		float thetaAdd = tau * (
			(n - 1.0 + pow(n, radiusWarpPower) + pow(radiusWarpBase, n))
			/ (radiusWarpIterations - 1.0)
		);
		warpedRadius += flower(theta + thetaAdd, n, radiusWarpFlowerHarshness);
	}
	warpedRadius /= radiusWarpIterations;
	// float modifiedRadiusWarpLerp = mix(radiusWarpLerp * 4.0, 0.0, min(1.0, pow(max(0.0, 1.0 - angularDistance / (warpedRadius * 0.8)), 1.0)));
	float modifiedAngularRadius = angularRadius * mix(
		1.0, // Perfect circle
		warpedRadius,
		radiusWarpLerp // Lerp between perfect circle and raggedy radius stuff
	);

	float heightOffset = height * (angularDistance < modifiedAngularRadius ? (
		(cos(tau * angularDistance / (2.0 * modifiedAngularRadius)) * 0.5 + 0.5)
		* (1.0 - pow(angularDistance / angularRadius, 2.0))
		* (1.0 - angularDistance / angularRadius)

		* mountainNoise(directionWarped * 5.0, 4, height * 2.0)
	) : 0.0);

	return vec4(vec3(heightOffset), 1.0);
}
