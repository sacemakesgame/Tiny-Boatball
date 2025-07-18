#ifdef VERTEX

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;


vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    vec4 screenPosition =  projectionMatrix * viewMatrix * modelMatrix * vertexPosition;
    return screenPosition;
}

#endif

#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
{
    vec4 texcolor = Texel(tex, texcoord);
    if (texcolor.a == 0.0) { discard; }
    return texcolor;
}

#endif