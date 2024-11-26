class_name Attackable extends Area3D

const HEALTHBAR_VISIBLE_TIME := 5.0

var healthbar_visible_time_rem := HEALTHBAR_VISIBLE_TIME;

@export var team: Team
var hp := 75:
	set(new_hp):
		if new_hp > max_hp:
			hp = max_hp
		else:
			hp = new_hp
		$Label3D.text = str(hp) + "/" + str(max_hp)

var max_hp := hp:
	set(new_max_hp):
		max_hp = new_max_hp
		$Label3D.text = str(hp) + "/" + str(max_hp)

enum Team {PLAYER, ENEMY}

signal died()


func _ready() -> void:
	# TODO: This dont work. When does Unit.direction get set?
	if get_parent().direction == Unit.Direction.LEFT:
		$Healthbar.rotate_z(PI);


func _physics_process(delta: float) -> void:
	healthbar_visible_time_rem -= delta
	if healthbar_visible_time_rem <= 0:
		$Healthbar.hide()


func take_damage(damage: int) -> void:
	if get_parent() is Unit and (get_parent() as Unit).is_invulnerable:
		return

	hp -= damage

	if hp <= 0:
		emit_signal("died")
		get_parent().queue_free()

	if has_node("Healthbar"):
		healthbar_visible_time_rem = HEALTHBAR_VISIBLE_TIME
		$Healthbar.show()

		var tween := get_tree().create_tween()
		var material: ShaderMaterial = $Healthbar.material_override
		tween.tween_method(set_healthbar_percent, material.get_shader_parameter("percent"), float(hp) / float(max_hp), 0.3);

		material.set_shader_parameter("color", Color.RED)

		await get_tree().create_timer(0.3).timeout

		if material.get_shader_parameter("color") == Color.RED:
			material.set_shader_parameter("color", Color.WHITE)


func set_healthbar_percent(value: float) -> void:
	$Healthbar.material_override.set_shader_parameter("percent", value)


func heal(amount: int) -> void:
	hp += amount
