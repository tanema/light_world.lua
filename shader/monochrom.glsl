extern float time = 0.0;
extern vec3 tint = vec3(1.0, 1.0, 1.0);
extern float fudge = 0.1;

float rand(vec2 position, float seed) {
   return fract(sin(dot(position.xy,vec2(12.9898, 78.233))) * seed);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 pixel = Texel(texture, texture_coords);
	float intensity = (pixel.r + pixel.g + pixel.b) / 3.0 + (rand(texture_coords, time) - 0.5) * fudge;
	return vec4(intensity * tint.r, intensity * tint.g, intensity * tint.b, 1.0);
}