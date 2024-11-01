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
uniform float bodyRadius;
uniform samplerCube heightmap;
uniform bool nearPole; // Oh my god

vec3 getTriangleNormal(vec3 p1, vec3 p2, vec3 p3) {
	return normalize(cross(p2 - p1, p3 - p1));
}

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

	vec3 northPos = northDir * (bodyRadius + northSample);
	// vec3 southPos = southDir * (bodyRadius + southSample);
	vec3 eastPos = eastDir * (bodyRadius + eastSample);
	// vec3 westPos = westDir * (bodyRadius + westSample);

	float centralSample = Texel(heightmap, direction).r;
	vec3 centralPos = direction * (bodyRadius + centralSample);

	vec3 outNormalObjectSpace = getTriangleNormal(centralPos, eastPos, northPos);
	
	return vec4(outNormalObjectSpace * 0.5 + 0.5, 1.0);
}
