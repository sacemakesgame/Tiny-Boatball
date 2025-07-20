/*
	based on godotshaders.com: Wobbly Effect – Hand painted animation
    https://godotshaders.com/shader/wobbly-effect-hand-painted-animation/
*/


uniform Image flowMap;
uniform float time;

uniform float strength = 0.003;
uniform float scale = 2.;
uniform int frames = 4;
uniform float speed = 5;

//Returns a value between 0 and 1 depending of the frames -> exemple: frames = 4, frame 1 = 0.25
float clock(float time){
	float fframes = float(frames);
	return floor(mod(time * speed, fframes)) / fframes;
}


vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords){
    // Scale for texture look
    // float n = noise(uv * scale + u_time * 0.1); // Add time for animated noise if needed
    // float n = noise(uv * scale);

    float c = clock(time);
    vec4 offset = Texel(flowMap, uv + vec2(c, c)) * strength;

    // return Texel(texture, uv + n);
    return Texel(texture, uv + offset.xy - vec2(.5, .5) * strength);

	// vec4 offset = texture(flowMap, vec2(UV.x + c, UV.y + c)) * strength; //Get offset 
	//COLOR = texture(TEXTURE, vec2(UV.x,UV.y) + normal.xy); //Apply offset
	// COLOR = texture(TEXTURE, vec2(UV.x,UV.y) + offset.xy - vec2(0.5,0.5)*strength); //We need to remove the displacement 

}

