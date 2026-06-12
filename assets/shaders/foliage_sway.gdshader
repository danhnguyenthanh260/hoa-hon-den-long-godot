// Lá cây v2: texture PBR thật (Polyhaven CC0) chiếu triplanar world-space
// + đung đưa theo gió (vertex sway, pha lệch theo world-position).
// Triplanar lấy world-pos TRƯỚC khi sway → texture đứng yên trên lá đang lay.
// sway=0 → đứng yên (rêu, thân giả).
shader_type spatial;
render_mode cull_disabled;  // lá hai mặt — tàu lá ribbon nhìn từ dưới vẫn thấy

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float sway : hint_range(0.0, 0.3) = 0.05;
uniform float speed : hint_range(0.0, 4.0) = 1.4;
uniform float tex_scale = 0.45;
uniform float nrm_depth : hint_range(0.0, 2.0) = 0.8;
uniform sampler2D tex_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_nrm : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 v_tpos;
varying vec3 v_tnrm;

void vertex() {
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tpos = wpos * tex_scale;
	v_tnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float ph = wpos.x * 0.9 + wpos.z * 0.7 + wpos.y * 0.4;
	float t = TIME * speed;
	float amp = sway * (0.65 + 0.35 * sin(ph * 2.3));
	VERTEX.x += (sin(t + ph) + 0.45 * sin(t * 2.17 + ph * 1.6)) * amp;
	VERTEX.z += (cos(t * 0.83 + ph) + 0.45 * sin(t * 1.7 + ph * 2.1)) * amp * 0.7;
	VERTEX.y += sin(t * 1.13 + ph * 1.3) * amp * 0.3;
}

void fragment() {
	vec3 w = abs(v_tnrm);
	w = pow(w, vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 c = texture(tex_diff, v_tpos.zy).rgb * w.x
		+ texture(tex_diff, v_tpos.xz).rgb * w.y
		+ texture(tex_diff, v_tpos.xy).rgb * w.z;
	ALBEDO = tint.rgb * c * 1.25;
	NORMAL_MAP = texture(tex_nrm, v_tpos.zy).rgb * w.x
		+ texture(tex_nrm, v_tpos.xz).rgb * w.y
		+ texture(tex_nrm, v_tpos.xy).rgb * w.z;
	NORMAL_MAP_DEPTH = nrm_depth;
	ROUGHNESS = roughness;
}
