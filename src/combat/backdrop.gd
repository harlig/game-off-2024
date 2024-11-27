extends Node3D

func _ready() -> void:
	# Grass
	spawn_random(Vector2i(-60, -40), Vector2i(60, 40), Vector2i(120, 80), Vector2(1.0, 1.0), $GrassMM, 0.3, 0.7, 0.5)

	# Bush
	spawn_random(Vector2i(-30, -15), Vector2i(30, 20), Vector2i(10, 10), Vector2(1.0, 1.0), $BushMM, 0.7)


func spawn_random(from: Vector2i, to: Vector2i, partitions: Vector2i, overflow: Vector2, multimesh: MultiMeshInstance3D, scale_min: float, scale_max: float = 1.0, range_scale: float = 1.0) -> void:
	var x_step := float(to.x - from.x) / float(partitions.x);
	var y_step := float(to.y - from.y) / float(partitions.y);
	var x_range := range(from.x, to.x, x_step);
	var y_range := range(from.y, to.y, y_step);

	# Throws Buffer argument error: https://github.com/godotengine/godot/issues/68592
	multimesh.multimesh.instance_count = len(x_range) * len(y_range)

	var ind := 0;

	for x: int in x_range:
		@warning_ignore("NARROWING_CONVERSION")
		x *= range_scale;
		for y: int in y_range:
			@warning_ignore("NARROWING_CONVERSION")
			y *= range_scale;
			# var flip_x := float(randi() % 2 == 0);
			var x_pos := randf_range(x - overflow.x, x + x_step + overflow.x);
			var z_pos := randf_range(y - overflow.y, y + y_step + overflow.y);
			var y_pos := 0.0;

			if z_pos > -13.0 and z_pos < -8.0:
				y_pos = -10.0;


			var xform := Transform3D();
			xform.origin = Vector3(x_pos, y_pos, z_pos);
			xform = xform.rotated_local(Vector3(1.0, 0.0, 0.0), -PI / 4)
			xform = xform.scaled_local(Vector3.ONE * randf_range(scale_min, scale_max));

			multimesh.multimesh.set_instance_transform(ind, xform);
			# multimesh.multimesh.set_instance_custom_data(ind, Color(x_pos, z_pos, 0.0, flip_x));

			ind += 1;
