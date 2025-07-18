uniform vec2 pixelSize; // usually 1.0 / resolution
uniform vec3 outlineColor;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec3 center = Texel(texture, uv).rgb;
    vec3 left   = Texel(texture, uv + vec2(-pixelSize.x, 0)).rgb;
    vec3 right  = Texel(texture, uv + vec2(pixelSize.x, 0)).rgb;
    vec3 up     = Texel(texture, uv + vec2(0, -pixelSize.y)).rgb;
    vec3 down   = Texel(texture, uv + vec2(0, pixelSize.y)).rgb;

    float diff = 0.0;
    diff += distance(center, left);
    diff += distance(center, right);
    diff += distance(center, up);
    diff += distance(center, down);

    if (diff > 0.1) {
        return vec4(outlineColor, 1.); // black outline
    } else {
        discard; // transparent
    }
}