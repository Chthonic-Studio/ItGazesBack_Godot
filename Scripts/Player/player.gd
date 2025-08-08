class_name Player extends CharacterBody2D

@export_category("Health")
@export var max_hp : int = 6
@export var hp : int = 6


const DIR_4 = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

@onready var sprite : AnimatedSprite2D = $PlayerSprite
@onready var state_machine: PlayerStateMachine = $StateMachine

signal direction_changed ( new_direction : Vector2 )

func _ready() -> void:
	state_machine.initialize(self)


func _process( delta ):
	
	#direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	#direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
func _physics_process( delta ):
	move_and_slide()
	
func set_direction(  ) -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var direction_id : int = int ( round( ( direction ).angle() / TAU * DIR_4.size() ) )
	var new_dir = DIR_4[ direction_id ]
		
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	direction_changed.emit( new_dir )
	return true
	
func update_animation( state : String ) -> void:
	sprite.play( state + "_" + anim_direction() )
	
func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	elif cardinal_direction == Vector2.LEFT:
		return "left"
	else:
		return "right"	
