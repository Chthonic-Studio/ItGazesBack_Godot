class_name State_Crouch extends State

@onready var idle: State = $"../Idle"
@onready var crouch_run: State = $"../CrouchRun"
@onready var hidden: State = $"../Hidden"

func enter() -> void:
	player.is_crouched = true
	player.update_animation("crouch")
	player.velocity = Vector2.ZERO
	PlayerManager.is_crouched = true

func exit() -> void:
	pass

func process(_delta: float) -> State:
	# Movement -> moving crouch state
	if player.direction != Vector2.ZERO:
		return crouch_run
	
	# Attempt to stand
	if Input.is_action_just_pressed("crouch"):
		if player.can_stand_up:
			player.is_crouched = false
			PlayerManager.is_crouched = false
			return idle
		else:
			# Forced crouch: show blocked message
			player.show_blocked_stand_message()
	
	return null

func physics(_delta: float) -> State:
	player.velocity = player.velocity.move_toward(Vector2.ZERO, 500 * _delta)
	return null
