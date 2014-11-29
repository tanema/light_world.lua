#define PI 3.1415926535897932384626433832795

extern vec2 screenResolution;
extern vec3 lightPosition;
extern vec3 lightColor;
extern float lightRange;
extern float lightSmooth;
extern vec2 lightGlow;
extern float lightDirection;
extern float lightAngle;
extern bool  invert_normal;

float getHeightAt(Image texture, vec2 texture_coords) {
  vec4 pixel = Texel(texture, texture_coords);
  if(pixel.a > 0.0){
    return 0.0;
  } else {
    return pixel.g;
  }
}

bool is_in_shadow(Image texture, vec2 texture_coords, vec3 lightPosition, vec2 pixel_coords) {
  vec3 coords = vec3(pixel_coords, 0.0);
  vec3 lightVec = normalize(lightPosition - coords);

  float startHeight = getHeightAt(texture, texture_coords); 
  vec2 tx;
  float currentHeight;

  for(int i = 0; i < 100; ++i) {
    tx = texture_coords + lightVec.xy;
    currentHeight = getHeightAt(texture, tx);
    if(startHeight < currentHeight){
      return true;
    }
  }
  return false;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
  vec4 pixelColor = Texel(texture, texture_coords);

  //if the light is a slice and the pixel is not inside
  if(lightAngle > 0.0) {
    float angle2 = atan(lightPosition.x - pixel_coords.x, pixel_coords.y - lightPosition.y) + PI;
    if(lightDirection - lightAngle > 0 && lightDirection + lightAngle < PI * 2) {
      if(angle2 < mod(lightDirection + lightAngle, PI * 2) && angle2 > mod(lightDirection - lightAngle, PI * 2)) {
        return vec4(0.0, 0.0, 0.0, 1.0);
      }
    } else {
      if(angle2 < mod(lightDirection + lightAngle, PI * 2) || angle2 > mod(lightDirection - lightAngle, PI * 2)) {
        return vec4(0.0, 0.0, 0.0, 1.0);
      }
    }
  }

  vec3 normal;
  //if on the normal map ie there is normal map data
	if(pixelColor.a > 0.0) {
    if(invert_normal == true) {
      normal = normalize(vec3(pixelColor.r, 1 - pixelColor.g, pixelColor.b) * 2.0 - 1.0); 
    } else {
      normal = normalize(pixelColor.rgb * 2.0 - 1.0);
    }
  } else {
    normal = vec3(0.0, 0.0, 1.0);
  }
  float dist = distance(lightPosition, vec3(pixel_coords, normal.b));
  if(dist < lightRange) {
    float att = clamp((1.0 - dist / lightRange) / lightSmooth, 0.0, 1.0);
    if(pixelColor.a == 0.0) {
      vec4 val = pixelColor;
      val.a = 1.0;
      if (lightGlow.x < 1.0 && lightGlow.y > 0.0) {
        val.rgb = clamp(lightColor * pow(att, lightSmooth) + pow(smoothstep(lightGlow.x, 1.0, att), lightSmooth) * lightGlow.y, 0.0, 1.0);
      } else {
        val.rgb = lightColor * pow(att, lightSmooth);
      }
      return val;
    } else {
      vec3 dir = vec3((lightPosition.xy - pixel_coords.xy) / screenResolution.xy, lightPosition.z);
      dir.x *= screenResolution.x / screenResolution.y;
      vec3 diff = lightColor * max(dot(normalize(normal), normalize(dir)), 0.0);
      return vec4(diff * att, 1.0);
    }
  } else {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }
}

