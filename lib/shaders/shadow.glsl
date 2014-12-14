/*
    Copyright (c) 2014 Tim Anema
    light shadow, shine and normal shader all in one
*/
#define PI 3.1415926535897932384626433832795

extern Image shadowMap;       //a canvas containing shadow data only
extern vec3 lightPosition;    //the light position on the screen(not global)
extern vec3 lightColor;       //the rgb color of the light
extern float lightRange;      //the range of the light
extern float lightSmooth;     //smoothing of the lights attenuation
extern vec2 lightGlow;        //how brightly the light bulb part glows
extern float lightAngle;      //if set, the light becomes directional to a slice lightAngle degrees wide
extern float lightDirection;  //which direction to shine the light in if directional in degrees 
extern bool  invert_normal;   //if the light should invert normals

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
  vec4 pixelColor = Texel(texture, texture_coords);
  vec4 shadowColor = Texel(shadowMap, texture_coords);

  float dist = distance(lightPosition, vec3(pixel_coords, 1.0));
  //if the pixel is within this lights range
  if(dist > lightRange) {
    //not in range draw in shadows
    return vec4(0.0, 0.0, 0.0, 1.0);
  }else{
    vec3 normal;
    if(pixelColor.a > 0.0) {
      //if on the normal map ie there is normal map data
      //so get the normal data
      if(invert_normal) {
        normal = normalize(vec3(pixelColor.r, 1 - pixelColor.g, pixelColor.b) * 2.0 - 1.0); 
      } else {
        normal = normalize(pixelColor.rgb * 2.0 - 1.0);
      }
    } else {
      // not on the normal map so it is the floor with a normal point strait up
      normal = vec3(0.0, 0.0, 1.0);
    }
    //calculater attenuation of light based on the distance
    float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);
    // if not on the normal map draw attenuated shadows
    if(pixelColor.a == 0.0) {
      //start with a dark color and add in the light color and shadow color
      vec4 pixel = vec4(0.0, 0.0, 0.0, 1.0);
      if (lightGlow.x < 1.0 && lightGlow.y > 0.0) {
        pixel.rgb = clamp(lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y, 0.0, 1.0);
      } else {
        pixel.rgb = lightColor * pow(att, lightSmooth);
      }
      //If on the shadow map add the shadow color
      if(shadowColor.a > 0.0) {
        pixel.rgb = pixel.rgb * shadowColor.rgb;
      }
      return pixel;
    } else {
      //on the normal map, draw normal shadows
      vec3 dir = vec3((lightPosition.xy - pixel_coords.xy) / love_ScreenSize.xy, lightPosition.z);
      dir.x *= love_ScreenSize.x / love_ScreenSize.y;
      vec3 diff = lightColor * max(dot(normalize(normal), normalize(dir)), 0.0);
      //return the light that is effected by the normal and attenuation
      return vec4(diff * att, 1.0);
    }
  }
}

