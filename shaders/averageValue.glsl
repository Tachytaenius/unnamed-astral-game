uniform vec2 halfTexelSize;
uniform sampler2D valueCanvas;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec2 halfTexelSizeRotated = vec2(halfTexelSize.x, -halfTexelSize.y);
	float a = Texel(valueCanvas, textureCoords + halfTexelSize).r;
	float b = Texel(valueCanvas, textureCoords - halfTexelSize).r;
	float c = Texel(valueCanvas, textureCoords + halfTexelSizeRotated).r;
	float d = Texel(valueCanvas, textureCoords - halfTexelSizeRotated).r;

	// Averaging may not be perfect when considering fragments that have a mix of -1 and accepted fragments
	float valuePreDivide = 0.0;
	float weightTotal = 0.0;
	if (a >= 0.0) {
		weightTotal += 1.0;
		valuePreDivide += a;
	}
	if (b >= 0.0) {
		weightTotal += 1.0;
		valuePreDivide += b;
	}
	if (c >= 0.0) {
		weightTotal += 1.0;
		valuePreDivide += c;
	}
	if (d >= 0.0) {
		weightTotal += 1.0;
		valuePreDivide += d;
	}

	float outValue = weightTotal != 0.0 ? valuePreDivide / weightTotal : -1.0;
	return vec4(vec3(outValue), 1.0);
}
