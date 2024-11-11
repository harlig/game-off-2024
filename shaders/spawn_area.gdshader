shader_type spatial;

uniform vec4 color: source_color;
uniform float width = 1.0;
uniform bool is_hovered = false;
uniform vec2 hover_loc = vec2(0.5);
uniform float x_scale = 1.667;

void fragment() {
	float border = smoothstep(1.0, 0.96, UV.x)
	* smoothstep(1.0, 0.7, UV.y)
	* smoothstep(0.0, 0.3, UV.y);

	float dist = distance(UV * vec2(x_scale, 1.0), hover_loc * vec2(x_scale, 1.0));
	float ripple = sin(dist * 85.0 + TIME * 10.0);
	ripple *= smoothstep(0.15, 0.12, dist);

	float alpha = min((UV.x * 7.5), 1.0) * border * color.a;

	if (is_hovered) {
		alpha *= smoothstep(0.12, 0.15, dist);
		alpha += ripple;
	}

	ALBEDO = color.rgb;
	ALPHA = max(alpha, 0.0);
}
