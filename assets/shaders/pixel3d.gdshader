shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 virtual_resolution = vec2(426.0, 240.0);
uniform float color_steps = 28.0;
uniform float shadow_crush = 0.08;
uniform float warm_lift = 0.035;

void fragment() {
	vec2 pixel_uv = (floor(SCREEN_UV * virtual_resolution) + vec2(0.5)) / virtual_resolution;
	vec3 color = texture(screen_texture, pixel_uv).rgb;

	color.r += warm_lift;
	color.b -= warm_lift * 0.45;
	color = max(color - vec3(shadow_crush), vec3(0.0)) / (1.0 - shadow_crush);
	color = floor(color * color_steps + vec3(0.5)) / color_steps;

	COLOR = vec4(color, 1.0);
}
