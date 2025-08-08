class_name State_Walk extends State

@export_category("Movement")
@export var move_speed : float = 100.0

@onready var idle: State = $"../Idle"

func enter() -> void:
	player.update_animation( "walk" )

func exit() -> void:
	pass

func process( _delta : float ) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	
	# Let the physics process handle movement
	return null

func physics( _delta : float ) -> State:
	# Apply movement velocity
	player.velocity = player.direction * move_speed
	
	# Check if the animation direction needs to change
	player.update_animation_direction()
	
	return null

func handle_input( _event : InputEvent ) -> State:
	return null

func update_animation() -> void:
	player.update_animation("walk")
