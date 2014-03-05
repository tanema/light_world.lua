extern vec3 lightPositionRange;
extern vec3 lightColor;
extern float smooth;
extern vec2 glow;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec2 lightToPixel = pixel_coords - lightPositionRange.xy;
	float distance = length(lightToPixel);
	float att = 1 - distance / lightPositionRange.z;

	if (distance <= lightPositionRange.z) {
		if (glow.x < 1.0 && glow.y > 0.0) {
			pixel.rgb = clamp(lightColor * pow(att, smooth) + pow(smoothstep(glow.x, 1.0, att), smooth) * glow.y, 0.0, 1.0);
		} else {
			pixel.rgb = lightColor * pow(att, smooth);
		}
	} else {
		pixel.rgb = vec3(0, 0, 0);
	}

	return pixel;
}