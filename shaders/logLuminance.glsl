uniform float delta;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	float inValue = Texel(image, textureCoords).r;
	float outValue;
	if (inValue < 0.0) {
		outValue = -1.0;
	} else {
		outValue = log(inValue + delta);
	}
	return vec4(vec3(outValue), 1.0);
}
