extern Image glowImage;

extern float glowTime;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec3 glowInfo = Texel(glowImage, texture_coords).rgb;

	if(glowInfo.r != glowInfo.g) {
		float glowStrength = glowTime + glowInfo.b;
		if(mod(glowStrength, 2.0) < 1.0) {
			glowInfo.b = mod(glowStrength, 1.0);
		} else {
			glowInfo.b = 1.0 - mod(glowStrength, 1.0);
		}

		return Texel(texture, texture_coords) * (glowInfo.g + glowInfo.b * (glowInfo.r - glowInfo.g));
	}
	
	return vec4(Texel(texture, texture_coords).rgb * glowInfo.r, 1.0);
}