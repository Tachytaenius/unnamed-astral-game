varying vec3 fragmentPosition;

#ifdef VERTEX

uniform bool useStartAndOffset;
uniform mat4 modelToWorld;
uniform vec3 lineStart;
uniform vec3 lineOffset;

uniform mat4 worldToClip;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	if (useStartAndOffset) {
		// In this case the intent is to be using the line mesh, which has 0,0,0 or 1,1,1 as its vertices
		fragmentPosition = lineStart + lineOffset * vertexPosition.xyz;
	} else {
		fragmentPosition = (modelToWorld * vertexPosition).xyz; // w should be 1 so no division needed
	}
	return worldToClip * vec4(fragmentPosition, 1.0);
}

#endif

#ifdef PIXEL

uniform bool negativeAlpha;

void effect() {
	love_Canvases[0] = vec4(VaryingColor.rgb, negativeAlpha ? -1.0 : 1.0); // lightCanvas (negative alpha means "use raw without tonemapping")
	love_Canvases[1] = vec4(fragmentPosition, 1.0); // positionCanvas
}

#endif
