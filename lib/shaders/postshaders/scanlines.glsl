extern float strength = 2.0;
extern float time = 0.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec2 pSize = 1.0 / love_ScreenSize.xy;
	float brightness = 1.0;
	float offsetX = sin(texture_coords.y * 10.0 + time * strength) * pSize.x;
	float corner = 500.0;

	if(texture_coords.x < 0.5) {
		if(texture_coords.y < 0.5) {
			brightness = min(texture_coords.x * texture_coords.y * corner, 1.0);
		} else {
			brightness = min(texture_coords.x * (1.0 - texture_coords.y) * corner, 1.0);
		}
	} else {
		if(texture_coords.y < 0.5) {
			brightness = min((1.0 - texture_coords.x) * texture_coords.y * corner, 1.0);
		} else {
			brightness = min((1.0 - texture_coords.x) * (1.0 - texture_coords.y) * corner, 1.0);
		}
	}
	float red = Texel(texture, vec2(texture_coords.x + offsetX, texture_coords.y + pSize.y * 0.5)).r;
	float green = Texel(texture, vec2(texture_coords.x + offsetX, texture_coords.y - pSize.y * 0.5)).g;
	float blue = Texel(texture, vec2(texture_coords.x + offsetX, texture_coords.y)).b;

	if(fract(gl_FragCoord.y * (0.5*4.0/3.0)) > 0.5) {
		return vec4(vec3(red, green, blue) * brightness, 1.0);
	} else {
		return vec4(vec3(red * 0.75, green * 0.75, blue * 0.75) * brightness, 1.0);
	}
}
