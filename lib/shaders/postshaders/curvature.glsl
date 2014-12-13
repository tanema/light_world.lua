#define distortion 0.2
vec2 radialDistortion(vec2 coord) {
	vec2 cc = coord - 0.5;
	float dist = dot(cc, cc) * distortion;
	return coord + cc * (1.0 + dist) * dist;
}

vec4 checkTexelBounds(Image texture, vec2 coords) {
	vec2 ss = step(coords, vec2(1.0, 1.0)) * step(vec2(0.0, 0.0), coords);
	return Texel(texture, coords) * ss.x * ss.y;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 coords = radialDistortion(texture_coords);
	vec4 texcolor = checkTexelBounds(texture, coords);
	texcolor.a = 1.0;
	return texcolor;
}

