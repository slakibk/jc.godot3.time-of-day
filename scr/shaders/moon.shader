// Description:
// - Simple moon.
// License:
// - J. Cuéllar 2022 MIT License
// - See: LICENSE File.
shader_type spatial;
render_mode unshaded, async_visible;

uniform sampler2D _Texture;
uniform vec3 _SunDirection;

float Saturate(float v){
	return clamp(v, 0.0, 1.0);
}

varying vec3 v_normal;
void vertex(){
	v_normal = (WORLD_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment(){
	float l = Saturate(max(0.0, dot(_SunDirection, v_normal)) * 2.0);
	ALBEDO = texture(_Texture, UV).rgb * l;
}