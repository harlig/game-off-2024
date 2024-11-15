shader_type canvas_item;
uniform vec3 color: source_color;

void fragment() {
	COLOR.rgb = mix(color, color + 0.2, UV.y + UV.x) + sin(TIME) * 0.1;
}
