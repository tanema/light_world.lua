#define PI 3.1415926535897932384626433832795

extern vec2 screenResolution;
extern vec3 lightPosition;
extern vec3 lightColor;
extern float lightRange;
extern float lightSmooth;
extern float lightDirection;
extern float lightAngle;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
    vec4 pixelColor = Texel(texture, texture_coords);

	if(pixelColor.a > 0.0) {
		if(lightAngle > 0.0) {
			float angle2 = atan(lightPosition.x - pixel_coords.x, pixel_coords.y - lightPosition.y) + PI;
			if(lightDirection - lightAngle > 0 && lightDirection + lightAngle < PI * 2) {
				if(angle2 < mod(lightDirection + lightAngle, PI * 2) && angle2 > mod(lightDirection - lightAngle, PI * 2)) {
					return vec4(0.0, 0.0, 0.0, 1.0);
				}
			} else {
				if(angle2 < mod(lightDirection + lightAngle, PI * 2) || angle2 > mod(lightDirection - lightAngle, PI * 2)) {
					return vec4(0.0, 0.0, 0.0, 1.0);
				}
			}
		}

		vec3 normal = vec3(pixelColor.r, 1 - pixelColor.g, pixelColor.b);
		float dist = distance(lightPosition, vec3(pixel_coords, normal.b));

		if(dist < lightRange) {
			vec3 dir = vec3((lightPosition.xy - pixel_coords.xy) / screenResolution.xy, lightPosition.z);

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