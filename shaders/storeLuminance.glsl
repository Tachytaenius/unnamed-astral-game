uniform sampler2D atmosphereLightCanvas;

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec4 sample1 = Texel(image, textureCoords);
	vec3 inColour = (sample1.a >= 0.0 ? sample1.rgb : vec3(0.0)) + Texel(atmosphereLightCanvas, textureCoords).rgb;
	float luminance = dot(inColour, vec3(0.2126, 0.7152, 0.0722));
	return vec4(vec3(
		luminance
		// log(luminance + 1.0)
	), 1.0);
}