shader_type spatial;

uniform bool is_valid = false;
uniform vec3 valid_color: source_color;
uniform vec3 not_valid_color: source_color;
uniform bool is_selected = false;
uniform float len;

void fragment() {
	float speedx = float(is_selected) * .02 + .003;
	float scalex = (UV.x - TIME * speedx) * 20.0 * len;
	ALPHA = step(sin(scalex), 0);

	if (is_valid) {
		ALBEDO = valid_color;
		EMISSION = vec3(10.0);
	} else {
		ALBEDO = not_valid_color;
	}
}
