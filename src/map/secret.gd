class_name Secret extends Control

const secret_scene := preload("res://src/map/secret.tscn")


const TRIALS_OFFERED_COUNT := 3

var difficulty: int

enum TrialType {
	DAMAGE,
	HEALTH,
	DAMAGE_AND_HEALTH,
	MANA
}
func trial_type_string(trial_type: TrialType) -> String:
	match trial_type:
		TrialType.DAMAGE:
			return "damage"
		TrialType.HEALTH:
			return "health"
		TrialType.DAMAGE_AND_HEALTH:
			return "damage + health"
		TrialType.MANA:
			return "mana"
		_:
			return "unknown"

signal gained_secret(secret: String)
signal lost_secret()


####################################################
####################################################
# This is how you should instantiate a secret scene
####################################################
####################################################
static func create_secret_trial(secret_difficulty: int) -> Secret:
	var secret := secret_scene.instantiate()
	secret.difficulty = secret_difficulty
	return secret
####################################################
####################################################
####################################################
####################################################

func _ready() -> void:
	var used_trial_types := []
	for ndx in range(TRIALS_OFFERED_COUNT):
		var button := $SecretsArea/HBoxContainer/Button.duplicate()
		var trial_type: TrialType
		while true:
			trial_type = TrialType.values()[randi() % TrialType.size()]
			if trial_type not in used_trial_types:
				used_trial_types.append(trial_type)
				break
		var trial_value := 0
		match trial_type:
			TrialType.DAMAGE:
				trial_value = 5 * difficulty
			TrialType.HEALTH:
				trial_value = 10 * difficulty
			TrialType.DAMAGE_AND_HEALTH:
				trial_value = 15 * difficulty
			TrialType.MANA:
				trial_value = 3 * difficulty
			_:
				push_error("Unknown trial type", trial_type)
		button.text = str(trial_value) + " " + trial_type_string(trial_type)
		button.connect("pressed", _on_trial_button_pressed.bind(trial_type, trial_value))
		button.show()
		$SecretsArea/HBoxContainer.add_child(button)

func _on_trial_button_pressed(trial_type: TrialType, trial_value: int) -> void:
	gained_secret.emit(str(trial_value) + " " + trial_type_string(trial_type))
