// Optionally, #define INSTANCED

varying float fade;
varying vec3 colour;

#ifdef VERTEX

#ifdef INSTANCED
attribute vec3 InstanceDirection;
attribute vec3 InstanceColour;
#else
uniform vec3 pointDirection;
uniform vec3 pointColour;
#endif

// Both depend on angular radius
uniform float diskDistanceToSphere;
uniform float scale;

uniform vec3 cameraUp;
uniform mat4 worldToClip;

attribute float VertexFade;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	fade = VertexFade;
#ifdef INSTANCED
	colour = InstanceColour;
	vec3 direction = InstanceDirection;
#else
	colour = pointColour;
	vec3 direction = pointDirection;
#endif
	// TODO: Handle singularities
	vec3 billboardRight = cross(cameraUp, direction);
	vec3 billboardUp = cross(direction, billboardRight);
	vec3 centre = direction * (1.0 - diskDistanceToSphere);
	vec3 celestialSpherePos = centre + scale * (billboardRight * vertexPosition.x + billboardUp * vertexPosition.y);
	return worldToClip * vec4(celestialSpherePos, 1.0);
}

#endif

#ifdef PIXEL

uniform float vertexFadePower;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	// Expects additive mode
	float fadeMultiplier = pow(1.0 - fade, vertexFadePower);
	return vec4(fadeMultiplier * colour, 1.0);
}

#endif
