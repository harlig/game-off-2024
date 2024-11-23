shader_type canvas_item;

uniform float percent: hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	COLOR.rgb = tex.rgb;

	bool inner = texture(TEXTURE, UV * 1.2 - vec2(0.1)).a > 0.5;
	bool outer = tex.r > 0.05;
	float thresh = step(percent, UV.y + sin(TIME * 2.0 + UV.x * 20.0) * 0.02);
	float mask = float(inner) * float(outer) * thresh;

	COLOR.rgb += mask * 0.4;
}
