// Lá cây: đốm noise hai tầng (chất lá) + normal sần + đung đưa theo gió.
// Sway = vertex displacement pha theo world-position — mỗi khóm lệch pha,
// hai sóng sin chồng nhau cho nhịp gió không đều. sway=0 → đứng yên (rêu).
shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.16, 0.3, 0.1, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float sway : hint_range(0.0, 0.3) = 0.05;
uniform float speed : hint_range(0.0, 4.0) = 1.4;
uniform float mottle : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_nrm : hint_normal, filter_linear_mipmap, repeat_enable;

void vertex() {
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ph = wpos.x * 0.9 + wpos.z * 0.7 + wpos.y * 0.4;
	float t = TIME * speed;
	float amp = sway * (0.65 + 0.35 * sin(ph * 2.3));
	VERTEX.x += (sin(t + ph) + 0.45 * sin(t * 2.17 + ph * 1.6)) * amp;
	VERTEX.z += (cos(t * 0.83 + ph) + 0.45 * sin(t * 1.7 + ph * 2.1)) * amp * 0.7;
	VERTEX.y += sin(t * 1.13 + ph * 1.3) * amp * 0.3;
}

void fragment() {
	float n = texture(noise_tex, UV * 2.5).r;
	float n2 = texture(noise_tex, UV * 9.0).r;
	ALBEDO = albedo.rgb * (1.0 - mottle * 0.5 + mottle * (0.6 * n + 0.55 * n2));
	ROUGHNESS = roughness - 0.15 * n2;
	NORMAL_MAP = texture(noise_nrm, UV * 6.0).rgb;
	NORMAL_MAP_DEPTH = 0.7;
}
