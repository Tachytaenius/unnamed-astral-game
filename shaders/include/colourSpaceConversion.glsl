#line 1

// Some of these are ported from https://www.chilliant.com/rgb2hsv.html

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

const mat3 rgb2xyz = mat3(
	0.4124, 0.3576, 0.1805,
	0.2126, 0.7152, 0.0722,
	0.0193, 0.1192, 0.9505
);

vec3 rgb2xyY(vec3 rgb) {
	vec3 xyz = rgb2xyz * rgb;

	// xyz to xyY
	float sum = xyz.x + xyz.y + xyz.z;
	return vec3(
		xyz.x / sum,
		xyz.y / sum,
		xyz.y
	);
}

const mat3 xyz2rgb = mat3(
	 3.2406, -1.5372, -0.4986,
	-0.9689,  1.8758,  0.0415,
	 0.0557, -0.2040,  1.0570
);

vec3 xyY2rgb(vec3 xyY) {
	float zDivY = xyY.z / xyY.y;
	vec3 xyz = vec3(
		zDivY * xyY.x,
		xyY.z,
		zDivY * (1.0 - xyY.x - xyY.y)
	);

	return xyz2rgb * xyz;
}
