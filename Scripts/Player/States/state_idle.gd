class_name State_Idle extends State

@onready var walk : State = $"../Walk"

func _ready() -> void:
	pass 

func enter() -> void:
	player.update_animation( "idle" )
	player.velocity = Vector2.ZERO

func exit() -> void:
	pass

func process( _delta : float ) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	return null

func physics( _delta : float ) -> State: 
	player.velocity = player.velocity.move_toward(Vector2.ZERO, 500 * _delta)
	return null

func handle_input( _event : InputEvent ) -> State:
	return null	
