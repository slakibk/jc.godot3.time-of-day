// Description:
// - Per pixel sky.
// License:
// - J. Cuéllar 2022 MIT License
// - See: LICENSE File.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_front, skip_vertex_transform, blend_mix;

// Uniforms.
//------------------------------------------------------------------------------
// General.
uniform vec2 _ColorCorrection;
uniform vec4 _GroundColor: hint_color;
uniform float _HorizonLevel;

// Coords.
uniform vec3 _SunDirection;
uniform vec3 _MoonDirection;
uniform mat3 _DeepSpaceMatrix;

// Rayleigh.
uniform float _AtmDarkness;
uniform float _AtmSunIntensity;
uniform vec4 _AtmDayTint: hint_color;
uniform vec4 _AtmHorizonLightTint: hint_color;
uniform vec4 _AtmNightTint: hint_color;
uniform vec3 _AtmLevelParams;
uniform float _AtmThickness;
uniform vec3 _AtmBetaRay;

// Mie.
uniform vec4 _AtmSunMieTint: hint_color;
uniform float _AtmSunMieIntensity;
uniform vec3 _AtmSunPartialMiePhase;

uniform vec4 _AtmMoonMieTint: hint_color;
uniform float _AtmMoonMieIntensity;
uniform vec3 _AtmMoonPartialMiePhase;
uniform vec3 _AtmBetaMie;

const float RAYLEIGH_ZENITH_LENGTH = 8.4e3;
const float MIE_ZENITH_LENGTH = 1.25e3;

// Background.
uniform sampler2D _BackgroundTexture: hint_albedo;
uniform vec4 _BackgroundColor: hint_color;

// Stars Field.
uniform vec4 _StarsFieldColor: hint_color;
uniform sampler2D _StarsFieldTexture: hint_albedo;
uniform float _StarsScintillation;
uniform float _StarsScintillationSpeed;
uniform sampler2D _NoiseTex: hint_albedo;

// Lib,
//------------------------------------------------------------------------------
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

vec3 TonemapPhoto(vec3 col, float exposure, float level){
	col.rgb *= exposure;
	return mix(col.rgb, 1.0 - exp2(-col.rgb), level);
}

vec2 EquirectUV(vec3 norm){
	vec2 ret;
	ret.x = (atan(norm.x, norm.z) + kPI) * kINV_TAU;
	ret.y = acos(norm.y) * kINV_PI;
	return ret;
}

// Functions.
//------------------------------------------------------------------------------
float RayleighPhase(float mu){
	return k3PI16 * (1.0 + mu * mu);
}

float MiePhase(float mu, vec3 partial){
	return kPI4 * partial.x * (pow(partial.y - partial.z * mu, -1.5));
}

// Simplifield for more performance.
void SimpleOpticalDepth(float y, out float sr, out float sm){
	y = max(0.03, y + 0.03) + _AtmLevelParams.y;
	y = 1.0 / (y * _AtmLevelParams.x);
	sr = y * RAYLEIGH_ZENITH_LENGTH;
	sm = y * MIE_ZENITH_LENGTH;
}

// ṔPaper based.
void OpticalDepth(float y, out float sr, out float sm){
	y = max(0.0, y);
	y = Saturate(y * _AtmLevelParams.x);
	
	float zenith = acos(y);
	zenith = cos(zenith) + 0.15 * pow(93.885 - ((zenith * 180.0) / kPI), -1.253);
	zenith = 1.0 / (zenith + _AtmLevelParams.y);
	
	sr = zenith * RAYLEIGH_ZENITH_LENGTH;
	sm = zenith * MIE_ZENITH_LENGTH;
}

