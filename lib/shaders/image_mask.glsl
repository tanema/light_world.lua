//https://love2d.org/wiki/love.graphics.setStencil image mask
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  if (Texel(texture, texture_coords).rgb == vec3(0.0))
    discard;
  return vec4(1.0);
}
