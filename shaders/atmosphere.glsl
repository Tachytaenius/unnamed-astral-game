#line 1

// Requires include/lights.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform sampler2D positionCanvas;
uniform vec3 cameraPosition;
uniform float rayStepCount;

uniform vec3 bodyPosition;
uniform float bodyRadius;
uniform float densityPower;
uniform float atmosphereRadius;
uniform float atmosphereDensity;
uniform float atmosphereEmissiveness;

uniform bool fullLightingCalculation;

uniform bool starCorona;
uniform samplerCube coronaReductionTexture1;
uniform samplerCube coronaReductionTexture2;
uniform mat3 coronaReductionMatrix1;
uniform mat3 coronaReductionMatrix2;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	float objectDistance;
	bool facingSky;
	vec4 objectPostionTexel = Texel(positionCanvas, textureCoords);
	if (objectPostionTexel.a > 0.0) {
		objectDistance = distance(cameraPosition, objectPostionTexel.xyz);
		facingSky = false;
	} else {
		facingSky = true;
	}

	vec3 outColour = vec3(0.0);

	// Sphere raycast, but ray start to end is normalised (it's direction)
	vec3 sphereToStart = cameraPosition - bodyPosition;
	float b = 2.0 * dot(sphereToStart, direction);
	float c = dot(sphereToStart, sphereToStart) - pow(atmosphereRadius, 2.0);
	float h = pow(b, 2.0) - 4.0 * c;
	if (h < 0.0) {
		discard;
	}
	float t1 = (-b - sqrt(h)) / 2.0;
	float t2 = (-b + sqrt(h)) / 2.0;
	if (t2 <= 0.0) {
		discard;
	}
	t1 = max(t1, 0.0);
	if (!facingSky) {
		t2 = min(t2, objectDistance);
	}
	if (t2 <= t1) {
		discard;
	}

	float stepSize = (t2 - t1) / rayStepCount; // direction's length is 1
	for (float i = 0.0; i < rayStepCount; i++) {
		float t = mix(t1, t2, i / rayStepCount);
		vec3 samplePosition = cameraPosition + direction * t;
		vec3 difference = samplePosition - bodyPosition;
		float altitude = length(difference) - bodyRadius;
		float reductionMultiplier;
		if (!starCorona) {
			reductionMultiplier = 1.0;
		} else {
			reductionMultiplier = 1.0 - (
				0.2 * Texel(coronaReductionTexture1, coronaReductionMatrix1 * difference).r +
				0.1 * Texel(coronaReductionTexture2, coronaReductionMatrix2 * difference).r
			);
		}
		float densityMultiplier = pow(
			clamp(1.0 - altitude / (reductionMultiplier * (atmosphereRadius - bodyRadius)), 0.0, 1.0),
			densityPower
		);
		// TODO: Work out units here and just reorganise this a bit
		vec3 sampleBaseColour = loveColour.rgb * atmosphereDensity * densityMultiplier;
		vec3 incomingLight;
		if (fullLightingCalculation) {
			incomingLight = getLightAtPoint(samplePosition);
		} else {
			incomingLight = getAverageLightColourAtPoint(samplePosition);
		}
		vec3 sample = sampleBaseColour * (incomingLight + atmosphereEmissiveness);
		outColour += sample * stepSize;
	}

	return vec4(outColour, 1.0);
}

#endif
