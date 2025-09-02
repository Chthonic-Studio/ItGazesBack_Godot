# How-to-use:
# This scene is a child of the Player. It creates the fog-of-war effect.
# The root LightOccluder2D casts a full-screen shadow, and its child PointLight2D
# creates a "hole" in that shadow, revealing the world.
class_name VisionCone extends LightOccluder2D

# We get a reference to the light node to rotate it.
@onready var player_light: PointLight2D = $PlayerLight

func _process(_delta: float) -> void:
	# This logic is self-contained. It calculates the direction to the mouse and sets the rotation.
	var mouse_direction = get_global_mouse_position() - global_position
	
	# The texture for the cone points "down" in its local space. We add PI/2 (90 degrees)
	# to its calculated angle to make it point correctly towards the mouse cursor.
	player_light.rotation = mouse_direction.angle() + (PI / 2.0)
