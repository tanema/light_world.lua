extern vec3 lightPositionRange;
extern vec3 lightColor;
extern float lightSmooth;
extern vec2 lightGlow;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec2 lightToPixel = pixel_coords - lightPositionRange.xy;
	float distance = length(lightToPixel);
	float att = 1 - distance / lightPositionRange.z;

	if (distance <= lightPositionRange.z) {
		if (lightGlow.x < 1.0 && lightGlow.y > 0.0) {
			pixel.rgb = clamp(lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y, 0.0, 1.0);
		} else {
			pixel.rgb = lightColor * pow(att, lightSmooth);
		}
	} else {
		pixel.rgb = vec3(0, 0, 0);
	}

	return pixel;
}