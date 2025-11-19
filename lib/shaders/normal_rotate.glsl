extern float rotation;
        
vec4 effect(vec4 color, Image normalTex, vec2 uv, vec2 pixel_coords) {
    vec4 tex = Texel(normalTex, uv);

    vec3 normal = tex.rgb * 2.0 - 1.0;
    
    // Z-axis rotation (rotates in XY plane)
    float c = cos(rotation);
    float s = sin(rotation);
    vec3 rotated = vec3(
        c * normal.x - s * normal.y,  // X'
        s * normal.x + c * normal.y,  // Y'
        normal.z                      // Z'
    );
    
    rotated = normalize(rotated);
    
    vec3 encoded = rotated * 0.5 + 0.5;
    
    return vec4(encoded, tex.a);
}