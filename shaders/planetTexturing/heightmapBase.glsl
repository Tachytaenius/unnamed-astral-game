#line 1

// Requires include/lib/worley.glsl concatenated
// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform bool bumps;
uniform float bumpHeight;
uniform float bumpFrequency;

uniform bool valleys;
uniform float valleyDepth;
uniform float valleyDensity;
uniform float valleyWidth;

uniform int seed;

// idk lol i just found this i didnt write it but it works
float snoiseFractal(vec3 m) {
	return   0.5333333* snoise(m)
				+0.2666667* snoise(2.0*m)
				+0.1333333* snoise(4.0*m)
				+0.0666667* snoise(8.0*m);
}

// Idk what to call these functions anymore
// they were originally made for fog but they're useful in many places
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

vec3 multiplyVectorInDirection(vec3 v, vec3 d, float m) { // d should be normalised
	vec3 parallel = d * dot(v, d);
	vec3 perpendicular = v - parallel;
	vec3 parallelScaled = parallel * m;
	return parallelScaled + perpendicular;
}

// Hacked together lol
// Definitely not uniformly distributed
vec3 directionNoise(vec3 pos) {
	return normalize(vec3(
		snoise(pos),
		snoise(pos + 1000.0),
		snoise(pos + 2000.0)
	));
}

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float seedEffect = float(mod(seed, 2)); // Discard half of the information

	float height = 0;

	if (bumps) {
		float heightMultiplierFrequencyMultilpier = (snoise(direction * 2.0 + seedEffect) * 0.5 + 0.5) + 0.5;
		float heightMultiplier = (snoise(direction * 0.75 * heightMultiplierFrequencyMultilpier + seedEffect + 100.0) * 0.5 + 0.5) * 1.0 + 0.0;
		float frequencyMultiplierFrequencyMultiplier = (snoise(direction * 0.4 + seedEffect + 200.0) * 0.5 + 0.5) + 0.5;
		float frequencyMultiplier = (snoise(direction * 0.7 * frequencyMultiplierFrequencyMultiplier + seedEffect + 300.0) * 0.5 + 0.5) * 0.5 + 0.75;
		height += heightMultiplier * bumpHeight * snoise(direction * bumpFrequency * frequencyMultiplier + seedEffect + 400.0);
		height += heightMultiplier * bumpHeight * snoiseFractal(direction * bumpFrequency * frequencyMultiplier + seedEffect + 500.0);
	}

	if (valleys) {
		vec3 directionWarped = multiplyVectorInDirection(
			direction,
			directionNoise(direction * 1.0),
			(snoise(direction * 1.0 + seedEffect + 600.0) * 0.5 + 0.5) * 5.0
		);
		// directionWarped = direction;
		float noiseIn = snoiseFractal(directionWarped * valleyDensity + seedEffect + 700.0) * 0.5 + 0.5;
		float noise = calculateFogFactor(noiseIn, 1.0 - valleyWidth, 0.1) * noiseIn;
		noise = noiseIn;
		height += -valleyDepth * noise * 0.1;

		float valleyWidthMultiplier = (snoise(direction * 15.0 + seedEffect + 800.0) * 0.5 + 0.5) * 0.5 + 0.75;
		float valleyHeightMultiplier = (snoise(direction * 2.0 + seedEffect + 900.0) * 0.5 + 0.5) * 0.5 + 0.75;
		vec2 noiseInBVec = worley2(direction * valleyDensity);
		float nonEdgeAmount = abs(noiseInBVec.x - noiseInBVec.y);
		float effectiveValleyWidth = valleyWidth * valleyWidthMultiplier;
		float noiseB = 1.0 - calculateFogFactor(nonEdgeAmount < effectiveValleyWidth ? 0.0 : 1.0, 1.0 - effectiveValleyWidth, 0.1);
		height += -valleyDepth * valleyHeightMultiplier * noiseB;
	}

	return vec4(vec3(height), 1.0);
}

#endif
