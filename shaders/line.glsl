varying vec3 fragmentPosition;
varying vec3 fragmentColour;
varying vec4 loveColour;

#ifdef VERTEX

uniform mat4 modelToWorld;
uniform mat4 modelToClip;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	loveColour = ConstantColor;
	fragmentPosition = (modelToWorld * vertexPosition).xyz; // w should be 1 so no division needed
	return modelToClip * vertexPosition;
}

#endif

#ifdef PIXEL

uniform bool negativeAlpha;

void effect() {
	love_Canvases[0] = vec4(VaryingColor.rgb, negativeAlpha ? -1.0 : 1.0); // lightCanvas (negative alpha means "multiply by max luminance in scene")
	love_Canvases[1] = vec4(fragmentPosition, 1.0); // positionCanvas
}

#endif
