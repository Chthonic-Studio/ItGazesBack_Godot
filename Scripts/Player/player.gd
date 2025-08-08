class_name Player extends CharacterBody2D

@export_category("Health")
@export var max_hp : int = 6
@export var hp : int = 6

# We'll store the last non-zero direction to keep facing the same way when idle.
var last_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

@onready var sprite : AnimatedSprite2D = $PlayerSprite
@onready var state_machine: PlayerStateMachine = $StateMachine

signal direction_changed ( new_direction : Vector2 )

func _ready() -> void:
	state_machine.initialize(self)

func _process( delta ):
	# get_vector is perfect for 8-directional movement.
	# It automatically handles normalization, so the player doesn't move faster diagonally.
	direction = Input.get_vector("left", "right", "up", "down")
	
func _physics_process( delta ):
	# This function's only job is to execute the movement based on the 
	# velocity calculated by the current state (Walk, Idle, etc.).
	move_and_slide()
	
func update_animation_direction() -> void:
	# Only update if the player is actually moving.
	if direction == Vector2.ZERO:
		return

	# We determine the dominant direction by looking at the vector's components.
	# This is far more reliable than angle calculations.
	var new_direction := Vector2.ZERO
	
	if abs(direction.x) > 0.2:
		new_direction.x = sign(direction.x)
	if abs(direction.y) > 0.2:
		new_direction.y = sign(direction.y)
	
	# Only update the animation if the resulting direction has changed.
	if new_direction != last_direction:
		last_direction = new_direction
		# We don't need to emit the direction_changed signal here unless another
		# system depends on the 8-way vector. For now, we'll keep it for the
		# InteractionHost, but it could be removed if that's not needed.
		direction_changed.emit(last_direction)
		state_machine.update_animation()

# This function will determine the animation suffix (e.g., "down", "up_left").
func get_anim_direction_string() -> String:
	# Define the mapping from a direction vector to its animation suffix.
	# This is done once and stored for efficiency.
	var direction_map := {
		Vector2(0, 1): "down",
		Vector2(0, -1): "up",
		Vector2(1, 0): "right",
		Vector2(-1, 0): "left",
		Vector2(1, 1): "down_right",
		Vector2(-1, 1): "down_left",
		Vector2(1, -1): "up_right",
		Vector2(-1, -1): "up_left"
	}
	
	# The .round() is crucial here. It converts the direction vector into a clean,
	# grid-aligned vector (e.g., (0.707, -0.707) becomes (1, -1)),
	# which can be used as a key in our dictionary.
	var rounded_dir = last_direction.round()
	
	# Look up the rounded direction in our map.
	# If it's not found (which shouldn't happen with the current logic),
	# default to "down" to prevent a crash.
	return direction_map.get(rounded_dir, "down")
	
func update_animation( state : String ) -> void:
	var anim_dir = get_anim_direction_string()
	var anim_name = state + "_" + anim_dir
	
	# To prevent crashes, we check if the animation exists before playing it.
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		# If a diagonal animation is missing, fall back to a cardinal one.
		if anim_dir.contains("up"):
			sprite.play(state + "_up")
		elif anim_dir.contains("down"):
			sprite.play(state + "_down")
		elif anim_dir.contains("left"):
			sprite.play(state + "_left")
		elif anim_dir.contains("right"):
			sprite.play(state + "_right")
