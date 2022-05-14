// Description:
// - Sun and moon.
// License:
// - J. Cuéllar 2022 MIT License
// - See: LICENSE File.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, blend_add, async_visible;

// Library.
float Saturate(float value){
	return clamp(value, 0.0, 1.0);
}

vec3 Mul43(mat4 m, vec4 v){
	return (m * v).xyz;
}

vec4 Mul44(mat4 m, vec4 v){
	return m * v;
}

float Disk(vec3 norm, vec3 coords, lowp float size){
	float d = length(norm - coords);
	return 1.0 - step(size, d);
}

vec3 ContrastLevel(vec3 val, float level){
	return mix(val, val * val * val, level);
}

// Sun.
uniform vec3 _SunDirection = vec3(0.0, 1.0, 0.0);
uniform vec4 _SunDiskColor: hint_color = vec4(1.0);
uniform float _SunDiskSize = 0.03;
uniform float _SunDiskIntensity = 1.0;

// Moon.
uniform vec4 _MoonColor: hint_color;
uniform sampler2D _MoonTexture: hint_albedo;
uniform vec3 _MoonDirection;
uniform mat3 _MoonMatrix;
uniform float _MoonSize;
uniform float _HorizonLevel = 0.0;

varying mat4 v_camera_matrix; varying float v_moon_size;
void vertex(){
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	v_camera_matrix = CAMERA_MATRIX;
	v_moon_size = 1.0 / _MoonSize;
}

void fragment(){
	vec3 color;
	vec4 view = Mul44(INV_PROJECTION_MATRIX, vec4(SCREEN_UV * 2.0 - 1.0, 1.0, 1.0));
	view = CAMERA_MATRIX * view;
	view.xyz /= view.w;
	view.xyz -= (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 worldPos = normalize(view).xyz;
	
	float moonMask = Saturate(dot(worldPos.xyz, _MoonDirection.xyz));
	vec3 moonCoords = v_moon_size * (_MoonMatrix * worldPos) + 0.5;
	
	vec3 sunDisk = Disk(worldPos, _SunDirection, _SunDiskSize) *
		_SunDiskColor.rgb * _SunDiskIntensity;
	
	vec4 moon = textureLod(_MoonTexture, 
		vec2(-moonCoords.x + 1.0, moonCoords.y), 0.0);
	moon.rgb = ContrastLevel(moon.rgb * _MoonColor.rgb, _MoonColor.a);
	moon.rgb *= moonMask;
	float moonDiskMask = Saturate(1.0 - moon.a);
	
	color.rgb = sunDisk * moonDiskMask;
	color.rgb += moon.rgb;
	worldPos.y += _HorizonLevel;
	color.rgb = mix(color.rgb, vec3(0.0), Saturate(-worldPos.y * 100.0));
	ALBEDO = color.rgb;
}