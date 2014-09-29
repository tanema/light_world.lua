extern vec2 screen = vec2(800.0, 600.0);
extern float steps = 2.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 pSize = vec2(1.0 / screen.x, 1.0 / screen.y);
	vec4 col = Texel(texture, texture_coords);
	for(int i = 1; i <= steps; i++) {
		col = col + Texel(texture, vec2(texture_coords.x - pSize.x * i, texture_coords.y));
		col = col + Texel(texture, vec2(texture_coords.x + pSize.x * i, texture_coords.y));
	}
	col = col / (steps * 2.0 + 1.0);
	return vec4(col.r, col.g, col.b, 1.0);
}