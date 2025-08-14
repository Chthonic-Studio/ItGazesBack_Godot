class_name State_CrouchRun extends State

@export var crouch_walk_speed : float = 50.0
@export var crouch_run_speed : float = 100.0

@onready var crouch: State = $"../Crouch"
@onready var run: State = $"../Run"
@onready var walk: State = $"../Walk"
# --- REASON FOR CHANGE ---
# We need a reference to the Hidden state for consistency in our exit logic.
@onready var hidden: State = $"../Hidden"

func enter() -> void:
	player.is_crouched = true
	# The animation will be based on whether "run" is held down.
	update_animation()

func exit() -> void:
	# --- REASON FOR CHANGE ---
	# We add the same check as in the Crouch state. We should not stand up
	# if the next state is one that preserves the crouch/hidden memory.
	if not (state_machine.current_state is State_Crouch or state_machine.current_state == hidden):
		player.is_crouched = false

func process(_delta: float) -> State:
	# If we stop moving, go to the base Crouch state.
	if player.direction == Vector2.ZERO:
		return crouch

	# If we toggle crouch, stand up. Transition to Run or Walk based on input.
	if Input.is_action_just_pressed("crouch") and player.can_stand_up:
		if Input.is_action_pressed("run"):
			return run
		else:
			return walk
	
	# Check if we need to switch between crouch_walk and crouch_run animations.
	if Input.is_action_just_pressed("run") or Input.is_action_just_released("run"):
		update_animation()

	return null

func physics(_delta: float) -> State:
	# Set speed based on whether the run key is held.
	var current_speed = crouch_run_speed if Input.is_action_pressed("run") else crouch_walk_speed
	player.velocity = player.direction * current_speed
	player.update_animation_direction()
	return null
	
func update_animation() -> void:
	# Use "crouch_run" for faster movement, "crouch_walk" for slower.
	# You will need to create these animations in the AnimatedSprite2D.
	var anim_name = "crouch_run" if Input.is_action_pressed("run") else "crouch_walk"
	player.update_animation(anim_name)
