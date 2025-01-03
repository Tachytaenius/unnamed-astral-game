#line 1

// Requires include/colourSpaceConversion.glsl concatenated
// Requires include/lights.glsl concatenated
// Requires include/lib/worley.glsl concatenated
// Requires include/lib/simplex4d.glsl concatenated

// const float tau = 6.28318530718; // Redefinition lol

// NOTE: This is weird because requirements changed

uniform mat4 modelToWorld;
uniform mat3 modelToWorldNormal;
uniform mat3 worldToModelNormal;

uniform float bodyRadius;

uniform vec3 bodyPosition;
uniform vec3 cameraPosition;

uniform mat4 clipToSky;
uniform vec3 cameraForwardVector;
uniform float nearDistance;
uniform float farDistance;

uniform samplerCube baseColourTexture;
uniform samplerCube normalTexture;
uniform samplerCube heightmapTexture;
uniform sampler2D heightmapMinMax;
const float heightStartMultiplier = 1.0001;

uniform bool enableSelfShadowing;
uniform mat3 inverseBodyOrientationMatrix;

uniform float time;

// Star stuff

uniform bool isStar;
uniform vec3 starColour;

// uniform float simplexTimeRate;
// uniform float simplexFrequency;
// // uniform float simplexColourHueShift;
// // uniform float simplexColourSaturationAdd;
// // uniform float simplexColourValueMultiplier;
// uniform vec3 simplexColour;
// uniform float simplexPower;
// uniform float simplexEffect;

uniform float worleyFrequency;
uniform float worleyEffect;

vec3 sampleStar(vec3 direction) {
	// // vec3 starColourHsl = rgb2hsl(starColour);
	// // vec3 simplexHsl = starColourHsl;
	// // simplexHsl.x = mod(simplexHsl.x + simplexColourHueShift, 1.0);
	// // simplexHsl.y = clamp(simplexHsl.y + simplexColourSaturationAdd, 0.0, 1.0);
	// // simplexHsl.z *= simplexColourValueMultiplier;
	// // vec3 simplexColour = hsl2rgb(simplexHsl);

	// float worleyRaw = worley(direction * worleyFrequency);
	// float worleyResult = 1.0 - worleyEffect * (1.0 - worleyRaw);
	// float simplexResult = pow(clamp(snoise(vec4(direction * simplexFrequency, time * simplexTimeRate)) * 0.5 + 0.5, 0.0, 1.0), simplexPower);
	// vec3 colour = mix(starColour * worleyResult, simplexColour, simplexResult * simplexEffect);
	
	float noise = clamp(snoise(vec4(direction * 12.0, time * 0.2)) * 0.5 + 0.5, 0.0, 1.0);
	noise = 1.0 - pow(noise, 2.0);
	float noiseB = clamp(snoise(vec4(direction, time * 0.1) + 100.0) * 0.5 + 0.5, 0.0, 1.0);
	noise = pow(max(0.0,
		mix(noise / 3.0, 1.0, noiseB)
	), 0.8);

	return starColour * noise;
}

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

	vec4 lightCanvasOutput;
	vec4 positionCanvasOutput = vec4(raycastFragmentPosition, 1.0);
	if (!isStar) {
		vec3 baseColour = Texel(baseColourTexture, textureSampleDirection).rgb;
		vec3 normalMapSample = Texel(normalTexture, textureSampleDirection).rgb * 2.0 - 1.0; // Probably normalised, but I don't think it makes a difference here
		normalMapSample.y *= -1.0; // TODO: Why...?
		vec3 normal = normalize(modelToWorldNormal * normalMapSample);
		// y flipping and gamma correction are like my recurring archnemeses that I fight once a season. during the final battle against y flipping im gonna get almost defeated and then come back thru the power of love and win, and gamma will be redeemed

		vec3 totalLight;
		if (!enableSelfShadowing) {
			totalLight = getAverageFormShadowAndColourAtPointNormal(raycastFragmentPosition, normal);
		} else {
			float heightmapMin = texelFetch(heightmapMinMax, ivec2(0, 0), 0).r;
			float heightmapMax = texelFetch(heightmapMinMax, ivec2(1, 0), 0).r;
			// Step size needs to be small enough to catch any heightmap variation.
			// It needs to increase with minimum size, err on the side of being smaller, and decrease as texture resolution increases
			float selfShadowRayStepSize = (bodyRadius + heightmapMin) * 0.2 / float(textureSize(heightmapTexture, 0).x);
			float startHeightmapSample = Texel(heightmapTexture, textureSampleDirection * vec3(1.0, -1.0, 1.0)).r; // No idea why the y flip is needed
			vec3 fragmentPositionHeightmap = bodyPosition + heightStartMultiplier * raycastFragmentNormal * (bodyRadius + startHeightmapSample);
			totalLight = getAverageFormShadowAndColourAtPointNormalSelfShadow(
				fragmentPositionHeightmap, normal,
				bodyPosition, bodyRadius, heightmapTexture, heightmapMin, heightmapMax, selfShadowRayStepSize, inverseBodyOrientationMatrix
			);
		}

		lightCanvasOutput = vec4(baseColour * totalLight, 1.0); // lightCanvas
	} else {
		// star!!!!!!1111
		lightCanvasOutput = vec4(sampleStar(normalize(textureSampleDirection)), 1.0);
	}

	love_Canvases[0] = lightCanvasOutput;
	love_Canvases[1] = positionCanvasOutput;
	vec3 hitPosCameraSpace = hitPosWorldSpace - cameraPosition;
	float positionZ = dot(cameraForwardVector, hitPosCameraSpace);
	gl_FragDepth = farDistance * (nearDistance - positionZ) / (positionZ * (nearDistance - farDistance));
}
