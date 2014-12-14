/*
    Copyright (c) 2014 Tim Anema
    light shadow, shine and normal shader all in one
*/
extern Image shadowMap;       //a canvas containing shadow data only
extern vec3  lightPosition;    //the light position on the screen(not global)
extern vec3  lightColor;       //the rgb color of the light
extern float lightRange;      //the range of the light
extern float lightSmooth;     //smoothing of the lights attenuation
extern vec2  lightGlow = vec2(0.5, 0.5); //how brightly the light bulb part glows
extern bool  invert_normal;   //if the light should invert normals

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
  vec4 pixelColor = Texel(texture, texture_coords);

  float dist = distance(lightPosition, vec3(pixel_coords, 1.0));
  //if the pixel is within this lights range
  if(dist > lightRange) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }else{
    //calculater attenuation of light based on the distance
    float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);
    // if not on the normal map draw attenuated shadows
    if(pixelColor.a == 0.0) {
      vec3 pixel = lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y;
      //If on the shadow map add the shadow color
      vec4 shadowColor = Texel(shadowMap, texture_coords);
      if(shadowColor.a > 0.0) {
        pixel.rgb = pixel.rgb * shadowColor.rgb;
      }
      return vec4(pixel, 1.0);
    } else {
      //on the normal map, draw normal shadows
      vec3 lightDir = vec3((lightPosition.xy - pixel_coords.xy) / love_ScreenSize.xy, lightPosition.z);
      lightDir.x *= love_ScreenSize.x / love_ScreenSize.y;
      vec3 normal = normalize(vec3(pixelColor.r,(invert_normal ? 1 - pixelColor.g : pixelColor.g), pixelColor.b) * 2.0 - 1.0); 
      vec3 diffuse = lightColor * max(dot(normalize(normal), normalize(lightDir)), 0.0);
      //return the light that is effected by the normal and attenuation
      return vec4(diffuse * att, 1.0);
    }
  }
}

