shader_type canvas_item;

uniform float percent: hint_range(0.0, 1.0) = 0.5;
uniform float border_width = 0.1;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	COLOR.rgb = tex.rgb;

	bool inner = texture(TEXTURE, UV * (1.0 + border_width * 2.0) - vec2(border_width)).a > 0.5;
	bool outer = tex.r > 0.05;
	float thresh = step(percent, UV.y + sin(TIME * 2.0 + UV.x * 20.0) * 0.02);
	float mask = float(inner) * float(outer) * thresh;

	COLOR.rgb += mask * 0.1;
}
