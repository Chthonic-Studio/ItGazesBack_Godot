extends CanvasLayer

# These constants define the min/max values for the shader effects.
# Adjust these to tune the "feel" of the anxiety and sanity loss.
const MIN_BREATHING_SPEED = 4.0
const MAX_BREATHING_SPEED = 15.0
const MIN_LUNGS_SCALE = 0.05
const MAX_LUNGS_SCALE = 0.15

const MAX_GLITCH_POWER = 0.08
const MAX_GLITCH_RATE = 0.6
const MAX_GLITCH_COLOR_RATE = 0.05

# Get references to the sprites.
@onready var lungs: Sprite2D = $Control/HBoxContainer/Lungs
@onready var brain: Sprite2D = $Control/HBoxContainer/Brain

func _ready() -> void:
	# Ensure the materials are unique to this instance to avoid weird shared behavior.
	lungs.material = lungs.material.duplicate()
	brain.material = brain.material.duplicate()

	# Connect to the PlayerManager signals.
	PlayerManager.anxiety_changed.connect(_on_anxiety_changed)
	PlayerManager.sanity_changed.connect(_on_sanity_changed)
	
	# Set the initial state of the shaders when the game starts.
	_on_anxiety_changed(PlayerManager.anxiety)
	_on_sanity_changed(PlayerManager.sanity)

# This function is called whenever the player's anxiety changes.
func _on_anxiety_changed(new_anxiety: int) -> void:
	# Calculate an "anxiety level" from 0.0 (calm) to 1.0 (max anxiety).
	var anxiety_level = 1.0 - (float(new_anxiety) / PlayerManager.max_anxiety)

	# Use lerp (linear interpolation) to smoothly map the anxiety level to shader properties.
	var speed = lerp(MIN_BREATHING_SPEED, MAX_BREATHING_SPEED, anxiety_level)
	var scale = lerp(MIN_LUNGS_SCALE, MAX_LUNGS_SCALE, anxiety_level)
	
	# Set the uniforms on the lungs shader material.
	lungs.material.set_shader_parameter("breathing_speed", speed)
	lungs.material.set_shader_parameter("scale_amount", scale)
	lungs.material.set_shader_parameter("red_tint_intensity", anxiety_level)

# This function is called whenever the player's sanity changes.
func _on_sanity_changed(new_sanity: int) -> void:
	# Calculate an "insanity level" from 0.0 (sane) to 1.0 (max insanity).
	var insanity_level = 1.0 - (float(new_sanity) / PlayerManager.max_sanity)
	
	# Map the insanity level to the glitch shader properties.
	var power = lerp(0.0, MAX_GLITCH_POWER, insanity_level)
	var rate = lerp(0.0, MAX_GLITCH_RATE, insanity_level)
	var color_rate = lerp(0.0, MAX_GLITCH_COLOR_RATE, insanity_level)

	# Set the uniforms on the brain shader material.
	brain.material.set_shader_parameter("shake_power", power)
	brain.material.set_shader_parameter("shake_rate", rate)
	brain.material.set_shader_parameter("shake_color_rate", color_rate)
