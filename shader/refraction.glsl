extern Image backBuffer;

extern vec2 screen = vec2(800.0, 600.0);
extern float refractionStrength = 1.0;
extern vec3 refractionColor = vec3(1.0, 1.0, 1.0);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 pSize = vec2(1.0 / screen.x, 1.0 / screen.y);
	vec4 normal = Texel(texture, texture_coords);
	if(normal.a > 0.0) {
		return vec4(Texel(backBuffer, vec2(texture_coords.x + (normal.x - 0.5) * pSize.x * refractionStrength, texture_coords.y + (normal.y - 0.5) * pSize.y * refractionStrength)).rgb * refractionColor, 1.0);
	} else {
		return vec4(0.0);
	}
}