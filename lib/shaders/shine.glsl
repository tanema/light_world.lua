/*
    Copyright (c) 2014 Tim Anema
*/
extern vec3  lightPosition;                  //the light position on the screen(not global)
extern vec3  lightColor;                     //the rgb color of the light
extern float lightRange;                     //the range of the light
extern float lightSmooth;                    //smoothing of the lights attenuation
extern vec2  lightGlow     = vec2(0.5, 0.5); //how brightly the light bulb part glows
extern vec4  AmbientColor;                   //ambient RGBA -- alpha is intensity 

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
  float dist = distance(lightPosition, vec3(pixel_coords, 1.0));
  //if the pixel is within this lights range
  //calculater attenuation of light based on the distance
  float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);
  // if not on the normal map draw attenuated shadows
  vec3 Ambient = AmbientColor.rgb * AmbientColor.a;
  vec3 pixel = lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y;
  return vec4(Ambient + pixel, 1.0);
}

