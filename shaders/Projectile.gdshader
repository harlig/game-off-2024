shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo: source_color;
uniform bool flip_h = false;
uniform bool highlight = false;
uniform vec3 highlight_color : source_color;

void fragment() {
	vec2 uv = UV;

	if (flip_h) {
		uv.x = 1.0 - uv.x;
	}

	vec4 tex = texture(albedo, uv);

	ALPHA = tex.a;
	

}
