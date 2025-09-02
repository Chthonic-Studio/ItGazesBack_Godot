# How-to-use:
# 1. This scene should be a child of the Player.
# 2. The script will automatically handle rotating to face the mouse.
class_name VisionCone extends Node2D

# --- REASON FOR CHANGE ---
# We need a reference to the light node to rotate it, not the root node.
@onready var light: PointLight2D = $Light

func _process(_delta: float) -> void:
	# This logic is self-contained. It calculates the direction to the mouse and sets the rotation.
	var mouse_direction = get_global_mouse_position() - global_position
	
	# The texture for the cone points "down" in its local space. We add PI/2 (90 degrees)
	# to its calculated angle to make it point correctly towards the mouse cursor.
	# We now apply the rotation to the light node itself.
	light.rotation = mouse_direction.angle() + (PI / 2.0)
