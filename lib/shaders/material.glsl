extern Image material;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec4 normal = Texel(texture, texture_coords);
	if(normal.a == 1.0) {
		return Texel(material, vec2(normal.x, normal.y));
	} else {
		return vec4(0.0);
	}
}