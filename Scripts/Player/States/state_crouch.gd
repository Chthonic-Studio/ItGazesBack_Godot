class_name State_Crouch extends State

@onready var idle: State = $"../Idle"
@onready var crouch_run: State = $"../CrouchRun"
# --- REASON FOR CHANGE ---
# We need a reference to the Hidden state to check against it in the exit function.
@onready var hidden: State = $"../Hidden"

func enter() -> void:
	player.is_crouched = true
	player.update_animation("crouch")
	player.velocity = Vector2.ZERO
	PlayerManager.is_crouched = true

func exit() -> void:
	if not (state_machine.current_state is State_CrouchRun or state_machine.current_state == hidden):
		player.is_crouched = false
	PlayerManager.is_crouched == false

func process(_delta: float) -> State:
	# If the player starts moving, transition to the crouch movement state.
	# That state will handle whether it's a walk or a run.
	if player.direction != Vector2.ZERO:
		return crouch_run
		
	# Stand up if crouch is toggled again, but only if allowed.
	if Input.is_action_just_pressed("crouch") and player.can_stand_up:
		return idle

	return null

func physics(_delta: float) -> State:
	# Slow down to a stop, similar to Idle.
	player.velocity = player.velocity.move_toward(Vector2.ZERO, 500 * _delta)
	return null
