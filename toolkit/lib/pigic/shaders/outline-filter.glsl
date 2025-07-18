#ifdef VERTEX

varying vec4 worldPosition;
varying vec3 worldNormal;
vec4 screenPosition;

//Model and Camera
uniform mat4 projectionMatrix; //Camera Matrix (FOV, Aspect Ratio, etc.)
uniform mat4 viewMatrix; //Camera Transformation Matrix
uniform mat4 modelMatrix; //Model Transformaton Matrix
uniform mat4 modelMatrixInverse; //Inverse to calculate normals
attribute vec3 VertexNormal;
uniform bool isWater;
uniform float time;

vec4 position(mat4 transformProjection, vec4 vertexPosition)
{    
    worldNormal = normalize(vec3(vec4(modelMatrixInverse * vec4(VertexNormal, 0.)))); //interpolate normal

    vec4 pos = vertexPosition;
    worldPosition = modelMatrix * pos;

    if (isWater) {
        worldPosition.y += .0 + 0.2 * sin(worldPosition.x * 2. + time * 3.) * cos(worldPosition.z * 2. + time * 5.);
    }


    vec4 viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;
    screenPosition.y *= -1.; // for canvas flip y thing

    return screenPosition;
}

#endif


#ifdef PIXEL

uniform vec3 idColor;

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {   
    //IGNORE ALPHA
    vec4 texcolor = Texel(tex, texcoord);
    if (texcolor.a == 0.0) { discard; };
       
           
    return vec4(idColor, 1.);
}

#endif