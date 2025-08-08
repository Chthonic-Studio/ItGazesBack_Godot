class_name Enemy extends CharacterBody2D

signal direction_changed ( new_direction : Vector2 )
signal enemy_damaged ()

# We'll use this to store the last non-zero direction for animations.
var last_direction : Vector2 = Vector2.DOWN
# This will be controlled by the state machine (Wander, Chase, etc.).
var direction : Vector2 = Vector2.ZERO

@export var hp : int = 3

@onready var sprite : AnimatedSprite2D = $EnemySprite
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

# We will add this for the Wander state to use
const DIR_4 := [ Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT ]

var invulnerable : bool = false

func _ready() -> void:
	# The state machine must be initialized to start the AI logic.
	state_machine.Initialize(self)

func _physics_process(delta: float) -> void:
	# This ensures the enemy moves based on the velocity set by its current state.
	move_and_slide()

## Sets the enemy's direction and returns true if it changed.
func set_direction(new_direction: Vector2) -> bool:
	var normalized_dir = new_direction.normalized()
	
	# Determine the dominant direction for 8-way animation.
	var new_anim_direction := Vector2.ZERO
	if abs(normalized_dir.x) > 0.2:
		new_anim_direction.x = sign(normalized_dir.x)
	if abs(normalized_dir.y) > 0.2:
		new_anim_direction.y = sign(normalized_dir.y)
	
	# Only update and emit the signal if the direction has actually changed.
	if new_anim_direction != last_direction:
		last_direction = new_anim_direction
		direction_changed.emit(last_direction)
		return true
		
	return false

# A direct copy of the player's animation direction logic.
func get_anim_direction_string() -> String:
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
	
	var rounded_dir = last_direction.round()
	return direction_map.get(rounded_dir, "down")

## Plays the correct animation based on state (e.g., "walk") and direction.
func update_animation(state: String) -> void:
	var anim_dir = get_anim_direction_string()
	var anim_name = state + "_" + anim_dir
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		# Fallback for missing diagonal animations, just like the player.
		if anim_dir.contains("up"):
			sprite.play(state + "_up")
		elif anim_dir.contains("down"):
			sprite.play(state + "_down")
		elif anim_dir.contains("left"):
			sprite.play(state + "_left")
		elif anim_dir.contains("right"):
			sprite.play(state + "_right")
