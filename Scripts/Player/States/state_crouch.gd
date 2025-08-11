class_name State_Crouch extends State

@onready var idle: State = $"../Idle"
@onready var crouch_run: State = $"../CrouchRun"

func enter() -> void:
	player.is_crouched = true
	player.update_animation("crouch")
	player.velocity = Vector2.ZERO

func exit() -> void:
	# We only set is_crouched to false if we are not transitioning to another crouch state.
	# The CrouchRun state will handle keeping the player crouched.
	if not (state_machine.current_state is State_CrouchRun):
		player.is_crouched = false

func process(_delta: float) -> State:
	# Transition to CrouchRun if moving and holding run.
	if player.direction != Vector2.ZERO and Input.is_action_pressed("run"):
		return crouch_run
		
	# Stand up if crouch is toggled again, but only if allowed.
	if Input.is_action_just_pressed("crouch") and player.can_stand_up:
		return idle
		
	# If moving without holding run, transition to CrouchRun (it will handle speed).
	if player.direction != Vector2.ZERO:
		return crouch_run

	return null

func physics(_delta: float) -> State:
	# Slow down to a stop, similar to Idle.
	player.velocity = player.velocity.move_toward(Vector2.ZERO, 500 * _delta)
	return null
