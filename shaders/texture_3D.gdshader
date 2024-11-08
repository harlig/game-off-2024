shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo: source_color;
uniform bool flip_h = false;

void fragment() {
	vec2 uv = UV;

	if (flip_h) {
		uv.x = 1.0 - uv.x;
	}

	vec4 tex = texture(albedo, uv);

	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
