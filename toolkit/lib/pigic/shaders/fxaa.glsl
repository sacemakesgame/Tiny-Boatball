/**
Basic FXAA implementation based on the code on geeks3d.com with the
modification that the texture2DLod stuff was removed since it's
unsupported by WebGL.

--

From:
https://github.com/mitsuhiko/webgl-meincraft

Copyright (c) 2011 by Armin Ronacher.

Some rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * The names of the contributors may not be used to endorse or
      promote products derived from this software without specific
      prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @license
 * Copyright (c) 2011 NVIDIA Corporation. All rights reserved.
 *
 * TO  THE MAXIMUM  EXTENT PERMITTED  BY APPLICABLE  LAW, THIS SOFTWARE  IS PROVIDED
 * *AS IS*  AND NVIDIA AND  ITS SUPPLIERS DISCLAIM  ALL WARRANTIES,  EITHER  EXPRESS
 * OR IMPLIED, INCLUDING, BUT NOT LIMITED  TO, NONINFRINGEMENT,IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL  NVIDIA 
 * OR ITS SUPPLIERS BE  LIABLE  FOR  ANY  DIRECT, SPECIAL,  INCIDENTAL,  INDIRECT,  OR  
 * CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION,  DAMAGES FOR LOSS 
 * OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY 
 * OTHER PECUNIARY LOSS) ARISING OUT OF THE  USE OF OR INABILITY  TO USE THIS SOFTWARE, 
 * EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
 */

// #ifndef fxaa_reduce_min
//   #define fxaa_reduce_min   (1.0/ 128.0)
// #endif
// #ifndef fxaa_reduce_mul
//   #define fxaa_reduce_mul   (1.0 / 8.0)
// #endif
// #ifndef fxaa_span_max
//   #define fxaa_span_max     8.0
// #endif

uniform float fxaa_reduce_min;
uniform float fxaa_reduce_mul;
uniform float fxaa_span_max;

varying vec2 v_rgbNW;
varying vec2 v_rgbNE;
varying vec2 v_rgbSW;
varying vec2 v_rgbSE;
varying vec2 v_rgbM;


// ----------------------------- VERTEX ----------------------------------------

#ifdef VERTEX

void texcoords(
  vec2 fragCoord, 
  vec2 resolution,
  out vec2 v_rgbNW, 
  out vec2 v_rgbNE,
  out vec2 v_rgbSW, 
  out vec2 v_rgbSE,
  out vec2 v_rgbM
) {
  vec2 inverseVP = 1.0 / resolution.xy;
  v_rgbNW = (fragCoord + vec2(-1.0, -1.0)) * inverseVP;
  v_rgbNE = (fragCoord + vec2(1.0, -1.0)) * inverseVP;
  v_rgbSW = (fragCoord + vec2(-1.0, 1.0)) * inverseVP;
  v_rgbSE = (fragCoord + vec2(1.0, 1.0)) * inverseVP;
  v_rgbM = vec2(fragCoord * inverseVP);
}

vec4 position( mat4 transform_projection, vec4 vertex_position ) {
  //compute the texture coords and store them in varyings
  vec2 res = love_ScreenSize.xy;
  vec2 fragCoord = VertexTexCoord.xy * res;
  texcoords(fragCoord, res, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);
  return transform_projection * vertex_position;
}

#endif

// ----------------------------- FRAGMENT -------------------------------------
 
#ifdef PIXEL

//optimized version for mobile, where dependent 
//texture reads can be a bottleneck
vec4 fxaa(
  Image tex, 
  vec2 fragCoord, 
  vec2 resolution,
  vec2 v_rgbNW, 
  vec2 v_rgbNE, 
  vec2 v_rgbSW, 
  vec2 v_rgbSE, 
  vec2 v_rgbM
) {
  vec4 color;
  mediump vec2 inverseVP = vec2(1.0 / resolution.x, 1.0 / resolution.y);
  vec3 rgbNW = Texel(tex, v_rgbNW).xyz;
  vec3 rgbNE = Texel(tex, v_rgbNE).xyz;
  vec3 rgbSW = Texel(tex, v_rgbSW).xyz;
  vec3 rgbSE = Texel(tex, v_rgbSE).xyz;
  vec4 texColor = Texel(tex, v_rgbM);
  vec3 rgbM  = texColor.xyz;
  vec3 luma = vec3(0.299, 0.587, 0.114);
  float lumaNW = dot(rgbNW, luma);
  float lumaNE = dot(rgbNE, luma);
  float lumaSW = dot(rgbSW, luma);
  float lumaSE = dot(rgbSE, luma);
  float lumaM  = dot(rgbM,  luma);
  float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
  
  mediump vec2 dir;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
  
  float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                        (0.25 * fxaa_reduce_mul), fxaa_reduce_min);
  
  float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
  dir = min(vec2(fxaa_span_max, fxaa_span_max),
            max(vec2(-fxaa_span_max, -fxaa_span_max),
            dir * rcpDirMin)) * inverseVP;
  
  vec3 rgbA = 0.5 * (
      Texel(tex, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz +
      Texel(tex, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz);
  vec3 rgbB = rgbA * 0.5 + 0.25 * (
      Texel(tex, fragCoord * inverseVP + dir * -0.5).xyz +
      Texel(tex, fragCoord * inverseVP + dir * 0.5).xyz);

  float lumaB = dot(rgbB, luma);
  if ((lumaB < lumaMin) || (lumaB > lumaMax))
      color = vec4(rgbA, texColor.a);
  else
      color = vec4(rgbB, texColor.a);
  return color;
}

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
  vec2 res = love_ScreenSize.xy;
  vec2 fragCoord = texture_coords * res; 

  return fxaa(tex, fragCoord, res, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);
}

#endif