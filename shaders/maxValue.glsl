uniform vec2 halfTexelSize;
uniform sampler2D valueCanvas;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec2 halfTexelSizeRotated = vec2(halfTexelSize.x, -halfTexelSize.y);
	float a = Texel(valueCanvas, textureCoords + halfTexelSize).r;
	float b = Texel(valueCanvas, textureCoords - halfTexelSize).r;
	float c = Texel(valueCanvas, textureCoords + halfTexelSizeRotated).r;
	float d = Texel(valueCanvas, textureCoords - halfTexelSizeRotated).r;

	float outValue = max(
		max(a, b),
		max(c, d)
	);
	return vec4(vec3(outValue), 1.0);
}
