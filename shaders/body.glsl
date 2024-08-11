#line 1

// Requires include/lights.glsl concatenated

varying vec3 fragmentPosition;
varying vec3 fragmentNormal;
varying vec2 fragmentTextureCoord;

#ifdef VERTEX

uniform mat4 modelToWorld;
uniform mat4 modelToClip;
uniform mat3 modelToWorldNormal;

attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	fragmentNormal = normalize(modelToWorldNormal * VertexNormal);
	fragmentTextureCoord = VertexTexCoord.st;
	fragmentPosition = (modelToWorld * vertexPosition).xyz; // w should be 1 so no division needed
	return modelToClip * vertexPosition;
}

#endif

#ifdef PIXEL

void effect() {
	vec3 albedo = vec3(1.0); // TEMP
	vec3 totalLight = getLightAtPointNormal(fragmentPosition, fragmentNormal);

	love_Canvases[0] = vec4(albedo * totalLight, 1.0); // lightCanvas
	love_Canvases[1] = vec4(fragmentPosition, 1.0); // positionCanvas
}

#endif
