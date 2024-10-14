#line 1

// Requires include/lights.glsl concatenated
// Requires include/lib/simplex3d.glsl concatenated

varying vec3 fragmentPosition;
// varying vec3 fragmentNormal;

#ifdef VERTEX

uniform mat4 modelToWorld;
uniform mat4 modelToClip;
// uniform mat3 modelToWorldNormal;

// attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	fragmentPosition = (modelToWorld * vertexPosition).xyz; // w should be 1 so no division needed
	// fragmentNormal = normalize(modelToWorldNormal * VertexNormal);
	return modelToClip * vertexPosition;
}

#endif

#ifdef PIXEL

uniform vec3 ringCentre;
uniform float startDistance;
uniform float endDistance;

uniform vec3[4] colours;
uniform float noiseAFrequency;
uniform float noiseBFrequency;
uniform float noiseCFrequency;
uniform float discardThreshold;

uniform vec3 cameraPosition;

void effect() {
	float dist = distance(ringCentre, fragmentPosition);
	if (startDistance > dist || dist > endDistance) {
		discard;
	}
	float progress = (dist - startDistance) / (endDistance - startDistance);

	// Make sure this code is consistent with the shadow casting in lights.glsl
	float noiseC = snoise(vec3(0.0, 0.0, progress * noiseCFrequency)) * 0.5 + 0.5; // Might be a bit above 1 or below 0
	if (min(1.0, noiseC) < discardThreshold) { // min with 1 to ensure that it always discards if threshold is 1
		discard;
	}

	float noiseA = snoise(vec3(progress * noiseAFrequency, 0.0, 0.0)) * 0.5 + 0.5;
	float noiseB = snoise(vec3(0.0, progress * noiseBFrequency, 0.0)) * 0.5 + 0.5;
	vec3 outColour = mix(
		mix(colours[0], colours[1], noiseA),
		mix(colours[2], colours[3], noiseA),
		noiseB
	);

	// vec3 doubleSidedNormal = gl_FrontFacing ? -fragmentNormal : fragmentNormal;
	vec3 totalLight = getAverageLightColourAtPoint(fragmentPosition) * 0.5; // Times a half because it's like a mix of lots of differently-aligned surfaces (asteroids or ice or whatever)

	love_Canvases[0] = vec4(outColour * totalLight, 1.0);
	love_Canvases[1] = vec4(fragmentPosition, 1.0);
}

#endif
