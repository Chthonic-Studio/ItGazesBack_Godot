@tool
class_name WallLight extends Node2D

## This script controls a customizable wall light.
## It manages the light's color, energy, and two flicker effects: Intensity and Blinking.
## To use: Place the WallLight.tscn scene in your level. Customize the properties in the Inspector.

enum FlickerType { INTENSITY, BLINKING }

@export_category("Light Settings")
@export var light_color : Color = Color.WHITE:
	set(value):
		light_color = value
		_update_light_properties()

@export_range(0.0, 5.0, 0.1) var energy : float = 1.0:
	set(value):
		energy = value
		_update_light_properties()

# --- REASON FOR CHANGE ---
# Added light_size to control the scale of the light's texture via an export variable.
# This allows for easy resizing of the light's area of effect directly from the editor.
@export_range(0.1, 10.0, 0.1) var light_size : float = 1.0:
	set(value):
		light_size = value
		_update_light_properties()

@export_category("Flicker Effect")
@export var flicker_enabled : bool = true

@export var flicker_type : FlickerType = FlickerType.INTENSITY

@export_group("Intensity Flicker")
@export_range(0.1, 20.0, 0.1) var flicker_speed : float = 5.0 # How fast the light flickers.
@export_range(0.0, 1.0, 0.05) var flicker_strength : float = 0.2 # How much the light's energy changes.

@export_group("Blinking Flicker")
## Higher values mean more blinks per second.
@export_range(0.1, 10.0, 0.1) var blink_frequency : float = 2.0 # Average blinks per second.
## A value of 0 will make the blinking perfectly regular. A value of 1 will make the time between blinks highly variable and chaotic.
@export_range(0.0, 1.0, 0.05) var blink_randomness : float = 0.5 # 0 = regular, 1 = highly random timing.

@onready var point_light_2d: PointLight2D = $PointLight2D

var _base_energy : float = 1.0
var _noise_offset : float

var _blink_timer : float = 0.0
var _is_blinking_on : bool = true

func _ready() -> void:
	_base_energy = energy
	_noise_offset = randf() * 1000.0
	_update_light_properties()
	# Initialize the blink timer with a random value to start.
	_reset_blink_timer()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not flicker_enabled:
		point_light_2d.energy = _base_energy
		return
	
	match flicker_type:
		FlickerType.INTENSITY:
			_process_intensity_flicker()
		FlickerType.BLINKING:
			_process_blinking_flicker(delta)

## This function ensures that changes in the Inspector are immediately visible.
func _update_light_properties() -> void:
	if not is_inside_tree():
		return
	
	if point_light_2d:
		point_light_2d.color = light_color
		_base_energy = energy # Update base energy when the exported property changes.
		# --- REASON FOR CHANGE ---
		# This line applies the light_size to the PointLight2D's texture_scale property.
		# It's the most direct way to control the visual size of the light.
		point_light_2d.texture_scale = light_size
		if not flicker_enabled:
			point_light_2d.energy = _base_energy

## Generates a seamless noise value between -1.0 and 1.0.
func noise(x: float) -> float:
	return (sin(x * 1.2) + cos(x * 2.5)) / 2.0

func _process_intensity_flicker() -> void:
	var noise_val = noise(Time.get_ticks_msec() * 0.001 * flicker_speed + _noise_offset)
	point_light_2d.energy = _base_energy + noise_val * _base_energy * flicker_strength

func _process_blinking_flicker(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0:
		# When the timer runs out, flip the light's state (on to off, or off to on).
		_is_blinking_on = not _is_blinking_on
		_reset_blink_timer()

	# Set the light's energy based on the current state.
	if _is_blinking_on:
		point_light_2d.energy = _base_energy
	else:
		point_light_2d.energy = 0.0

func _reset_blink_timer() -> void:
	# Calculate the base duration for one phase (half a blink cycle).
	var base_duration = (1.0 / blink_frequency) / 2.0
	# Introduce randomness.
	var min_duration = base_duration * (1.0 - blink_randomness)
	var max_duration = base_duration * (1.0 + blink_randomness)
	# Set the timer to a new random value within the calculated range.
	_blink_timer = randf_range(min_duration, max_duration)
