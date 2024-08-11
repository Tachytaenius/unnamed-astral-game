#line 1

// Ported from https://www.chilliant.com/rgb2hsv.html

const float colourSpaceConversionEpsilon = 1e-10; // Avoid redefinition

vec3 hue2rgb(float hue) {
	return clamp(
		vec3(
			abs(hue * 6.0 - 3.0) - 1.0,
			2.0 - abs(hue * 6.0 - 2.0),
			2.0 - abs(hue * 6.0 - 4.0)
		),
		0.0, 1.0
	);
}

vec3 rgb2hcv(vec3 rgb) {
	// Based on work by Sam Hocevar and Emil Persson
	vec4 p = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0 / 3.0) : vec4(rgb.gb, 0.0, -1.0 / 3.0);
	vec4 q = (rgb.r < p.x) ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
	float c = q.x - min(q.w, q.y);
	float h = abs((q.w - q.y) / (6.0 * c + colourSpaceConversionEpsilon) + q.z);
	return vec3(h, c, q.x);
}

vec3 hsl2rgb(vec3 hsl) {
	vec3 rgb = hue2rgb(hsl.x);
	float c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
	return (rgb - 0.5) * c + hsl.z;
}

vec3 rgb2hsl(vec3 rgb) {
	vec3 hcv = rgb2hcv(rgb);
	float l = hcv.z - hcv.y * 0.5;
	float s = hcv.y / (1.0 - abs(l * 2.0 - 1.0) + colourSpaceConversionEpsilon);
	return vec3(hcv.x, s, l);
}
