#ifdef GL_ES
precision highp float;
#endif

#ifdef VERTEX

varying vec4 worldPosition;
varying vec3 worldNormal;
varying vec4 localPosition;
vec4 screenPosition;

//Model and Camera
uniform mat4 projectionMatrix; //Camera Matrix (FOV, Aspect Ratio, etc.)
uniform mat4 viewMatrix; //Camera Transformation Matrix
uniform mat4 modelMatrix; //Model Transformaton Matrix
uniform mat4 modelMatrixInverse; //Inverse to calculate normals
attribute vec4 VertexNormal;
varying vec4 project; //shadow projected vertex


//Shadow Map
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;
mat4 Bias = mat4( // change projected depth values from -1 - 1 to 0 - 1
	0.5, 0.0, 0.0, 0.5,
	0.0, 0.5, 0.0, 0.5,
	0.0, 0.0, 0.5, 0.5,
	0.0, 0.0, 0.0, 1.0
	);

uniform mediump float time;
uniform bool isDisplay;

vec4 position(mat4 transformProjection, vec4 vertexPosition)
{    
    worldNormal = normalize(vec3(vec4(modelMatrixInverse * VertexNormal))); //interpolate normal


    localPosition = vertexPosition;
    vec4 pos = vertexPosition;
    float waveX = sin(pos.x * 10. + time * 20.);
    float waveY = cos(pos.y * 10. + time * 15.);
    float waveZ = sin(pos.z * 10. + time * 18.);
    vec3 wobble = vec3(waveX, waveY, waveZ) * 0.01;//.005;
    // pos.xyz += wobble;
    
    worldPosition = modelMatrix * pos;

    if (!isDisplay) {
        project = vec4(shadowProjectionMatrix * shadowViewMatrix * modelMatrix * vertexPosition * Bias); //projected position on shadowMap
        worldPosition.y += 0.2 * sin(worldPosition.x * 2. + time * 3.) * cos(worldPosition.z * 2. + time * 5.);
    }

    vec4 viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;
    screenPosition.y *= -1.; // for canvas flip y thing

    return screenPosition;
}

#endif


#ifdef PIXEL

varying vec4 worldPosition;
varying vec3 worldNormal;
varying vec4 localPosition;
varying vec4 project; //shadow projected vertex

uniform vec3 ballPosition;
uniform float ballRadius;
uniform bool isDisplay;



vec3 shadowColor = vec3(51./255., 93./255., 142./255.);

//Shadow Map
uniform vec3 shadowMapDir;
uniform Image shadowMapImage;

float shadowBiasStrength = .00005;

uniform Image textureImage;
uniform mediump float time;

// Hash function for noise
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}


mediump vec4 effect(mediump vec4 color, Image tex, mediump vec2 texcoord, mediump vec2 pixcoord) {
// vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {   
    vec3 n = normalize(worldNormal);
    
    
    // cool foam thing goin on
    vec2 uv1, uv2;
    if (isDisplay) {
        // uv1 = localPosition.xz *2 * .5 + vec2(time * 0.02, time * 0.03);
        // uv2 = localPosition.xz *2 * .7 + vec2(-time * 0.1, time * 0.04);
        // return vec4(vec3(n.y), 1.);
        if (n.y > .5) {
            uv1 = localPosition.xz * 2. * .5 + vec2(time * 0.02, time * 0.03);
            uv2 = localPosition.xz * 2. * .7 + vec2(-time * 0.1, time * 0.04);
        } else {
            uv1 = localPosition.xy * 2. * .5 + vec2(time * 0.02, time * 0.03);
            uv2 = localPosition.xy * 2. * .7 + vec2(-time * 0.1, time * 0.04);
        }
    } else {
        if (n.y > 0.) {
            uv1 = worldPosition.xz *.6 * .5 + vec2(time * 0.02, time * 0.03);
            uv2 = worldPosition.xz *.6 * .7 + vec2(-time * 0.1, time * 0.04);
        } else {
            uv1 = worldPosition.xy *.6 * .5 + vec2(time * 0.02, time * 0.03);
            uv2 = worldPosition.xy *.6 * .7 + vec2(-time * 0.1, time * 0.04);
        }
    }

    float n1 = noise(uv1);
    float n2 = noise(uv2);

    float s1 = sin(n1 * 20.0 + time * 0.2);
    float s2 = sin(n2 * 15.0 + time * 0.35);

    // Separate thresholds
    float foam1 = step(0.8, s1);  // large, slow
    float foam2 = step(0.6, s2);  // small, twitchy

    // Colors
    vec3 water     = vec3(128./255., 230./255., 214./255.);
    vec3 foamA     = vec3(117./255., 224./255., 207./255.);
    vec3 foamB     = vec3(139./255., 240./255., 224./255.);

    // Combine
    vec3 c = water;
    c = mix(c, foamA, foam1);
    c = mix(c, foamB, foam2);

    vec3 texcolor = c;


    if (!isDisplay) {
        // Normalize the vertex normal (in case it's not already normalized)
        // Map the normal's XYZ components to RGB color
        vec3 normalColor = (n + vec3(1.0)) * 0.5; // Shift from [-1, 1] to [0, 1]
        
        // Output the color based on the normal
        float angleFactor = max(0.0, 1.0 - dot(normalColor, shadowMapDir)); // Approximation of angle effect
        float shadowBias = shadowBiasStrength * angleFactor;
        shadowBias = clamp(shadowBias, 0.0, 0.01);

        float pixelDist = (project.z-shadowBias)/project.w; //How far this pixel is from the camera
        vec2 shadowMapCoord = ((project.xy)/project.w); //Where this vertex is on the shadowMap
        float shadowMapPixelDist;
        float inShadow;

        shadowMapPixelDist = Texel(shadowMapImage, shadowMapCoord).r;
        inShadow = mix(float(shadowMapPixelDist < pixelDist),0.0,1.0-float((shadowMapCoord.x >= 0.0) && (shadowMapCoord.y >= 0.0) && (shadowMapCoord.x <= 1.0) && (shadowMapCoord.y <= 1.0))); //0.0;


        float dx = ballPosition.x - worldPosition.x;
        float dy = ballPosition.y - worldPosition.y;
        float dz = ballPosition.z - worldPosition.z;
        float radius = ballRadius - abs(dy)/20.;
        // if (playerPosition.y >= worldPosition.y && (sqrt(dx * dx + dz * dz) < playerRadius)) {
        if ((sqrt(dx * dx + dz * dz) < radius)) {
            // return texcolor * shadowColor;
            inShadow = 1.0;
        }
        // vec4 finalcolor = vec4(vec3(texcolor) * mix(vec3(1.), shadowColor, inShadow * .5), 1.);
        // vec4 finalcolor = vec4(vec3(texcolor) * mix(vec3(1.), shadowColor, clamp(inShadow * 10., 0., 1.)), 1.);

        if (inShadow > 0.) {
            return vec4(shadowColor, 1.);
        } else {
            return vec4(vec3(texcolor), 1.);
        }
    } else {
        return vec4(vec3(texcolor), 1.);
    }

    // return finalcolor;
}

#endif