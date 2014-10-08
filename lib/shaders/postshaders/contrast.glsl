vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec3 col = Texel(texture, texture_coords).rgb * 2.0;
	col *= col;
	return vec4(col, 1.0);
}