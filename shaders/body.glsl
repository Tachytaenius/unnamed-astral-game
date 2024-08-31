#line 1

// Requires include/lights.glsl concatenated

// NOTE: This is weird because requirements changed

uniform mat4 modelToWorld;

// varying vec3 fragmentPosition;
// varying vec3 fragmentNormal;
// varying vec2 fragmentTextureCoord;
// varying vec3 fragmentPositionModelSpace;
uniform mat3 modelToWorldNormal;
uniform mat3 worldToModelNormal;

#ifdef VERTEX

uniform mat4 modelToClip;

attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 vertexPosition) {
	// fragmentNormal = normalize(modelToWorldNormal * VertexNormal);
	// fragmentTextureCoord = VertexTexCoord.st;
	// fragmentPosition = (modelToWorld * vertexPosition).xyz; // w should be 1 so no division needed
	// fragmentPositionModelSpace = vertexPosition.xyz;
	return modelToClip * vertexPosition;
}

#endif

#ifdef PIXEL

// uniform bool spherise;
uniform float bodyRadius;

uniform vec3 bodyPosition;
uniform vec3 cameraPosition;

uniform mat4 clipToSky;

uniform samplerCube baseColourTexture;
uniform samplerCube normalTexture;

// going crazy lollle (having fun too)
vec3 flipAroundDirection(vec3 v, vec3 dir) { // dir should be normalised
	float d = dot(v, dir);
	vec3 parallel = d * dir;
	vec3 perpendicular = v - parallel;
	vec3 flippedParallel = -parallel;
	return flippedParallel + perpendicular;
}

uniform vec3 normalFlipDirectionHack;

void effect() {
	// graaaaaaaaaaaaaahhhhhhhh
	// could do with a rewrite to make it more neat tbh lol

	vec2 screen = ((love_PixelCoord / love_ScreenSize.xy) * 2.0 - 1.0) * vec2(1.0, -1.0);
	vec3 direction = normalize((clipToSky * vec4(screen, -1.0, 1.0)).xyz);
	ConvexRaycastResult raycastResult = sphereRaycast2(bodyPosition, bodyRadius, cameraPosition, direction);
	if (!raycastResult.hit) {
		discard;
	}
	if (raycastResult.t2 <= 0.0) {
		// Planet is behind us
		discard;
	}
	vec3 hitPosWorldSpace = cameraPosition + direction * (raycastResult.t1 >= 0.0 ? raycastResult.t1 : raycastResult.t2);
	// vec3 raycastFragmentPositionModelSpace = (inverse(modelToWorld) * vec4(hitPosWorldSpace - bodyPosition, 1.0)).xyz; // Should be normalised (mathematically speaking) because modelToWorld has radius as scale (NOTE: This is broken lol)
	vec3 raycastFragmentNormal = normalize(hitPosWorldSpace - bodyPosition); // World space
	vec3 raycastFragmentPosition = hitPosWorldSpace;

	// vec3 effectiveFragmentPositionModelSpace =
	// 	spherise ?
	// 	normalize(fragmentPositionModelSpace) :
	// 	fragmentPositionModelSpace;
	// vec3 effectiveFragmentPosition = (modelToWorld * vec4(effectiveFragmentPositionModelSpace, 1.0)).xyz;

	// vec3 fragmentNormal = normalize(modelToWorldNormal * fragmentPositionModelSpace);

	// mat3 worldToModelNormal = mat3(transpose(modelToWorld)); // mat3(transpose(inverse(worldToModel)))
	vec3 textureSampleDirection = worldToModelNormal * raycastFragmentNormal;
	vec3 baseColour = Texel(baseColourTexture, textureSampleDirection).rgb;
	vec3 normalMapSample = Texel(normalTexture, textureSampleDirection).rgb * 2.0 - 1.0; // Probably normalised, but I don't think it makes a difference here
	normalMapSample.y *= -1.0; // TODO: Why...?
	// vec3 normal = normalize((transpose(inverse(modelToWorld)) * vec4(normalMapSample, 0.0)).xyz);
	vec3 normal = normalize(modelToWorldNormal * normalMapSample);
	// vec3 normal = normalMapSample;
	// normal.y *= -1.0;
	// normal = flipAroundDirection(normal, modelToWorldNormal * vec3(0, 1, 0));
	// y flipping and gamma correction are like my recurring archnemeses that I fight once a season. during the final battle against y flipping im gonna get almost defeated and then come back thru the power of love and win, and gamma will be redeemed

	vec3 totalLight = getLightAtPointNormal(raycastFragmentPosition, normal);

	love_Canvases[0] = vec4(baseColour * totalLight, 1.0); // lightCanvas
	love_Canvases[1] = vec4(raycastFragmentPosition, 1.0); // positionCanvas
	// gl_FragDepth = // TODO: Make it smooth
}

#endif
