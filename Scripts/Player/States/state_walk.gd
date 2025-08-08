class_name State_Walk extends State

@export_category("Movement")
@export var move_speed : float = 100.0

@onready var idle: State = $"../Idle"

func _ready() -> void:
	pass 

func enter() -> void:
	player.update_animation( "walk" )

func exit() -> void:
	pass

func process( _delta : float ) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	
	player.velocity = player.direction * move_speed
	
	if player.set_direction():
		player.update_animation( "walk" )	
	
	return null

func physics( _delta : float ) -> State: 
	return null	

func handle_input( _event : InputEvent ) -> State:
	return null	
