varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
// varying vec4 vertexColor;
varying vec4 instanceColor;


#ifdef VERTEX

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn

uniform vec3 headPosition;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;
attribute vec3 InstancePosition;
attribute float InstanceScale;
attribute vec4 InstanceColor;


vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    instanceColor = InstanceColor;

    // Transform to world, view, and projection space
    vertexPosition.xyz += InstancePosition;
    worldPosition = modelMatrix * vertexPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;
    screenPosition.y *= -1.;

    // Apply a color gradient based on vertex height (y)
    return screenPosition;
}

#endif


#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
    vec4 texcolor = Texel(tex, texcoord);    
    if (texcolor.a == 0.0) discard;

    return texcolor * color;
}

#endif