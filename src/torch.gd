class_name Torch extends Node3D;

var is_lit := false

func _ready() -> void:
	var seek_time := randf();
	$AnimationPlayer.seek(seek_time);
	print(seek_time);
	$MeshInstance3D.material_override.set_shader_parameter("flip_h", seek_time > 0.5);

func light_torch() -> void:
	$CPUParticles3D.emitting = true
	$OmniLight3D.show()
	is_lit = true
