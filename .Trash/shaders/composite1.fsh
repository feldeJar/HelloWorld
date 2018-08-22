#version 120
/*
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
*/

/*
						[][][][][] [][][][][] [][][][][] [][][][][] []   	  
						[]	  	       []     []      [] []	     [] []        
						[]	 	       []     []      [] []	     [] []  	    	  
						[][][][][]     []     []      [] [][][][][] []   	  
								[]     []     []      [] []	        []        
								[]     []     []      [] []	              	  
						[][][][][]     []     [][][][][] []	        []        
						Before editing anything here make sure you've 
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
 http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2348685-kadir-nck-shader-v1-2
						   
				Kadir Nck's shaders, derived from Chocapic's shaders */

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES



#define GODRAYS
	const float exposure = 1.0;			//godrays intensity 1.2 is default
	const float density = 0.2;			
	const int NUM_SAMPLES = 6;			//increase this for better quality at the cost of performance /8 is default
	const float grnoise = 0.0;		//amount of noise /0.0 is default
	
#define WATER_REFLECTIONS			
	#define REFLECTION_STRENGTH 0.8


//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;

uniform sampler2D composite;
uniform sampler2D gaux4;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;

uniform int isEyeInWater;
uniform int worldTime;
uniform ivec2 eyeBrightness;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;

float rainStrength2 = clamp(wetness, 0.0f, 1.0f)/1.0f;

uniform int fogMode;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float matflag = texture2D(gaux1,texcoord.xy).g;
	
vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
	
vec4 color = texture2D(composite,texcoord.xy);
	
vec3 aux = texture2D(gaux1, texcoord.st).rgb;
float sky_lightmap = pow(aux.r,10.0);
float torch_lightmap = pow(aux.r,1.0);
float iswet = wetness*pow(sky_lightmap,10.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));
	


float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

#ifdef WATER_REFLECTIONS

float cdist(vec2 coord) {
	return max(abs(coord.x-0.5),abs(coord.y-0.5))*2.0;
}

#endif

#ifdef GODRAYS

	float getnoise(vec2 pos) {
		return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
	}

#endif

#ifdef WATER_REFLECTIONS
	vec4 raytrace(vec3 fragpos, vec3 normal) {

		vec4 color = vec4(0.0);
		vec3 start = fragpos;
		vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
		vec3 vector = 1.2 * rvector;
		vec3 oldpos = fragpos;
		fragpos += vector;
		vec3 tvector = vector;
		int sr = 0;
			
		for(int i=0;i<30;i++){
			
			vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
			if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
			vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
			spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
			float err = distance(fragpos.xyz,spos.xyz);
			if(err < length(vector)*pow(length(tvector),0.11)*1.75){

				sr++;
				if(sr >=  4.0){
						
					float border = clamp(1.0 - pow(cdist(pos.st), 5.0), 0.0, 1.0);
					color = texture2D(composite, pos.st);
					color.a = 1.0;
					color.a *= border;
					break;
						
				}
					
				tvector -=vector;
				vector *= 0.1;
			
			}
				
			vector *= 2.2;
			oldpos = fragpos;
			tvector += vector;
			fragpos = start + tvector;
				
		}
			
		return color;
			
	}

#endif

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {

	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);
	
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
	

	#ifdef WATER_REFLECTIONS

		if (iswater > 0.9) {

			vec4 reflection = raytrace(fragpos, normal);
				
				float normalDotEye = dot(normal, normalize(fragpos));
				float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
				
				reflection.rgb = mix(gl_Fog.color.rgb, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
				reflection.a = min(reflection.a + 0.75,1.0);
				
				color.rgb = mix(color.rgb,reflection.rgb , fresnel * (1.0-isEyeInWater*0.8)*reflection.a);

		}
		
	#endif

	vec3 colmult = mix(vec3(1.0),vec3(0.1,0.25,0.45),isEyeInWater);
	float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*3.4,2.0),0.0,1.0);
	color.rgb = mix(color.rgb*colmult,vec3(0.05,0.1,0.15),depth_diff*isEyeInWater);
		
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));

		
		
/* DRAWBUFFERS:5 */
	
	//draw rain
	color.rgb += texture2D(gaux4,texcoord.xy).a*0.1;
	
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lpos = tpos.xy/tpos.z;
	vec2 lightPos = lpos*0.5+0.5;
	
	
	#ifdef GODRAYS
	
		const float exposure = 0.7;
		const float density = 0.5;			
		const int NUM_SAMPLES = 10;
		const float grnoise = 0.0;
	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float illuminationDecay = 1.0;
		vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
		float gr = 0.0;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),3.0);
	
		for(int i=0; i < NUM_SAMPLES ; i++) {
		
			textCoord -= deltaTextCoord;
				
			float sample = texture2D(gdepth, textCoord + noise*grnoise).r;
			gr += sample;

		}
	
		vec3 gr_color_sunrise = vec3(2.52, 0.6, 0.1) * TimeSunrise * (1.0 - rainStrength2 * 1.0);
		vec3 gr_color_noon = vec3(2.52, 0.6, 0.1) * TimeNoon * (1.0 - rainStrength2 * 1.0);
		vec3 gr_color_sunset = vec3(2.52, 0.6, 0.1) * TimeSunset * (1.0 - rainStrength2 * 1.0);
		vec3 gr_color_night = vec3(0.01, 0.2, 0.7) * TimeMidnight * (1.0 - rainStrength2 * 1.0);
		vec3 gr_color_rain = vec3(0.5,0.7,1.0) * 0.3 * (TimeSunrise + TimeNoon + TimeSunset) * rainStrength2;
		
		vec3 gr_color = gr_color_sunrise + gr_color_noon + gr_color_sunset + gr_color_night + gr_color_rain;
		
		// Fix, that moonrays are visible at daytime
		float truepos = 0.0f;
		
		if ((worldTime < 13000 || worldTime > 23000) && sunPosition.z < 0) truepos = 1.0 * (TimeSunrise + TimeNoon + TimeSunset); 
		if ((worldTime < 23000 || worldTime > 13000) && -sunPosition.z < 0) truepos = 1.0 * TimeMidnight; 
		
		color.rgb = mix(color.rgb,pow(gr_color,vec3(1.0/4.0)),(gr/NUM_SAMPLES)*exposure*truepos*(eyeBrightness.y/255.0)*length(pow(gr_color,vec3(1.0/2.2)))*illuminationDecay/sqrt(3.0)*transition_fading);
		
	#endif
	
	float visiblesun = 0.0;
	float temp;
	int nb = 0;

				
	//calculate sun occlusion (only on one pixel) 
	if (texcoord.x < pw && texcoord.x < ph) {
		for (int i = 0; i < 10;i++) {
			for (int j = 0; j < 10 ;j++) {
			temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0)*10.0,ph*(j-5.0)*10.0)).g;
			visiblesun +=  1.0-float(temp > 0.04) ;
			nb += 1;
			}
		}
		visiblesun /= nb;

	}
	
	color = clamp(color,0.0,1.0);

	gl_FragData[0] = vec4(color.rgb,visiblesun);
	
}
