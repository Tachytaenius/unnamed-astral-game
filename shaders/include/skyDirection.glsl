#line 1

// If needed, concatenate "#define FLIP_Y 1" in front to make it flip screen Y

varying vec3 directionPreNormalise;

#ifdef VERTEX

uniform mat4 clipToSky;

vec4 position(mat4 loveTransform, vec4 homogenVertexPos) {
	directionPreNormalise = (
		clipToSky * vec4(
#ifndef FLIP_Y
			(VertexTexCoord.xy * 2.0 - 1.0),
#else
			(VertexTexCoord.xy * 2.0 - 1.0) * vec2(1.0, -1.0),
#endif
			-1.0,
			1.0
		)
	).xyz;
	return loveTransform * homogenVertexPos;
}

#endif
