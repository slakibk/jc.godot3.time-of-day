// Description:
// - Panoramic clouds.
// License:
// - J. Cuéllar 2022 MIT License
// - See: LICENSE File.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_front, skip_vertex_transform, blend_mix;

uniform sampler2D _Texture: hint_black_albedo;
uniform vec4 _DayColor: hint_color = vec4(1.0);
uniform vec4 _HorizonColor: hint_color = vec4(1.0);
uniform vec4 _NightColor: hint_color = vec4(1.0);
uniform float _Intensity = 1.0;
uniform vec4 _DensityChannel = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 _AlphaChannel = vec4(0.0, 0.0, 1.0, 0.0);

uniform float _HorizonFadeOffset = 0.1;
uniform float _HorizonFade = 5.0;

uniform vec3 _SunDirection;
uniform vec3 _MoonDirection;

const float kPI          = 3.1415927f;
const float kINV_PI      = 0.3183098f;
const float kHALF_PI     = 1.5707963f;
const float kINV_HALF_PI = 0.6366198f;
const float kQRT_PI      = 0.7853982f;
const float kINV_QRT_PI  = 1.2732395f;
const float kPI4         = 12.5663706f;
const float kINV_PI4     = 0.0795775f;
const float k3PI16       = 0.1193662f;
const float kTAU         = 6.2831853f;
const float kINV_TAU     = 0.1591549f;
const float kE           = 2.7182818f;

float Saturate(float val){
	return clamp(val, 0.0, 1.0);
}

vec3 SaturateRGB(vec3 val){
	return clamp(val, 0.0, 1.0);
}

vec3 ContrastLevel(vec3 val, float level){
	return mix(val, val * val * val, level);
}

vec2 EquirectUV(vec3 norm){
	vec2 ret;
	ret.x = (atan(norm.x, norm.z) + kPI) * kINV_TAU;
	ret.y = acos(norm.y) * kINV_PI;
	return ret;
}

//varying vec4 v_world_pos;
varying vec4 v_angle_mult;
void vertex(){
	vec4 vert = vec4(VERTEX, 0.0);
	POSITION =  PROJECTION_MATRIX * INV_CAMERA_MATRIX * WORLD_MATRIX * vert;
	POSITION.z = POSITION.w;
	//v_world_pos = WORLD_MATRIX * vert;
	v_angle_mult.x = Saturate((1.0 - _SunDirection.y)-0.20);
	v_angle_mult.y = Saturate(_SunDirection.y + 0.45);
	v_angle_mult.z = Saturate(-_SunDirection.y + 0.30);
	v_angle_mult.w = Saturate((-_SunDirection.y)+0.60);
}

void fragment(){
	vec3 localPos = normalize(VERTEX).xyz;
	vec4 col = texture(_Texture, EquirectUV(localPos));
	//col.rgb = ContrastLevel(col.rgb, 0.5);
	
	float density = dot(col, _DensityChannel) * _Intensity;
	float alpha  = dot(col, _AlphaChannel);
	
	vec3 tint = mix(_DayColor.rgb, _HorizonColor.rgb, v_angle_mult.x) ;
	tint = mix(tint, _NightColor.rgb, v_angle_mult.w);
	
	ALBEDO = tint.rgb * density;
	ALPHA = alpha;
	ALPHA = mix(ALPHA, 0.0, Saturate((-localPos.y+_HorizonFadeOffset) * _HorizonFade));
}