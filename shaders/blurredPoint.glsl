#pragma language glsl4
#line 2

// Optionally, define INSTANCED

varying float fade;
varying vec3 colour;

#ifdef VERTEX

#ifdef INSTANCED
struct StarDrawable {
	vec3 direction;
	vec3 incomingLight;
};
readonly buffer StarDrawables {
	StarDrawable starDrawables[];
};
#else
uniform vec3 pointDirection;
uniform vec3 pointIncomingLight;
#endif

// Both depend on angular radius
uniform float diskDistanceToSphere;
uniform float scale;

uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform mat4 worldToClip;

layout (location = 0) in vec2 VertexPosition;
layout (location = 1) in float VertexFade;

void vertexmain() {
	fade = VertexFade;
#ifdef INSTANCED
	StarDrawable starDrawable = starDrawables[gl_InstanceID];
	colour = starDrawable.incomingLight;
	vec3 direction = starDrawable.direction;
#else
	colour = pointIncomingLight;
	vec3 direction = pointDirection;
#endif
	vec3 billboardRight = cross(cameraUp, direction);
	if (length(billboardRight) == 0.0) {
		// Singularity
		billboardRight = cameraRight;
	}
	vec3 billboardUp = cross(direction, billboardRight);
	vec3 centre = direction * (1.0 - diskDistanceToSphere);
	vec3 celestialSpherePos = centre + scale * (billboardRight * VertexPosition.x + billboardUp * VertexPosition.y);
	gl_Position = worldToClip * vec4(celestialSpherePos, 1.0);
}

#endif

#ifdef PIXEL

uniform float vertexFadePower;

out vec4 outColour;

void pixelmain() {
	// Expects additive mode
	float fadeMultiplier = pow(1.0 - fade, vertexFadePower);
	outColour = vec4(fadeMultiplier * colour, 1.0);
}

#endif
