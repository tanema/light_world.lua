#define PI 3.1415926535897932384626433832795

extern vec3 lightPosition;
extern vec3 lightColor;
extern float lightRange;
extern float lightSmooth;
extern vec2 lightGlow;
extern float lightDirection;
extern float lightAngle;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec3 lightToPixel = vec3(pixel_coords.x, pixel_coords.y, 0.0) - lightPosition;
	float distance = length(lightToPixel);
	float att = 1 - distance / lightRange;

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

	if (distance <= lightRange) {
		if (lightGlow.x < 1.0 && lightGlow.y > 0.0) {
			pixel.rgb = clamp(lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y, 0.0, 1.0);
		} else {
			pixel.rgb = lightColor * pow(att, lightSmooth);
		}
	} else {
		return vec4(0.0, 0.0, 0.0, 1.0);
	}

	return pixel;
}
