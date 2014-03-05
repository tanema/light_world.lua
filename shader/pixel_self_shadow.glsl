extern vec3 lightPosition;
extern float lightRange;
extern vec3 lightColor;
extern vec3 lightAmbient;
extern float lightSmooth;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec3 lightDirection = vec3(pixel_coords.xy, 0) - lightPosition.xyz;
	float distance = length(lightDirection);

	vec4 pixel = Texel(texture, texture_coords);
	vec3 normal = vec3(pixel.x, 1 - pixel.y, pixel.z);
	normal = mix(vec3(-1), vec3(1), normal);

	float att = 1 - distance / lightRange;

	if(distance < lightRange && pixel.a > 0.0) {
		return vec4(vec3(clamp(1 - dot(normal, lightDirection), 0.0, 1.0)) * lightColor * pow(att, lightSmooth) + lightAmbient, 1.0);
	} else if(pixel.a == 0.0) {
		return vec4(0.0);
	} else {
		return vec4(0.0, 0.0, 0.0, 1.0);
	}
}