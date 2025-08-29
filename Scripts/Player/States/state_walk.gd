class_name State_Walk extends State

@export_category("Movement")
@export var move_speed : float = 100.0

@onready var idle: State = $"../Idle"
@onready var run: State = $"../Run"
@onready var crouch_run: State = $"../CrouchRun"

func enter() -> void:
	player.update_animation( "walk" )

func exit() -> void:
	pass

func process( _delta : float ) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	
		# Transition to Run state if run is pressed.
	if Input.is_action_pressed("run"):
		return run
		
	# Transition to CrouchRun state if crouch is toggled.
	if Input.is_action_just_pressed("crouch") and player.can_stand_up:
		return crouch_run
		
	return null

func physics( _delta : float ) -> State:
	# Apply movement velocity
	player.velocity = player.direction * move_speed
	
	# Check if the animation direction needs to change
	player.update_animation_direction()
	
	# Call the player's footstep audio handler with the walk-specific multiplier.
	player.handle_footstep_audio(_delta, 0.8)
	
	return null

func handle_input( _event : InputEvent ) -> State:
	return null

func update_animation() -> void:
	player.update_animation("walk")
