class_name Projectile extends Node3D
@onready var unit_attackable: Attackable = $Attackable
var team: Attackable.Team
var damage: int = 1
var speed: float = 5
var velocity:= Vector3(0, 0, -5)
enum Direction {LEFT, RIGHT}
@export var direction: Direction = Direction.RIGHT
var has_processed_collision:=  false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if velocity.x < 0:
		$MeshInstance3D.material_override.set_shader_parameter("flip_h", true)
	else:
		$MeshInstance3D.material_override.set_shader_parameter("flip_h", false)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	global_position+= velocity * delta

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
