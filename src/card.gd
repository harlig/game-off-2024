extends AspectRatioContainer
var max_health = 5
var health = max_health
var mana = 2
var damage = 2
var card_name = "Example Creature"
var card_image_path = "res://logo.png"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateDisplay()

	pass # Replace with function body.

func updateDisplay() -> void:
	$Background/Title.text = card_name
	$Background/Health.text = str(health)
	$Background/Mana.text = str(mana)
	$Background/Damage.text = str(damage)
	$MarginContainer/TextureRect.texture = load(card_image_path)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	resizePortrait()
	
func resizePortrait() -> void:
	var current_width = $MarginContainer.size.x
	var margin_value = current_width * 0.2 
	$MarginContainer.add_theme_constant_override("margin_left", margin_value)
	$MarginContainer.add_theme_constant_override("margin_right", margin_value)
	$MarginContainer.add_theme_constant_override("margin_top", margin_value * 0.5)  # Optional: set a different ratio for top
	$MarginContainer.add_theme_constant_override("margin_bottom", margin_value * 0.5)  # Optional: set a different ratio for bottom
	
func setStats(max_health, health, mana, damage, card_name, card_image_path) -> void:
	self.max_health = max_health
	self.health = health
	self.mana = mana
	self.damage = damage
	self.card_name = card_name
	self.card_image_path = card_image_path
	updateDisplay()
	
