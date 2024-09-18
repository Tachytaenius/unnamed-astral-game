varying float fadeMultiplier;

#ifdef VERTEX

uniform vec3 cameraUp;
uniform vec3 direction;
uniform float diskDistanceToSphere;
uniform float scale;
uniform mat4 worldToClip;

attribute float VertexFade;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	fadeMultiplier = 1.0 - VertexFade;

	// TODO: Handle singularities
	vec3 billboardRight = cross(cameraUp, direction);
	vec3 billboardUp = cross(direction, billboardRight);
	vec3 centre = direction * (1.0 - diskDistanceToSphere);
	vec3 celestialSpherePos = centre + scale * (billboardRight * vertexPosition.x + billboardUp * vertexPosition.y);
	return worldToClip * vec4(celestialSpherePos, 1.0);
}

#endif

#ifdef PIXEL

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	// Expects additive mode
	return vec4(fadeMultiplier * loveColour.rgb * loveColour.a, 1.0);
}

#endif
