extern Image backBuffer;

extern vec2 screen = vec2(800.0, 600.0);
extern float refractionStrength = 1.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 pSize = vec2(1.0 / screen.x, 1.0 / screen.y);
	vec4 normal = Texel(texture, texture_coords);
	if(normal.b > 0.0) {
		vec4 normalOffset = Texel(texture, vec2(texture_coords.x + (normal.x - 0.5) * pSize.x * refractionStrength, texture_coords.y + (normal.y - 0.5) * pSize.y * refractionStrength));
		if(normalOffset.b > 0.0) {
			return Texel(backBuffer, vec2(texture_coords.x + (normal.x - 0.5) * pSize.x * refractionStrength, texture_coords.y + (normal.y - 0.5) * pSize.y * refractionStrength));
		} else {
			return Texel(backBuffer, texture_coords);
		}
	} else {
		return vec4(0.0);
	}
}