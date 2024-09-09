#line 1

// Requires include/lights.glsl concatenated

// NOTE: This is weird because requirements changed

uniform mat4 modelToWorld;
uniform mat3 modelToWorldNormal;
uniform mat3 worldToModelNormal;

uniform float bodyRadius;

uniform vec3 bodyPosition;
uniform vec3 cameraPosition;

uniform mat4 clipToSky;

uniform samplerCube baseColourTexture;
uniform samplerCube normalTexture;

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
	// if (raycastResult.t1 <= 0.0) {
	// 	// Inside planet
	// 	discard;
	// }
	vec3 hitPosWorldSpace = cameraPosition + direction * (raycastResult.t1 >= 0.0 ? raycastResult.t1 : raycastResult.t2);
	vec3 raycastFragmentNormal = normalize(hitPosWorldSpace - bodyPosition); // World space
	vec3 raycastFragmentPosition = hitPosWorldSpace;

	vec3 textureSampleDirection = worldToModelNormal * raycastFragmentNormal;
	vec3 baseColour = Texel(baseColourTexture, textureSampleDirection).rgb;
	vec3 normalMapSample = Texel(normalTexture, textureSampleDirection).rgb * 2.0 - 1.0; // Probably normalised, but I don't think it makes a difference here
	normalMapSample.y *= -1.0; // TODO: Why...?
	vec3 normal = normalize(modelToWorldNormal * normalMapSample);
	// y flipping and gamma correction are like my recurring archnemeses that I fight once a season. during the final battle against y flipping im gonna get almost defeated and then come back thru the power of love and win, and gamma will be redeemed

	vec3 totalLight = getLightAtPointNormal(raycastFragmentPosition, normal);

	love_Canvases[0] = vec4(baseColour * totalLight, 1.0); // lightCanvas
	// love_Canvases[0] = vec4(baseColour * totalLight * 0.00000000000000000000001 + baseColour, 1.0); // lightCanvas ((HACK) debug to see base colour while avoiding variable not used error)
	love_Canvases[1] = vec4(raycastFragmentPosition, 1.0); // positionCanvas
	// gl_FragDepth = // TODO: Make it smooth
}
