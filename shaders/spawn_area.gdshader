shader_type spatial;

uniform vec4 color: source_color;
uniform float width = 1.0;
uniform bool is_hovered = false;
uniform vec2 hover_loc = vec2(0.5);

void fragment() {
	float border = smoothstep(1.0, 0.96, UV.x)
	* smoothstep(1.0, 0.7, UV.y)
	* smoothstep(0.0, 0.3, UV.y);

	float dist = distance(UV, hover_loc);
	float ripple = sin(dist * 200.0 + TIME * 10.0);
	ripple *= smoothstep(0.15, 0.12, dist);

	float alpha = (UV.x) * border * color.a;

	if (is_hovered) {
		alpha += ripple;
	}

	ALBEDO = color.rgb;
	ALPHA = max(alpha, 0.0);
}
