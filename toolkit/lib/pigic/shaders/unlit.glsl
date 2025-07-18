#ifdef VERTEX

varying vec4 worldPosition;
varying vec3 worldNormal;
varying vec4 vertexColor;
vec4 screenPosition;

//Model and Camera
uniform mat4 projectionMatrix; //Camera Matrix (FOV, Aspect Ratio, etc.)
uniform mat4 viewMatrix; //Camera Transformation Matrix
uniform mat4 modelMatrix; //Model Transformaton Matrix
uniform mat4 modelMatrixInverse; //Inverse to calculate normals
attribute vec3 VertexNormal;


vec4 position(mat4 transformProjection, vec4 vertexPosition)
{    
    worldNormal = normalize(vec3(vec4(modelMatrixInverse * vec4(VertexNormal, 0.)))); //interpolate normal

    vertexColor = VertexColor;

    vec4 pos = vertexPosition;
    worldPosition = modelMatrix * pos;

    vec4 viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;
    screenPosition.y *= -1.; // for canvas flip y thing

    return screenPosition;
}

#endif


#ifdef PIXEL

varying vec4 worldPosition;
varying vec3 worldNormal;
varying vec4 vertexColor;

vec4 shadowColor = vec4(51./255., 93./255., 142./255., 1.);


uniform vec3 boatColor;
uniform bool blink;


vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {

    //IGNORE ALPHA
    vec4 texcolor = Texel(tex, texcoord);
    if (texcolor.a == 0.0) { discard; };
    
    if (blink) {
        return vec4(1.);
    }
    // calculate normal
    vec3 n = normalize(worldNormal);
    vec3 normalColor = (n + vec3(1.0)) * 0.5; // Shift from [-1, 1] to [0, 1]

    // SHADOW
    float inShadow = 0.;
    
    if (vertexColor != vec4(1.)) {
        return vec4(vec3(vec4(boatColor, 1.) * mix(shadowColor, vec4(1.), 1.-inShadow)), 1.0);
    } else {
        texcolor *= color;
        return inShadow > 0.5 ? shadowColor : texcolor;
    }
}

#endif