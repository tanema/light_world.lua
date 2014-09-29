extern Image imgBuffer;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec4 pixelBuffer = Texel(imgBuffer, texture_coords);

	if(texture_coords.y > 0.5) {
		return vec4(pixel.rgb * (texture_coords.y - 0.5) * 2.0 + pixelBuffer.rgb * (1.0 - texture_coords.y) * 2.0, 1.0);
	} else {
		return vec4(pixel.rgb * (0.5 - texture_coords.y) * 2.0 + pixelBuffer.rgb * texture_coords.y * 2.0, 1.0);
	}
}