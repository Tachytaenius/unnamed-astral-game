#line 1

// Requires include/lights.glsl concatenated
// Requires include/skyDirection.glsl concatenated

#ifdef PIXEL

uniform int stepsPerRay;
uniform vec3 cameraPosition;
uniform sampler2D positionCanvas;

uniform vec3 atmospherePosition;
uniform float atmosphereRadius;
uniform float baseScatterance;
uniform float baseAbsorption;
uniform float baseEmission;
uniform vec3 atmosphereColour;
uniform float atmosphereDensityPower;
uniform float bodyRadius;

uniform bool starCorona;
uniform samplerCube coronaReductionTexture1;
uniform samplerCube coronaReductionTexture2;
uniform mat3 coronaReductionMatrix1;
uniform mat3 coronaReductionMatrix2;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	ConvexRaycastResult result = sphereRaycast(atmospherePosition, atmosphereRadius, cameraPosition, direction);
	if (!result.hit) {
		discard;
	}
	float t1 = result.t1;
	float t2 = result.t2;
	if (t2 <= 0.0) {
		discard;
	}
	t1 = max(t1, 0.0);
	vec4 objectPostionTexel = Texel(positionCanvas, textureCoords);
	if (objectPostionTexel.a > 0.0) {
		float objectDistance = distance(cameraPosition, objectPostionTexel.xyz);
		t2 = min(t2, objectDistance);
	}
	if (t2 <= t1) {
		discard;
	}

	vec3 totalIncomingLight = vec3(0.0);
	float totalTransmittance = 1.0;
	for (int i = stepsPerRay - 1; i >= 0; i--) {
		float stepSize = (t2 - t1) / float(stepsPerRay);
		float t = mix(t1, t2, float(i) / float(stepsPerRay));
		vec3 samplePosition = cameraPosition + direction * t;

		vec3 difference = samplePosition - atmospherePosition;
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
		float density = pow(
			clamp(1.0 - altitude / (reductionMultiplier * (atmosphereRadius - bodyRadius)), 0.0, 1.0),
			atmosphereDensityPower
		);

		float absorption = baseAbsorption * density;
		float scatterance = baseScatterance * density; // In-scattering is not accounted for
		float emission = baseEmission * density;
		float extinction = absorption + scatterance;

		float transmittanceThisStep = exp(-extinction * stepSize);
		vec3 incomingLightThisStep = atmosphereColour * (stepSize * emission + stepSize * scatterance * getAverageLightColourAtPoint(samplePosition));

		totalIncomingLight *= transmittanceThisStep;
		totalIncomingLight += incomingLightThisStep;
		totalTransmittance *= transmittanceThisStep;
	}

	return vec4(totalIncomingLight, 1.0 - totalTransmittance);
}

#endif
