extern Image backBuffer;

extern vec2 screen = vec2(800.0, 600.0);
extern float reflectionStrength;
extern float reflectionVisibility;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 pSize = vec2(1.0 / screen.x, 1.0 / screen.y);
	vec4 normal = Texel(texture, texture_coords);
	if(normal.a > 0.0 && normal.r > 0.0) {
		vec3 pColor = Texel(backBuffer, texture_coords).rgb;
		vec4 pColor2;
		for(int i = 0; i < reflectionStrength; i++) {
			pColor2 = Texel(texture, vec2(texture_coords.x, texture_coords.y + pSize.y * i));
			if(pColor2.a > 0.0 && pColor2.g > 0.0) {
				vec3 rColor = Texel(backBuffer, vec2(texture_coords.x, texture_coords.y + pSize.y * i * 2.0)).rgb;
				return vec4(rColor, (1.0 - i / reflectionStrength) * reflectionVisibility);
			}
		}
		return vec4(0.0);
	} else {
		return vec4(0.0);
	}
}