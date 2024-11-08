shader_type spatial;

uniform vec4 color: source_color;
uniform float width = 0.5;

void fragment() {
	float border = float(UV.x > 1.0 - width)
	* smoothstep(1.0, 0.7, UV.y)
	* smoothstep(0.0, 0.3, UV.y);
		//|| UV.y < width / 2.0
		//|| UV.y > 1.0 - width / 2.0) * UV.x;
		//UV.x < width);
		//||
	float dash = step(sin((UV.y + UV.x) * 50.0 - TIME), -0.4);

	ALBEDO = color.rgb;
	ALPHA = (UV.x - 0.3) * border * dash * color.a;
}
