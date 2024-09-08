// Quaternions aren't actually vectors, of course. They're scalars.
// At least, I think they are, since they're a generalisation of complex numbers,
// and I'd say a complex number is a scalar?

vec4 quatFromAxisAngle(vec3 v) {
	vec3 axis = normalize(v);
	float angle = length(v);
	float s = sin(angle / 2.0);
	float c = cos(angle / 2.0);
	return normalize(vec4(axis * s, c));
}

vec3 rotate(vec3 v, vec4 q) {
	vec3 uv = cross(q.xyz, v);
	vec3 uuv = cross(q.xyz, uv);
	return v + ((uv * q.w) + uuv) * 2.0;
}

vec3 rotateAxisAngle(vec3 v, vec3 v2) {
	return rotate(v, quatFromAxisAngle(v2));
}

vec3 setVectorLength(vec3 v, float l) {
	return normalize(v) * l;
}

uniform vec3 rightVector;
uniform vec3 upVector;
uniform vec3 forwardVector;
uniform float rotateAngle;
uniform float strength;
uniform samplerCube heightmap;
uniform bool nearPole; // Oh my god

vec4 effect(vec4 loveColour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec3 direction = normalize(directionPreNormalise);

	// Thanks to nearPole the cross result should never have a magnitude of 0. Yippeeee!!!
	vec3 northCross = cross(direction, nearPole ? rightVector : forwardVector); // I don't think this is really "north" anymore lol
	vec3 northRotate = setVectorLength(northCross, rotateAngle);
	vec3 southRotate = -northRotate;
	vec3 eastRotate = (nearPole ? rightVector : forwardVector) * rotateAngle;
	vec3 westRotate = -eastRotate;

	vec3 northDir = rotateAxisAngle(direction, northRotate);
	vec3 southDir = rotateAxisAngle(direction, southRotate);
	vec3 eastDir = rotateAxisAngle(direction, eastRotate);
	vec3 westDir = rotateAxisAngle(direction, westRotate);

	float northSample = Texel(heightmap, northDir).r;
	float southSample = Texel(heightmap, southDir).r;
	float eastSample = Texel(heightmap, eastDir).r;
	float westSample = Texel(heightmap, westDir).r;

	float northVsSouthDerivative = 2.0 * southSample - 2.0 * northSample;
	float eastVsWestDerivative = 2.0 * westSample - 2.0 * eastSample;

	vec3 outNormalTangentSpace = normalize(vec3(eastVsWestDerivative, northVsSouthDerivative, 1.0 / strength));
	vec3 n = direction;
	vec3 t = normalize(cross(nearPole ? rightVector : forwardVector, n));
	vec3 b = cross(n, t);
	mat3 tbn = mat3(t, b, n);
	vec3 outNormalObjectSpace = tbn * outNormalTangentSpace;
	
	return vec4(outNormalObjectSpace * 0.5 + 0.5, 1.0);
}
