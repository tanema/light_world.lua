extern vec2 screenResolution;
extern vec3 lightPosition;
extern vec3 lightColor;
extern float lightRange;
extern float lightSmooth;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixelColor = Texel(texture, texture_coords);

	if(pixelColor.a > 0.0) {
		vec3 normal = vec3(pixelColor.r, 1 - pixelColor.g, pixelColor.b);
		float dist = distance(lightPosition, vec3(screen_coords, normal.b));

		if(dist < lightRange) {
			vec3 dir = vec3((lightPosition.xy - screen_coords.xy) / screenResolution.xy, lightPosition.z);

			dir.x *= screenResolution.x / screenResolution.y;

			vec3 N = normalize(normal * 2.0 - 1.0);
			vec3 L = normalize(dir);

			vec3 diff = lightColor * max(dot(N, L), 0.0);

			float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);

			return vec4(diff * att, 1.0);
		} else {
			return vec4(0.0, 0.0, 0.0, 1.0);
		}
	} else {
		return vec4(0.0);
	}
}