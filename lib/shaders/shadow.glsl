/*
    Copyright (c) 2014 Tim Anema
    light shadow, shine and normal shader all in one
*/
#define PI 3.1415926535897932384626433832795

extern Image normalMap;       //a canvas containing shadow data only
extern vec3 lightPosition;    //the light position on the screen(not global)
extern vec3 lightColor;       //the rgb color of the light
extern float lightRange;      //the range of the light
extern float lightSmooth;     //smoothing of the lights attenuation
extern vec2 lightGlow;        //how brightly the light bulb part glows
extern bool  invert_normal;   //if the light should invert normals

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
  float dist = distance(lightPosition, vec3(pixel_coords, 1.0));
  if(dist > lightRange) { //not in range draw in shadows
    return vec4(0.0, 0.0, 0.0, 1.0);
  }else{
    vec4 shadowColor = Texel(texture, texture_coords);
    vec4 normalColor = Texel(normalMap, texture_coords);
    vec4 pixel;
    //calculate attenuation of light based on the distance
    float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);
    // if not on the normal map draw attenuated shadows
    if(normalColor.a <= 0.0) {
      //start with a dark color and add in the light color and shadow color
      pixel = vec4(0.0, 0.0, 0.0, 1.0);
      if (lightGlow.x < 1.0 && lightGlow.y > 0.0) {
        pixel.rgb = clamp(lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y, 0.0, 1.0);
      } else {
        pixel.rgb = lightColor * pow(att, lightSmooth);
      }
    } else {
      vec3 normal = normalize(vec3(normalColor.r,invert_normal ? 1 - normalColor.g : normalColor.g, normalColor.b) * 2.0 - 1.0); 
      //on the normal map, draw normal shadows
      vec3 dir = vec3((lightPosition.xy - pixel_coords.xy) / love_ScreenSize.xy, lightPosition.z);
      dir.x *= love_ScreenSize.x / love_ScreenSize.y;
      vec3 diff = lightColor * max(dot(normalize(normal), normalize(dir)), 0.0);
      //return the light that is effected by the normal and attenuation
      pixel = vec4(diff * att, 1.0);
    }

    if(shadowColor.a > 0.0) {
      pixel.rgb = pixel.rgb * shadowColor.rgb;
    }
    return pixel;
  }
}

