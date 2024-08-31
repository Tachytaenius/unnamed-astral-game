vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	float alpha = Texel(image, textureCoords).r;
	return vec4(loveColour.rgb, loveColour.a * alpha);
}
