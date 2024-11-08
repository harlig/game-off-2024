class_name CombatCamera extends Camera3D;

const CAMERA_MOTION_X_SCALE = 0.0002;
const CAMERA_MOTION_Y_SCALE = 0.0005;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position.x += event.relative.x * CAMERA_MOTION_X_SCALE;
		position.z += event.relative.y * CAMERA_MOTION_Y_SCALE;
