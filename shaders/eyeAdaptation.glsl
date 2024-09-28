uniform sampler2D thisFrameMaxLuminanceCanvas;
uniform sampler2D thisFrameAverageLuminanceCanvas;
uniform float averageLuminanceLogDelta;
uniform bool moveLinearly;
uniform float smoothing;
uniform float moveRate;
uniform float dt;
uniform bool jump;
uniform bool expAverage;

vec4 effect(vec4 loveColour, sampler2D previousFrameEyeAdaptationCanvas, vec2 textureCoords, vec2 windowCoords) {
	bool maxSide = textureCoords.x < 0.5; // Otherwise average side
	float thisFrameValue = maxSide ?
		Texel(thisFrameMaxLuminanceCanvas, vec2(0.5, 0.5)).r :
		(
			expAverage ?
			exp(Texel(thisFrameAverageLuminanceCanvas, vec2(0.5, 0.5)).r) - averageLuminanceLogDelta :
			Texel(thisFrameAverageLuminanceCanvas, vec2(0.5, 0.5)).r
		);
	if (jump) {
		return vec4(vec3(thisFrameValue), 1.0);
	}
	float previousFrameEyeValue = Texel(previousFrameEyeAdaptationCanvas, textureCoords).r;

	float logDelta = 0.000000001; // Must be very small for the linear movement approach to work well with negative exponents
	float previousLog = log2(previousFrameEyeValue + logDelta);
	float thisLog = log2(thisFrameValue + logDelta);

	float movedLog;
	if (!moveLinearly) {
		float lerpThisFrame = 1.0 - pow(smoothing, dt);
		movedLog = mix(
			previousLog,
			thisLog,
			lerpThisFrame
		);
	} else {
		float delta = thisLog - previousLog;
		float newDelta = max(0.0, abs(delta) - moveRate * dt) * sign(delta);
		movedLog = thisLog - newDelta;
	}
	float thisFrameEyeValue = pow(2.0, movedLog) - logDelta;

	return vec4(vec3(thisFrameEyeValue), 1.0);
}