vec3 AtmosphericScattering(float sr, float sm, vec2 mu, vec3 mult){
	vec3 betaMie = _AtmBetaMie;
	vec3 betaRay = _AtmBetaRay * _AtmThickness;
	
	vec3 extcFactor = SaturateRGB(exp(-(betaRay * sr + betaMie * sm)));
	
	float extcFF = mix(Saturate(_AtmThickness * 0.5), 1.0, mult.x);
	vec3 finalExtcFactor = mix(1.0 - extcFactor, (1.0 - extcFactor) * extcFactor, extcFF);
	float rayleighPhase = RayleighPhase(mu.x);
	vec3 BRT = betaRay * rayleighPhase;
	vec3 BMT = betaMie * MiePhase(mu.x, _AtmSunPartialMiePhase);
	BMT *= _AtmSunMieIntensity * _AtmSunMieTint.rgb;
	
	
	vec3 BRMT = (BRT + BMT) / (betaRay + betaMie);
	vec3 scatter = _AtmSunIntensity  * (BRMT * finalExtcFactor) * _AtmDayTint.rgb * mult.y;
	scatter = mix(scatter, scatter * (1.0 - extcFactor), _AtmDarkness);
	
	vec3 lcol =  mix(_AtmDayTint.rgb, _AtmHorizonLightTint.rgb, mult.x);
	vec3 nscatter = (1.0 - extcFactor) * _AtmNightTint.rgb;
	nscatter += MiePhase(mu.y, _AtmMoonPartialMiePhase) * 
		_AtmMoonMieTint.rgb * _AtmMoonMieIntensity * 0.005;
	
	nscatter = mix(nscatter, nscatter * (1.0 - extcFactor), _AtmDarkness);

	
	return (scatter * lcol) + nscatter;
}

varying vec4 v_world_pos;
varying vec3 v_deep_space_coords;
varying vec4 v_angle_mult;

void vertex(){
	vec4 vert = vec4(VERTEX, 0.0);
	POSITION =  PROJECTION_MATRIX * INV_CAMERA_MATRIX * WORLD_MATRIX * vert;
	POSITION.z = POSITION.w;
	
	v_world_pos = WORLD_MATRIX * vert;
	v_deep_space_coords.xyz = (_DeepSpaceMatrix * VERTEX).xyz;
	
	v_angle_mult.x = Saturate(1.0 - _SunDirection.y);
	v_angle_mult.y = Saturate(_SunDirection.y + 0.45);
	v_angle_mult.z = Saturate(-_SunDirection.y + 0.30);
	v_angle_mult.w = Saturate(_SunDirection.y);
}

void fragment(){
	vec3 col = vec3(0.0);
	vec3 worldPos = normalize(v_world_pos).xyz;
	
	// Atmosphere.
	vec2 mu = vec2(dot(_SunDirection, worldPos), dot(_MoonDirection, worldPos));
	float sr, sm;
	SimpleOpticalDepth(worldPos.y + _AtmLevelParams.z + _HorizonLevel, sr, sm);
	worldPos.y += _HorizonLevel;
	float horizonBlend = Saturate((worldPos.y - 0.03) * 3.0);
	
	vec3 scatter = AtmosphericScattering(sr, sm, mu.xy, v_angle_mult.xyz);
	col.rgb += scatter.rgb;
	
	// DeepSpace.
	vec3 deepSpace = vec3(0.0);
	vec2 deepSpaceUV = EquirectUV(normalize(v_deep_space_coords));
	
	vec3 background = textureLod(_BackgroundTexture, deepSpaceUV, 0.0).rgb;
	background *= _BackgroundColor.rgb;
	background = ContrastLevel(background, _BackgroundColor.a);
	deepSpace += background.rgb;// * moonMask;
	
	float starsScintillation = textureLod(_NoiseTex, UV + (TIME * _StarsScintillationSpeed), 0.0).r;
	starsScintillation = mix(1.0, starsScintillation * 1.5, _StarsScintillation);
	
	vec3 starsField = textureLod(_StarsFieldTexture, deepSpaceUV, 0.0).rgb * _StarsFieldColor.rgb;
	starsField = SaturateRGB(mix(starsField.rgb, starsField.rgb * starsScintillation, _StarsScintillation));
	//deepSpace.rgb -= saturate(starsField.r*10.0);
	deepSpace.rgb += starsField.rgb;// * moonMask;
	deepSpace.rgb *= v_angle_mult.z;
	col.rgb += deepSpace.rgb * horizonBlend;
	col.rgb = mix(col.rgb, _GroundColor.rgb *v_angle_mult.w, 
		Saturate((-worldPos.y - _AtmLevelParams.z)*100.0) * _GroundColor.a);
	col.rgb = TonemapPhoto(col.rgb, _ColorCorrection.y, _ColorCorrection.x);
	
	ALBEDO = col.rgb;
}