#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/skyDirection.glsl concatenated

uniform vec3 featureDirection;
uniform float angularRadius;
uniform float depth;
uniform float power;
uniform float centreAngularRadius;
uniform float centreHeight;
uniform float centrePower;
uniform float wallWidthRampUp;
uniform float wallWidthRampDown;
uniform float wallPeakHeight;
uniform float heightMultiplierNoiseFrequency;
uniform float heightMultiplierNoiseAmplitude;

const float tau = 6.28318530718;

float getAngularDistance(vec3 a, vec3 b) { // Both should be normalised
	return acos(clamp(dot(a, b), -1.0, 1.0)); // Clamp becuase sometimes dot is out of [-1, 1] and then acos returns NaN
}

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);
	float angularDistance = max(0.0, getAngularDistance(direction, featureDirection));

	float heightOffset;
	if (angularDistance < angularRadius) {
		heightOffset = depth * (pow(angularDistance / angularRadius, power) - 1.0);
	} else if (angularDistance < angularRadius + wallWidthRampUp) {
		heightOffset = wallPeakHeight * (1.0 - pow(1.0 - (angularDistance - angularRadius) / wallWidthRampUp, 2.0));
	} else if (angularDistance < angularRadius + wallWidthRampUp + wallWidthRampDown) {
		heightOffset = wallPeakHeight * (cos((tau * (angularDistance - (angularRadius + wallWidthRampUp))) / (2.0 * wallWidthRampDown)) * 0.5 + 0.5);
	} else {
		heightOffset = 0.0;
	}
	heightOffset -= min(0.0, centreHeight * (pow(angularDistance / centreAngularRadius, centrePower) - 1.0));
	
	float heightOffsetMultiplier = (1.0 - snoise(direction * heightMultiplierNoiseFrequency) * 0.5 + 0.5) * heightMultiplierNoiseAmplitude;
	float heightOffsetMultiplied = heightOffset > 0.0 ? heightOffsetMultiplier * heightOffset : heightOffset;

	return vec4(vec3(heightOffsetMultiplied), 1.0);
}
