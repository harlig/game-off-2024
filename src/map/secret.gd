class_name Secret extends Control

const secret_scene := preload("res://src/map/secret.tscn")


const TRIALS_OFFERED_COUNT := 3

var difficulty: int

enum TrialType {
	DAMAGE,
	HEALTH,
	DAMAGE_AND_HEALTH,
	MANA,
}

signal gained_secret(secret: String)
signal lost_secret()


####################################################
####################################################
# This is how you should instantiate a secret scene
####################################################
####################################################
static func create_secret_trial(combat_difficulty: int) -> Secret:
	var secret := secret_scene.instantiate()
	secret.difficulty = combat_difficulty
	return secret
####################################################
####################################################
####################################################
####################################################

func _ready() -> void:

	#TODO: make the trial types unique
	for ndx in range(TRIALS_OFFERED_COUNT):
		var button := $SecretsArea/HBoxContainer/Button.duplicate()
		var trial_type: TrialType = TrialType.values()[randi() % TrialType.size()]
		var trial_value := 0
		match trial_type:
			TrialType.DAMAGE:
				trial_value = 5 + difficulty
			TrialType.HEALTH:
				trial_value = 10 + difficulty
			TrialType.DAMAGE_AND_HEALTH:
				trial_value = 15 + difficulty
			TrialType.MANA:
				trial_value = 1 + difficulty
			_:
				push_error("Unknown trial type", trial_type)
		button.text = str(trial_value) + " " + TrialType.keys()[trial_type].to_lower()
		button.connect("pressed", _on_trial_button_pressed.bind(trial_type, trial_value))
		button.show()
		$SecretsArea/HBoxContainer.add_child(button)

func _on_trial_button_pressed(trial_type: TrialType, trial_value: int) -> void:
	gained_secret.emit(str(trial_value) + " " + str(TrialType.keys()[trial_type]))
