class_name Torch extends Node3D;

var is_lit := false

signal torch_state_changed(lit: bool)

func _ready() -> void:
	var seek_time := randf();
	$AnimationPlayer.seek(seek_time);
	$MeshInstance3D.material_override.set_shader_parameter("flip_h", seek_time > 0.5)

func light_torch() -> void:
	$CPUParticles3D.emitting = true
	$OmniLight3D.show()
	is_lit = true
	torch_state_changed.emit(is_lit)

func extinguish_torch() -> void:
	$CPUParticles3D.emitting = false
	$OmniLight3D.hide()
	is_lit = false
	torch_state_changed.emit(is_lit)
