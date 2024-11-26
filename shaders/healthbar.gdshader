shader_type spatial;
render_mode shadows_disabled, unshaded;

uniform float percent: hint_range(0.0, 1.0) = 0.5;
uniform vec4 color: source_color = vec4(1.0);

void fragment() {
	float thresh = step(UV.x, percent);
	
	ALBEDO = thresh * color.rgb;
}
