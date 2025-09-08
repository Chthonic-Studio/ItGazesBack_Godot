class_name InteractionPrompt extends CanvasLayer

## This UI element will follow a Node2D in the game world.
var target_node: Node2D = null
## The vertical offset in pixels to position the prompt above the target.
var y_offset: float = -50.0

@onready var label: Label = $Label

func _ready() -> void:
	# Ensure the label is always full bright and not affected by world lighting.
	label.modulate = Color(1, 1, 1, 1)
	hide()
	label.hide()

func _process(_delta: float) -> void:
	# If the prompt is visible and has a valid target, update its position.
	if visible and is_instance_valid(target_node):
		# Get the main camera from the scene tree's active viewport.
		var camera = get_viewport().get_camera_2d()
		if not camera: return
		
		# Calculate the target world position for the prompt (above the target node).
		var world_position = target_node.global_position + Vector2(0, y_offset)
		
		# --- REASON FOR THE CHANGE ---
		# This is the correct and robust way to convert a world position to a screen position
		# for a control node within a CanvasLayer in Godot 4. A camera's transform converts
		# screen-to-world, so its affine_inverse() converts world-to-screen. This is the
		# mathematically correct operation that was missing before.
		label.global_position = camera.get_transform().affine_inverse() * world_position

func set_text(text: String) -> void:
	label.text = text
	label.modulate = Color(1, 1, 1, 1) # Re-apply every time to be safe

## Shows the prompt.
func show_prompt() -> void:
	print("Showing prompt!")
	show()
	label.show()

## Hides the prompt.
func hide_prompt() -> void:
	hide()
	label.hide()
