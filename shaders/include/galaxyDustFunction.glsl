#line 1

// Requires include/lib/simplex3d.glsl concatenated
// Requires include/colourSpaceConversion.glsl

// uniform float squashDirection; // galaxyForwards
uniform float squashAmount;
uniform float galaxyRadius;
uniform float haloProportion;
uniform vec3 galaxyForwards;
uniform vec3 galaxyUp;
uniform vec3 galaxyRight;
uniform float baseScatterance;
uniform float baseAbsorption;
uniform float baseEmission;
uniform float emissionDensityCurvePower;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

struct GalaxyDustSample {
	vec3 colour;
	float scatterance;
	float absorption;
	float emission;
};

GalaxyDustSample sampleGalaxy(vec3 samplePosition) {
	float haloDensity = max(0.0, 1.0 - length(samplePosition) / galaxyRadius);
	vec3 haloSample = hsl2rgb(vec3(
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
	vec3 diskSample = hsl2rgb(vec3(
		mod(snoise(samplePositionSwirled / galaxyRadius * 2.0) * 0.5 + 0.5 + 0.5, 1.0),
		(snoise((samplePositionSwirled + 2.0) / galaxyRadius * 7.0) * 0.5 + 0.5) * 0.1 + 0.9,
		(snoise((samplePositionSwirled - 2.0) / galaxyRadius * 4.0) * 0.5 + 0.5) * 0.25 + 0.5
	));

	vec3 colour = mix(diskSample, haloSample, haloProportion);
	float density = mix(diskDensity, haloDensity, haloProportion);
	return GalaxyDustSample (
		colour,
		density * baseScatterance,
		density * baseAbsorption,
		pow(density, emissionDensityCurvePower) * baseEmission
	);
}
