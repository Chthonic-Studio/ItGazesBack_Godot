# How-to-use:
# 1. Create a Node2D named "FieldOfView" as a child of the Player scene. Attach this script.
# 2. Add a PointLight2D named "VisionCone" and a CanvasModulate named "Darkness" as children of "FieldOfView".
# 3. Configure the nodes in the editor as per the final instructions. This script handles the rest.
class_name FieldOfView extends Node2D

@export_category("Field of View Settings")
@export_range(1, 180) var fov_angle: float = 60.0:
	set(value):
		fov_angle = value
		if is_inside_tree(): _update_cone_shape()

@export_range(1, 20) var fov_distance: float = 5.0:
	set(value):
		fov_distance = value
		if is_inside_tree(): _update_cone_shape()

@export var obscurity_color: Color = Color("#404040"): # A dark grey, not pure black
	set(value):
		obscurity_color = value
		if is_inside_tree() and _darkness: _darkness.color = obscurity_color

@onready var _vision_cone: PointLight2D = $VisionCone
@onready var _darkness: CanvasModulate = $Darkness

func _ready() -> void:
	# This ensures the initial values from the Inspector are applied when the scene loads.
	_darkness.color = obscurity_color
	_update_cone_shape()

func _process(_delta: float) -> void:
	# This logic is self-contained. It calculates the direction to the mouse and sets the rotation.
	var mouse_direction = get_global_mouse_position() - global_transform.origin
	if not mouse_direction.is_zero_approx():
		# This calculation correctly aligns the downward-pointing texture with the mouse.
		rotation = mouse_direction.angle() + (PI / 2.0)

## Toggles the entire FOV effect on or off. Useful for cutscenes or specific zones.
func toggle_visibility(is_visible: bool) -> void:
	if _vision_cone: _vision_cone.enabled = is_visible
	if _darkness: _darkness.visible = is_visible

## Recalculates the PointLight2D's properties based on the exported variables.
func _update_cone_shape() -> void:
	if not _vision_cone: return
	
	var base_scale := Vector2.ONE
	base_scale.y = fov_distance
	
	var angle_scale_factor = fov_angle / 45.0
	base_scale.x = fov_distance * angle_scale_factor
	
	# This correctly scales the light's texture via the node's transform scale property.
	_vision_cone.scale = base_scale
