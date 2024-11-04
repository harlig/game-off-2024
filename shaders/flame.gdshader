shader_type spatial;
//render_mode blend_add;
render_mode unshaded;

uniform sampler2D albedo: source_color, repeat_disable;
uniform vec3 color: source_color;

varying float angle;

float random(int seed) {
    float float_seed = float(seed);
    return fract(sin(float_seed * 12.9898 + 78.233) * 43758.5453);
}

void vertex() {
	angle = random(INSTANCE_ID) / 3.0;
	//angle -= angle / 2.0;
}

void fragment() {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    mat2 rotation_matrix = mat2(vec2(cos_angle, -sin_angle), vec2(sin_angle, cos_angle));

    // Apply the rotation
    vec2 uv = rotation_matrix * UV;
	
	vec4 tex = texture(albedo, uv);

	ALBEDO = color * tex.r * 3.0;
	ALPHA = tex.a * 2.0;
}
