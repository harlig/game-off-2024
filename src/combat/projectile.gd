class_name Projectile extends Node3D

@export var direction: Direction = Direction.RIGHT

var team: Attackable.Team
var damage: int = 1
var speed: float = 5
var velocity := Vector3(0, 0, -5)
var has_processed_collision := false
var initial_position: Vector3

enum Direction {LEFT, RIGHT}

func _ready() -> void:
	initial_position = global_position
	if velocity.x < 0:
		$MeshInstance3D.material_override.set_shader_parameter("flip_h", true)
	else:
		$MeshInstance3D.material_override.set_shader_parameter("flip_h", false)


func _process(delta: float) -> void:
	global_position += velocity * delta
	if velocity.x < 0:
		if global_position.x < initial_position.x - 10:
			queue_free()
	else:
		if global_position.x > initial_position.x + 10:
			queue_free()

# when something runs into my target area
func _on_target_area_area_entered(area: Area3D) -> void:
	if area is not Attackable or area.get_parent() == self:
		return
	var attackable := area as Attackable
	if attackable.team == team:
		return
	if has_processed_collision:
		return
	has_processed_collision = true
	attackable.take_damage(damage)
	queue_free()


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
