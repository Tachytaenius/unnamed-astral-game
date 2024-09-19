varying float fadeMultiplier;
varying vec3 colour;

#ifdef VERTEX

// uniform vec3 direction;
attribute vec3 InstanceDirection;
attribute vec3 InstanceColour;

// Both depend on angular radius
uniform float diskDistanceToSphere;
uniform float scale;

uniform vec3 cameraUp;
uniform mat4 worldToClip;

attribute float VertexFade;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	fadeMultiplier = 1.0 - VertexFade;
	colour = InstanceColour;

	// TODO: Handle singularities
	vec3 billboardRight = cross(cameraUp, InstanceDirection);
	vec3 billboardUp = cross(InstanceDirection, billboardRight);
	vec3 centre = InstanceDirection * (1.0 - diskDistanceToSphere);
	vec3 celestialSpherePos = centre + scale * (billboardRight * vertexPosition.x + billboardUp * vertexPosition.y);
	return worldToClip * vec4(celestialSpherePos, 1.0);
}

#endif

#ifdef PIXEL

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	// Expects additive mode
	return vec4(fadeMultiplier * colour, 1.0);
}

#endif
