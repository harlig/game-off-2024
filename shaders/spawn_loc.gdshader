shader_type spatial;

uniform vec3 color: source_color;

void fragment() {
	float dist = distance(UV, vec2(0.5));
	float ripple = sin(dist * 40.0 + TIME * 10.0);
	ripple *= smoothstep(0.45, 0.35, dist);

	ALPHA = ripple * 2.0;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
