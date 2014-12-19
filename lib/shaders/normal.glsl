extern Image NormalMap;  //normal map
extern vec3 LightPos;    //light position, normalized, div x/res
extern vec4 LightColor;  //light RGBA -- alpha is intensity
extern vec4 AmbientColor;//ambient RGBA -- alpha is intensity 
extern vec3 Falloff;     //attenuation coefficients

vec4 effect(vec4 vColor, Image u_texture, vec2 vTexCoord, vec2 screen_coords) {
  //RGBA of our diffuse color
  vec4 DiffuseColor = Texel(u_texture, vTexCoord);
  //RGB of our normal map
  vec4 normal = Texel(NormalMap, vTexCoord);
  if(normal.a == 0.0) {
    return vec4(0.0);
  }
  //The delta position of light
  vec3 LightDir = vec3((LightPos.xy - screen_coords.xy)/love_ScreenSize.xy, LightPos.z);
  //Correct for aspect ratio
  LightDir.x *= love_ScreenSize.x / love_ScreenSize.y;
  //Determine distance (used for attenuation) BEFORE we normalize our LightDir
  float D = length(LightDir);
  //normalize our vectors
  vec3 N = normalize(normal.rgb * 2.0 - 1.0);
  vec3 L = normalize(LightDir);
  //Pre-multiply light color with intensity
  //Then perform "N dot L" to determine our diffuse term
  vec3 Diffuse = (LightColor.rgb * LightColor.a) * max(dot(N, L), 0.0);
  //pre-multiply ambient color with intensity
  vec3 Ambient = AmbientColor.rgb * AmbientColor.a;
  float Attenuation = 1.0 / ( Falloff.x + (Falloff.y*D) + (Falloff.z*D*D) );
  vec3 Intensity = Ambient + Diffuse * Attenuation;
  return vec4(DiffuseColor.rgb * Intensity, DiffuseColor.a);
}

